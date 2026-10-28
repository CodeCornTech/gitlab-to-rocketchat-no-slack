#!/usr/bin/env bash
# Publish the prepared repository. Dry-run by default; --apply performs writes.
# Requires an authenticated GitHub CLI on the operator's own computer.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OWNER="${GITHUB_OWNER:-CodeCornTech}"
REPO="${GITHUB_REPO:-gitlab-to-rocketchat-no-slack}"
FULL="$OWNER/$REPO"
MODE="${1:---dry-run}"

if [[ "$MODE" != '--dry-run' && "$MODE" != '--apply' ]]; then
  printf 'Usage: %s [--dry-run|--apply]\n' "$0" >&2
  exit 2
fi
printf 'Repository: %s\nVisibility: PUBLIC\nMode: %s\n' "$FULL" "$MODE"
printf 'Will initialize local git, make the initial commit, create a public GitHub repo, and push main.\n'
printf 'Webhook URLs and tokens are not included in this project.\n'

if [[ "$MODE" == '--dry-run' ]]; then
  printf '\nDry run only; no changes were made.\n'
  printf 'To publish, install/authenticate gh then run: bash scripts/publish-github.sh --apply\n'
  exit 0
fi

for cmd in git gh python3; do
  command -v "$cmd" >/dev/null 2>&1 || { printf 'ERROR: %s is required.\n' "$cmd" >&2; exit 1; }
done
(cd "$ROOT" && python3 -m unittest discover -s tests -q)
gh auth status >/dev/null

if gh repo view "$FULL" >/dev/null 2>&1; then
  printf 'ERROR: %s already exists or is accessible. Refusing to overwrite it.\n' "$FULL" >&2
  exit 1
fi

cd "$ROOT"
if [[ ! -d .git ]]; then
  git init -b main
fi
if [[ "$(git symbolic-ref --quiet --short HEAD)" != 'main' ]]; then
  printf 'ERROR: local branch is not main. Refusing to publish.\n' >&2
  exit 1
fi
if git remote get-url origin >/dev/null 2>&1; then
  printf 'ERROR: an origin remote already exists. Inspect manually.\n' >&2
  exit 1
fi

# Explicit allowlist of published files: never accidentally stage secrets.
git add -- README.md LICENSE SECURITY.md .gitignore .editorconfig \
  docs/it.md docs/troubleshooting.md docs/native-webhooks.md \
  examples/payload.json \
  scripts/test-webhook.sh scripts/publish-github.sh \
  tests/test_repository.py .github/workflows/validate.yml

# Validate the staged diff before the PUBLIC push.
if git diff --cached --name-only | grep -Eq '(^|/)(\.env|.*\.pem|.*\.key)$'; then
  printf 'ERROR: staged files contain a suspicious secret filename.\n' >&2
  exit 1
fi
if ! git diff --cached --quiet; then
  git commit -m 'docs: explain GitLab to Rocket.Chat notifications without Slack'
fi

gh repo create "$FULL" --public \
  --description 'GitLab notifications in Rocket.Chat — no Slack account or middleware required.' \
  --source=. --remote=origin --push
printf '\nPublished: https://github.com/%s\n' "$FULL"
