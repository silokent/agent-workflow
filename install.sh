#!/usr/bin/env bash
# Cài hoặc cập nhật quy trình Orchestrator → Plan → Execute → Review vào một project.
#   ~/agent-workflow/install.sh [đường-dẫn-project]   (mặc định: thư mục hiện tại)
# Chạy lại bất cứ lúc nào: chỉ thay khối workflow trong AGENTS.md và file mẫu,
# không đụng phần mô tả riêng của project hay TASK.md đang có.
# Luật dùng chung nằm trong AGENTS.md (Codex đọc sẵn; Claude đọc qua skill orchestrate),
# nên kit không ghi gì vào CLAUDE.md.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$(cd "${1:-.}" && pwd)"

# --- Phần dùng chung cho mọi project (idempotent) ---
mkdir -p "$HOME/.local/bin" "$HOME/.claude/skills"
ln -sfn "$KIT/bin/agent-run" "$HOME/.local/bin/agent-run"
ln -sfn "$KIT/bin/agent-task" "$HOME/.local/bin/agent-task"
# Skill Claude cấp user. Thư mục thật (không phải link) có sẵn thì chuyển vào kit/.backup trước khi thay bằng link.
for SKILL in orchestrate plan-task review-task; do
  DEST="$HOME/.claude/skills/$SKILL"
  if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
    mkdir -p "$KIT/.backup/skills"
    mv "$DEST" "$KIT/.backup/skills/$SKILL-$(date +%Y%m%d-%H%M%S)"
    echo "Skill $SKILL cũ đã chuyển vào $KIT/.backup/skills/"
  fi
  ln -sfn "$KIT/skills/$SKILL" "$DEST"
done

# Hook Claude Code (cấp user): SessionStart in trạng thái task; PreToolUse chặn git pull/push khi sync-check không đạt.
# Chỉ thêm nếu chưa có; sao lưu settings.json trước khi ghi.
SETTINGS="$HOME/.claude/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
STATUS_CMD="$HOME/.local/bin/agent-task status --hook"
GUARD_CMD="$HOME/.local/bin/agent-task guard"
NEW="$(jq --arg s "$STATUS_CMD" --arg g "$GUARD_CMD" '
  def has($c): [.. | objects | select(.type? == "command") | .command] | index($c) != null;
  (if has($s) then . else .hooks.SessionStart += [{hooks: [{type: "command", command: $s, timeout: 15}]}] end)
  | (if has($g) then . else .hooks.PreToolUse += [{matcher: "Bash", hooks: [{type: "command", command: $g, timeout: 90}]}] end)
' "$SETTINGS")"
if [ "$NEW" != "$(jq . "$SETTINGS")" ]; then
  cp "$SETTINGS" "$SETTINGS.bak-agent-workflow"
  printf '%s\n' "$NEW" > "$SETTINGS"
  echo "~/.claude/settings.json: đã thêm hook agent-task (bản cũ: settings.json.bak-agent-workflow)"
fi
command -v agent-run >/dev/null || echo "Lưu ý: ~/.local/bin chưa nằm trong PATH, agent-run sẽ không gọi được."
command -v codex >/dev/null || echo "Lưu ý: chưa cài Codex CLI (codex)."

# --- Phần riêng của project ---
mkdir -p "$PROJECT/docs"
cp "$KIT/templates/TASK.md" "$PROJECT/docs/TASK.template.md"

python3 - "$PROJECT/AGENTS.md" "$KIT/WORKFLOW.md" "$KIT/templates/AGENTS.project.md" <<'PY'
import os
import re
import sys

agents_path, workflow_path, project_template_path = sys.argv[1:]
with open(workflow_path, encoding="utf-8") as stream:
    block = stream.read().strip()
pattern = re.compile(r"<!-- agent-workflow:start.*?<!-- agent-workflow:end -->", re.S)

if os.path.exists(agents_path):
    with open(agents_path, encoding="utf-8") as stream:
        text = stream.read()
    if pattern.search(text):
        text = pattern.sub(lambda _match: block, text)
        action = "đã cập nhật khối workflow"
    else:
        text = text.rstrip() + "\n\n" + block + "\n"
        action = "đã thêm khối workflow vào cuối file có sẵn"
else:
    with open(project_template_path, encoding="utf-8") as stream:
        text = stream.read().rstrip() + "\n\n" + block + "\n"
    action = "đã tạo mới — hãy điền phần mô tả project ở đầu file"

with open(agents_path, "w", encoding="utf-8") as stream:
    stream.write(text)
print(f"AGENTS.md: {action}")
PY

# Log của agent-run không vào git: dùng .git/info/exclude để khỏi sửa .gitignore của project.
if GIT_DIR="$(git -C "$PROJECT" rev-parse --git-common-dir 2>/dev/null)"; then
  case "$GIT_DIR" in /*) ;; *) GIT_DIR="$PROJECT/$GIT_DIR" ;; esac
  EXCLUDE="$GIT_DIR/info/exclude"
  mkdir -p "$(dirname "$EXCLUDE")"
  grep -qxF "/.agent-workflow/" "$EXCLUDE" 2>/dev/null || echo "/.agent-workflow/" >> "$EXCLUDE"
else
  echo "Lưu ý: $PROJECT chưa là git repo — agent-run và mốc refs/agent-base cần git."
fi

echo "Xong: $PROJECT"
