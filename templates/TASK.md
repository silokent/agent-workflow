# TASK — <tên ngắn>

<!-- Khối trạng thái: mọi vai cập nhật tại chỗ. Agent nào vào cũng đọc khối này trước. -->
- Task ID: `<YYYYMMDD-ten-ngan>`
- Trạng thái: planned   <!-- planned | in-progress | in-review | changes-requested | done | blocked -->
- Đang làm bởi:         <!-- <agent> — YYYY-MM-DD HH:MM; để trống khi không ai làm -->
- Bước tiếp theo: S1    <!-- hành động cụ thể: "S3 — sửa hàm X trong file Y", hoặc "R4" -->
- Chặn / cần user quyết: không

---

## 0. ĐIỀU PHỐI
<!-- Orchestrator cập nhật. Agent hay phiên mới (kể cả ở máy khác) đọc phần này + khối trạng thái là biết
     đang làm gì, tới đâu, user đã quyết gì — không cần lịch sử chat hay phiên Codex cũ. -->
- Yêu cầu gốc của user: <viết lại đủ ý để người không đọc chat vẫn hiểu>
- Giai đoạn: plan   <!-- research | plan | execute | review | verify | chờ user | xong -->
- Vòng review: 0/3
- Đang chờ user: không   <!-- hoặc câu hỏi cụ thể đang chờ -->

### Quyết định của user
<!-- Chỉ thêm. Mọi điều user chốt trong chat mà ảnh hưởng tới task phải ghi ở đây.
- YYYY-MM-DD HH:MM — <quyết định> — (trả lời cho: <câu hỏi>)
-->

### Tài liệu
<!-- Báo cáo research (docs/research/…), ảnh đã tạo, link thiết kế… -->

### Nhật ký điều phối
<!-- Chỉ thêm. agent-run tự ghi một dòng sau mỗi lượt giao việc; Orchestrator ghi thêm khi tự làm gì đó
     (kiểm chứng, hỏi user, pull/push). Dạng: YYYY-MM-DD HH:MM — <vai> — <kết quả> -->

---

## 1. KẾ HOẠCH
<!-- Planner viết. Executor và Reviewer KHÔNG sửa phần này. -->
- Planner: <agent> — <YYYY-MM-DD HH:MM> — HEAD `<hash>` (nhánh `<branch>`)

### Mục tiêu
<1–3 câu: làm xong thì user thấy gì khác>

### Phạm vi
- Được sửa: <file / thư mục>
- **Không được đụng:** <file / hàm / hành vi phải giữ nguyên>

### Thiết kế
<ngắn gọn: cách làm, lý do, ràng buộc kỹ thuật cần biết>

### Các bước

#### S1 — <tên bước>
- File: `<path>`
- Làm: <việc cụ thể>
- Đạt khi: <tiêu chí kiểm chứng được>
- Reviewer kiểm tra: <hành vi cần test, edge case — Reviewer tự viết test, Executor không chạy test>

#### S2 — <tên bước>
- File:
- Làm:
- Đạt khi:
- Reviewer kiểm tra:

### Tiêu chí hoàn thành
- [ ] <tiêu chí hành vi>
- [ ] Không có thay đổi ngoài phạm vi
- [ ] Test độc lập của Reviewer đều pass
- [ ] Không có test fail mới so với baseline

### Test baseline
<!-- Planner chạy bộ test đầy đủ ở HEAD lúc lập plan -->
- `<lệnh>` → <N pass, M fail; tên các test fail sẵn; hoặc lý do không chạy được>

### Rủi ro / câu hỏi mở
- <…>

### Điều chỉnh kế hoạch
<!-- Chỉ dùng khi task đã bắt đầu. Thêm mục mới, không sửa các bước cũ ở trên.
#### <YYYY-MM-DD HH:MM> — <agent>
- Lý do:
- Bước mới: S<n+1> — … (viết đủ File / Làm / Đạt khi / Reviewer kiểm tra)
- Bỏ bước: S<k> (Executor đánh dấu `skipped`)
- Thay đổi nội dung bước: S<k> — …
-->

---

## 2. TIẾN TRÌNH
<!-- Executor cập nhật. Nhật ký chỉ thêm vào cuối. -->

### Mốc
<!-- Executor ghi MỘT LẦN khi bắt đầu task lần đầu; không sửa về sau -->
- `refs/agent-base/<task-id>` = `<hash>` — <YYYY-MM-DD HH:MM> — <agent>
- File đã bẩn sẵn trước task (không thuộc task này): <kết quả `git status --short`, hoặc "không">

### Bảng bước
<!-- todo · doing · done · blocked · skipped -->
| Bước | Trạng thái | Ghi chú |
|---|---|---|
| S1 | todo | |
| S2 | todo | |

### Nhật ký
<!--
#### <YYYY-MM-DD HH:MM> — <agent> — S1
- Đã làm:
- File sửa:
- Lệnh đã chạy (build/typecheck/lint — KHÔNG chạy test): `<lệnh>` → <kết quả thật, hoặc "không">
- Lệch so với kế hoạch (nếu có) + lý do:
-->

### Câu hỏi / lệch kế hoạch
- không

---

## 3. REVIEW
<!-- Reviewer viết. Mỗi lần review thêm một "Vòng" mới ở cuối, không sửa vòng cũ.
     Mã R<n> đánh số nối tiếp qua các vòng (vòng 1 có R1–R3 thì vòng 2 bắt đầu từ R4).
#### Vòng 1 — <agent> — <YYYY-MM-DD HH:MM>
- Test độc lập đã viết: `<file>` — <các case: hành vi / edge case>
- Chạy: `<lệnh>` → <kết quả test mới + bộ đầy đủ, so với Test baseline trong KẾ HOẠCH>
- Kiểm tay (cho Orchestrator): <phần chỉ kiểm được bằng mắt, hoặc "không">
- Đối chiếu:
  | Bước | Kết quả | Ghi chú |
  |---|---|---|
  | S1 | ✅ đúng / ⚠️ lệch / ❌ thiếu | |
- Thay đổi ngoài phạm vi: <không>
- Lỗi phát hiện: <file:dòng — mô tả — tình huống gây lỗi>
- Việc cần sửa:
  - [ ] R1 — `<file:dòng>` — <việc cần làm> — Đạt khi: <…>
- Kết luận: Approve | Changes requested
-->
