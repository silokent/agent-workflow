# agent-workflow

[English](README.md) · **Tiếng Việt**

Quy trình dùng chung cho mọi project. Bạn chỉ nói chuyện với **Claude Code (Orchestrator)**; Claude giao việc cho Codex qua lệnh `agent-run`:

    bạn ──► Claude Orchestrator ──► Researcher (gpt-6.1-sol high, web search, chỉ đọc) → docs/research/
                                 ├► Planner    (gpt-6-astra high)   → TASK.md + test baseline
                                 ├► Artist     (gpt-6.1-sol high)   → mọi ảnh: sprite, icon, banner…
                                 ├► Executor   (gpt-6.1-sol xhigh | --hard: gpt-6-astra medium) → code, KHÔNG chạy test
                                 └► Reviewer   (gpt-6.1-sol high)   → đọc lại code, tự viết test độc lập, ghi REVIEW (≤ 3 vòng)
                 ◄── chạy lại test, xem diff, kiểm tay rồi báo kết quả

Luật nằm trong khối `agent-workflow` của `AGENTS.md` (Codex đọc sẵn, Claude đọc qua skill `orchestrate`). Kit không dùng `CLAUDE.md`.

## Bộ nhớ không phụ thuộc session
Mất phiên chat, mất phiên Codex hay đổi máy vẫn làm tiếp được, vì mọi trạng thái nằm trong file được commit:
- `TASK.md`: khối trạng thái, **0. ĐIỀU PHỐI** (yêu cầu gốc, giai đoạn, quyết định của user, nhật ký điều phối), plan, tiến trình, review.
- `docs/tasks/` + `INDEX.md`: các task đã xong. `docs/research/`: báo cáo research. `docs/assets/PROMPTS.md`: prompt tạo ảnh.
- `agent-task status`: tóm tắt đang làm gì / tới đâu / làm tiếp thế nào. Hook SessionStart in nó vào mọi phiên Claude mới.
- `agent-run` tự ghi nhật ký điều phối, tự lưu task cũ khi lập task mới, tự dựng lại mốc diff ở clone khác.
- `.agent-workflow/` (log, id phiên Codex, khoá) chỉ là bộ đệm cục bộ, không commit.

## Kiểm tra trước khi pull / push
`agent-task sync-check pull|push` sẽ fetch rồi báo **OK** hoặc **CHƯA ĐƯỢC**. Nó kiểm tra:
- merge/rebase đang làm dở, file còn xung đột;
- file chưa commit trùng với file remote đã sửa;
- giả lập merge bằng `git merge-tree` để thấy trước xung đột;
- local có đang đi sau remote không (push sẽ bị từ chối);
- `TASK.md` có bị máy hoặc agent khác sửa không.

Hook PreToolUse `agent-task guard` chặn `git pull` / `git push` của Claude khi kết quả không OK.

## Thành phần
- `WORKFLOW.md`: luật cho mọi agent. `install.sh` chèn nó vào `AGENTS.md` của project.
- `roles.conf`: model / effort / sandbox / mạng của từng vai. Project ghi đè ở `.agent-workflow/roles.conf`.
- `bin/agent-run`: gọi `codex exec` cho một vai, in câu trả lời cuối.
- `bin/agent-task`: `status`, `archive`, `sync-check`, `guard`.
- `bin/journal.py`: ghi một dòng vào "Nhật ký điều phối".
- `roles/*.md`: lời dặn riêng từng vai (planner, executor, reviewer, researcher, artist).
- `skills/`: `orchestrate`, `plan-task`, `review-task`, được link vào `~/.claude/skills/`.
- `templates/`: `TASK.md`, `AGENTS.project.md`.

## Cài vào project
    ~/agent-workflow/install.sh --global              # chỉ phần dùng chung cho máy (lệnh, skill, hook)
    ~/agent-workflow/install.sh /đường/dẫn/project    # cài vào project (kèm luôn phần dùng chung)
Lần đầu chạy, lệnh này:
- link `agent-run` và `agent-task` vào `~/.local/bin`;
- link 3 skill vào `~/.claude/skills`. Skill cũ dạng thư mục thật được chuyển vào `.backup/`;
- thêm 2 hook vào `~/.claude/settings.json`, sau khi lưu bản sao `settings.json.bak-agent-workflow`.

Chạy lại bao nhiêu lần cũng được, không bị lặp. Sau đó điền phần mô tả project ở đầu `AGENTS.md`: lệnh test, **thư mục / quy ước test**, cấu trúc thư mục. Planner và Reviewer dựa vào phần này.

## Dùng
Mở Claude Code trong project và nói yêu cầu như bình thường, kể cả "làm tiếp" (hoặc `/orchestrate <yêu cầu>`). Gọi tay để thử:

    agent-task status
    agent-task sync-check pull
    agent-run researcher --save phaser-webgpu "Phaser 4 có hỗ trợ WebGPU chưa?"
    agent-run artist "assets/coin.png 32x32 PNG nền trong suốt, pixel art"
    agent-run planner --dry-run "…"                                   # chỉ in lệnh codex
    AGENT_EFFORT=low agent-run reviewer "Review task trong TASK.md."  # ghi đè effort một lần

## Đổi model / luật
- Đổi model cho mọi project: sửa `roles.conf`. Cho một project: tạo `.agent-workflow/roles.conf` chỉ với dòng cần đổi.
- Đổi luật: sửa `WORKFLOW.md` hoặc `templates/TASK.md` rồi chạy lại `install.sh` cho từng project. `roles/`, `roles.conf`, `bin/`, `skills/` có hiệu lực ngay.
