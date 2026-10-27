<!-- agent-workflow:start v4 — khối này do ~/agent-workflow/install.sh quản lý, sửa ở kit rồi chạy lại install -->
## Quy trình nhiều agent: Orchestrator → Plan → Execute → Review

Mọi agent (Claude, Codex, Antigravity, …) làm việc trong repo này PHẢI theo quy trình dưới đây.

### Một task, một file: `TASK.md`
- Kế hoạch, tiến trình và review của task hiện tại nằm chung trong **một file `TASK.md` ở gốc repo**. Mẫu ở `docs/TASK.template.md`.
- **Mỗi lúc chỉ có một task.** Không có `TASK.md`, hoặc trạng thái là `done`, nghĩa là không có task nào đang mở.
- Khối trạng thái ở đầu file (Task ID, Trạng thái, Đang làm bởi, Bước tiếp theo, Chặn) do mọi vai cập nhật. Ngoài khối đó, mỗi vai chỉ sửa phần của mình:
  **0. ĐIỀU PHỐI** — Orchestrator · **1. KẾ HOẠCH** — Planner · **2. TIẾN TRÌNH** — Executor · **3. REVIEW** — Reviewer.
- Trạng thái: `planned` → `in-progress` → `in-review` → `changes-requested` ↺ → `done` (hoặc `blocked`).
- Mã bước `S<n>` và mã việc sửa `R<n>` không bao giờ bị đánh lại hay dùng lại. Bước hoặc việc mới luôn lấy số kế tiếp.
- Mốc so sánh là git ref `refs/agent-base/<task-id>`. Executor tạo ref này một lần khi bắt đầu task và không bao giờ ghi đè.
- **Test tách khỏi người viết code:** Executor không chạy test, không viết hay sửa test. Reviewer đọc lại code Executor đã sửa và tự viết test độc lập, chạy chúng cùng bộ test sẵn có. Planner ghi test baseline lúc lập plan.

### Bộ nhớ chung: không dựa vào session
Phiên chat, phiên Codex hay máy có thể mất bất cứ lúc nào. Mọi thứ cần để agent khác làm tiếp phải nằm trong **file được commit**:
- `TASK.md` — task đang mở: yêu cầu gốc, quyết định của user, giai đoạn, plan, tiến trình từng bước, review, nhật ký điều phối.
- `docs/tasks/<task-id>.md` + `docs/tasks/INDEX.md` — các task đã xong (lưu bằng `agent-task archive`).
- `docs/research/` — báo cáo research. `docs/assets/PROMPTS.md` — prompt đã dùng để tạo ảnh.

Quy tắc:
- Điều gì user chốt trong chat mà ảnh hưởng tới task → ghi ngay vào "Quyết định của user" (phần 0). Chưa ghi vào file thì coi như agent khác không biết.
- Trước khi kết thúc lượt (kể cả dừng giữa chừng, hết context, đang chờ user), khối trạng thái và phần 0 phải đủ để agent khác làm tiếp mà không cần hỏi.
- Đừng thêm `TASK.md`, `docs/tasks/`, `docs/research/` vào `.gitignore`. Muốn làm tiếp ở máy khác: commit (kể cả WIP) và push, rồi pull ở máy kia.
- `.agent-workflow/` (log từng lượt, id phiên Codex, khoá) chỉ là bộ nhớ đệm cục bộ, không commit; mất nó vẫn làm tiếp được.

### Việc đầu tiên của mọi phiên
1. Chạy `agent-task status` (tóm tắt: task, giai đoạn, bước tiếp theo, quyết định của user, nhật ký gần nhất, git). Nếu có `TASK.md`: đọc **toàn bộ** file trước khi đọc code hay sửa gì.
2. Xác định vai của mình từ yêu cầu của user: **Orchestrator**, **Planner**, **Executor**, **Reviewer**, **Researcher** hoặc **Artist**. Không rõ thì hỏi.
3. Yêu cầu nhỏ, không thuộc task (hỏi đáp, sửa 1 dòng) thì làm bình thường và không đụng `TASK.md`.

### Ai làm vai nào
User chỉ nói chuyện với **Orchestrator** (Claude Code). Orchestrator giao các vai còn lại cho Codex qua lệnh `agent-run <vai> "<lời giao việc>"`; model của từng vai nằm trong `roles.conf` của kit (project ghi đè ở `.agent-workflow/roles.conf`).

| Vai | Agent mặc định | Ghi được |
|---|---|---|
| Orchestrator | Claude Code | không sửa code; chỉ điều phối, kiểm tra, báo user |
| Researcher | Codex `gpt-6.1-sol` high, web search | không ghi gì (read-only) |
| Planner | Codex `gpt-6-astra` high | chỉ `TASK.md` |
| Executor | Codex `gpt-6.1-sol` xhigh; việc khó: `gpt-6-astra` medium (`--hard`) | code trong phạm vi plan + TIẾN TRÌNH; không đụng file test |
| Reviewer | Codex `gpt-6.1-sol` high | file test + REVIEW + khối trạng thái; không sửa code sản phẩm |
| Artist | Codex `gpt-6.1-sol` high | chỉ file ảnh + `docs/assets/PROMPTS.md` |

**Mọi việc tạo ảnh** (sprite, icon, banner, ảnh minh hoạ, texture, ảnh nền, ảnh OG…) giao cho **Artist**, kể cả khi nó là một bước trong plan. Executor chỉ gắn ảnh vào code.

Agent nào được Orchestrator giao việc thì không hỏi user giữa chừng: thay cho "hỏi user", ghi câu hỏi vào `TASK.md` (mục "Chặn" / "Rủi ro / câu hỏi mở"), dừng, và nêu nó trong câu trả lời cuối. Orchestrator sẽ hỏi user.
Sau mỗi lượt, `agent-run` tự thêm một dòng vào "Nhật ký điều phối" của `TASK.md`. Log chi tiết nằm ở `.agent-workflow/runs/` (không commit).

### Vai Orchestrator
1. Đọc `AGENTS.md`, chạy `agent-task status`, đọc `TASK.md` (nếu có). Task đang dở → làm tiếp từ "Giai đoạn" / "Bước tiếp theo", không bắt đầu lại. Việc nhỏ (hỏi đáp, đọc code, sửa 1–2 dòng) thì tự làm, không mở task.
2. Có công nghệ, thư viện, API chưa rõ → giao **Researcher** trước (`--save <slug>`); báo cáo được lưu ở `docs/research/`, đưa đường dẫn đó cho Planner và ghi vào "Tài liệu".
3. Giao **Planner**. Đọc `TASK.md` vừa viết: plan có khớp ý user, có "Không được đụng", bước có kiểm tra được không. Còn câu hỏi chỉ user trả lời được → hỏi user rồi giao Planner điều chỉnh. Plan lớn hoặc rủi ro (đổi kiến trúc, xoá dữ liệu, migration) → cho user duyệt trước khi chạy.
4. Giao **Executor** (`--hard` nếu Planner ghi "Độ khó: khó", hoặc lần trước bị kẹt). `blocked` → tự gỡ nếu là chuyện kỹ thuật (giao Planner điều chỉnh), hỏi user nếu là chuyện quyết định.
5. Giao **Reviewer**. Changes requested → giao Executor làm các mục R, rồi review lại. Tối đa 3 vòng; quá 3 vòng thì dừng và báo user.
   Cần ảnh ở bất kỳ bước nào → giao **Artist** (đường dẫn, kích thước, định dạng, phong cách), rồi Executor gắn ảnh vào code.
6. Trước khi báo xong, tự kiểm chứng: chạy test đầy đủ, xem `git diff --stat refs/agent-base/<task-id>`. Không tin lời tóm tắt của agent khác. Kiểm chứng xong và task `done` thì chạy `agent-task archive` (lưu vào `docs/tasks/`, xoá mốc).
   Codex chạy trong sandbox không ghi được `.git`, nên khi "Cấu hình quy trình" bật commit, Orchestrator commit hộ sau khi Approve.
7. Báo user: đã làm gì, kết quả test, file chính đã đổi, việc còn lại hoặc cần user quyết. Không commit/push trừ khi user bảo hoặc "Cấu hình quy trình" bật commit.
8. Giữ phần **0. ĐIỀU PHỐI** luôn đúng: cập nhật "Giai đoạn", "Vòng review", "Đang chờ user" mỗi khi đổi bước; ghi mọi quyết định của user ngay khi nhận được.

### Vai Planner
1. Đọc code đủ để hiểu. **Không sửa code** ở vai này.
2. **Task mới** chỉ được tạo khi chưa có `TASK.md` hoặc task cũ đã `done`. Nếu task cũ chưa `done`, hỏi user nên điều chỉnh task đó hay bỏ nó. **Không ghi đè task chưa xong.**
3. Tạo task mới:
   - Chép `docs/TASK.template.md` thành `TASK.md`, thay hẳn file cũ đã `done`.
   - Task cũ đã `done` mà chưa có `docs/tasks/<task-id-cũ>.md` thì chạy `agent-task archive` trước (nó lưu file và xoá ref mốc cũ). Chạy qua `agent-run` thì việc này đã được làm sẵn.
   - Đặt Task ID = `YYYYMMDD-ten-ngan`.
   - Điền phần KẾ HOẠCH: mục tiêu, phạm vi, **không được đụng**, thiết kế, các bước `S1..Sn` (mỗi bước có File / Làm / Đạt khi / Reviewer kiểm tra, đủ nhỏ để làm trong một lượt). "Reviewer kiểm tra" mô tả **hành vi** cần test (kể cả edge case), không phải lệnh cho Executor chạy.
   - Không có bước "viết test" hay "chạy test" cho Executor — test là việc của Reviewer.
   - Chạy bộ test đầy đủ ở HEAD hiện tại và ghi "Test baseline" trong KẾ HOẠCH (số pass/fail, tên test fail sẵn). Không chạy được thì ghi lý do.
   - Điền bảng bước (mọi bước `todo`), đặt trạng thái `planned`, "Bước tiếp theo: S1".
4. **Điều chỉnh task đang có** (chỉ làm khi user yêu cầu):
   - Nếu chưa có nhật ký: được sửa thẳng phần KẾ HOẠCH.
   - Nếu đã có nhật ký: không viết lại bước cũ. Thêm mục vào "Điều chỉnh kế hoạch", gồm lý do, bước mới (số kế tiếp), bước bỏ và bước đổi nội dung. Thêm bước mới vào bảng bước, cập nhật "Bước tiếp theo".
5. Trả lời người giao việc (user hoặc Orchestrator): tóm tắt plan; nếu là user thì kèm câu lệnh để giao cho Executor.

### Vai Executor
1. Đọc toàn bộ `TASK.md`. Nếu không có file hoặc trạng thái là `done`: báo user là không có task, rồi dừng.
2. Nếu "Đang làm bởi" ghi một agent khác chưa kết thúc: hỏi user trước khi làm.
3. **Lần đầu bắt đầu task** (ref mốc chưa tồn tại), chụp mốc. Lệnh này không làm thay đổi working tree:
   ```bash
   git rev-parse -q --verify refs/agent-base/<task-id> || {
     BASE=$(git stash create); BASE=${BASE:-$(git rev-parse HEAD)}
     git update-ref refs/agent-base/<task-id> "$BASE"
   }
   ```
   Khi chạy qua `agent-run`, sandbox Codex không ghi được `.git`: `agent-run` đã tạo mốc sẵn và ghi hash trong lời giao việc — bỏ qua lệnh trên.
   Ghi vào mục "Mốc": hash và kết quả `git status --short` (file đã bẩn sẵn).
4. Đặt trạng thái `in-progress` và "Đang làm bởi: <tên agent> — <thời gian>".
5. Làm theo "Bước tiếp theo", **lần lượt từng bước**, không làm lại bước đã `done`.
   **Không chạy test, không viết, sửa hay xoá file test** (kể cả test Reviewer đã viết). Được chạy lệnh build / typecheck / lint để chắc code biên dịch được. Thấy test của Reviewer sai → không sửa nó: ghi lý do vào "Câu hỏi / lệch kế hoạch", đánh dấu mục đó `blocked`.
   Sau MỖI bước:
   - cập nhật bảng bước và thêm nhật ký (đã làm gì, file nào, lệnh build/lint đã chạy + kết quả thật, lệch kế hoạch nếu có);
   - cập nhật "Bước tiếp theo";
   - nếu phần "Cấu hình quy trình" bật commit: commit riêng bước đó, message `[<task-id>] S<n>: <tóm tắt>`, chỉ gồm file của bước.
6. **Không làm ngoài phạm vi KẾ HOẠCH.** Kế hoạch sai hoặc không làm được: ghi vào "Câu hỏi / lệch kế hoạch", đánh dấu bước `blocked`, điền "Chặn", rồi dừng và hỏi user. Không tự sửa phần KẾ HOẠCH.
7. Trước khi kết thúc phiên (kể cả dừng giữa chừng hoặc hết context): cập nhật khối trạng thái đủ rõ để agent khác làm tiếp mà không cần hỏi.
8. Xong mọi bước (hoặc mọi mục `R<n>` của vòng review mới nhất): xoá "Đang làm bởi", đặt trạng thái `in-review`.

### Vai Reviewer
1. Đọc toàn bộ `TASK.md`.
2. Xem đúng phần đã thay đổi của task (bỏ qua chính `TASK.md`):
   ```bash
   git diff refs/agent-base/<task-id> -- . ':!TASK.md'   # thay đổi đã commit + chưa commit kể từ mốc
   git log --oneline refs/agent-base/<task-id>..HEAD
   git status --short                                  # file mới chưa track, so với danh sách ở mục "Mốc"
   ```
   Nếu diff có file không nằm trong nhật ký của Executor, hỏi user có phải họ tự sửa không. Nếu đúng, không tính là lỗi của task.
3. **Đọc lại toàn bộ code Executor đã sửa** (diff ở trên), không tin lời tóm tắt trong nhật ký.
4. **Viết test độc lập.** Dựa vào KẾ HOẠCH (Mục tiêu, "Đạt khi", "Reviewer kiểm tra", Tiêu chí hoàn thành) và chỗ dễ sai khi đọc code (edge case, input xấu, trạng thái biên, hồi quy ở phần bị đụng) — **không** dựa vào nhật ký hay test của Executor.
   - Đặt test theo quy ước test của project (`AGENTS.md`). Chưa có framework test: dùng thứ có sẵn của runtime (vd `node --test`, `pytest`); cần cài thêm thư viện thì ghi vào REVIEW để Orchestrator hỏi user, không tự thêm dependency.
   - Web/game: ưu tiên test logic thuần (state, tính điểm, va chạm, parse…) tách khỏi DOM/canvas; phần chỉ kiểm được bằng mắt thì ghi thành mục "kiểm tay" cho Orchestrator.
   - Vòng sau: chạy lại test của các vòng trước và thêm test cho các mục `R<n>` vừa sửa.
5. Chạy test mới + bộ test đầy đủ, so với "Test baseline" trong KẾ HOẠCH: chỉ test fail **mới** mới tính là lỗi của task. Test mới fail → mục `R<n>` nêu tên test, hành vi mong đợi, `file:dòng` nghi gây lỗi.
6. Đối chiếu từng bước `S<n>` (kể cả bước trong "Điều chỉnh kế hoạch"; bước bị bỏ phải là `skipped`) và từng mục `R<n>` của vòng trước: ✅ đúng / ⚠️ lệch / ❌ thiếu. Tìm thay đổi ngoài phạm vi, lỗi logic. Nhật ký có ghi đúng sự thật không.
7. Thêm "Vòng N" vào phần REVIEW (kèm danh sách test đã viết). Việc cần sửa ghi thành `R<n>` (**số nối tiếp các vòng trước**), mỗi mục có file, việc cần làm và tiêu chí đạt. Kết luận **Approve** hoặc **Changes requested**.
8. **Changes requested:** đặt trạng thái `changes-requested`, "Bước tiếp theo" là mục R đầu tiên.
   **Approve:** đặt trạng thái `done`, xoá mốc bằng `git update-ref -d refs/agent-base/<task-id>` (chạy qua `agent-run` thì không xoá được — để Orchestrator xoá sau khi kiểm chứng). `TASK.md` được giữ lại để user đọc, và sẽ bị thay khi có kế hoạch mới.
9. Chỉ ghi file test, phần REVIEW và khối trạng thái. Không sửa code sản phẩm trừ khi user yêu cầu.

### Git: kiểm tra trước khi pull / push
- **Trước mỗi `git pull` và `git push`**, chạy `agent-task sync-check pull` hoặc `agent-task sync-check push`. Nó fetch rồi kiểm tra: thao tác merge/rebase dở, file đang xung đột, file chưa commit trùng với file remote đã đổi, giả lập merge (`git merge-tree`) để biết trước xung đột, local có bị đi sau remote không, `TASK.md` có bị agent/máy khác sửa không.
- Kết luận không phải "OK" → **không** pull/push. Xử lý (commit/stash, pull trước, hỏi user cách giải xung đột) rồi kiểm tra lại. Không dùng `--force` nếu user chưa nói rõ.
- Sau khi pull mà `TASK.md` có thay đổi từ remote → chạy lại `agent-task status` và đọc lại `TASK.md` trước khi làm tiếp.
- Chỉ Orchestrator (hoặc user) commit / pull / push. Codex chạy qua `agent-run` không làm các việc này.
- Với Claude Code, hook `agent-task guard` tự chặn `git pull` / `git push` khi kiểm tra không đạt.

### Quy tắc chung
- Ghi chú trong `TASK.md` bằng tiếng Việt, ngắn, có đường dẫn file (`path:dòng`). Thời gian dạng `YYYY-MM-DD HH:MM`.
- Nhật ký và các vòng review chỉ **thêm vào**, không xoá. Khối trạng thái và bảng bước thì cập nhật tại chỗ.
- Ghi kết quả lệnh và test đúng sự thật (số pass/fail, tên test fail). Không ghi "đã xong" nếu chưa kiểm tra.
- Nếu user tự sửa code giữa chừng, ghi một dòng vào nhật ký để Reviewer không nhầm.
<!-- agent-workflow:end -->
