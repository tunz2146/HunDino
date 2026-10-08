# HunDino — Bãi luyện tập v2.3

Cập nhật ngày 08/10/2026, tiếp tục bản v2.3 người dùng đã lưu từ công việc ngày 07/10: mở rộng bãi tập, sửa chữ, thêm bộ bảy vũ khí và sửa camera cung.

## File để chơi và chỉnh tiếp

Mở **C:\Users\khanh\OneDrive\Desktop\game roblox\HunDino\HunDino_DarkJungle_v2_3.rbxl** bằng Roblox Studio, rồi nhấn Play. Tiếp tục lưu định dạng `.rbxl`: bản XML v2.2 từng bị đổi mã một số bảng khi Studio lưu lại. Bản người dùng v2.3 trước lần sửa này đã sao lưu trong `backups/HunDino_v2_3_user_6293a5ddc15f.rbxl`. Source ở Documents; khi chỉnh tiếp bằng Studio, dùng bản Desktop, không chép đè bằng bản Documents cũ.

## Bãi tập mới

- Diện tích 460 × 420 studs, thay bãi nhỏ cũ trong cùng Place.
- Sân võ tròn lát đá có vòng đánh dấu khoảng cách, ba hình nộm cận chiến.
- Bốn làn cung với bia cách vạch bắn 30, 60, 90 và 120 studs.
- Nhà vũ khí mái xanh, bảy bệ trưng bày có thể chọn; giữ giá giáp và bảng xóa thống kê cá nhân.
- Thêm đường lát đá, hồ nhỏ, cây, đèn, viền sân và cổng quay về trại.
- Giữ sảnh 12 base, cảnh quan đảo chính và 23 mặt nước của v2.1. Sửa các bảng tiếng Việt bị sai mã còn trong file nguồn.

## Điều khiển

| Thao tác | Phím |
| --- | --- |
| Qua cổng, chọn vũ khí trên bệ, thay giáp, xóa thống kê | Giữ G gần đối tượng |
| Mở/đóng bảng chọn vũ khí | I hoặc nút trên màn hình; cất vũ khí trước |
| Rút/cất vũ khí | R |
| Đánh thường / mạnh / kỹ năng | Chuột trái / Q / E |
| Nhảy / lướt | V / Space |
| Chạy / ghim tâm | Shift / Ctrl |
| Ngắm khi đã rút cung | Giữ chuột phải |
| Giữ thế đỡ khi dùng kiếm & khiên | Giữ F |

I được chặn khỏi phím zoom mặc định Roblox; Space không kích hoạt nhảy mặc định.

Trong v2.3, R cất cung và Shift chạy hủy ngắm ngay; menu Esc được nhả chuột để thao tác. Tâm ngắm ẩn khi mở menu hoặc nhân vật chết.

Ngắm cung dùng camera lệch vai phải: nhân vật nằm bên trái khung hình, zoom chuyển mượt về 8,5 studs, FOV 58 và độ nhạy chuột bằng 65% mức trước đó. Tâm bắn đặt đúng giữa viewport, không bị lệch do thanh giao diện Roblox. Nhả chuột phải/cất cung/hồi sinh trả lại camera và độ nhạy trước khi ngắm; vẫn dùng xử lý vật cản của camera Roblox.

## Bộ vũ khí thử

| Vũ khí | Hành vi trong bản thử |
| --- | --- |
| Búa tạ | Giữ combo thường → mạnh → kỹ năng kết thúc |
| Kiếm & khiên | Ba đòn, mô hình khiên tay trái, thế đỡ tiêu thể lực |
| Katana | Kiếm và bao kiếm, nhịp đòn riêng |
| Thương cán dài | Tầm đánh cận chiến xa hơn, kỹ năng quét rộng |
| Song dao | Hai lưỡi, nhiều hit nhỏ và nhịp nhanh |
| Cung | Ngắm, bắn thường/mạnh, kỹ năng ba mũi; ngắm rồi lướt tăng sát thương một mũi tên kế tiếp trong 4 giây, không cộng dồn |
| Rìu đại hai lưỡi | Đòn chậm, sát thương và tiêu thể lực lớn |

Mỗi loại có mô hình, sát thương, tầm đánh, nhịp và thể lực riêng trong `src/dark-jungle/Weapons.luau`. Đây là **thông số thử**, chưa chốt cân bằng toàn game. Mô hình và chuyển động vũ khí dùng Part/weld để thử chơi, chưa phải bộ mesh/animation cuối. Khiên hiện có thế đỡ; chưa kiểm chứng giảm sát thương vì bãi tập chưa có địch tấn công. Cung dùng raycast máy chủ và hiệu ứng mũi tên bay, chưa mô phỏng đường đạn cong. Không PvP, thưởng hoặc lưu trang bị theo tài khoản.

## Kiểm tra ngày 07/10/2026

- Kiểm tra tự động: quy tắc cả bảy vũ khí, combo búa, đổi vũ khí, thiếu thể lực/thế đỡ, hình học bãi tập, UTF-8 và biên dịch code nhúng.
- Trong Studio Play: chọn kiếm & khiên/cung bằng giao diện, rút/cất và gây sát thương. Đòn mạnh kiếm gây 47; chuỗi ba đòn búa 246, katana 176, thương 177, song dao 138, rìu 230 khi đủ thể lực.
- Cung bằng chuột/Q/E: tổng 119 ở bia thẳng hướng; bắn xa 120 studs gây 29; có tường chắn gây 0. Sau ngắm/lướt, hai phát thường lần lượt 36 và 29, buff hết sau phát đầu.
- Thế đỡ chặn yêu cầu tấn công, nhả F kết thúc thế đỡ. Cổng G đưa người/pet qua lại; về trại pet cách chủ khoảng 5 studs. Không có lỗi gameplay trong Output ở phiên kiểm tra.
- Camera cung: xác nhận tâm ngắm trùng điểm chiếu bia (sai lệch dưới 0,01 pixel trong phép đo), bấm chuột trái gây 29 sát thương; di chuyển ngang giữ góc lệch vai. Nhả ngắm trả FOV 70, offset 0, zoom 0,5–128 và độ nhạy 1 trong cấu hình thử. Thêm tường sau lưng khiến camera tiến gần lại; chết/hồi sinh khi đang ngắm không kẹt zoom hay độ nhạy.
- Chưa kiểm thử đủ 12 người, điện thoại hoặc cảm giác cân bằng cuối. Pet giữ hành vi thử cũ, chưa có tìm đường vòng hoàn chỉnh.

Kiểm tra bổ sung 08/10/2026 trên bản `.rbxl` v2.3:

- Mở lại đúng file người dùng: đủ bảy vũ khí, bãi tập và chuỗi tiếng Việt nguyên vẹn. 12 nhóm kiểm tra source/cấu trúc đạt.
- I mở bảng chọn: khoảng cách camera trước/sau đều khoảng 12,5 studs, không bị zoom mặc định.
- Cung đang ngắm ở FOV 58, offset vai (2,6; 0,65; 0): nhấn R cất hoặc giữ Shift/W để chạy trả FOV 70 và offset 0. Độ nhạy trở về 1 trong cấu hình thử.
- Đang ghim tâm bằng Ctrl, mở Esc: menu mở, chuột về Default, tâm ngắm ẩn. Không có lỗi gameplay trong Output.
- Sau lưu lại v2.3 bằng Studio, kiểm tra UTF-8 và code nhúng khớp source đạt. Không ghi lại file bằng bộ dựng cũ.

## Source và dựng lại

`tools/build-training-sanctuary.luau` chỉ tạo khu tập và mẫu vũ khí. `tools/merge-training-sanctuary.py` ghép vào bản v2.1 Desktop, sao lưu nguồn theo SHA256, bảo toàn hình học lobby/đảo và sửa mã chữ. Không dùng công cụ này để ghi đè các chỉnh sửa mới trong v2.2; nó kiểm tra hash bản dựng trước khi thay đầu ra. Kết quả nằm trong `TrainingSanctuary_manifest.json`.

Chạy từ thư mục HunDino trong Documents:

```powershell
.\tools\lune\lune.exe run tools/build-training-sanctuary.luau
# Chạy tools/merge-training-sanctuary.py bằng Python, rồi:
.\tools\lune\lune.exe run tools/test-training-sanctuary.luau HunDino_DarkJungle_v2_3.rbxl
.\tools\lune\lune.exe run tools/test-dark-jungle.luau HunDino_DarkJungle_v2_3.rbxl
```

`tools/build-dark-jungle.luau` vẫn là bộ dựng toàn đảo từ đầu, không dành cho cập nhật map đang chỉnh thủ công. Không đồng bộ cấu hình Rojo L0 cũ vào v2.2.

Với v2.3, cập nhật script qua Studio rồi lưu bằng Studio để bảo toàn các thuộc tính Terrain mới. Không dùng Lune để đọc rồi ghi lại toàn file: bộ đọc kiểm tra hiện báo chưa hỗ trợ `Terrain.VoxelGridAssetContentMap`. Cảnh báo này không xuất hiện trong Studio và không làm mất dữ liệu khi chỉ đọc để kiểm tra.

Tham chiếu API camera: [Roblox Camera](https://create.roblox.com/docs/reference/engine/classes/Camera), [Humanoid.CameraOffset](https://create.roblox.com/docs/reference/engine/classes/Humanoid#CameraOffset). Các giá trị góc nhìn bên trên là cấu hình thử của HunDino.
