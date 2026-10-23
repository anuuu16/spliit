#!/usr/bin/env bash
# Builds the Taiga upload from a branch (default sandbox-base) and refuses to finish if anything that must not be uploaded is inside.
# sandbox-base already has .github, .devcontainer, the Docker/compose files, scripts/, perf/, README.md and vercel.json removed;
# this script leaves out this .sandbox/ folder and checks that nothing of that kind came back (e.g. from a task branch).
# Usage (from the repo root): bash .sandbox/make-sandbox-zip.sh [branch]
# Or, with any branch checked out: git -C <repo> show sandbox-base:.sandbox/make-sandbox-zip.sh | REPO=<repo> bash -s -- [branch]
set -euo pipefail

if [ -n "${REPO:-}" ]; then REPO="$(cd "$REPO" && pwd)"; else REPO="$(cd "$(dirname "$0")/.." && pwd)"; fi
BRANCH="${1:-sandbox-base}"
NAME="spliit"
ZIP="$(dirname "$REPO")/$NAME-sandbox.zip"

git -C "$REPO" rev-parse --verify --quiet "$BRANCH" >/dev/null || { echo "No branch '$BRANCH' in $REPO"; exit 1; }
echo "Branch $BRANCH @ $(git -C "$REPO" log --oneline -1 "$BRANCH")"

# Left out of the upload. A trailing "/" means the whole folder.
DROP=(
	.sandbox/
)

dropped() { # path -> 0 if it is left out
	local path="$1" entry
	for entry in "${DROP[@]}"; do
		case "$entry" in
			*/) [ "${path#"$entry"}" != "$path" ] && return 0 ;;
			*) [ "$path" = "$entry" ] && return 0 ;;
		esac
	done
	return 1
}

files=()
skipped=0
while IFS= read -r -d '' path; do
	if dropped "$path"; then skipped=$((skipped + 1)); else files+=("$path"); fi
done < <(git -C "$REPO" ls-tree -r -z --name-only "$BRANCH")
echo "Files: ${#files[@]} packed, $skipped left out"

# git archive packs committed files only: no .git, no node_modules, no .env, no build output.
rm -f "$ZIP"
git -C "$REPO" --literal-pathspecs archive --format=zip --prefix="$NAME/" -o "$ZIP" "$BRANCH" -- "${files[@]}"

fail=0
check() { # name, count, expected
	if [ "$2" != "$3" ]; then echo "  ✗ $1: $2 (expected $3)"; fail=1; else echo "  ✓ $1"; fi
}
list="$(unzip -Z1 "$ZIP")"
check ".git entries"            "$(grep -c '/\.git/' <<<"$list" || true)" 0
check "node_modules entries"    "$(grep -c 'node_modules/' <<<"$list" || true)" 0
check "build output (.next, generated prisma)" "$(grep -cE "/\.next/|^$NAME/src/generated/" <<<"$list" || true)" 0
check ".env files (except .env.example)" "$(grep -E '/\.env' <<<"$list" | grep -vc '\.env\.example$' || true)" 0
check "agent / AI-tool files"   "$(grep -ciE '(^|/)(AGENTS|CLAUDE|GEMINI)\.md$|copilot-instructions\.md$|(^|/)SKILL\.md$|(^|/)\.mcp\.json$|(^|/)llms(-full)?\.txt$|/\.(cursor|codex|gemini|windsurf|claude|agents|kiro)/|\.cursorrules$' <<<"$list" || true)" 0
check ".github / .devcontainer" "$(grep -cE "^$NAME/\.(github|devcontainer)/" <<<"$list" || true)" 0
check "Docker / deploy files"   "$(grep -ciE "^$NAME/(Dockerfile|compose[^/]*\.ya?ml|\.dockerignore|container\.env\.example|vercel\.json)$|^$NAME/(scripts|perf)/" <<<"$list" || true)" 0
check "README.md (COMMANDS.md instead)" "$(grep -c "^$NAME/README\.md$" <<<"$list" || true)" 0
check "COMMANDS.md present"     "$(grep -c "^$NAME/COMMANDS\.md$" <<<"$list" || true)" 1
check "this .sandbox folder"    "$(grep -c "^$NAME/\.sandbox/" <<<"$list" || true)" 0
check ".gitignore present"      "$(grep -c "^$NAME/\.gitignore$" <<<"$list" || true)" 1
check "package-lock.json, pnpm-lock.yaml, .npmrc, .env.example present" "$(grep -cE "^$NAME/(package-lock\.json|pnpm-lock\.yaml|\.npmrc|\.env\.example)$" <<<"$list" || true)" 4
check "pnpm builds approved"    "$(unzip -p "$ZIP" "$NAME/package.json" | grep -c '"onlyBuiltDependencies"' || true)" 1
check "next.config: agentRules off" "$(unzip -p "$ZIP" "$NAME/next.config.mjs" | grep -c 'agentRules: false' || true)" 1
check "private registry URLs"   "$(unzip -p "$ZIP" | grep -acE 'artifactor[y]|\.jfrog\.io' || true)" 0
check "API keys"                "$(unzip -p "$ZIP" | grep -acE 'sk-[A-Za-z0-9_-]{20,}|sk-ant-|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_|BEGIN [A-Z ]*PRIVATE KEY' || true)" 0

ls -lh "$ZIP" | awk '{print "Size:", $5, " ->", $9}'
if [ "$fail" = 1 ]; then echo "NOT OK: fix the items above before uploading."; rm -f "$ZIP"; exit 1; fi
echo "OK: upload $ZIP with 'Mount files' (extraction path /workspace)."
