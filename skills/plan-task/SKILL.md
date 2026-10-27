---
name: plan-task
description: Lập hoặc điều chỉnh kế hoạch trong TASK.md theo quy trình Plan → Execute → Review, để Codex/Antigravity thực hiện. Dùng khi user gõ /plan-task, hoặc bảo "lên kế hoạch", "viết plan", "sửa plan". Chỉ viết kế hoạch, không sửa code.
---

# Plan task

Bạn đang ở vai **Planner** trong quy trình mô tả ở khối `agent-workflow` của `AGENTS.md`. Nếu project chưa có khối đó hoặc chưa có `docs/TASK.template.md`, dừng lại và bảo user chạy:

```bash
~/agent-workflow/install.sh
```

## Các bước

1. Đọc `AGENTS.md`. Nếu có `TASK.md`, đọc toàn bộ và xem trạng thái:
   - không có file, hoặc trạng thái `done` → **task mới** (bước 4);
   - user muốn sửa plan hiện tại → **điều chỉnh** (bước 6);
   - trạng thái chưa `done` mà user đưa yêu cầu mới → hỏi user nên điều chỉnh task hiện tại hay bỏ nó để làm task mới. **Không ghi đè task chưa xong** khi user chưa trả lời.
2. Tìm hiểu code liên quan đủ để thiết kế. Dùng subagent Explore nếu phải quét nhiều file. **Không sửa code.**
3. Nếu còn quyết định mà chỉ user trả lời được, hỏi trước khi viết.
4. **Task mới:**
   - Task cũ đã `done` mà chưa có `docs/tasks/<task-id-cũ>.md` → chạy `agent-task archive` (lưu task cũ, xoá ref mốc cũ).
   - Chép `docs/TASK.template.md` thành `TASK.md` (thay file cũ).
   - Đặt Task ID = `YYYYMMDD-ten-ngan` (ngày hôm nay, slug không dấu).
5. Điền phần **1. KẾ HOẠCH**:
   - Viết cho một agent **khác**, không có ngữ cảnh cuộc trò chuyện này: nêu rõ đường dẫn, tên hàm, ràng buộc kỹ thuật.
   - Ghi HEAD hiện tại (`git rev-parse --short HEAD`, nhánh). **Không** tạo ref mốc; Executor sẽ tạo khi bắt đầu.
   - Mỗi bước `S<n>` nhỏ, làm tuần tự được, có "Đạt khi" kiểm chứng được và "Reviewer kiểm tra" (hành vi cần test, edge case).
   - Mục **Không được đụng** phải cụ thể (file, hàm, hành vi).
   - **Không** có bước viết/chạy test cho Executor: Executor không chạy test, Reviewer tự viết test độc lập.
   - Chạy bộ test đầy đủ ở HEAD hiện tại, ghi vào "Test baseline".
   - Bước cần ảnh mới → bước riêng ghi "Vai: Artist".
   - Điền phần **0. ĐIỀU PHỐI**: "Yêu cầu gốc của user" (đủ ý để không cần đọc chat), "Giai đoạn: plan", và mọi điều user đã chốt vào "Quyết định của user".

   Sau đó điền bảng bước ở phần TIẾN TRÌNH (mọi bước `todo`). Trong khối trạng thái: `planned`, "Bước tiếp theo: S1", để trống "Đang làm bởi". Chuyển sang bước 7.
6. **Điều chỉnh task hiện tại:**
   - Chưa có nhật ký: sửa thẳng phần KẾ HOẠCH và bảng bước.
   - Đã có nhật ký: giữ nguyên các bước cũ. Thêm mục vào "Điều chỉnh kế hoạch" (ngày giờ, lý do, bước mới lấy số kế tiếp, bước bỏ, bước đổi nội dung). Thêm bước mới vào bảng bước, cập nhật "Bước tiếp theo". Nếu task đang `in-review`/`done` thì đổi về `in-progress`.
   - **Không bao giờ** đánh lại số bước, dùng lại số cũ, hay động vào `refs/agent-base/<task-id>`.
7. Trả lời user bằng:
   - tóm tắt plan hoặc phần điều chỉnh (mục tiêu, số bước, phần không đụng tới, rủi ro);
   - link tới `TASK.md`;
   - câu giao việc cho Executor, trong một code block để user dán sang Codex/Antigravity:
     ```
     Làm task trong TASK.md theo quy trình trong AGENTS.md, vai Executor. Cập nhật phần TIẾN TRÌNH sau mỗi bước.
     ```
