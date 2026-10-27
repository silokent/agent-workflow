"""Thêm một dòng vào cuối mục "### Nhật ký điều phối" của TASK.md.

    python3 journal.py <TASK.md> "<dòng>"

TASK.md kiểu cũ (không có mục này) thì bỏ qua, không báo lỗi.
"""
import sys

HEADING = "### Nhật ký điều phối"

path, line = sys.argv[1:]
with open(path, encoding="utf-8") as stream:
    lines = stream.read().split("\n")
if HEADING not in lines:
    sys.exit(0)

start = lines.index(HEADING)
end = len(lines)
in_comment = False
for index in range(start + 1, len(lines)):
    text = lines[index]
    if in_comment:
        in_comment = "-->" not in text
        continue
    if "<!--" in text and "-->" not in text:
        in_comment = True
        continue
    if text.startswith("#") or text.startswith("---"):
        end = index
        break
while end > start + 1 and lines[end - 1].strip() == "":
    end -= 1
lines.insert(end, line)
with open(path, "w", encoding="utf-8") as stream:
    stream.write("\n".join(lines))
