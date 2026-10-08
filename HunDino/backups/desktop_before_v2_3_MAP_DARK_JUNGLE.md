# HunDino — Dark Jungle DJ.2.2

**Bản hiện tại để mở: `HunDino_DarkJungle_v2_2.rbxlx` trên Desktop/game roblox/HunDino.** Bãi tập đã được mở rộng và bổ sung bảy vũ khí. Đọc [hướng dẫn v2.2](TRAINING_SANCTUARY.md) để xem điều khiển, phạm vi và kiểm tra mới. Nội dung bên dưới lưu lịch sử đảo chính/v2.1; các chỗ nhắc bãi ba hình nộm chỉ áp dụng bản cũ.

Ngày cập nhật: 07/10/2026. Bản v2.1 sửa trực tiếp từ **v2 trên Desktop đã được bạn lưu trong Studio**. Bản v2 gốc được giữ nguyên và sao lưu; không dựng lại cây, nhà, địa hình hay vị trí bãi tập từ bản cũ.

## Sửa trong v2.1

- Sửa nội dung tiếng Việt bị sai mã ở cổng đi/về, bảng luyện tập, giá giáp và biển đền sau thác. Giữ font hiện có vì lỗi nằm ở chuỗi ký tự.
- **V = nhảy, Space = lướt.** Space chặn hành vi nhảy mặc định của Roblox. Máy chủ kiểm tra trạng thái để không chồng nhảy/lướt, không nhảy nhiều lần trên không và không lướt khi đang bay. Lướt chỉ tác động ngang, trọng lực vẫn hoạt động.
- Phủ kín 63 ô lòng hồ/sông/đầm bằng 23 mặt nước nối nhau, mặt nước tại Y = 2, thấp hơn đường/cầu. Di chuyển bọt nước ở chân thác lên mặt hồ. Đây vẫn là nước trang trí; chưa triển khai bơi/lặn.
- Xác nhận trong Play bằng phím thực tế: V, Space, Space rồi V, V rồi Space/V, giữ Space và sau hồi sinh. Đi/về qua cổng bằng G, xóa thống kê và pet theo về cũng đã kiểm tra. Chi tiết tại [kết quả kiểm tra](TEST_DARK_JUNGLE_V2_1.md).

## Mở đúng file

Mở `C:\Users\khanh\OneDrive\Desktop\game roblox\HunDino\HunDino_DarkJungle_v2_1.rbxlx` bằng Roblox Studio. Nhấn **F5** để chơi thử; **Shift + F5** để dừng.

Bản dựng cùng source nằm trong thư mục Documents/ChatGPT/game roblox/HunDino. **Bản trên Desktop là bản chính để bạn mở và tiếp tục thiết kế**; những lần bạn lưu bằng Studio không tự đồng bộ ngược về bộ dựng. Không chỉnh xen kẽ cả hai bản.

## Đã có trong map

- Đảo nền khoảng 1.800 × 1.800 studs; vách đá, tầng đất và bờ rừng. Địa hình hiện làm bằng Part để chỉnh sửa trực tiếp, chưa phải Sculpt Terrain chi tiết.
- Đủ **12 base**: 8 vòng ngoài (bán kính 785), 4 vòng giữa (bán kính 455), không đặt base trong tâm. Mỗi sân tròn đường kính 170 studs; có cổng, nhà trú nhỏ, bệ canh, bảng chủ và khoảng trống dành cho spawn/trưng bày.
- Hai đường rời mỗi base: đường chính rộng 28 studs, đường rừng rộng 16 studs. Các vòng đường và nhánh hướng tâm nối về quảng trường. Cầu có mặt đi liền và lan can ở những đoạn vượt sông.
- Trung tâm có thác **ba tầng**, cao khoảng 123 studs; hồ quanh chân thác, hang đền, bàn thờ và tinh thể. Mặt hồ theo ranh giới các ô đất đã đào, không còn bị giới hạn bởi đĩa nước đường kính 188 studs cũ. Có lối tiếp cận hang từ phía Tây.
- Một cây cổ thụ lớn dựng với chiều cao thiết kế 210 studs cạnh thác, sáu cây lớn quanh đảo, 430 cây rừng nhỏ, rễ nổi, dây leo, dương xỉ và nấm. Tán cây đã được nới rộng để các cụm rừng liền nhau hơn.
- Sửa hướng xoay từng đoạn đường và mặt sông; sửa cổng base quay ngang lối vào. Giảm độ sáng màu đường, thêm đá/rêu che cạnh vuông của thác và chỉnh màn nước để nhìn thấy rõ.
- Phía Tây: đầm lầy; Đông: đền đổ nát; Nam: rừng nấm; Bắc: đá đen. Sông chia nhánh về Đông Nam.
- Tông ánh sáng xanh xám, đá tối, rêu, rune xanh ngọc và tím. Đã bỏ giới hạn sương 200 studs kế thừa từ bản cũ vì nó che mất cảnh quan rộng.
- Sân đón có cổng **Bãi luyện tập**. Giữ **G** gần cổng để đi/về. Bãi tập nằm tách khỏi đảo chính, trong cùng Place; giữ ba hình nộm, búa, giáp và pet thử của L0.
- Giữ phím **V để nhảy**, **Space để lướt**. Cả hai chỉ thực hiện khi còn sống, đứng trên mặt đất, không ngồi/bị cố định hoặc đang bận động tác khác; không cộng dồn hai chuyển động khi bấm sát nhau.
- Một hệ thống tự cấp base trong phiên. Không đưa `BaseClaimSystem` thứ hai hoặc `GiantTreeFall` từ bản cũ vào map mới để tránh tranh quyền base và cây tự đổ.
- Khi rơi thấp hơn đảo, nhân vật và pet được đưa lại sân đón. Nước hiện là cảnh trang trí, chưa có cơ chế bơi/lặn.

## Cách chỉnh tiếp

Trong Explorer:

| Nhóm | Nội dung |
| --- | --- |
| Workspace → DarkJungle → Bases | 12 sân base và nhà trang trí |
| DarkJungle → Landmarks | Thác, cây cổ thụ, hang và bốn khu phụ |
| DarkJungle → Paths | Mặt đường, cầu và các nhánh |
| DarkJungle → Rainforest | Cây rừng |
| DarkJungle → TerrainRock / Rivers | Nền đất đá và nước |
| Workspace → HunDinoL0 → Lobby / Training | Spawn, cổng, bãi tập |
| Lighting | Ánh sáng, sương và màu cảnh |

Các hình khối đều có sẵn trong file; không cần tải model Toolbox để nhìn thấy cảnh. Khi thay một cụm cây bằng mesh đẹp hơn, giữ đường và vùng trống quanh cổng. Hãy dùng **Save As** sang tên mới trước những lần chỉnh lớn.

## Phạm vi còn cần tinh chỉnh

- Đây là bản dựng **phong cách hóa bằng hình khối Roblox**, chưa đạt chi tiết điện ảnh như ảnh tham khảo. Cây, tượng, đá, thác và kiến trúc có thể tiếp tục thay bằng mesh/texture riêng.
- 65–70% tán rừng và 30–50 giây di chuyển là **mục tiêu thiết kế**, chưa được đo để xác nhận đạt. Khoảng cách base trong kiểm tra là tâm–tâm, không phải mép–mép. Vòng giữa gần trung tâm hơn; chưa tuyên bố cân bằng PvP.
- Chưa thêm PvP, quái săn, phần thưởng, NPC, kho, trưng bày hay lưu dữ liệu. Các khu phụ hiện phục vụ bố cục và khám phá.
- Cầu dây, lối đi trên rễ, chuông, tượng chiến binh chi tiết và các lối tắt bổ sung chưa triển khai. Cầu hiện dùng sàn đá/gỗ và trụ.
- Chưa kiểm thử đủ 12 người hoặc tối ưu điện thoại. Cần đo hiệu năng trên máy yếu trước khi tăng mật độ cây và hiệu ứng. Khi xuất bản, đặt số người tối đa là 12 trong cấu hình experience.

## Kiểm tra

Đã chạy 6 nhóm kiểm tra của bản map mới: số base/phân vòng/khoảng cách; hai tuyến mỗi base và độ dốc; spawn/cổng/bãi tập; biên dịch toàn bộ script nhúng; vật thể cố định và ngân sách hình khối; thác/cây/khu phụ. Kiểm tra hộp va chạm dọc tim đường hiện **không còn ứng viên vật cản** tại các mẫu đã quét; không thay thế việc đi thử toàn tuyến.

9 nhóm kiểm tra L0 trước đó vẫn qua. Ngày 06/10/2026 đã kiểm tra trực tiếp bản v2 trên Desktop sau khi được lưu trong Studio: cả 6 nhóm cấu trúc vẫn qua.

Trong Play đã xác nhận nhân vật xuất hiện trên sân đón, HUD nhận Base 1/12, búa/giáp/pet được tạo và phím V làm nhân vật nhảy. Phép thử trong phiên chơi đưa nhân vật tới từng cổng, thực hiện giữ ProximityPrompt đủ thời gian và xác nhận: **sân đón → bãi tập → sân đón**, trạng thái khu được cập nhật đúng, nhân vật về gần điểm Arrival và pet theo về cách chủ dưới 20 studs. Phép thử này không đổi code hoặc vật thể lưu trong file map.

Chưa đi bộ đủ mọi tuyến hoặc kiểm thử 12 người và điện thoại; không đánh dấu bản phát hành hoàn thiện. Bản v2.1 trên Desktop là bản để tiếp tục chỉnh thủ công, không ghi đè lại nó bằng bộ dựng nếu chưa sao lưu.

## Dựng lại và bảo toàn dữ liệu

Source của bản vá: `tools/patch-dark-jungle-v2.py`, `src/dark-jungle/Training.client.luau`, `src/dark-jungle/Training.server.luau`. Công cụ vá nhận đường dẫn đầu vào v2 và đầu ra khác tên, sao lưu đầu vào theo SHA256 và giữ nguyên các thuộc tính XML ngoài phạm vi sửa. Báo cáo nằm trong `DarkJungle_v2_1_patch.json`.

`tools/build-dark-jungle.luau` là bộ dựng bản nháp từ đầu, lấy bãi tập từ bản sao L0 cũ; **không dùng để cập nhật những chỉnh sửa thủ công mới của bạn**. Bộ dựng đã cập nhật phím và chữ để tránh tái tạo lỗi, nhưng bản giao v2.1 được tạo bằng công cụ vá, không dùng bộ dựng này.

Không kết nối cấu hình Rojo `default.project.json` cũ vào map này: nó dành cho L0 và sẽ thay các chỉnh sửa chuyển khu, phím V bằng code cũ. Chỉnh trực tiếp bản giao trong Studio hoặc cập nhật bộ dựng; không đồng bộ chéo hai cách khi đang có sửa thủ công chưa lưu riêng.

Chạy từ thư mục HunDino trong Documents:

```powershell
.\tools\lune\lune.exe run tools/build-dark-jungle.luau
.\tools\lune\lune.exe run tools/test-dark-jungle.luau
```

Nếu file map mới đã tồn tại, bộ dựng sẽ dừng. `--rebuild` chỉ dùng khi đã lưu các sửa thủ công sang file khác; nó dựng lại bản sinh tự động, không nhập ngược những thay đổi bạn làm trong Studio. Không chạy `tools/build-map.luau --rebuild` để cập nhật map mới.

Bản L0 bạn đã chỉnh được giữ nguyên và có thêm bản sao tại `backups/HunDino_L0_before_DarkJungle_20261005.rbxlx`. SHA256 của bản L0 đầu vào: `6F99954B7526CAFFDC9064ECF891839320B33E5F45CFA31F56ADBCC5EC678B30`.

Tham khảo kỹ thuật: [Roblox instance streaming](https://create.roblox.com/docs/workspace/streaming). Bản này bật streaming theo vùng và dùng tải trước khi đi qua cổng; chưa áp dụng kiểm thử tải 12 người.
