# Kiểm tra HunDino Dark Jungle v2.1

Ngày 07/10/2026. Kiểm tra trong Roblox Studio, Play solo PC, trên file `HunDino_DarkJungle_v2_1.rbxlx` ở Desktop. Phép đo chuyển động lấy mẫu Humanoid và vị trí nhân vật khi gửi phím vào client bằng công cụ Studio. Mọi đối tượng đo chỉ tồn tại trong phiên thử; đã dừng Play sau kiểm tra.

| Trường hợp | Kết quả thực tế |
| --- | --- |
| V | 1 lần vào trạng thái Jumping; cao thêm khoảng 7,27 studs; không lướt; thể lực 100 |
| Space | 0 lần Jumping; đi ngang khoảng 14,88 studs; tăng độ cao dưới 0,001; thể lực 100 → 80 |
| Space rồi V sau 50 ms | 0 lần Jumping; lướt ngang khoảng 14,19 studs; không cộng lực nhảy |
| V rồi Space sau 50 ms, thêm V sau 75 ms | Chỉ 1 lần Jumping; không lướt, không nhảy lần hai |
| Sau chết/hồi sinh: V, rồi giữ Space 1,3 giây | 1 lần nhảy và 1 lần lướt, không tự nhảy thêm khi giữ Space; thể lực 100 → 80 |
| Giữ G ở cổng sân đón | Sang bãi tập; InTraining = true |
| Giữ G ở bảng luyện tập | Thống kê được xóa; thông báo tiếng Việt đúng |
| Giữ G ở cổng trở về | Về sân đón; InTraining = false; pet cách chủ khoảng 5,10 studs |
| Chữ trong cảnh | Đã nhìn trực tiếp biển “TRỞ VỀ TRẠI”, “BẮT ĐẦU LƯỢT TẬP MỚI”, nút “Xóa thống kê của tôi” trong Play |
| Mặt nước | Đã nhìn hồ dưới thác; 63 ô lòng hồ/sông/đầm được phủ đúng một lần bởi 23 mặt nước; không phủ thêm ô đất khô |
| Log Studio | Không có lỗi khi khởi tạo và thử các thao tác trên |

Kiểm tra ngoài Studio: 6 nhóm cấu trúc của `tools/test-dark-jungle.luau` đều qua; toàn bộ 5 script nhúng biên dịch được; không có vật cản trong các mẫu tim đường đã quét. Công cụ vá kiểm tra nguyên trạng 14.777 đối tượng gốc ngoài danh sách sửa, giữ các thuộc tính XML mới của Studio, kiểm tra lại Unicode sau khi ghi file.

Đầu vào gốc: SHA256 `5f198ba295ce125777e4a0427e8eb55e3bf72b9b4ccad81f8875163765138df8`. Bản gốc không bị ghi đè; vị trí bản sao và SHA256 đầu ra được ghi trong `DarkJungle_v2_1_patch.json`.

Chưa kiểm thử tải 12 người, điện thoại hoặc toàn bộ tuyến đi bộ. Nước là bề mặt trang trí, chưa phải hệ thống bơi.
