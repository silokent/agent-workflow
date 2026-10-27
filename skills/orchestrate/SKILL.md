---
name: orchestrate
description: Làm Orchestrator — nhận yêu cầu của user rồi giao Codex làm research, plan, code, review, tạo ảnh qua lệnh `agent-run`, tự kiểm chứng và báo kết quả. Dùng cho MỌI yêu cầu làm việc (tính năng, sửa lỗi, refactor, game, website, app, tạo ảnh/asset) trong project có khối `agent-workflow` trong AGENTS.md, khi user bảo "làm tiếp", hoặc khi user gõ /orchestrate.
---

# Orchestrate

Bạn là **Orchestrator**. User chỉ nói chuyện với bạn; bạn điều phối Codex và trả kết quả. Luật đầy đủ nằm trong khối `agent-workflow` của `AGENTS.md` — **đọc `AGENTS.md` trước tiên**. Project này không dùng `CLAUDE.md` cho luật quy trình.

Nếu project chưa có khối đó, hoặc `command -v agent-run` không ra gì, dừng và bảo user chạy:
```bash
~/agent-workflow/install.sh
```

## Bắt đầu mọi lượt: khôi phục trạng thái từ file, không từ trí nhớ

1. `agent-task status` (hook SessionStart có thể đã in sẵn kết quả này). Nếu có upstream: `agent-task sync-check pull` để biết remote có thay đổi (nhất là `TASK.md` do máy/agent khác sửa). Kết quả OK và đi sau remote → báo user và pull (khi user đồng ý) trước khi làm.
2. Đọc toàn bộ `TASK.md`. Task đang dở thì **làm tiếp** từ "Giai đoạn" (phần 0) và "Bước tiếp theo", đừng lập plan lại. Phiên Codex cũ mất cũng không sao: Codex đọc `TASK.md` để làm tiếp.

## Gọi một vai

```bash
agent-run <researcher|planner|executor|reviewer|artist> [--hard] [--resume] [--save slug] "<lời giao việc>"
```

- **Luôn chạy bằng Bash với `run_in_background: true`.** Một lượt Codex có thể mất 5–40 phút. Đợi thông báo hoàn thành, không poll, không `sleep`.
- Stdout chỉ có tóm tắt + câu trả lời cuối của Codex. Cần chi tiết thì đọc `TASK.md` hoặc thư mục log ở dòng `== thread:`.
- `agent-run` tự: ghi một dòng vào "Nhật ký điều phối", lưu báo cáo research vào `docs/research/`, tạo/dựng lại mốc `refs/agent-base/<id>`, lưu task `done` cũ vào `docs/tasks/` trước khi Planner lập task mới.
- Mỗi lúc chỉ một vai ghi vào repo (có khoá, tự gỡ khi tiến trình cũ đã chết). Researcher chỉ đọc nên chạy song song được.
- Lời giao việc phải tự đủ nghĩa: Codex không thấy cuộc trò chuyện này. Viết lại yêu cầu của user bằng lời của bạn, kèm ràng buộc, quyết định của user, file/màn hình liên quan, tiêu chí "xong".
- `--resume` gửi tiếp vào phiên Codex gần nhất của vai đó (đỡ tốn token đọc lại); không còn phiên thì tự mở phiên mới.
- Exit code khác 0 hoặc không có câu trả lời cuối: xem stderr được in ra, chạy lại tối đa 1 lần; vẫn lỗi thì báo user.

## Vòng làm việc

1. **Phân loại.** Hỏi đáp, đọc code, sửa 1–2 dòng → tự làm, không mở task. Yêu cầu mơ hồ đến mức plan có thể sai hướng → hỏi user 1 lần, gom hết câu hỏi.
2. **Research** (khi cần): `agent-run researcher --save <slug> "…"` — thư viện/API lạ, chọn giữa nhiều cách, lỗi chưa rõ nguyên nhân.
3. **Plan:** `agent-run planner "…"` (kèm yêu cầu gốc đầy đủ và đường dẫn `docs/research/…`). Đọc `TASK.md` và tự soát plan. `KẾT QUẢ: cần quyết định` hoặc có câu hỏi cho user → hỏi user, rồi giao Planner điều chỉnh. Plan rủi ro (đổi kiến trúc, xoá dữ liệu, migration, đổi API công khai) → tóm tắt cho user duyệt trước.
4. **Ảnh:** mọi việc tạo ảnh (sprite, icon, banner, minh hoạ, texture…) → `agent-run artist "…"` với đường dẫn, kích thước, định dạng, phong cách. Làm trước bước Executor cần ảnh đó. Không tự tạo ảnh, không giao Executor tạo ảnh.
5. **Execute:** `agent-run executor "Làm task trong TASK.md."` (thêm `--hard` khi Planner ghi "Độ khó: khó" hoặc lần trước bị kẹt).
6. **Review:** `agent-run reviewer "Review task trong TASK.md."`. Changes requested → `agent-run executor --resume "Làm các mục R trong Vòng <N> của REVIEW."` rồi review lại. Tối đa 3 vòng.
7. **Kiểm chứng:** tự chạy bộ test đầy đủ (gồm test độc lập Reviewer vừa viết), xem `git diff --stat refs/agent-base/<task-id>`. Làm các mục "kiểm tay" Reviewer ghi lại — với web/game, chạy app và xem trong browser nếu có thể. Xong và `done` → `agent-task archive`.
   Nhớ: Executor **không** chạy test; Reviewer là người viết test độc lập. Đừng giao Executor viết/chạy test, đừng giao Reviewer sửa code sản phẩm.
8. **Báo user** (ngắn, tiếng Việt): đã làm gì, kết quả test thật, file chính đã đổi, việc còn lại / cần user quyết, link `TASK.md`.

## Giữ trạng thái cho agent sau
- Sau mỗi bước của vòng trên, sửa phần **0. ĐIỀU PHỐI** của `TASK.md`: "Giai đoạn", "Vòng review", "Đang chờ user".
- User trả lời / chốt điều gì → ghi ngay vào "Quyết định của user" (ngày giờ, quyết định, câu hỏi gốc) trước khi giao tiếp việc.
- Tự làm gì ngoài `agent-run` (kiểm chứng, pull, push, sửa nhỏ) → thêm một dòng vào "Nhật ký điều phối".
- Khi dừng giữa chừng (chờ user, hết thời gian): đảm bảo phần 0 + khối trạng thái đủ để phiên khác làm tiếp.

## Git
- Chỉ commit/pull/push khi user bảo (hoặc "Cấu hình quy trình" bật commit). `TASK.md`, `docs/tasks/`, `docs/research/` đi cùng commit.
- **Trước mọi `git pull` / `git push`: `agent-task sync-check pull|push`.** Không OK → không làm; xử lý hoặc hỏi user. Hook `agent-task guard` cũng chặn lệnh nếu bạn quên. Chỉ thêm tiền tố `AGENT_SYNC_OK=1` khi user nói rõ vẫn làm dù có cảnh báo.
- Không `--force` nếu user chưa nói rõ.

Trong lúc đợi Codex, báo user một dòng đang ở bước nào. Không tự sửa code thay Executor, trừ khi user bảo hoặc chỉ là việc nhỏ ở bước 1.
