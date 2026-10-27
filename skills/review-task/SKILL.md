---
name: review-task
description: Review phần một agent khác (Codex/Antigravity) đã làm cho task trong TASK.md, đối chiếu với KẾ HOẠCH và TIẾN TRÌNH, rồi ghi kết quả vào phần REVIEW. Dùng khi user gõ /review-task, hoặc bảo "review task", "kiểm tra xem Codex làm đúng plan chưa".
---

# Review task

Bạn đang ở vai **Reviewer** trong quy trình mô tả ở khối `agent-workflow` của `AGENTS.md`.

## Các bước

1. Đọc toàn bộ `TASK.md`. Nếu không có file hoặc trạng thái là `done`, báo user là không có task để review. Nếu bảng bước còn `todo`/`doing`/`blocked`, báo user và hỏi có review phần đã làm luôn không.
2. Lấy đúng phần đã thay đổi của task:
   ```bash
   git diff --stat refs/agent-base/<task-id> -- . ':!TASK.md'
   git diff refs/agent-base/<task-id> -- . ':!TASK.md'
   git log --oneline refs/agent-base/<task-id>..HEAD
   git status --short
   ```
   - Đọc cả file mới chưa track, tức là file có trong `git status` nhưng không nằm trong danh sách "đã bẩn sẵn" ở mục "Mốc".
   - Nếu ref mốc không tồn tại, dùng danh sách "File sửa" trong nhật ký và ghi rõ điều đó trong REVIEW.
   - Nếu diff có file không nằm trong nhật ký của Executor, hỏi user có phải họ tự sửa không. Nếu đúng, không tính là lỗi của task.
3. **Đọc lại toàn bộ code Executor đã sửa**, rồi **viết test độc lập** dựa vào KẾ HOẠCH ("Đạt khi", "Reviewer kiểm tra", Tiêu chí hoàn thành) và các chỗ dễ sai khi đọc code — không dựa vào nhật ký hay lời tóm tắt của Executor. Đặt test theo quy ước test trong `AGENTS.md`; không tự thêm dependency. Vòng sau: chạy lại test cũ, thêm test cho các mục R vừa sửa.
4. Đối chiếu:
   - từng bước `S<n>` (kể cả bước trong "Điều chỉnh kế hoạch"; bước bị bỏ phải là `skipped`) và các mục `R<n>` của vòng trước: làm đúng, lệch hay thiếu so với "Làm" / "Đạt khi";
   - thay đổi ngoài phạm vi, hoặc chạm vào mục "Không được đụng";
   - lỗi logic, edge case, test thiếu. Đọc code thật, không tin lời tóm tắt trong nhật ký;
   - nhật ký có ghi đúng sự thật không (kết quả test, file đã sửa).
5. Chạy test mới + bộ test đầy đủ. So với "Test baseline" trong KẾ HOẠCH: chỉ test fail **mới** mới tính là lỗi của task. Test mới fail → mục R có tên test và hành vi mong đợi.
6. Thêm "Vòng N" vào phần **3. REVIEW** theo mẫu (kèm danh sách test đã viết và mục "kiểm tay" nếu có). Mỗi việc cần sửa là một mục `R<n>`, **số nối tiếp các vòng trước**, có `file:dòng`, việc cần làm và tiêu chí đạt. Viết cho một agent khác đọc hiểu được mà không cần hỏi lại.
7. Cập nhật khối trạng thái:
   - **Changes requested:** `changes-requested`, "Bước tiếp theo" là mục R đầu tiên.
   - **Approve:** `done`, rồi `agent-task archive` (lưu vào `docs/tasks/`, xoá mốc). Giữ `TASK.md` để user đọc; nó sẽ bị thay khi có kế hoạch mới.

   Chỉ ghi file test và `TASK.md`. **Không tự sửa code sản phẩm** trừ khi user yêu cầu.
8. Trả lời user: kết luận, các lỗi quan trọng nhất và link tới `TASK.md`. Nếu Changes requested, kèm câu giao việc trong code block:
   ```
   Làm các mục R trong Vòng <N> của phần REVIEW trong TASK.md theo quy trình trong AGENTS.md, vai Executor. Cập nhật phần TIẾN TRÌNH sau mỗi mục.
   ```
