# HunDino — Dark Jungle và bãi tập

**Map đang phát triển: `HunDino_DarkJungle_v2_2.rbxlx`.** Mở bản trong `C:\Users\khanh\OneDrive\Desktop\game roblox\HunDino`. Bãi tập mới rộng 460 × 420 studs, có sân võ, bốn làn cung và **bảy loại vũ khí**. Cất vũ khí rồi nhấn **I** để chọn; **R** rút/cất, **V** nhảy, **Space** lướt. Bản này giữ đảo chính 12 base và mặt nước, sửa các bảng tiếng Việt. Xem [hướng dẫn v2.2 và kết quả thử](TRAINING_SANCTUARY.md).

**Không đồng bộ `default.project.json` vào Dark Jungle:** cấu hình này dành cho L0, sẽ thay code chuyển khu và điều khiển mới bằng code cũ. Không dựng lại map khi chưa lưu các sửa thủ công sang file riêng.

## Tài liệu bản L0.1 cũ

Các hướng dẫn bên dưới dành riêng cho L0.1, không phải cách cập nhật map Dark Jungle.

File để mở trong **Roblox Studio → File → Open from File**: **HunDino_L0.rbxlx**. Bấm **F5 / Play** để chạy. Đây là bản phát triển từ `HunDino1.rbxl` của bạn; file Desktop được giữ nguyên.

## Phần đã tạo

- Giữ 12 base, thác, đường đi và cây cảnh; thêm sân đón, cổng và biển số/chủ base. 14 cây/đá vướng sân đón được dời sang mép rừng trong bản phát triển.
- Vào game ở sân đón; mỗi người được gán một base trống trong phiên. Máy chủ thử từ chối người thứ 13. Cấu hình số người của game trên Roblox vẫn cần đặt 12 khi xuất bản.
- Đứng gần cổng, giữ **G** để đi/về bãi tập. Bãi tập hiện là khu tách vị trí trong **cùng một Place**, chưa phải map/server riêng qua TeleportService.
- Búa thử với ba đòn, combo thường → mạnh → kỹ năng; thể lực, rút/cất, chạy và lướt thử.
- Ba hình nộm có số sát thương; hết máu tự đầy lại. Không trao nguyên liệu/phần thưởng.
- Giáp mẫu gắn trên nhân vật; giá trang bị cho mặc/tháo. Chưa có chỉ số phòng thủ/chế tạo.
- Pet mô hình khối theo chủ và đánh hình nộm chủ vừa đánh theo chu kỳ. Chưa có hoạt ảnh chân, tìm đường vòng, gọi hồi, máu/choáng hay trang bị pet.

## Điều khiển PC

| Thao tác | Phím |
| --- | --- |
| Di chuyển / xoay camera | WASD / chuột phải mặc định Roblox |
| Rút hoặc cất búa | R, mất 1 giây |
| Đánh thường / mạnh / kỹ năng | Chuột trái / Q / E |
| Combo thử | Chuột trái → Q → E, chờ đòn trước kết thúc |
| Chạy | Giữ Shift; tự cất búa trước nếu đang rút |
| Lướt thử | Space, tốn thể lực; chưa có động tác lộn/i-frame |
| Ghim tâm tự tạo | Ctrl; Shift Lock mặc định đã tắt |
| Cổng / thay giáp / xóa thống kê tập | Giữ G gần đối tượng; cất búa trước khi thay giáp/reset |

Chỉ kiểm tra PC ở mốc này; chưa có nút cảm ứng. Thông số trong `src/shared/TrainingConfig.luau` đều là cấu hình thử. Pet không thay đổi luật đóng góp 10% của game tương lai.

## Trạng thái kiểm tra

Đã chạy **9 nhóm kiểm tra tự động bằng Lune**, gồm biên dịch Luau, combo và hết thể lực, chặn đánh quá nhanh, hồi thể lực, bảo toàn số đối tượng map gốc/12 base, điểm spawn và đối chiếu code nhúng. **Chưa xác nhận bằng Play trong Studio**: công cụ điều khiển cửa sổ bị lỗi nhập liệu/foreground trong phiên làm việc này. Chưa đánh dấu bản L0 hoàn thành hoặc sẵn sàng mở cho người chơi.

Checklist cần chơi thử:

- [ ] Mở file không báo lỗi tải; Play không có lỗi đỏ trong Output.
- [ ] Xuất hiện ở sân đón, đi qua cổng bằng G và quay về được.
- [ ] R rút/cất đủ trễ; Shift không bỏ qua cất; nhả Shift dừng chạy.
- [ ] Đánh đúng tầm/hướng làm hiện số; đứng xa/sau tường không trúng.
- [ ] Combo đúng ra 140 ở đòn kết thúc; spam không đánh nhanh hơn nhịp.
- [ ] Thể lực giảm/hồi; không đánh/lướt khi thiếu; Space không vừa nhảy vừa lướt.
- [ ] Đổi giáp, reset thống kê, hồi sinh nhân vật không nhân đôi búa/pet.
- [ ] Pet theo chủ qua cổng, đánh theo chu kỳ; kiểm tra chỗ dễ mắc cây/tường.
- [ ] Local server 2 người: base khác nhau; thống kê riêng; người rời trả base.
- [ ] Thử đủ 12 người; đọc biển, độ sáng, lối đi và tốc độ khung hình.

## File và cách tiếp tục

- `THIET_KE_GAME.md`: hồ sơ thiết kế, đọc **mục 25** trước khi làm tiếp.
- `HunDino_original.rbxl`: bản sao nguyên vẹn của map Desktop, SHA256 `3416378401F1338B1C33A125FC15F9BB49DF0D0AB87D75A6FCE42067731090FC`.
- `HunDino_original.rbxlx`: bản chuyển sang XML để kiểm tra; không sửa map này.
- `HunDino_L0.rbxlx`: map phát triển chứa code, mở trực tiếp không cần Rojo.
- `src/server/Training.server.luau`: cấp base, búa, giáp, hình nộm, pet, chuyển khu.
- `src/client/Training.client.luau`: điều khiển, camera và giao diện.
- `tools/build-map.luau`: dựng lại L0 từ bản sao gốc + source. **Dựng lại sẽ ghi đè file L0**, vì vậy lưu mọi sửa map thủ công sang tên khác trước; không chạy lại nếu đang có chỉnh sửa map cần giữ.
- `tools/test-training.luau`: bộ kiểm tra ngoài Studio.

Chạy từ thư mục này, sau khi đã lưu các thay đổi map thủ công ở file riêng:

```powershell
.\tools\lune\lune.exe run tools/build-map.luau --rebuild
.\tools\lune\lune.exe run tools/test-training.luau
```

`default.project.json` chỉ đồng bộ code, để nguyên các đối tượng ngoài phạm vi. Không dùng `rojo build` để thay cho map có cảnh: cấu hình này không chứa hình học bản đồ. Mở L0 trước rồi dùng Rojo nếu cần đồng bộ source.

Lune 0.10.5 tải từ [kho chính thức](https://github.com/lune-org/lune/releases/tag/v0.10.5), kiểm tra SHA256 archive `ad0305f5cc6d7ff20996644b40bf7de0de613812f431ca241456e16f9fc89cda`; nằm riêng trong `tools/lune`, không cài hệ thống. Định dạng map dùng [thư viện Roblox của Lune](https://lune-org.github.io/docs/api-reference/roblox/). Quy tắc xác thực server theo [Roblox Creator Hub](https://create.roblox.com/docs/scripting/security/client-server-boundary).
