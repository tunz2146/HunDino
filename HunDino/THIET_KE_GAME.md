# Hồ sơ thiết kế game Roblox săn khủng long

Phiên bản: 0.22 — Cập nhật: 28/09/2026

Tài liệu làm việc chung, được cập nhật trong suốt quá trình phát triển. **Ưu tiên hiện tại là mục 25: sảnh 12 base và bãi luyện tập L0**, theo yêu cầu mới của người dùng. Đã có map do người dùng dựng và bản phát triển L0.1 kèm source; chưa xác nhận chạy bằng Play trong Studio. **Mục 23–24** giữ thiết kế vòng săn P1 để nối sau L0, chưa triển khai săn/bắt/thưởng/lưu tài khoản.

**Đọc nhanh:** đọc mục 25 và README dự án trước khi làm tiếp; mục 1–22 lưu định hướng; mục 23–24 dành cho P1 sau bước sảnh/luyện tập. Nhật ký ở mục 15 là lịch sử, không phải danh sách quyết định hiện hành. Các đề xuất trong ảnh không mặc nhiên là yêu cầu người dùng đã chốt.

| Nhóm | Cách sử dụng | Trạng thái hiện tại |
| --- | --- | --- |
| Yêu cầu đã thống nhất | Giữ khi làm hệ thống tương ứng; xem nhãn ở từng mục | Đã ghi thiết kế, chưa lập trình |
| Ưu tiên hiện tại L0 | Map sảnh 12 base, khu chuyển sang luyện tập, búa/giáp/đòn đánh/hình nộm/pet cơ bản | Đã tạo bản phát triển; kiểm tra trực tiếp trong Studio còn mở, xem mục 25 |
| P1 sau L0 | Solo trên PC, búa với combo ngắn, một quái/một đòn, pet cơ bản, săn/bắt, thưởng, nâng cấp, một ống và lưu | Giữ kế hoạch P1-0 → P1-G; tái sử dụng phần L0 đã đạt, không bắt đầu lại từ đầu |
| Định hướng toàn game ngoài P1 | Điện thoại hoàn chỉnh, săn đội, bảy vũ khí, nhiều loài/hệ, năm ống, sảnh 12 người, pet nâng cao | Để mốc sau; vẫn giữ yêu cầu game hỗ trợ hai nền tảng |
| Cấu hình thử | Thông số và cách xử lý do trợ lý đề xuất tại mục 23–24 | Có thể điều chỉnh sau thử nghiệm; chưa phải chốt toàn game |
| Chưa chốt | Các lựa chọn được đánh dấu còn mở | Không tự coi là quyết định; chỉ giải quyết khi bước làm phụ thuộc vào chúng |

## 1. Cách đọc và cập nhật

- **Đã thống nhất:** yêu cầu người dùng nêu hoặc đồng ý; chỉ thay đổi khi trao đổi lại.
- **Đề xuất:** hướng giải quyết để thảo luận, chưa tự động trở thành yêu cầu.
- **Chưa chốt:** thiếu thông số hoặc còn nhiều cách hiểu; không tự đặt thành quyết định cuối cùng.
- Các số minh họa không phải thông số cân bằng chính thức.
- Khi có thay đổi: sửa trực tiếp mục liên quan, ghi quyết định vào nhật ký; không giữ các yêu cầu mâu thuẫn song song.
- Dùng tên viết tắt **MHW** cho Monster Hunter: World trong mọi trao đổi tiếp theo.
- Phân biệt thuật ngữ: **tiêu diệt/hạ thú** kết thúc mục tiêu; **choáng/gục tạm thời** chỉ làm quái mất khả năng hành động một lúc rồi tiếp tục chiến đấu. Các mục cũ dùng “hạ gục” đối lập với bắt giữ mang nghĩa kết thúc mục tiêu.
- Người làm game bắt đầu từ chưa biết lập trình và đồ họa: hướng dẫn theo từng bước, giải thích thuật ngữ, kiểm tra bản nhỏ trước khi mở rộng.
- Người dùng đã xác nhận **bắt đầu dự án**, đổi sảnh từ 16 xuống **12 người**, làm map/base và khu luyện tập trước. Nếu mở đợt gửi nội dung mới và yêu cầu đợi, tiếp nhận đến khi họ báo “xong” rồi mới tổng hợp. Hiện tại đã có yêu cầu triển khai/tiếp tục, không phải đang chờ.
- **Cấu hình thử:** lựa chọn/thông số do trợ lý đặt để bản thử có thể được thực hiện và đánh giá; chưa phải quyết định cuối cho toàn game. Các mục 1–22 giữ yêu cầu nền tảng; mục 23–24 ghi phạm vi rút gọn và lựa chọn thử. Đợt rà soát ngày 27/09 chỉ sửa hồ sơ, không tự khởi động việc viết code.
- Các câu “chưa chốt” trong phần toàn game có thể đã có phương án thử riêng cho P1. Khi làm P1 đọc cấu hình mục 23–24; không hiểu là phải hỏi lại mọi thông số trước khi thử, cũng không dùng số thử để kết luận toàn game đã chốt.

## 2. Tầm nhìn và vòng chơi

**Đã thống nhất:** Game Roblox lấy cảm hứng từ MHW, tập trung săn/bắt khủng long, nguyên liệu chế tạo, trang bị, sưu tầm và thể hiện chiến tích tại base cá nhân.

Vòng chơi dự kiến: chuẩn bị trang bị và pet → đi săn một mình hoặc theo đội → hạ gục/bắt giữ → nhận nguyên liệu và phần thưởng → nâng cấp → chọn chiến tích trưng bày → tiếp tục săn mục tiêu mới.

- Bắt giữ giúp sở hữu cá thể để sưu tầm và trưng bày.
- Người khác có thể tham quan base, xem khủng long, vũ khí và thành tích.
- Mục tiêu máy chủ mở tối đa 12 người; nhóm đi săn dự kiến 1–4 người. Chưa quyết định nhóm săn dùng chung bản đồ với sảnh hay có khu/phiên săn riêng.
- Chọn nhiệm vụ ở bảng trước khi vào map: săn thông thường cho phép tiêu diệt hoặc bắt mục tiêu; nhiệm vụ bắt sống yêu cầu bắt. Map có ba con để tự do săn, mục tiêu chính quyết định hoàn thành. Thời gian khoảng 40 phút; xem mục 20–21.
- Làm từng bản nhỏ có thể chơi và kiểm tra được; chưa xây toàn bộ nội dung cùng lúc.

## 3. Base, kho sưu tầm và lưu tiến trình

### Đã thống nhất

- Mỗi người có một base riêng.
- Kho sưu tầm tách khỏi phần trưng bày: có thể sở hữu nhiều hơn năm cá thể; trưng bày tối đa năm cá thể trong năm ống nghiệm.
- Tự chọn cá thể trưng bày, kể cả nhiều cá thể cùng loài nhưng khác màu/biến thể. Không bắt buộc một hệ hoặc một loài cho mỗi ống.
- Đổi cá thể trưng bày không làm mất cá thể cũ trong kho.
- Khủng long được thu nhỏ cho vừa ống; màu sắc, ngoại hình và hiệu ứng đặc biệt thể hiện sự khác biệt.
- Có một vị trí trưng bày **một vũ khí duy nhất** do chủ base chọn, trên tường hoặc vị trí phù hợp.
- Vũ khí nâng cấp cao, dùng nguyên liệu từ quái mạnh có thể có aura nhẹ.
- Lưu tiến trình và lựa chọn trưng bày theo tài khoản để dùng lại qua các lần vào game/máy chủ.

### Đề xuất để sảnh không quá lớn

- Kho là danh sách trong giao diện; không cần dựng phòng hoặc mô hình cho mọi cá thể đang sở hữu.
- Base dùng bố cục nhỏ: năm ống quanh tường, một chỗ vũ khí, vị trí giáp nếu bổ sung sau.
- Map hiện có đủ 12 base; L0 giữ bố cục này, thử tầm nhìn/đi lại và tải hiển thị trước khi mở cho 12 người thật.
- Nếu 12 base cùng sảnh quá chật/nặng, cân nhắc sảnh chung có lối vào base riêng. Chưa chốt phương án này.
- Chỉ cần lưu dữ liệu cá thể, vật phẩm và bố trí để dựng lại base; không cần lưu toàn bộ cảnh 3D.
- Lưu tiến trình thông thường và sao lưu/khôi phục khi lỗi là hai việc khác nhau; cần kiểm tra cả hai khi triển khai.

### Dữ liệu tối thiểu dự kiến phải lưu

- Cá thể sở hữu: mã riêng, loài, hệ, biến thể, màu, kích thước gốc và thông tin lần bắt cần thiết.
- Năm vị trí trưng bày tham chiếu tới các cá thể trong kho.
- Nguyên liệu, trang bị đã sở hữu, cấp nâng cấp, trang bị đang dùng và vũ khí được trưng bày.
- Pet, trang bị pet và thành tích săn.
- Bố trí base trong phạm vi cho phép; chưa thiết kế xây dựng base tự do.
- Cần thử thoát/vào lại, đổi máy chủ, lỗi lưu và nhận thưởng lặp; không hứa bảo toàn dữ liệu trước khi kiểm chứng.

**Chưa chốt:** dung lượng kho; sơ đồ sảnh/base; mức độ tùy chỉnh vị trí; hiển thị giáp; chính sách và cách khôi phục dữ liệu.

## 4. Loài, hệ và hình thái

### Đã thống nhất

- Tách **loài**, **hệ**, **cách di chuyển/hình thái** và **biến thể**; không xem rồng bay là đồng nghĩa với hệ rồng.
- Các hệ định hướng: **lửa, nước, sấm/điện, độc, rồng**. Ngoài ra có cá thể/loài **không hệ**.
- Khủng long hệ rồng có thể bay hoặc không bay. Các hệ khác cũng có thể có dạng đi bộ, bay, sống dưới nước.
- Một loài có thể có dạng không hệ và dạng có hệ; cách phân bố cụ thể chưa chốt.
- Dạng không hệ dễ săn hơn, cung cấp nguyên liệu cơ bản như xương, da, răng, vảy; không rơi lõi lửa hoặc nguyên liệu đặc trưng hệ tương tự.
- Nguyên liệu cơ bản vẫn là thành phần phụ để chế tạo/nâng cấp vũ khí có hệ, giúp người chơi kiếm phần nguyên liệu này nhanh hơn.
- Dạng có hệ là nguồn nguyên liệu đặc trưng cho vũ khí hệ tương ứng.
- Kỹ năng và cách đánh riêng của từng loài sẽ thiết kế trong phần riêng sau.

**Quy mô định hướng trước đó:** khoảng 1–2 loài mỗi nhóm khi mở rộng. Cần xác nhận lại số loài gốc, vì dạng không hệ và biến thể không nhất thiết là loài mới.

**Ví dụ minh họa:** Loài A không hệ → da/vảy/xương/nanh A. Loài A hệ lửa → có nguồn nguyên liệu lửa; công thức vũ khí lửa dùng nguyên liệu cơ bản cùng nguyên liệu hệ. Chưa xác định bảng rơi, công thức và tỉ lệ.

## 5. Hai loài giao chiến trong cuộc săn

### Yêu cầu đã thống nhất

- Chỉ kích hoạt giao chiến giữa hai loài khác nhau khi có trạng thái chiến đấu của người chơi được xác nhận; không tự cho chúng đánh nhau chỉ vì đứng gần ngoài cuộc săn.
- Trong giao chiến, cả hai vẫn có thể chuyển sang tấn công người chơi.
- Sát thương giữa quái làm giảm máu thực tế của mục tiêu, nhưng ở mức nhỏ để cuộc giao chiến kéo dài và tạo cơ hội bắt con đang yếu.
- Ví dụ người dùng: quái 1 có 100 máu, quái 2 đang bị săn còn 20 máu; một đòn giữa quái có thể gây 2–3 sát thương. Đây chỉ là ví dụ, chưa phải sát thương cố định hoặc phần trăm.

### Cần chốt trước khi lập trình

- Hai con cần cùng tham gia cuộc săn hay một con có thể đi ngang và tham gia?
- Điều kiện xác nhận chiến đấu, phạm vi phát hiện, thời gian duy trì và lúc kết thúc trạng thái.
- Cách chọn mục tiêu giữa người chơi và quái khác; thời gian giao chiến/tạm ngừng.
- Quái có được giết quái khác hay phải dừng ở một ngưỡng máu? Nếu giết được thì thưởng và nhiệm vụ xử lý thế nào?
- Sát thương của quái khác không tính thành đóng góp của người chơi; ngưỡng 10% chỉ tính sát thương người chơi và pet của họ theo mục 7.
- Sát thương nhỏ từng đòn vẫn có thể giết mục tiêu nếu đánh lâu; cần quyết định rõ, không mặc định rằng mục tiêu luôn sống để bắt.

**Phạm vi:** phát triển sau khi săn một quái, bắt giữ và nhận thưởng đã hoạt động ổn định.

## 6. Bắt giữ và phần thưởng

### Đã thống nhất

- Bắt quái còn sống khi máu **từ 10% trở xuống**: có dấu hiệu đi khập khiễng/chậm, đặt Iron Trap rồi dẫn quái vào, quái bị choáng cúi đầu, người chơi đến miệng cho uống thuốc ngủ. Công thức bẫy và giới hạn vật dụng ở mục 21; thời gian thao tác và điều kiện thất bại cụ thể chưa chốt.
- Bắt thành công nhận cá thể sưu tầm cùng nguyên liệu.
- Người dùng muốn **bắt nhận nhiều nguyên liệu hơn hạ gục**.
- **Số lượng nguyên liệu mặc định từ khủng long luôn là 1 đơn vị mỗi lượt rơi/mổ**, không phải 1 đơn vị cho toàn bộ cuộc săn. Loại nguyên liệu vẫn theo bảng rơi.
- Thưởng nguyên liệu khi bắt có **số lượt tương đương số lần mổ xác** của loại quái đó: 3/4/5 tùy loại. Áp dụng cơ chế tăng lượng đã nêu trên lượng gốc 1: **50% nhận 1, 50% nhận 2**, tính riêng từng lượt. Xem mục 20.
- Quy tắc mới thay ví dụ thưởng bắt ban đầu: không tự nhân đôi toàn bộ hoặc cộng thêm một gói thưởng bắt nữa lên các lượt đã tăng số lượng. Ngoại lệ tăng lượng cho nguyên liệu hiếm, nếu có, chưa được xác định.
- Khi đội bắt thành công, **mỗi người đủ điều kiện nhận một cá thể vào bộ sưu tập riêng**. Cách xác định điều kiện chi tiết và việc các bản cá thể có cùng màu/kích thước/biến thể chưa chốt.
- Loại nguyên liệu nhận có yếu tố ngẫu nhiên và có thể trùng qua nhiều lượt; tỉ lệ từng loại cần bảng riêng, số lượng gốc đã chốt là 1. Xác suất 50/50 tăng lượng khi bắt không phải xác suất rơi từng loại nguyên liệu.
- Sau lượt săn/bắt có bảng phần thưởng bổ sung: các loại xương như xương thường, cứng, mềm, rồng, hoặc vật phẩm khác để nâng vũ khí.
- Quy tắc không hệ không rơi nguyên liệu hệ phải áp dụng cả phần thưởng chính và bổ sung.
- Vật phẩm đã nhặt trong map, gồm vảy/đuôi và quặng đã đào, được giữ dù nhiệm vụ thắng hay thua. Việc giữ đồ đã nhặt không phụ thuộc hoàn thành mục tiêu; phạm vi ngưỡng 10% đối với quyền nhặt/mổ vẫn cần chốt.

### Đề xuất

- Mỗi người đủ điều kiện nhận phần thưởng cá nhân, tính ngẫu nhiên riêng; bảng thưởng trình bày rõ phần từ mục tiêu và phần bổ sung.
- Cho dạng không hệ rơi nguyên liệu cơ bản thường xuyên; sức mạnh vũ khí hệ vẫn yêu cầu săn nguồn nguyên liệu hệ.
- Đặt tên rõ cho thưởng bắt và thưởng hoàn thành để tránh vô tình nhân đôi nhiều lần.
- Chấp nhận bắt là phương án nhiều thưởng hơn theo ý người dùng; cân bằng bằng khâu chuẩn bị và thực hiện bắt. Không ép sửa thành hai cách có thưởng bằng nhau.

**Chưa chốt:** bảng loại nguyên liệu/xác suất và ngoại lệ tăng lượng với vật phẩm hiếm nếu có; ánh xạ từng nhóm quái với 3/4/5 lượt; ai được thao tác bắt; cách nhận thưởng bắt; xử lý hết chỗ kho. Đồ rơi trong map cần nhặt, quái bị tiêu diệt có thao tác mổ xác. Lượng mặc định từ khủng long là 1.

## 7. Săn đội, máu quái và điều kiện nhận thưởng

### Đã thống nhất

- Cho phép người mạnh săn cùng người mới.
- Mỗi người phải đạt ngưỡng **10%** để nhận thưởng. Sát thương đóng góp bằng **sát thương người chơi + sát thương pet của chính người chơi đó** lên mục tiêu săn; mẫu số dùng tính tỷ lệ còn cần chốt.
- **Hồi phục và các hành động hỗ trợ không cộng vào ngưỡng 10%.** Hồi phục là phần phụ của kỹ năng chiến đấu đồng hành, không thay thế yêu cầu gây sát thương.
- Máu quái tăng theo số thành viên 1, 2, 3, 4 để điều chỉnh độ khó.
- Ví dụ máu solo là 1.000; chưa chốt các mức máu đội. Không mặc định tăng tuyến tính.
- Mục tiêu là khuyến khích mọi người tham gia và chơi chung.

### Điểm cần cân bằng

- Nếu hiểu ngưỡng là 10% máu tối đa của quái sau điều chỉnh theo đội, cần ghi rõ trong giao diện và tính thống nhất.
- Người mạnh có thể kết thúc quá nhanh khiến người mới chưa đạt ngưỡng; tăng máu đơn thuần không giải quyết hết.
- Người dùng đã chọn chỉ tính sát thương của người chơi và pet; người chỉ hồi phục/hỗ trợ vẫn phải đạt ngưỡng sát thương để nhận thưởng. Không tự đổi sang điểm hỗ trợ khi cân bằng.
- Sát thương quái đánh nhau không thuộc sát thương của người chơi hoặc pet, nên không cộng vào đóng góp của thành viên.
- Nếu ngưỡng bắt là trước khi hết máu, tổng sát thương người chơi có thể gây sẽ thấp hơn máu tối đa; phải thử cùng quy tắc 10%.
- Cần xử lý người vào muộn, rời đội, mất kết nối và thay đổi số thành viên; tránh đổi máu/điều kiện tùy tiện giữa trận.
- Điều kiện thưởng nguyên liệu, cá thể bắt và hoàn thành nhiệm vụ có dùng chung một ngưỡng hay không chưa chốt.
- Quy tắc mới ở mục 20 bảo toàn vật phẩm đã nhặt khi thất bại; không tự tước lại đồ đã vào túi theo kết quả nhiệm vụ. Cần chốt riêng ngưỡng 10% áp dụng lúc nhặt/mổ và nhận thưởng cuối ra sao.

## 8. Cá thể hiếm, đột biến và trưng bày

### Đã thống nhất

- Người chơi tự do lựa chọn năm cá thể thể hiện cá tính; không khóa ống theo hệ/loài.
- Một loài gốc A có thể có nhiều chủng/biến thể: đột biến lửa, nguyên tố khác, thay đổi hình dạng như thêm gai và các ý tưởng sẽ phát triển tiếp.
- Có khác biệt về màu, kích thước và hiệu ứng; cá thể đặc biệt có ngoại hình/hiệu ứng nổi bật hơn trong ống nghiệm.
- Người dùng cho phép cùng phát triển thêm ý tưởng ở phần này; chưa chốt danh sách hoặc tỉ lệ hiếm.

### Đề xuất tổ chức

- Mỗi cá thể lưu các đặc điểm riêng thay vì dùng một nhãn hiếm duy nhất: loài gốc, hệ, đột biến, màu, kích thước.
- Phân biệt dạng hệ thông thường với đột biến hệ hiếm; không mặc định mọi quái có lửa là đột biến.
- Ngoại hình đặc biệt có thể nhận biết khi săn và giữ lại khi trưng bày.
- Có nhãn kích thước gốc vì mô hình đã thu nhỏ; giữ tương quan lớn/nhỏ trong giới hạn ống nếu phù hợp.
- Bản đầu chỉ một biến thể rõ nét; mở rộng sau khi chi phí làm mô hình/hoạt ảnh đã được kiểm chứng.

**Chưa chốt:** biến thể có đổi sức mạnh/kỹ năng hay chỉ ngoại hình; cách xuất hiện, xác suất, tổ hợp đặc điểm; cùng cá thể có giống nhau với mọi người trong đội không.

## 9. Vũ khí, giáp và thành tích

- **Đã thống nhất:** chỉ một vũ khí được chọn để trưng bày; có thể đổi; aura nhẹ cho các mốc nâng cấp phù hợp.
- **Hướng muốn phát triển:** trưng bày cả bộ giáp của người chơi. Chưa chốt số vị trí hoặc cách đặt.
- **Đã thống nhất:** phía trên ống nghiệm có thành tích săn nhanh nhất để thể hiện chiến tích cá nhân.
- **Đề xuất:** kỷ lục ghi rõ loài/biến thể, độ khó, solo/đội, bắt/hạ gục; không so chung các điều kiện khác nhau.
- **Cần chốt:** hiện thời gian bắt đúng cá thể trong ống hay kỷ lục tốt nhất của loài; thời điểm bắt đầu/kết thúc tính giờ.
- Đã có danh sách bảy loại vũ khí, trang bị khởi đầu và khung chiến đấu ở mục 18. Chuỗi đòn, công thức, cấp nâng cấp, chỉ số giáp và kỹ năng cụ thể từng vũ khí chưa chốt.

## 10. Pet khủng long đồng hành

### Đã thống nhất

- Người chơi có một pet khủng long nhỏ ngay khi mới vào game.
- Đây là thiết kế pet toàn game. Trong P1 chỉ làm theo chủ, đánh theo chu kỳ, gọi hồi và choáng; né/đỡ, chủ động thu hút quái, tự rút hồi và chế trang bị để sau P1 theo cấu hình thử mục 23.
- Pet hỗ trợ chiến đấu và hồi phục; là một hệ thống riêng với bộ sưu tập trong ống nghiệm. Chưa có yêu cầu biến mọi thú bắt được thành pet.
- Sát thương pet cộng vào đóng góp của chủ khi xét ngưỡng 10%; hồi phục chỉ là kỹ năng hỗ trợ, không cộng điểm nhận thưởng.
- Pet có ba mục trang bị: **vũ khí, mũ, giáp thân**; từng mục có thể chế tạo và trang bị.
- Pet có hai chế độ chính: **chiến đấu** và **về hồi máu cho chủ theo nút gọi**. Yêu cầu mới thay cách tự hồi khi chủ yếu máu trước đó; chưa có yêu cầu kết hợp thêm tự động.
- Pet chiến đấu có nhịp, không đánh liên tục; dùng vũ khí người chơi chế/trang bị và gây sát thương dựa trên chỉ số vũ khí. Có thể đỡ, thu hút chú ý của quái và né đòn cơ bản.
- Pet có máu riêng, khi gần hết máu có thể rút ra chỗ an toàn để tự hồi. Khi máu xuống **1**, pet **choáng bất động 30 giây**, không chết; hết thời gian hồi đầy máu và quay lại chiến đấu.
- Người chơi bấm nút gọi pet về hồi **70% máu tối đa của chủ**; pet mang viên thuốc lớn chạy đến, ném vào vùng đầu/miệng chủ. Màn hình có hồi chiêu; mốc **1 phút 59 giây (119 giây)** vẫn là thời gian đề xuất. Chi tiết chỉ số sẽ cân bằng khi làm game.
- Khi choáng, nút gọi hiện **“Pet đang hồi phục”** và thời gian choáng còn lại. Hồi đầy sau choáng không làm mới hồi chiêu kỹ năng hồi cho chủ.
- Khi chủ đang cho quái uống thuốc ngủ, pet tạm dừng đánh mục tiêu theo mục 21. Chi tiết hành vi và những điểm chưa chốt xem mục 22.

### Đề xuất cho bản thử

- Trạng thái tối thiểu: theo chủ → chiến đấu → hỗ trợ hồi phục → trở lại trạng thái phù hợp.
- Chia nhỏ: theo chủ và đánh theo chu kỳ trước, sau đó nối gọi hồi và choáng 30 giây trước bước thử bắt. Trang bị có thể chế, né/đỡ và tự rút lui để sau P1; xem phạm vi thử hiện hành ở mục 23–24.
- Cần xác định khoảng cách, thời gian thực hiện, thời điểm bắt đầu hồi chiêu, khả năng bị ngắt và xử lý chủ bị hạ gục. Lượng hồi đã đặt là 70% máu tối đa, kích hoạt bằng nút gọi.
- Kiểm tra hồi chiêu và tình trạng pet khi nhận lệnh, tránh bấm liên tục tạo nhiều lần hồi chồng nhau.

**Chưa chốt:** thời gian hồi chiêu cuối, thời điểm áp dụng hồi và các thông số chi tiết, ngưỡng/cách tự hồi của pet, đỡ/né/thu hút mục tiêu, loài pet, tác dụng mũ/giáp và cách xuất hiện ở base. Hồi chủ 70% máu tối đa, máu riêng và cơ chế 1 máu/choáng 30 giây đã chốt.

## 11. Lộ trình đề xuất và điều kiện hoàn thành

| Mốc | Phạm vi | Kiểm tra để qua mốc |
| --- | --- | --- |
| A — Săn thử | Một búa, một loài, khu nhỏ. P1-A/B làm người và quái; P1-C lần lượt thêm pet theo/đánh rồi gọi hồi/choáng | Đánh/né rõ ràng; pet cơ bản có đủ trước bước thử bắt P1-D |
| B — Vòng chơi đầu tiên | Suy yếu → bắt/hạ gục → nhận thưởng → một nâng cấp; kho, một ống, lưu tiến trình | Hoàn thành được cả lượt săn; thoát/vào vẫn giữ vật phẩm, cá thể và lựa chọn trưng bày |
| C — Định hình hệ thống | Dạng không hệ/có hệ, nguyên liệu cơ bản/đặc trưng; chiến đấu pet và ba ô trang bị tối thiểu | Nguồn nguyên liệu đúng; chế tạo/trang bị pet hoạt động; không nhận thưởng lặp |
| D — Base và cá thể | Năm ống tự chọn, màu/kích thước, một đột biến, một vũ khí trưng bày; giáp nếu đã chốt | Đổi trưng bày không mất thú; khách xem đúng; hiệu ứng không che thông tin |
| E — Săn đội | 2–4 người, điều chỉnh máu, điều kiện 10%, thưởng cá nhân nếu chốt, kỷ lục | Thử người mạnh/người mới, bắt sớm, rời đội và mất kết nối |
| F — Mở rộng | Giao chiến hai loài, thêm loài/hệ, bố trí máy chủ mục tiêu 12 người | Không phá cơ chế bắt/thưởng; kiểm tra tải với tối đa 60 cá thể trưng bày cùng pet và người chơi |

Các mốc A–F ở đây là lộ trình toàn game, khác các bước nhỏ P1-0 → P1-G ở mục 23. Không phải lịch hoặc cam kết thời gian. Cấu trúc dữ liệu và cách ghi giao dịch được chuẩn bị ở P1-0 bằng kho thử trong bộ nhớ; kết nối lưu tài khoản thật ở P1-F và kiểm tra lỗi tại P1-G. Không đợi đến cuối mới thiết kế dữ liệu, cũng không bắt người mới hoàn thiện DataStore ngay ngày đầu.

## 12. Quy tắc triển khai đề xuất

- Phân biệt rõ máy chủ 12 người với đội săn tối đa bốn người trong thiết kế.
- Sát thương, phần thưởng, sở hữu, đóng góp và thành tích cần được kiểm tra phía máy chủ khi lập trình.
- Không tạo toàn bộ mô hình trong kho ra thế giới; chỉ dựng các cá thể cần hiển thị.
- Kiểm tra tình huống đầy tải thay vì suy ra game chạy tốt chỉ từ số người cho phép.
- Khi làm đồ họa, ưu tiên nhận biết đòn đánh, cá thể và chiến tích; hiệu ứng phục vụ thông tin.
- Tra tài liệu Roblox hiện hành khi chọn giải pháp kỹ thuật cụ thể; tài liệu này mô tả thiết kế, chưa xác nhận hiệu năng hay API.
- Chưa thêm giao dịch, sinh sản, PvP, kiếm tiền, thế giới rộng hoặc hệ xây base tự do vào phạm vi đã chốt.

## 13. Những quyết định cần trao đổi tiếp

Ưu tiên gần cho P1: phạm vi nhỏ, nền tảng dữ liệu, cảm giác búa, AI một quái và quy trình bắt/thưởng. Mục 23–24 đưa ra cấu hình thử để kiểm tra; chưa có kết quả chơi thử.

Trước săn đội/giao chiến hai loài mới cần chốt mẫu số và phạm vi ngưỡng 10%, quái có được kết liễu nhau. Đã chốt đóng góp chỉ gồm sát thương người chơi và pet, không tính hồi phục/hỗ trợ; mỗi thành viên đủ điều kiện nhận một cá thể khi bắt. Những quyết định này chưa cản việc thử chiến đấu solo. Xem mục 24.5 về công thức đề xuất, không tự coi đó là quyết định đã chốt.

Sau đó: bố trí base/sảnh; chi tiết pet; thời gian cho uống và cách xử lý hành trang bắt ở mục 21; thời gian tính kỷ lục; danh sách loài và kỹ năng; biến thể và tỉ lệ; công thức trang bị. Hạn mức bẫy/thuốc theo số người đã chốt ở mục 21.

Không cần trả lời tất cả cùng lúc. Chỉ chốt phần cần cho mốc sắp làm.

## 14. Prompt dùng để tiếp tục công việc

> Hãy đọc THIET_KE_GAME.md trong thư mục dự án và dùng làm hồ sơ thiết kế hiện tại. Phân biệt yêu cầu đã thống nhất, đề xuất và phần chưa chốt. Tiếp tục từ mốc thực tế đã hoàn thành; đừng coi lộ trình là những gì đã được lập trình. Tôi là người mới: giải thích rõ từng bước. Khi tôi sửa ý tưởng, cập nhật mục liên quan và nhật ký quyết định, giữ những yêu cầu khác còn hiệu lực. Không tự đổi điều kiện thưởng, giới hạn trưng bày hoặc cơ chế pet. Với phần chưa chốt, hỏi điều thật sự cần trước khi làm phụ thuộc vào nó; vẫn tiếp tục phần độc lập. Sau mỗi mốc, ghi những gì đã làm, đã kiểm tra, hạn chế và việc tiếp theo vào chính tài liệu này.

Trạng thái hiện tại: đang triển khai L0 tại mục 25 trên map 12 base hiện có. Mở `HunDino_L0.rbxlx`, đọc README và source, tiếp tục kiểm tra phần đang dở; không dựng lại từ đầu hoặc ghi đè chỉnh sửa map thủ công. P1 săn/bắt tại mục 23–24 nối sau L0. Chỉ số thử không phải quyết định cuối. PC kiểm tra trước; chưa có cảm ứng hoàn chỉnh, nhiệm vụ, kinh tế hay lưu tài khoản. Chỉ đánh dấu hoàn thành sau khi có bằng chứng kiểm tra tương ứng.

## 15. Tiến độ và nhật ký

- **21/09/2026 — v0.1:** Tổng hợp trao đổi, tạo hồ sơ chung. Chưa có code hoặc bản game chạy được.
- Xác nhận năm ô trưng bày tự do, kho lớn hơn phần trưng bày; bỏ ràng buộc một hệ/một loài mỗi ống.
- Làm rõ hệ rồng tách khỏi khả năng bay; thêm dạng không hệ làm nguồn nguyên liệu cơ bản.
- Ghi yêu cầu giao chiến giữa hai loài trong cuộc săn, thưởng bắt cao hơn, sát thương tối thiểu 10% và máu tăng theo đội.
- Thêm pet có ngay từ đầu, hồi phục và ba mục trang bị; ghi hướng trưng bày giáp.
- **21/09/2026 — v0.2:** Ghi nhận phản hồi “ok” theo phương án vừa đề xuất: cộng thêm nguyên liệu khi bắt; mỗi thành viên đủ điều kiện nhận một cá thể vào kho riêng. Giữ các con số thưởng và quy tắc chi tiết ở trạng thái chưa chốt; các đề xuất khác chưa được tự động chuyển thành yêu cầu.
- **Bước hiện tại — 28/09:** phát triển sảnh/luyện tập L0 từ map có sẵn; đã kiểm tra tự động, chưa kiểm chứng bằng Play. Tiếp tục từ mục 25, chưa mở vòng săn P1.
- **21/09/2026 — v0.3:** Người dùng xác nhận ngưỡng 10% tính tổng sát thương người chơi và pet của họ. Hồi phục là phần phụ của kỹ năng đồng hành, không tính đóng góp nhận thưởng. Cập nhật đồng bộ phần săn đội, giao chiến giữa quái và pet; mẫu số tỷ lệ vẫn chưa chốt.
- **21/09/2026 — v0.4:** Rà soát mức độ sẵn sàng theo yêu cầu người dùng; thêm đánh giá ở mục 16. Không đổi các yêu cầu đã chốt, chưa triển khai game.
- **21/09/2026 — v0.5:** Nhận phần làm rõ điều khiển: PC và điện thoại, camera tự do, tấn công theo hướng di chuyển hoặc theo tâm ngắm. Thêm mục 17; chi tiết phím đã được thay thế bằng quyết định v0.8.
- **21/09/2026 — v0.6:** Người dùng đồng ý bổ sung góp ý điều khiển: đứng yên ở chế độ tự do giữ hướng di chuyển cuối; thả chuột phải về chế độ trước đó; cung ngắm cao/thấp theo tâm, cận chiến chủ yếu quay hướng trên mặt đất; điện thoại có nút bật/tắt ngắm. Bố trí nút, hỗ trợ ngắm và chi tiết từng vũ khí vẫn chưa chốt. Tiếp tục chờ các phần làm rõ khác.
- **21/09/2026 — v0.7:** Nhận phần vũ khí/chiến đấu: trang bị khởi đầu, bảy loại vũ khí, ba dạng hành động tấn công, đỡ khiên, dấu hiệu báo đòn, né lộn và lướt cung, hai trạng thái rút/cất, thể lực. Thêm mục 18; đánh dấu xung đột phím Shift và các thông số chưa chốt. Chưa lập trình, chưa tổng hợp toàn đợt.
- **21/09/2026 — v0.8:** Theo yêu cầu người dùng, loại bỏ sự phụ thuộc vào Shift Lock mặc định: PC yêu cầu tắt tính năng này trong cài đặt; Shift chạy, Ctrl ghim tâm riêng, chuột phải giữ ngắm, điện thoại có nút lock riêng. Chốt tự cất trước khi chạy, hồi thể lực theo trạng thái, buff cung một lần không cộng dồn và lướt lại chỉ làm mới thời gian. Thêm mục 19 về nghỉ sau đòn, đánh bộ phận, choáng/gục tăng dần và các phương án rụng đuôi. Các số minh họa và đề xuất cân bằng chưa phải thông số cuối.
- **21/09/2026 — v0.9:** Người dùng làm rõ cân bằng song dao/búa: song dao đánh nhanh nhưng sát thương mỗi đòn thấp hơn nhiều; búa có sát thương đòn/combo kỹ năng mạnh để bù tốc độ. Ghi định hướng này, không kết luận meta đã cân bằng khi chưa thử. Phân biệt sát thương với số lần quay xác suất rụng đuôi; chưa tự chọn phương án rụng đuôi hoặc thông số chống gục liên tục.
- **21/09/2026 — v0.10:** Làm rõ combo búa là chuỗi hành động mở ra combo/chiêu đặc biệt, không chỉ tổng các đòn độc lập. Ví dụ người dùng: thường → mạnh → thường → kỹ năng → kỹ năng. Ghi nguyên tắc và ví dụ, chưa khóa chuỗi cuối, thời gian nối hoặc hiệu ứng chiêu.
- **21/09/2026 — v0.11:** Nhận phần thắng/thua: bảng nhiệm vụ, một mục tiêu chính, ba quái trong map, khoảng 40 phút, giới hạn tử vong chung khi săn đội và hồi sinh ở điểm bắt đầu. Ghi bảo toàn đồ đã nhặt dù thua; mổ xác 3/4/5 lần tùy loại, bắt nhận số lượt tương đương và xét tăng lượng từng lượt. Đồng bộ mục 6/7, thêm mục 20; số lượng gốc làm rõ ở v0.12, mốc thất bại ở v0.13.
- **21/09/2026 — v0.12:** Người dùng sửa số lượng mặc định từ khủng long luôn là 1. Cập nhật mổ/rơi và ví dụ thưởng bắt: lượng gốc 1, cơ chế 50/50 giữ 1 hoặc tăng lên 2; số lượt 3/4/5 không đổi. Không áp quy tắc này sang quặng hoặc gói thưởng nhiệm vụ riêng chưa thiết kế.
- **21/09/2026 — v0.13:** Chốt thành công có 2 phút thu hoạch rồi tự về sảnh, hoặc chọn về sớm. Chốt chết quá ba lần: ba lần đầu hồi sinh ở điểm bắt đầu, lần tử vong thứ tư báo thất bại và cả đội về sảnh; tổng số lần tính chung đội. Thay các mô tả “ba mạng” dễ gây nhầm, giữ quy tắc bảo toàn đồ đã nhặt.
- **22/09/2026 — v0.14:** Nhận quy trình bắt: thương nhân bán Trap, kết hợp quặng sắt chế Iron Trap; quái còn sống và máu ≤10% đi khập khiễng; dẫn vào bẫy gây choáng/cúi đầu rồi cho uống thuốc ngủ. Giới hạn mang 3 Iron Trap và 3 bình ngủ, hết cơ hội bẫy không tự làm thua nhiệm vụ săn thông thường; nhiệm vụ bắt sống có điều kiện thất bại liên quan. Thêm mục 21, cập nhật điều kiện thắng theo loại nhiệm vụ; giới hạn theo người/đội và thời điểm thất bại cụ thể còn cần xác nhận.
- **22/09/2026 — v0.15:** Người dùng đồng ý pet của người cho uống tạm dừng đánh mục tiêu. Chốt choáng bẫy 13 giây, quái gầm gừ/rên nhẹ; ghi mốc cất vũ khí 1 giây và dự kiến chạy tới đầu khoảng 2 giây. Thời gian cho uống, cảnh báo gần hết bẫy và hạn mức vật dụng theo người/đội vẫn chưa chốt.
- **22/09/2026 — v0.16:** Nhận chi tiết pet: đánh có nhịp bằng trang bị, đỡ/thu hút quái/né cơ bản; tự rút hồi khi yếu; còn 1 máu thì choáng 30 giây, không chết, sau đó đầy máu tái chiến. Hồi cho chủ chuyển sang nút gọi có hiển thị hồi chiêu; 1:59 là mốc đề xuất, lượng hồi chưa chốt. Cập nhật mục 10 và thêm mục 22, giữ quy tắc pet ngừng đánh khi chủ cho uống thuốc ngủ.
- **22/09/2026 — v0.17:** Chốt hạn mức mỗi người theo số thành viên: solo 3 bẫy/3 bình, đội hai 2/2, đội ba hoặc bốn 1/1; giảm lượng mang dư trước khi vào map, sau trận chuẩn bị hành trang lại. Chốt nút báo pet đang hồi phục khi choáng và hồi đầy không làm mới kỹ năng. Pet hồi chủ 70% máu tối đa, chạy tới với viên thuốc lớn rồi ném vào vùng đầu; thông số/hoạt ảnh chi tiết bàn khi triển khai. Cách xử lý đồ dư trong kho vẫn cần xác định.
- **22/09/2026 — v0.18:** Người dùng chốt bẫy/bình ru ngủ mang vượt hạn mức được tự trả về kho trước khi vào map; không xóa hoặc tiêu hao phần vượt hạn mức. Quy tắc với đồ chưa dùng sau trận vẫn để bàn riêng.
- **22/09/2026 — v0.19:** Người dùng yêu cầu dừng mở rộng ý tưởng và chuyển sang thiết kế bản thử. Thêm mục 23: solo, PC kiểm tra trước, một búa có combo, một quái đi bộ không hệ, pet, săn/bắt, một nâng cấp và một ống trưng bày có lưu. Thông số mới là cấu hình thử của trợ lý; không chuyển các đề xuất cũ thành yêu cầu toàn game. Đã cập nhật trạng thái giai đoạn, chưa viết code.
- **27/09/2026 — v0.20:** Người dùng gửi đủ 12 ảnh góp ý và báo “xong”. Đối chiếu với file thực: mục 23 đã có trong v0.19, nhận xét thiếu mục này chỉ đúng với đoạn trích bị cắt. Thêm bảng trạng thái và mục 24; làm rõ vòng đời nhiệm vụ, tình huống bắt, ghi thưởng, kho/lưu, quyền máy chủ, nhịp búa, trạng thái AI và tiêu chí kiểm tra. Đề xuất đưa nền tảng dữ liệu lên P1-0 và giảm phần pet nâng cao trong P1. Không đổi yêu cầu đã chốt; thông số mới vẫn là cấu hình thử, chưa lập trình.
- **27/09/2026 — v0.21:** Nhận đủ đợt góp ý thứ hai: 12 ảnh, trong đó 12 mục nhận xét kèm phần ngoài phạm vi/kết luận. Đối chiếu với cả file vì người góp ý chỉ thấy đoạn cắt giữa mục 19. Sửa câu “chưa chọn vũ khí”; giữ bảng phím đang có; chia P1-0 → P1-G với tiêu chí hoàn thành từng bước. Đề xuất P1 bắt buộc PC, combo N → H → K kết thúc, một đòn quái; combo dài/đánh bộ phận/thêm đòn/nhiệm vụ bắt sống/điện thoại để sau P1. Dùng bộ nhớ thử trước, DataStore tại P1-F; bổ sung phân loại dữ liệu, mã thưởng theo lượt nhận và checklist hồi quy. Giữ pet hồi 70%, choáng 30 giây, bẫy 13 giây, chết thứ tư và đồ nhặt giữ khi thua. Không tự chốt góp ý thành yêu cầu toàn game; chưa viết code.

- **28/09/2026 — v0.22:** Người dùng chốt đổi 16 → 12 người, bắt đầu dự án và ưu tiên map/base + bãi luyện tập. Đọc HunDino1.rbxl hiện có: 12 base, 3539 đối tượng và script mẫu. Tạo bản sao nguyên vẹn, xuất bản phát triển L0.1 với source búa/giáp mẫu/hình nộm/pet cơ bản/cổng chuyển khu. Chín nhóm kiểm tra tự động đạt; thao tác Studio bị lỗi nên chưa xác nhận Play. Giữ P1 để nối sau; chưa mở hệ thống săn, thưởng hoặc lưu.

## 16. Đánh giá mức độ sẵn sàng — 21/09/2026

**Lưu ý cập nhật 28/09:** phần đánh giá dưới đây dành cho vòng săn. Ưu tiên triển khai đã chuyển sang sảnh/luyện tập L0 ở mục 25.

**Đánh giá của trợ lý:** định hướng đủ rõ để bước sang thiết kế bản thử; chưa đủ chi tiết để lập trình toàn bộ game. Cân bằng, độ vui và hiệu năng chưa thể xác nhận khi chưa có bản chơi được.

### Phần đã vững về định hướng

- Vòng săn/bắt → nhận nguyên liệu → chế tạo/nâng cấp → săn tiếp có mục tiêu liên tục.
- Bản sắc riêng nằm ở sưu tầm cá thể, năm ống tự chọn và base thể hiện chiến tích.
- Hệ/loài/hình thái đã được tách; nguồn nguyên liệu cơ bản và nguyên liệu hệ có vai trò khác nhau.
- Pet có từ đầu; đóng góp chỉ tính sát thương người chơi cộng pet, không tính hồi phục.
- Có lộ trình và phân biệt rõ quyết định với đề xuất.

### Phần có cấu hình P1 và việc cần kiểm chứng

| Quyết định | Nội dung cần làm rõ |
| --- | --- |
| Điều khiển và chiến đấu | P1 đã chọn búa, bảng phím PC, combo ngắn và chỉ số thử ở mục 23; cần kiểm chứng bằng chơi. Sáu vũ khí còn lại và điều khiển điện thoại để mốc sau |
| Một cuộc săn hoàn chỉnh | P1 một quái/nhiệm vụ săn thường; đã có luồng tại 24.3, cần thử vào/ra, hết giờ, chết thứ tư và kết thúc đồng thời. Ba quái/nhiệm vụ bắt sống để sau |
| Bắt giữ | Có cấu hình uống 3 giây và bảng thất bại tại 24.4; kiểm chứng bẫy 13 giây, ngắt thao tác, đồ tiêu hao và pet ngừng đánh |
| Pet tối thiểu | P1-C có theo/đánh, choáng 30 giây, gọi hồi 70%, hồi chiêu thử 119 giây; thử hành vi và UI. Tự rút hồi để sau P1 |
| Tiến trình đầu tiên | P1-E/F có công thức nâng, nguồn nguyên liệu, kho/ống/lưu; cần chơi và kiểm tra lỗi thực tế trước khi kết luận hoạt động |

### Phần cần chốt trước khi hoàn thiện săn đội

- Mẫu số của 10%: máu tối đa sau điều chỉnh theo đội hay đại lượng khác.
- Máu quái theo số người, vào/rời trận, đặc điểm cá thể trao cho cả đội.
- Quan hệ sảnh 12 người và khu săn 1–4 người.
- Giao chiến hai loài: việc kết liễu và ảnh hưởng tới nhiệm vụ/phần thưởng.

### Đề xuất thứ tự tiếp theo

- Tạm giữ phạm vi hệ thống hiện tại; tập trung thiết kế chiến đấu cho một vũ khí và một loài trước.
- Dùng mô hình đơn giản để kiểm tra cảm giác đánh, né, bắt và hồi phục; đầu tư hình ảnh sau khi vòng chơi hoạt động.
- Sau P1-G có thể thử đồng bộ cơ bản hai người trước khi mở rộng; săn đội đầy đủ thuộc mốc E của lộ trình toàn game. Đây là đề xuất hiện hành thay cách thử hai người ngay ở giai đoạn A/B trước đó.
- Chưa cần chốt mọi loài, hiệu ứng hoặc tỷ lệ hiếm để bắt đầu; cần kiểm chứng người chơi có muốn săn lại sau một lượt hay không.

Đối chiếu: Capcom mô tả vòng lặp MHW là thu nguyên liệu từ quái để làm trang bị phục vụ mục tiêu tiếp theo, cùng các hệ thống chuẩn bị, vũ khí và săn đội. Tham khảo: [Hướng dẫn MHW của Capcom](https://news.capcomusa.com/lets/browse/15-tips-on-playing-the-monster-hunter-world-beta). Các đánh giá và đề xuất bên trên dành riêng cho dự án này, không phải yêu cầu sao chép toàn bộ MHW.

## 17. Làm rõ từng phần — Điều khiển và hướng tấn công

**Trạng thái:** phần điều khiển nền tảng đã được ghi nhận. Các chi tiết chưa chốt giữ nguyên; cấu hình điều khiển rút gọn của bản thử ở mục 23.

### Điều khiển hiện hành — đã thống nhất

- Game chơi được trên **máy tính và điện thoại**. Người dùng định hướng trải nghiệm máy tính thuận tiện/hấp dẫn hơn; điều khiển điện thoại vẫn cần được thiết kế để chơi được.
- Góc nhìn tự do, không khóa vào mục tiêu.
- Có vũ khí cung; quy tắc hướng tấn công áp dụng cho tất cả vũ khí, kể cả cung. **P1 đã chọn búa** trong cấu hình thử; cung để mốc sau.
- Ở chế độ tự do thông thường, người chơi di chuyển bằng W/A/S/D theo hướng nào thì tấn công theo hướng đó.
- Trên PC, người dùng yêu cầu người chơi **tắt Shift Lock mặc định của Roblox trong cài đặt**. Game không dùng tính năng mặc định này để xác định hướng tấn công hoặc kích hoạt ngắm/buff cung. Đây là yêu cầu thiết kế; cách hướng dẫn/kiểm tra cài đặt sẽ xác minh khi triển khai.
- **Giữ Shift:** yêu cầu chạy nhanh; nếu đang rút vũ khí thì tự thực hiện hoạt ảnh cất trước khi chạy.
- **Nhấn Ctrl:** bật/tắt chế độ ghim tâm riêng của game, dùng hướng tâm giữa màn hình để tấn công.
- **Giữ chuột phải:** ngắm theo tâm, độc lập hướng di chuyển. Tính năng này được giữ theo xác nhận của người dùng, không dựa vào Shift Lock mặc định.
- Thả chuột phải trở về chế độ ghim tâm riêng nếu Ctrl đang bật; nếu không thì trở về tự do.
- Điện thoại có nút lock riêng để bật/tắt ghim tâm; vị trí nút và thao tác ngắm cung cụ thể chưa chốt.
- Đỡ khiên dùng nút riêng, không dùng chung chuột phải đã dành cho ngắm; phím cụ thể chưa chốt.

### Cách hiểu hiện tại

Hai cách xác định hướng: **theo hướng di chuyển** và **theo hướng tâm ngắm**. Chế độ ghim tâm Ctrl/nút lock và thao tác giữ chuột phải không tự khóa hoặc tự bám khủng long. Phân biệt ghim camera với trạng thái ngắm của cung; chưa mặc định chỉ bật Ctrl là đủ kích hoạt lướt ngắm/buff cung.

| Trạng thái | Hướng tấn công |
| --- | --- |
| Tự do, đang di chuyển | Theo hướng di chuyển của nhân vật |
| Ghim tâm riêng bật bằng Ctrl/nút lock | Theo hướng tâm giữa màn hình |
| Đang giữ chuột phải | Theo tâm ngắm, độc lập hướng di chuyển |
| Tự do, đứng yên | Giữ hướng di chuyển cuối; xoay camera quan sát không tự đổi hướng đánh |

### Góp ý đã được người dùng đồng ý

- Khi đứng yên ở chế độ tự do, giữ hướng nhân vật/hướng di chuyển cuối để xoay camera quan sát không tự đổi hướng đánh.
- Thả chuột phải không làm mất lựa chọn ghim tâm riêng đã bật bằng Ctrl.
- Với cung, cho hướng ngắm theo tâm có cả độ cao để bắn mục tiêu trên cao; với cận chiến, hướng tâm chủ yếu điều khiển hướng quay trên mặt đất. Không mặc định nhân vật nghiêng toàn thân theo camera.
- Điện thoại có nút **bật/tắt ghim tâm giữa màn hình**. Cần di chuyển, vùng vuốt camera, vị trí nút và cách vào trạng thái ngắm cung sẽ thiết kế sau; chưa chốt hỗ trợ ngắm tự động.

### Góp ý còn để thảo luận

- Đổi chế độ có dấu hiệu rõ trên tâm ngắm; tránh dùng hiệu ứng lớn che mục tiêu.

### Còn cần làm rõ

- Cung ở chế độ tự do (không dùng tâm ngắm) xử lý độ cao của hướng bắn thế nào; quy tắc đứng yên giữ hướng cuối đã chốt.
- Có được vừa đi vừa ra mọi đòn không; hướng đòn được chốt lúc bắt đầu hay còn đổi trong lúc ra đòn/kéo cung. Bàn cùng thiết kế vũ khí sau.
- Chuột phải có thay đổi góc camera/phóng gần không; ghim tâm bằng Ctrl có cùng hiệu ứng camera hay chỉ ghim hướng.
- Bố trí điều khiển điện thoại và việc người dùng có muốn hỗ trợ ngắm hay không.
- Trạng thái ngắm cung khi dùng Ctrl/nút lock: chỉ ghim tâm hay đồng thời ngắm vũ khí. Cần làm rõ trước khi gắn điều kiện buff cung; không tự bỏ cơ chế giữ chuột phải đã thống nhất.

## 18. Làm rõ từng phần — Trang bị, vũ khí và chiến đấu

**Trạng thái:** yêu cầu nền tảng đã được ghi nhận. Góp ý và câu hỏi bên dưới chưa tự trở thành quyết định. Vật dụng bắt giữ ở mục 21; cấu hình vũ khí bản thử ở mục 23.

### Túi đồ và trang bị khởi đầu — đã thống nhất

- Chọn/trang bị giáp và vũ khí qua túi đồ.
- Người chơi mới được cấp một bộ giáp cơ bản với chỉ số khởi đầu để đi săn.
- Trong túi có bản cơ bản của **tất cả các loại vũ khí** thuộc danh sách hiện tại để người chơi lựa chọn.
- Cấp một lượng nhỏ vật phẩm tiêu dùng; loại, số lượng và cơ chế sẽ bàn riêng sau.
- Chưa chốt bộ giáp có những ô nào, vũ khí tự trang bị ban đầu, có đổi trang bị giữa cuộc săn hay không.

### Danh sách vũ khí hiện tại — đã thống nhất

| Loại | Ngoại hình và vai trò người dùng mô tả |
| --- | --- |
| Cung | Tấn công tầm xa; có né lướt khi ngắm và đòn đầu sau lướt được tăng sát thương |
| Kiếm thường + khiên tròn | Một bộ vũ khí; khiên đỡ đòn khủng long, tiêu hao thể lực và chịu ảnh hưởng tùy loại đòn |
| Kiếm dài / katana | Kiếm có vỏ; hoạt ảnh rút kiếm là một phần chuyển trạng thái |
| Thương/giáo cán dài (tên tạm) | Hình dáng tham chiếu vũ khí Quan Vũ; cần mẫu hình sau để xác định lưỡi đao và dáng cán đúng ý người dùng |
| Song dao | Hai dao, đánh nhanh; sát thương mỗi đòn thấp hơn nhiều so với búa; chưa thiết kế chuỗi đòn hoặc kỹ năng |
| Búa tạ | Đầu búa lớn, thân/cán to như khúc củi; chuỗi đòn kết hợp kỹ năng mở ra combo đặc biệt, là phần quan trọng của sức mạnh vũ khí; cần tạo cảm giác đòn đánh có lực |
| Rìu đại hai lưỡi | Hai mảng lưỡi ở hai bên; tấn công mượt, thiên về sức tấn công |

Danh sách trên là phạm vi định hướng game. **P1 đã chọn búa làm trước** trong cấu hình thử mục 23; sáu loại còn lại để sau. Không cần chọn lại vũ khí trước khi bắt đầu P1-A.

**Định hướng cân bằng đã nêu:** song dao dùng nhiều đòn nhẹ; búa có sát thương mỗi đòn cao hơn và có chuỗi thao tác mở combo đặc biệt. Người dùng muốn cả hai có chỗ đứng trong cách chơi hiệu quả. Đánh giá búa phải xét cả khả năng thực hiện combo đặc biệt, không chỉ tốc độ và sát thương đánh thường. Chỉ số, thời gian combo, thể lực, khả năng đánh trúng và cơ hội ra đòn cần thử trước khi xác nhận cân bằng.

### Combo búa — nguyên tắc đã làm rõ, chuỗi cụ thể là ví dụ

- Kết hợp đánh thường, đánh mạnh và sử dụng kỹ năng theo chuỗi để thực hiện combo đặc biệt.
- Ví dụ người dùng: **đánh thường → đánh mạnh → đánh thường → kỹ năng → dùng kỹ năng lần nữa → combo đặc biệt**. Đây là minh họa cách hệ thống hoạt động, chưa phải chuỗi cuối bắt buộc.
- Cần ghi nhận tiến trình combo để phân biệt việc dùng kỹ năng trong chuỗi và dùng kỹ năng độc lập; không coi ví dụ là hai lần dùng cùng một chiêu độc lập chỉ cộng sát thương.
- Chưa chốt bước kỹ năng cuối tự biến thành chiêu kết thúc hay mở thêm hành động; không tự thêm lần bấm thứ sáu.
- Chưa chốt thời gian nối, có cần đánh trúng để tiến combo không, điều kiện ngắt/reset, tương tác né/cất vũ khí, thể lực và hồi chiêu.
- Chưa chốt số lần trúng, sát thương, tác động bộ phận hoặc khả năng gây choáng của chiêu đặc biệt; không mặc định chỉ có một hit.
- Các vũ khí khác sẽ thiết kế riêng; chưa áp dụng chuỗi ví dụ của búa cho toàn bộ vũ khí.
- Riêng P1 dùng cấu hình ngắn N → H → K kết thúc tại mục 23; các câu “chưa chốt” ở đây nói về thiết kế toàn game. Chuỗi năm lần bấm của v0.20 là phương án mở rộng sau khi chuỗi ngắn hoạt động, không còn là điều kiện hoàn thành P1.
- Tham khảo cấu hình dài v0.20 cho sau P1: N → H → N → K → K kết thúc, tổng 332 sát thương / 64 thể lực / 4,10 giây động tác nếu giữ các chỉ số đòn hiện tại. Không dùng các tổng này để kiểm tra combo ngắn P1.

### Khung hành động và đỡ đòn — đã thống nhất

- Mỗi vũ khí có **đánh thường, đánh mạnh, kỹ năng riêng**. Chưa chốt số kỹ năng, chuỗi đòn, phím bấm, hồi chiêu và sát thương.
- Khiên tròn đỡ được đòn khủng long; đỡ thành công mất thể lực.
- Đỡ đòn bắn lửa bị đẩy lùi. Chưa chốt đòn này có gây sát thương xuyên khiên hay hiệu ứng lửa không.
- Đỡ đòn mạnh vẫn mất một lượng máu nhỏ tính theo vài phần trăm máu tối đa; chưa chốt phần trăm, đẩy lùi hoặc giới hạn.
- Chưa chốt góc đỡ, đỡ đúng thời điểm, khả năng đỡ mọi loại đòn hoặc tình huống không đủ thể lực.

### Dấu hiệu báo đòn và né — đã thống nhất

- Khủng long có động tác báo trước để người chơi kịp né/đỡ. Ví dụ há miệng khoảng 1–2 giây rồi lao tới cắn; không mặc định mọi đòn hoặc mọi loài đều dùng thời gian này.
- Sau đòn có khoảng nghỉ để phản công; ví dụ nghỉ 5 giây sau đòn lao cắn. Phân biệt khoảng nghỉ này với trạng thái choáng/gục do đánh bộ phận ở mục 19.
- Né thông thường là lộn theo hướng di chuyển cuối cùng.
- Riêng cung, khi đang ngắm, né là lướt nhanh theo hướng di chuyển cuối cùng. Người dùng gọi là backstep nhưng mô tả cho phép lướt theo hướng, không mặc định chỉ lùi ra sau.
- Khi vừa giữ ngắm vừa lướt, **chỉ đòn tấn công đầu tiên của cung sau lướt** được tăng sát thương.
- Buff chỉ có một lượt sử dụng, không cộng dồn sát thương hoặc số lượt bắn. Hết thời gian thì mất; bắn phát đầu tiên thì tiêu thụ buff.
- Lướt hợp lệ thêm khi buff còn tồn tại chỉ **làm mới thời gian hiệu lực**, không cộng thêm thời gian vào thời lượng còn lại và không tăng mức buff. Giá trị thời lượng chưa chốt.
- Các trường hợp né còn lại dùng lộn. Ngắm/lướt/buff cung không phụ thuộc Shift Lock mặc định; điều kiện tương đương cho Ctrl và điện thoại còn cần làm rõ ở mục 17.
- Chưa chốt khoảng cách, thời lượng né, có thời gian miễn sát thương hay không, mức tăng sát thương và thời gian hiệu lực của đòn cung sau lướt.

### Hai trạng thái vũ khí — đã thống nhất

| Trạng thái | Hành vi |
| --- | --- |
| Rút vũ khí | Sẵn sàng chiến đấu; không chạy nước rút; muốn chạy nhanh phải trở về trạng thái cất |
| Cất vũ khí | Có thể giữ Shift để chạy nhanh; được dùng vật phẩm tiêu dùng và tương tác vật phẩm trên bản đồ/vật phẩm mang theo |

- Chỉ trạng thái cất vũ khí mới dùng vật phẩm tiêu dùng và thực hiện các tương tác vật phẩm nói trên.
- Đổi qua lại giữa hai trạng thái có độ trễ theo hoạt ảnh: lấy cung từ lưng, rút katana khỏi vỏ, cất vũ khí tương ứng.
- Người dùng đã nêu **cất vũ khí mất 1 giây** khi tính khoảng xử lý bắt giữ ở mục 21; thời gian rút và ngoại lệ theo từng loại vũ khí chưa được nêu riêng.
- Giữ Shift khi đang rút vũ khí tự yêu cầu cất; phải hoàn thành độ trễ/hoạt ảnh cất rồi mới chạy nhanh. Không bỏ qua hoạt ảnh để chạy ngay.
- Chưa chốt có né khi cất được không, có ngắt hoạt ảnh rút/cất hay dùng vật phẩm không, và đổi trạng thái trong lúc đang ra đòn xử lý thế nào.
- Đặt bẫy và dùng thuốc ngủ ở mục 21 tuân theo quy tắc dùng vật phẩm khi đã cất vũ khí; chưa có ngoại lệ được yêu cầu. Cần chốt có tự cất khi chọn dùng vật phẩm hay phải cất trước.

### Thể lực — đã thống nhất

- Dùng thể lực cho tấn công bằng vũ khí, né, chạy nhanh khi giữ Shift và đỡ bằng khiên.
- Chạy nhanh vừa dùng để di chuyển vừa là cách thoát đòn khủng long, nhưng vẫn tuân theo điều kiện trạng thái cất vũ khí.
- Khi cất vũ khí, thể lực hồi khi đã ngừng các hành động tấn công/chạy nhanh. Không mặc định hồi trong lúc đang chạy nhanh.
- Khi rút vũ khí, thể lực hồi sau khi dừng tấn công và né; không bắt buộc cất mới được hồi.
- Quy tắc hồi trong lúc giữ khiên/đỡ đòn và độ trễ trước khi bắt đầu hồi còn cần chốt.
- Chưa chốt thể lực tối đa, chi phí từng động tác, tốc độ/độ trễ hồi và hành vi khi không đủ thể lực.

### Góp ý để thảo luận

- Ánh xạ thêm phím đánh thường/đánh mạnh/kỹ năng/đỡ/né/rút cất chủ động, giữ nguyên Shift/Ctrl/chuột phải đã chốt.
- Hoạt ảnh, âm thanh và sát thương quái cần khớp với ba phần báo đòn → tấn công → nghỉ sau đòn đã thống nhất.
- Kiểm tra tình huống cạn thể lực vẫn có đường thoát, tránh người chơi bị kẹt trong chuỗi đòn không thể phản ứng.
- Cảm giác búa/rìu có lực nên đến từ hoạt ảnh, âm thanh, phản ứng trúng đòn và nhịp dừng ngắn phù hợp; cần thử để giữ được tính mượt mà mong muốn.
- Hệ thống trang bị khởi đầu cần tránh cấp lặp mỗi lần đăng nhập; chi tiết lưu và cấp phát sẽ xử lý khi triển khai.

### Việc cần làm rõ trước khi lập trình phần này

- Phím đỡ cho kiếm/khiên còn mở; P1 búa đã có Space né, E kỹ năng và xử lý giữ/thả Shift khi đang đánh/cất tại 24.10.
- Búa đã được chọn cho P1 và có phím/đòn/combo/chỉ số tại mục 23–24; việc tiếp theo khi triển khai là kiểm chứng cấu hình này, không chọn lại vũ khí. Các vũ khí còn lại giữ trong lộ trình.
- Thể lực P1 đã có cấu hình ở mục 23; đỡ thiếu thể lực và hồi khi giữ khiên cần thiết kế trước khi thêm kiếm/khiên.
- Điều kiện ngắm cung giữa chuột phải, chế độ ghim tâm Ctrl và điện thoại; buff có mất khi cất/đổi vũ khí hoặc ngừng ngắm không.
- Búa P1 dùng chốt hướng/đi chậm/không hủy động tác tại 24.10; các vũ khí khác sẽ thiết kế riêng.

## 19. Làm rõ từng phần — Nghỉ sau đòn, bộ phận và choáng/gục của boss

**Trạng thái:** thiết kế bộ phận cho toàn game đã được ghi nhận; P1 v0.21 chỉ có một đòn cắn và máu tổng, chưa làm gục đầu/chân/đuôi. Các số bên dưới là ví dụ hoặc cấu hình mở rộng, không phải yêu cầu hoàn thành P1.

### Nhịp tấn công — đã thống nhất

- Đòn boss có ba phần: báo trước → thực hiện đòn → nghỉ/hồi sau đòn để người chơi phản công.
- Ví dụ đòn lao cắn: há miệng khoảng 1–2 giây, lao cắn, sau đó có thể nghỉ khoảng 5 giây.
- Trong khoảng nghỉ, người chơi có thể tấn công liên tục trong giới hạn hành động/thể lực của mình.
- Chưa chốt mọi đòn có khoảng nghỉ bao lâu, boss có di chuyển/phòng thủ trong khoảng nghỉ không, và thời gian hồi chiêu từng kỹ năng khác thời gian nghỉ thế nào.

### Tấn công bộ phận — đã thống nhất

- Boss có các vùng riêng, ví dụ đầu, chân trái, chân phải, cánh, đuôi; danh sách tùy hình thể loài.
- Tích đủ sát thương vào từng bộ phận có thể kích hoạt phản ứng của quái.
- **Đầu:** gây choáng đứng.
- **Chân:** gây gục nằm.
- Trong lúc choáng/gục, người chơi có cơ hội tiếp tục tấn công; sau đó boss phục hồi và chiến đấu tiếp.
- Thời gian mất khả năng hành động tăng theo số lần kích hoạt: ví dụ lần đầu 1 giây, lần hai 2–3 giây, các lần sau lâu hơn. Chưa có công thức hoặc mức trần.
- Phản ứng cụ thể khi đánh cánh chưa được thiết kế.
- Chưa chốt số lần tăng thời gian tính chung toàn boss hay riêng đầu/chân/từng bộ phận; không tự coi hai trường hợp là tương đương.

### Đuôi và nguyên liệu — yêu cầu cùng các phương án chưa chọn

- Đánh vào đuôi có thể làm đuôi rụng; người chơi nhặt làm nguyên liệu nâng cấp vũ khí.
- Người dùng đưa **hai phương án thay thế**, chưa chọn cách cuối:
  - Theo xác suất khoảng **2–30%**. Giữ nguyên số người dùng viết; chưa rõ xác suất tính mỗi đòn trúng hay mỗi lần đạt ngưỡng bộ phận.
  - Sau khoảng **2–3 lần đạt ngưỡng/gây gục do đánh đuôi** thì rụng.
- Chưa chốt phản ứng của đuôi trước khi rụng, mức sát thương yêu cầu, loại vũ khí có thể làm rụng, cách chia phần nhặt cho đội và đòn quét đuôi thay đổi sau khi mất đuôi.
- Điều kiện cất vũ khí để nhặt vật phẩm trong mục 18 vẫn áp dụng, trừ khi người dùng thay đổi sau.
- Đuôi đã nhặt được giữ kể cả khi thất bại theo mục 20; ngưỡng 10% có giới hạn quyền nhặt trước đó không vẫn cần chốt, không tự tước vật phẩm đã nhặt khi thua.

### Đề xuất cân bằng — chưa tự áp dụng

- Giữ **máu tổng** và **tiến độ tác động từng bộ phận** thành hai giá trị riêng. Một đòn giảm máu tổng một lần đồng thời ghi nhận tiến độ vào đúng bộ phận, tránh vô tình trừ hai lần sát thương vào máu tổng.
- Thời gian choáng/gục có thể tăng như người dùng muốn nhưng nên có mức trần. Sau mỗi lần, có thể tăng ngưỡng gây gục hoặc có khoảng chống gục lại ngắn khi đứng dậy, tránh boss bị giữ nằm liên tục đến chết.
- Cần quyết định cách ghi nhận sát thương bộ phận khi boss đang gục: vẫn trừ máu nhưng không tự kéo dài vô hạn trạng thái gục đang có.
- Với đuôi, có thể dùng ngưỡng tích lũy sát thương hoặc xác suất như các phương án đã nêu. Nếu chọn cùng xác suất cố định mỗi lần trúng, số lần trúng sẽ ảnh hưởng số cơ hội; cần xét cả đòn thường và toàn bộ combo đặc biệt của từng vũ khí. Chưa biết số hit/hiệu ứng combo búa nên không kết luận song dao có lợi hơn về rụng đuôi hoặc chiến đấu tổng thể. Phương án cuối chưa chốt.
- Mỗi boss chỉ cho rụng đuôi và tạo phần thưởng đuôi một lần; cách chia cá nhân cho đội bàn riêng để tránh tranh nhặt. Đây là đề xuất, chưa chốt.
- Cân bằng thời gian nghỉ sau đòn cùng thời gian choáng/gục và sát thương đội bốn người; tránh boss mất gần hết thời gian chiến đấu vì liên tục bị khống chế.

Phương án số của v0.20 được giữ để tham khảo **sau P1**, chưa bật trong bản đầu:

- Đầu tích 250 gây choáng đứng, chân tích 300 gây gục; lần lượt 1 → 2 → 3 giây, trần 3, đếm riêng đầu/chân; mỗi lần ngưỡng tăng 25%.
- Trong choáng/gục và 2 giây sau đứng dậy không tích tiến độ gục mới, vẫn nhận sát thương máu.
- Lao cắn: báo 1,5 giây, gây 30, nghỉ 5 giây. Quét đuôi: báo 1,2 giây, gây 22, nghỉ 2 giây. Cần cân bằng lại khi thêm, không coi số này đã được chơi thử.

### Việc cần làm rõ khi triển khai cơ chế này

- Chọn phương án rụng đuôi; nếu dùng xác suất, chốt sự kiện được quay xác suất.
- Ngưỡng từng bộ phận và ảnh hưởng số người; sát thương pet/quái khác có góp vào ngưỡng không.
- Quy tắc tăng và giới hạn thời gian choáng/gục, ngắt hoặc nối tiếp trạng thái khi nhiều bộ phận đồng thời đủ ngưỡng.
- Điều kiện bắt hiện là còn sống, máu ≤10%, trúng Iron Trap và được cho uống thuốc ngủ ở mục 21. Choáng/gục do bộ phận không tự thay thế điều kiện trúng bẫy.

## 20. Làm rõ từng phần — Nhiệm vụ, thắng/thua và giữ chiến lợi phẩm

**Trạng thái:** phần nhiệm vụ đã được ghi nhận. Không tự lấp các điểm chưa chốt bằng quy tắc của MHW; lựa chọn dùng thử được tách ở mục 23.

### Nhiệm vụ và bản đồ — đã thống nhất

- Trước khi vào map, chọn ở bảng nhiệm vụ; mục tiêu chính là một loài khủng long. Có nhiệm vụ săn thông thường và nhiệm vụ yêu cầu bắt sống.
- Map có **ba con khủng long** để người chơi tự do săn; chưa xác định chúng nhất thiết thuộc ba loài khác nhau hoặc có hồi sinh/thay thế không.
- **Nhiệm vụ săn thông thường:** tiêu diệt hoặc bắt thành công mục tiêu chính đều thắng. Săn con khác không tự thay thế mục tiêu chính; hết bẫy vẫn có thể tiếp tục tiêu diệt mục tiêu.
- **Nhiệm vụ bắt sống:** phải bắt được mục tiêu chính. Hết khả năng bắt theo giới hạn vật dụng là điều kiện thất bại người dùng nêu; xử lý khi đội còn vật dụng và khi lỡ giết mục tiêu xem mục 21.
- Thời gian cho một nhiệm vụ dự kiến **khoảng 40 phút**; chưa chốt chính xác thời điểm bắt đầu đếm hoặc cách xử lý hết giờ.

### Giới hạn tử vong và hồi sinh — đã thống nhất

- Solo được tiếp tục sau ba lần tử vong đầu tiên; **lần tử vong thứ tư thì thất bại**.
- Khi đi đội, tổng tử vong tính **chung cả đội**, không phải riêng từng người và không tăng theo số thành viên.
- Ba lần tử vong đầu: thành viên vừa chết hồi sinh ở điểm bắt đầu map, cuộc săn tiếp tục.
- Lần thứ tư: báo nhiệm vụ thất bại, **cả đội quay về sảnh**; không bắt đầu thêm một lượt chiến đấu sau lần hồi sinh thứ tư.
- Ví dụ A chết hai lần, B chết một lần: tổng ba, nhiệm vụ vẫn tiếp tục. Bất kỳ ai chết thêm một lần: tổng bốn, cả đội thất bại.
- Không gọi quy tắc này là “chết ba lần thua” hoặc “ba mạng tính cả mạng ban đầu”.
- Chưa thiết kế cứu người trước khi chết; không mặc định cơ chế cứu đã có hoặc bị cấm.

### Sau thành công và quay về — đã thống nhất

- Hoàn thành mục tiêu chính **đúng điều kiện loại nhiệm vụ** sẽ mở **2 phút (120 giây)** để thu hoạch/mổ xác/nhặt đồ trước khi rời map. Tiêu diệt không được tính thắng nhiệm vụ bắt sống.
- Hết 2 phút tự động quay về sảnh; có lựa chọn quay về sớm.
- Chưa chốt lựa chọn về sớm áp dụng riêng người chọn hay cả đội; không tự cho trưởng đội đưa mọi người về.
- Thất bại do lần tử vong thứ tư: báo thất bại và về sảnh; khoảng thu hoạch 2 phút được quy định cho thành công, chưa có yêu cầu áp dụng cho thất bại.
- Vật phẩm đã nhặt vẫn được giữ theo quy tắc bên dưới.

### Vật phẩm đã nhặt — đã thống nhất

- Trong lúc chiến đấu có xác suất rơi vảy; đuôi có thể rụng theo cơ chế sẽ chốt ở mục 19.
- Map có quặng xuất hiện để người chơi đào lấy vật phẩm; vị trí, số lượng và tái xuất hiện chưa chốt.
- **Toàn bộ vật phẩm đã nhặt được mang về dù nhiệm vụ thắng hay thua**, gồm vảy, đuôi, quặng và đồ đã thu vào túi khác.
- Quy tắc này bảo toàn đồ đã nhặt; chưa quy định tự thu gom những món còn nằm dưới đất lúc kết thúc.
- Không đồng nhất đồ đã nhặt với gói thưởng hoàn thành chưa nhận; phần thưởng thất bại và thành công cần trình bày rõ.

### Tiêu diệt và mổ xác — đã thống nhất

- Khi tiêu diệt thành công, người chơi được mổ xác để lấy nguyên liệu.
- Giới hạn mổ là **3, 4 hoặc 5 lần**, tùy loại thường/có hệ/biến dị. Người dùng chưa chỉ định rõ bảng ghép nhóm với số lượt; không tự khóa thường = 3, có hệ = 4, biến dị = 5.
- Mỗi lượt mổ nhận **1 đơn vị** của nguyên liệu được chọn theo bảng rơi. Loại vật phẩm có thể trùng; ví dụ hai lượt cùng ra da thì tổng là 2 da.
- Chưa chốt số lần mổ là riêng mỗi người hay chung xác, giới hạn thời gian mổ, và điều kiện 10% để được mổ.

### Bắt giữ và lượt thưởng tương đương — đã thống nhất

- Bắt thành công nhận nguyên liệu qua **số lượt tương đương giới hạn mổ của loại quái đó**: 3/4/5 lượt; không mổ xác con còn sống.
- Số lượng cơ bản mỗi lượt là **1**. Theo cơ chế tăng lượng khi bắt đã nêu: **50% nhận 1, 50% nhận 2**, xét riêng từng lượt.
- Ví dụ bốn lượt cơ bản là 1 răng, 1 da, 1 da, 1 vảy; khi bắt có thể nhận 2 răng, 1 da, 2 da, 1 vảy, hoặc may mắn cả bốn lượt đều được 2.
- Không dùng một kết quả 50/50 cho toàn bộ gói và không tăng thêm số lượt khi lượng một lượt được tăng.
- Đây là cơ chế tăng lượng của thưởng bắt, không cộng chồng một gói “thưởng bắt thêm” chưa được định nghĩa. Phần thưởng hoàn thành bổ sung như xương ở mục 6 vẫn là phần riêng cần bảng cụ thể.
- Quy tắc lượng gốc 1 áp dụng nguyên liệu từ khủng long; xác suất rơi loại hiếm khác xác suất tăng lượng. Không tự mở rộng sang quặng hoặc gói thưởng nhiệm vụ bổ sung chưa thiết kế.
- “May mắn” đang chỉ kết quả ngẫu nhiên; chưa có yêu cầu thêm chỉ số Luck hay trang bị tăng xác suất.
- Quy tắc nhận cá thể cho mỗi người đủ điều kiện khi bắt vẫn giữ nguyên. Chưa chốt cá thể bắt từ quái phụ được giữ thế nào nếu sau đó nhiệm vụ chính thất bại.

### Góp ý để thảo luận

- Hiển thị rõ tổng tử vong **của cả đội**, mốc thất bại là lần thứ tư, thời gian nhiệm vụ và mục tiêu chính; tránh người chơi hiểu thành giới hạn riêng mỗi người.
- Sau thắng, hiển thị đếm ngược 2 phút và lựa chọn về sớm để người chơi biết thời gian còn lại cho thu hoạch.
- Bảng kết quả phân biệt đồ đã thu trong map, nguyên liệu mổ/thưởng bắt và thưởng hoàn thành; tránh tạo cảm giác mất đồ khi nhiệm vụ thất bại.
- Hết thời gian mà chưa hoàn thành mục tiêu thì thất bại là phương án đề xuất, cần người dùng xác nhận.

### Còn cần chốt

- Xử lý hết 40 phút và thứ tự khi thắng/chết/hết giờ xảy ra gần đồng thời; đã chốt mốc thất bại do tử vong ở lần thứ tư.
- Trong 2 phút sau thắng có tiếp tục săn quái phụ được không; tử vong còn tính hay có thể đảo kết quả thành công không; đồng hồ nhiệm vụ 40 phút có còn tác động không.
- Lựa chọn về sớm áp dụng riêng từng người hay cả đội; giữ thưởng và số lượt mổ còn lại khi chọn về sớm thế nào.
- Phần thưởng quái phụ, mổ xác trước khi nhiệm vụ chính kết thúc, giữ cá thể bắt phụ khi thua và cách áp dụng đóng góp 10% theo từng con.
- Số lượt mổ/thưởng bắt cụ thể theo nhóm; bảng nguyên liệu, quyền nhặt/mổ theo người và điều kiện nhận thưởng bổ sung.
- Xử lý rời nhiệm vụ chủ động/mất kết nối; chưa mặc định giống thắng hoặc thua thông thường.

## 21. Làm rõ từng phần — Thương nhân, chế bẫy và bắt sống

**Trạng thái:** phần bắt giữ đã được ghi nhận; chưa lập trình. Các thông số thiếu vẫn để mở cho toàn game, cấu hình thử ở mục 23.

### Thương nhân và chế tạo — đã thống nhất

- Có thương nhân bán hàng, ví dụ bình hồi máu và vật dụng tên **Trap**.
- Mua Trap, kết hợp quặng sắt nhặt/đào được để chế **Iron Trap**, là bẫy dùng bắt khủng long.
- Phân biệt Trap mua làm thành phần chế tạo với Iron Trap đã hoàn thiện; chưa chốt tên hiển thị tiếng Việt.
- Công thức định tính: **Trap + quặng sắt → Iron Trap**; chưa chốt số lượng nguyên liệu, giá tiền, nơi/thời gian chế.
- Thuốc ngủ/bình ru ngủ là vật dụng bắt riêng; nguồn mua/chế và công thức chưa được người dùng chỉ định.
- Chưa mở rộng thiết kế các vật phẩm tiêu dùng khác ngoài thông tin đã nêu.

### Quy trình bắt — đã thống nhất

1. Vào chiến đấu và đánh mục tiêu đến khi **còn sống, máu ≤10%**. Chưa quyết định hiển thị con số máu cho người chơi.
2. Dấu hiệu nhận biết: khủng long đi chậm, kéo lê/khập khiễng một chân.
3. Người chơi đặt **Iron Trap** và dẫn đúng con muốn bắt vào bẫy.
4. Trúng bẫy, khủng long bị choáng **13 giây**, gầm gừ/rên nhẹ và **cúi đầu xuống** để người chơi tiếp cận miệng.
5. Người chơi dùng **thuốc ngủ, đổ vào miệng** qua thao tác/hoạt ảnh; đây không phải tự bắt ngay khi chạm bẫy hoặc ném thuốc từ xa. Khi bắt đầu cho uống, **pet của người thực hiện tạm dừng tấn công mục tiêu**.
6. Hoàn tất bắt thì xử lý cá thể sở hữu và nguyên liệu theo mục 6/20; số liều và điều kiện hoàn tất thao tác cần chốt.

Đặt bẫy/cho uống là dùng vật phẩm nên tuân theo trạng thái cất vũ khí ở mục 18. Mức máu đủ bắt không thay thế bước bẫy và thuốc; gục do bộ phận cũng không tự thay thế bẫy.

### Thời gian xử lý và pet — đã thống nhất

- Thời gian choáng/giữ mục tiêu của Iron Trap là **13 giây tính từ lúc quái trúng bẫy**, không phải thời gian bẫy nằm trên đất chờ quái.
- Trong trạng thái này, quái cúi đầu và gầm gừ/rên nhẹ. Chưa chốt tín hiệu riêng báo sắp hết thời gian, không tự thêm đồng hồ hiển thị.
- Người dùng dành khoảng **1 giây cất vũ khí + khoảng 2 giây chạy đến đầu**, còn khoảng 10 giây để thao tác và xử lý tình huống. Hai giây di chuyển là ước lượng tùy khoảng cách, không phải hoạt ảnh kéo người chơi tới đầu.
- Thời gian cho uống cụ thể chưa chốt; 10 giây còn lại không mặc định là thời gian bắt buộc giữ nút.
- Pet của người cho uống tạm dừng đánh đúng mục tiêu từ lúc chủ bắt đầu thao tác; không mặc định toàn bộ pet/người chơi trong đội tự ngừng tấn công.
- Chưa chốt lúc pet đánh lại nếu thao tác bị ngắt hoặc bẫy hết hiệu lực; bắt thành công thì không còn tấn công cá thể đã bắt.

### Giới hạn và thất bại — đã thống nhất về nguyên tắc

- Giới hạn **mỗi người**, xác định theo số thành viên đội khi vào map:

| Số người | Iron Trap mỗi người | Bình ru ngủ mỗi người | Tổng bẫy / tổng bình tối đa của đội |
| --- | --- | --- | --- |
| 1 (solo) | 3 | 3 | 3 / 3 |
| 2 | 2 | 2 | 4 / 4 |
| 3 | 1 | 1 | 3 / 3 |
| 4 | 1 | 1 | 4 / 4 |

- Mang dư thì hệ thống tự giảm số lượng được mang vào map về hạn mức và **trả toàn bộ phần dư về kho trước khi vào map**. Phần dư không bị xóa hoặc tiêu hao.
- Xong trận người chơi **trang bị/chuẩn bị lại vật dụng cho lượt sau**. Không có yêu cầu tự cấp miễn phí số đã dùng hoặc tháo toàn bộ vũ khí/giáp.
- Dùng hết số Iron Trap được mang thì người đó không còn bẫy để tiếp tục bắt; solo thất bại ba bẫy là hết bẫy. Chưa có cơ chế hoàn trả/tái sử dụng bẫy được chốt.
- Giới hạn cơ hội đến từ lượng vật dụng mang theo; không thêm bộ đếm thất bại độc lập ngoài lượng vật dụng.
- Với nhiệm vụ săn thông thường, hết bẫy hoặc bắt thất bại không tự kết thúc nhiệm vụ; có thể tiếp tục săn/tiêu diệt. Giới hạn tử vong và thời gian vẫn áp dụng.
- Với nhiệm vụ bắt sống, mất hết khả năng bắt là lý do thất bại theo yêu cầu người dùng. Chưa chốt thời điểm báo thua nếu chỉ một người hết bẫy trong khi đồng đội còn bẫy/thuốc.
- Chưa chốt lúc trừ bẫy/thuốc, thời gian bẫy đặt trên đất chờ mục tiêu, bẫy đặt hụt có thu lại được không, và một lần bắt cần bao nhiêu bình. Thời gian giữ quái sau khi kích hoạt đã chốt là 13 giây.

### Góp ý để thảo luận

- Có thể đánh dấu vị trí tương tác ở miệng và dùng thay đổi âm thanh/hoạt ảnh khi gần hết 13 giây để dễ đọc tình huống; đây là góp ý chưa chốt, không mặc định thêm thanh đếm ngược.
- Quái bay/dưới nước cần dấu hiệu suy yếu và tư thế trúng bẫy phù hợp hình thể; thiết kế đi khập khiễng/cúi đầu hiện phù hợp bản thử quái đi bộ.
- Tránh cho chế thêm hoặc tiếp tế trong map vượt giới hạn cơ hội bắt đã định; cần chốt quy tắc mang Trap thô/quặng, chế tại map và quay trại trước khi triển khai.
- Nhiệm vụ bắt sống nên báo thất bại nếu mục tiêu bị giết; đây là đề xuất xử lý kết thúc, còn yêu cầu đã chắc chắn là giết không được tính thắng.
- Hạn mức cá nhân đã chốt; đề xuất nhiệm vụ bắt sống không thua chỉ vì một người hết khi đồng đội vẫn có thể bắt. Cách kết luận thất bại toàn đội chưa chốt.
- Đề xuất hiển thị số vật dụng được mang và số đã trả kho trước khi vào map. Việc trả phần dư về kho đã chốt, chỉ cách thông báo còn là đề xuất.

### Cần làm rõ trước khi triển khai

- Có được đặt bẫy giúp và cho uống giúp nhau không; cách xử lý vật dụng chưa dùng sau trận và việc vào/rời đội có làm đổi hạn mức không. Phần vượt hạn mức trước khi vào map đã chốt trả kho.
- Thời gian đặt bẫy và cho uống; điều kiện ngắt, tiêu hao khi thất bại và lúc pet trở lại chiến đấu. Thời gian giữ quái đã chốt là 13 giây.
- Điều gì được tính bẫy thất bại: hết thời gian, quái thoát, sai con đi vào, máu chưa đủ thấp hoặc thao tác thuốc bị ngắt.
- Quái trên 10% máu có bị bẫy giữ tạm thời không; có thể dùng thuốc sớm không; nếu quái hồi máu thì kiểm tra điều kiện lúc nào.
- Nguồn thuốc ngủ, số liều, giá/công thức và giới hạn tiếp tế/chế trong cuộc săn.
- Cách kết thúc nhiệm vụ bắt sống khi hết vật dụng hoặc mục tiêu chết, trong khi bảo toàn đồ đã nhặt theo quy tắc chung.

## 22. Làm rõ từng phần — Chiến đấu và hồi phục của pet

**Trạng thái:** phần pet đã được ghi nhận. Hai chế độ chính là chiến đấu và hồi cho chủ; rút lui, tự hồi, choáng là tình trạng bên trong. Cấu hình pet bản thử ở mục 23.

### Chế độ chiến đấu — đã thống nhất về hành vi

- Pet lao vào tham gia nhưng **không tấn công liên tục**; có nhịp hành động như một đồng hành chiến đấu.
- Cầm vũ khí do người chơi chế tạo hoặc trang bị; sát thương dựa trên chỉ số vũ khí. Chưa chốt công thức và hệ số riêng của pet.
- Có thể đỡ đòn, thu hút sự chú ý của khủng long và né các đòn cơ bản. Chưa chốt tần suất, điều kiện, khả năng đỡ theo vũ khí hoặc cách quái chọn mục tiêu.
- Pet có máu riêng. Khi gần hết máu, có thể tự chạy ra vùng an toàn để hồi cho bản thân; ngưỡng rút, vùng an toàn, lượng hồi và thời gian tự hồi chưa chốt.
- Sát thương pet vẫn cộng vào đóng góp của chủ cho ngưỡng 10%; đỡ, né và hồi không được quy thành sát thương.

### Khi pet còn 1 máu — đã thống nhất

- Khi máu xuống **1**, pet bị choáng **30 giây**, không cử động và không chết.
- Không tiếp tục chiến đấu hoặc di chuyển về chủ trong lúc bất động.
- Hết 30 giây, pet **hồi đầy máu** rồi tái giao tranh.
- Trong lúc choáng, nút gọi hồi báo **“Pet đang hồi phục”** cùng thời gian choáng còn lại; không thể gọi pet thực hiện hồi trong lúc bất động.
- Hồi đầy sau choáng **không làm mới hồi chiêu kỹ năng hồi cho chủ**. Theo dõi riêng thời gian choáng và hồi chiêu kỹ năng.
- Pet không chết nên lần choáng này không phải một lần tử vong của người chơi trong bộ đếm thất bại chung.
- Cần triển khai để đòn sát thương lớn không vượt qua mốc 1 và làm chết pet trái thiết kế. Chưa chốt phản ứng khi tiếp tục bị đánh trong lúc choáng; không tự cho kéo dài/reset 30 giây.

### Chế độ hồi máu cho chủ — đã thống nhất và thông số đề xuất

- Có **nút gọi pet về hồi máu**. Đây là kích hoạt chủ động; thay mô tả cũ tự hồi khi chủ yếu máu.
- Màn hình hiển thị thời gian hồi chiêu của lần hồi cho chủ.
- Người dùng đề xuất khoảng **1 phút 59 giây = 119 giây** cho mỗi lần; ghi là mốc thử, chưa khóa thành thông số cuối.
- Lượng hồi cho chủ là **70% tổng máu tối đa**, không phải 70% máu đang thiếu. Các chỉ số cụ thể sẽ thống kê/cân bằng lúc làm game.
- Khi nhận lệnh, pet mang một **viên thuốc rất lớn**, chạy/lao tới chủ và ném thuốc vào miệng. Về hình ảnh, chỉ cần ném tới vùng đầu người chơi, không cần hoạt ảnh miệng chi tiết.
- Chưa chốt thời gian chạy/ném, thời điểm cộng máu, hồi một lần hay theo thời gian, phạm vi, ngắt khi bị tấn công và lúc bắt đầu đếm hồi chiêu.
- Tự hồi của pet, hồi đầy sau choáng và kỹ năng hồi cho chủ là ba cơ chế khác nhau; không tự dùng chung hồi chiêu hoặc lượng hồi.

### Liên hệ với bắt giữ — giữ nguyên quyết định trước

- Khi chủ bắt đầu cho mục tiêu uống thuốc ngủ, pet của chủ tạm ngừng đánh mục tiêu đó.
- Chưa chốt có nhận lệnh gọi hồi trong lúc chủ đang cho uống không, hoặc phải chờ hoàn thành/hủy thao tác; không tự ngắt việc bắt của người chơi.
- Pet khác trong đội chưa có quy tắc tự ngừng theo chủ đang bắt.

### Góp ý để thảo luận

- Đề xuất giới hạn máu sau hồi ở máu tối đa, không tạo máu vượt trần; ví dụ tối đa 100, đang 20 thì hồi thêm 70 thành 90, đang 60 thì hồi tới 100.
- Thu hút chú ý nên có thời lượng/giới hạn, không mặc định pet giữ mục tiêu mãi khiến chủ không cần né/đỡ.
- Kiểm tra khả năng hồi khi pet đang tự rút lui: cần chọn ưu tiên rõ giữa tự bảo toàn và lệnh chủ; không tự quyết trước khi người dùng làm rõ.

### Còn cần chốt

- Xác nhận mốc hồi chiêu 119 giây; thời gian gọi về/ném, thời điểm cộng 70% máu tối đa và lúc bắt đầu hồi chiêu.
- Ngưỡng pet tự rút, lượng/tốc độ tự hồi, điều kiện quay lại và hành vi nếu không tìm được chỗ an toàn.
- Ưu tiên lệnh gọi khi pet đang đánh, đỡ, né, tự hồi hoặc bị choáng; có xếp lệnh chờ hay yêu cầu gọi lại không.
- Quái có tiếp tục chọn pet đang choáng không; sát thương nhận khi choáng có tác động tới đồng hồ hay không.
- Trang bị pet ảnh hưởng máu/phòng thủ/khả năng hồi thế nào; chỉ sát thương theo vũ khí đã được nêu.

## 23. Thiết kế bản thử đầu tiên — cấu hình thử P1

**Thứ tự mới ngày 28/09:** hoàn thiện và chơi thử sảnh/luyện tập L0 ở mục 25 trước. Nội dung P1 dưới đây là bước nối tiếp; những phần búa/điều khiển/pet đã làm ở L0 được tái sử dụng sau khi kiểm chứng.

### Mục tiêu, hai mốc kiểm tra và phạm vi

**Yêu cầu giai đoạn:** dừng mở rộng hệ thống lớn, làm một bản nhỏ để kiểm chứng săn/bắt và cảm giác chiến đấu. **Mọi lựa chọn rút gọn/thông số mới dưới đây là đề xuất cấu hình thử của trợ lý**, chưa phải quyết định cuối toàn game.

- **P1 tối thiểu — xong P1-0 đến P1-D:** trên PC có thể điều khiển, đánh/né, dùng pet và tiêu diệt/bắt một quái. Chỉ là mốc kiểm chứng chiến đấu/bắt; chưa có đủ tiến trình kinh tế, trưng bày và lưu qua lần thoát.
- **P1 đầy đủ — xong P1-0 đến P1-G:** thêm thưởng, nâng búa, cá thể, kho, một ống và lưu tài khoản đã kiểm tra. Chỉ mốc này mới được gọi là hoàn thành P1.
- **Hai nền tảng:** game đầy đủ vẫn phải chơi được trên PC và điện thoại. Cấu hình P1 hiện đề xuất chỉ bắt buộc chuột/bàn phím; cảm ứng hoàn chỉnh để mốc tiếp theo. Thiết kế hành động độc lập với phím để sau đó gắn nút điện thoại; phải thử lại UI/camera/nhắm/né khi thêm cảm ứng.

| Phần | Làm trong P1 đầy đủ | Để sau P1 |
| --- | --- | --- |
| Người chơi | Solo trên PC | Săn đội 2–4 người, kiểm tra đóng góp 10%, điện thoại hoàn chỉnh |
| Vũ khí | Một búa, ba dạng đòn, combo ngắn N → H → K kết thúc, một cấp nâng | Chuỗi búa dài, sáu loại còn lại, đỡ khiên và ngắm/lướt cung |
| Quái | Một loài đi bộ không hệ, tên tạm A, một đòn cắn có báo trước/nghỉ | Thêm đòn, đầu/chân gây gục, đuôi, ba quái/map, quái giao chiến, hệ/biến thể |
| Pet | Theo chủ, đánh theo chu kỳ, máu riêng/choáng 30 giây, gọi hồi 70% | Né/đỡ, chủ động thu hút quái, tự rút hồi, chế/trang bị pet |
| Nhiệm vụ | Săn thường: tiêu diệt HOẶC bắt mục tiêu đều thắng; trại, đồng hồ, tử vong và thu hoạch | Nhiệm vụ chỉ được bắt sống; bản đồ nhiều mục tiêu |
| Tiến trình/base | Kho, thương nhân, chế bẫy, một nâng cấp, một ống tự chọn, lưu | Năm ống, tham quan base, trưng bày vũ khí/giáp và kỷ lục hoàn chỉnh; sảnh 12 base làm trước ở L0 |
| Hình ảnh | Khối/hoạt ảnh đơn giản, đọc được báo đòn, hướng đánh, trúng đòn, khập khiễng/cúi đầu | Hiệu ứng và mô hình hoàn thiện |

Không xóa yêu cầu toàn game khi đưa chúng ra ngoài P1. Nhiệm vụ bắt sống, nhiều đòn và ngưỡng gục từng có trong cấu hình v0.20 nay là phương án sau P1; không bật âm thầm trong các bước đầu.

### Quy tắc nền tảng giữ nguyên

- Tắt Shift Lock mặc định; Shift chạy, Ctrl ghim tâm riêng, chuột phải giữ ngắm. Tự cất đủ 1 giây trước khi chạy; hướng tự do theo hướng di chuyển/hướng cuối khi đứng yên.
- Đánh/né/chạy tiêu hao thể lực. Dùng vật phẩm và tương tác vật phẩm khi đã cất vũ khí.
- Quái còn sống, máu ≤10% mới được bắt; đi khập khiễng. Iron Trap giữ 13 giây, cúi đầu; người đến miệng cho uống. Pet chủ dừng đánh từ lúc bắt đầu cho uống.
- Solo mang tối đa 3 bẫy + 3 bình; phần dư trả kho. Mỗi lượt chuẩn bị hành trang lại.
- Ba lần chết đầu hồi sinh; lần thứ tư thất bại. Giữ đồ đã nhặt khi thua. Thành công có 120 giây thu hoạch hoặc chọn về sớm.
- Nguyên liệu quái gốc 1/lượt; bắt quay độc lập 50% lượng 1 hoặc 50% lượng 2 mỗi lượt.
- Pet hồi 70% máu tối đa; còn 1 máu thì bất động 30 giây rồi đầy máu. Hồi đầy không làm mới hồi chiêu kỹ năng; nút báo “Pet đang hồi phục”.

### Một lượt chơi khi P1 đầy đủ

1. Vào base, tải hồ sơ và nhận đồ đầu một lần; chọn búa, xem kho/pet.
2. Mua Trap/thuốc, lấy sắt trong lượt săn nếu cần, chế Iron Trap ở base; chọn đồ mang. Không cần bẫy để vào săn thường.
3. Nhận nhiệm vụ săn A tại bảng; kiểm tra hành trang và vào trại. Bắt đầu đồng hồ khi nhân vật sẵn sàng điều khiển.
4. Né đòn cắn, phản công bằng búa/combo, gọi pet hồi; tiêu diệt hoặc dẫn quái yếu vào bẫy rồi cho uống.
5. Ghi kết quả một lần: tiêu diệt mở ba lượt mổ; bắt nhận ba lượt nguyên liệu và một cá thể. Có gói thưởng nhiệm vụ riêng.
6. Thu hoạch 120 giây hoặc về sớm. Nếu thua, về với đồ đã nhặt. Đồ mang chưa dùng trả kho theo cấu hình thử.
7. Nâng búa/chọn cá thể vào ống; sau xác nhận lưu, thoát/vào vẫn có tiến trình.

### Bảng phím PC thử — dùng thống nhất, chưa phải cấu hình cuối

| Thao tác | Hành động |
| --- | --- |
| WASD / chuột | Di chuyển / camera |
| Chuột trái | Đánh thường N |
| R | Đánh mạnh H |
| E | Kỹ năng K; đúng chuỗi thì thành chiêu kết thúc |
| Space | Né lộn; chưa làm nhảy chiến đấu |
| X | Rút/cất búa chủ động |
| Giữ Shift / Ctrl / giữ chuột phải | Chạy / bật-tắt ghim tâm / ngắm theo hướng tâm |
| Q | Gọi pet hồi máu |
| F | Tương tác theo ngữ cảnh: NPC, quặng, mổ, đặt bẫy hoặc cho uống |
| Tab / 1–2 | Túi đồ / chọn bẫy hoặc thuốc, sau đó F để dùng |

Giữ bảng phím v0.20 để tránh đổi không cần thiết: E chỉ cho kỹ năng, F cho tương tác, Q gọi pet, R đánh mạnh, X rút/cất. Nếu đang giữ tương tác thì không nhận lệnh tương tác thứ hai. P1 không có cung; giữ chuột phải chỉ điều khiển hướng đánh búa, không thêm buff/lướt cung. Chưa yêu cầu dựng nút cảm ứng trong P1.

### Búa và combo ngắn dùng thử

P1-A làm từng đòn độc lập trước, rồi mới nối **N → H → K**. Khi đúng hai bước N → H, lần K tiếp theo chính là chiêu kết thúc; ngoài chuỗi K là kỹ năng thường. Chuỗi dài **N → H → N → K → K** giữ làm phương án sau P1 theo ý tưởng tại mục 18.

| Hành động | Sát thương gốc | Thể lực | Tổng động tác |
| --- | ---: | ---: | ---: |
| N — vung ngang | 36 | 8 | 0,55 giây |
| H — bổ búa | 70 | 16 | 1,10 giây |
| K thường — hất búa | 50 | 12 | 0,70 giây |
| K kết thúc — nện đất | 140 | 20 | 1,20 giây |

- Nối đòn trong 1 giây từ lúc động tác trước hết; không bắt buộc trúng để tiến chuỗi, vẫn phải trúng để gây sát thương. Không nhận nút đòn mới khi đang trong động tác; chưa làm hàng đợi nút.
- Bấm sai thì thực hiện đòn độc lập hợp lệ và reset chuỗi; nếu nút đó là N thì bắt đầu lại từ N. Thiếu thể lực không ra đòn, không tiến chuỗi.
- Né, cất, chết, ngắt hành động hoặc quá thời gian nối thì reset. Bị trừ máu nhẹ không tự reset nếu không bị ngắt.
- P1 cho mỗi đòn chạy hết động tác trước khi né/đánh tiếp, chưa làm hủy thu đòn. Khóa hướng từ đầu pha gây sát thương. Phân chia pha/vùng trúng ở 24.10.
- Combo ngắn trúng đủ ba đòn: **246 sát thương, 44 thể lực, tối thiểu 2,85 giây** chưa tính khoảng nối. Đây là tổng lý thuyết, không phải tốc độ gây sát thương thực tế.
- Chưa có hồi chiêu riêng của K trong cấu hình thử; thời gian động tác, thể lực và chuỗi giới hạn việc lặp.

### Người chơi, quái và pet dùng thử

| Thành phần | Cấu hình P1 |
| --- | --- |
| Người chơi | 100 máu; giáp đầu cố định, sát thương quái dưới đây là lượng thực nhận |
| Thể lực | Tối đa 100; hồi 20/giây sau 0,75 giây không tiêu hao |
| Né / chạy | Né tốn 20, dài 0,55 giây, thử miễn sát thương 0,15 giây giữa động tác; chạy tốn 10/giây, cạn thì đi thường |
| Rút / cất | Rút thử 1 giây; cất 1 giây theo yêu cầu đã nêu |
| Quái A | 2.400 máu; đủ bắt khi 0 < máu ≤240; không tự hồi máu |
| Một đòn cắn | Báo 0,8 giây → cửa sổ gây 18 sát thương dài 0,30 giây → nghỉ 1,5 giây; mỗi đòn trúng mỗi nạn nhân tối đa một lần |
| Pet cơ bản | 100 máu; đánh 12 mỗi 4 giây trong tầm thử 6 studs; đồ cố định |
| Gọi pet hồi | Tới cách chủ khoảng 3 studs, ném thuốc trong 0,8 giây; hồi 70% máu tối đa, không vượt trần; hồi chiêu thử 119 giây từ khi máu được hồi |

Trong P1 quái nhận sát thương máu tổng, chưa có tích ngưỡng đầu/chân hoặc gục do bộ phận. P1-B chỉ làm một đòn cắn; các phương án quái đầy đủ tại mục 19 để sau. Pet làm ở P1-C theo thứ tự theo/đánh → máu/choáng → gọi hồi; P1-D nối ngừng đánh khi cho uống. Pet choáng không bị kéo dài/reset do đòn mới; chủ hồi sinh không làm mới hồi chiêu pet. Chi tiết tại 24.12.

### Bắt, kết thúc và tiến trình

- Công thức thử: 1 Trap + 1 sắt → 1 Iron Trap, chỉ chế ở base. Đặt 1 giây; xong mới trừ bẫy, không thu lại; chưa kích hoạt thì tồn tại 60 giây.
- **Giữ lựa chọn v0.20:** quái trên 10% vẫn có thể mắc bẫy 13 giây, nhưng không được cho uống/bắt. Đây là cấu hình thử, không lấy ví dụ “trên 10% không kích hoạt bẫy” trong ảnh làm thay đổi mặc định.
- Giữ tương tác 3 giây tại miệng để cho uống; hoàn tất khi quái vẫn sống/đủ ngưỡng/bẫy còn hiệu lực mới trừ một bình. Bị ngắt thì không trừ bình, đồng hồ bẫy vẫn chạy. Xem 24.4.
- P1 chỉ săn thường: hết bẫy/thuốc vẫn được tiếp tục tiêu diệt. Nhiệm vụ bắt sống và quy tắc hết khả năng bắt được giữ ở mục 21/24.4 cho mốc sau P1.
- Hết 40 phút chưa hoàn thành thì thua. Hoàn thành khóa kết quả và chuyển sang 120 giây thu hoạch; không đổi thành thua do chết sau đó. Thao tác kết thúc sau hạn không tính thành công; đúng hạn thì thử ưu tiên kết quả hợp lệ.
- Quái cho ba lượt mổ, mỗi lượt 1,5 giây và lượng gốc 1. Bắt cho ba lượt chọn loại rồi xét lượng 1/2 độc lập, không có xác để mổ.
- Loại nguyên liệu thử: da 50%, răng 25%, vảy 25% mỗi lượt; gói hoàn thành riêng là 1 xương thường + 40 xu. Thua không có gói này nhưng giữ đồ đã nhặt.
- Sáu điểm quặng/lượt, mỗi điểm 1 sắt, không tái tạo. Vật rơi thử giữa trận theo 24.6, không cần cơ chế đánh bộ phận.
- Thương nhân bán Trap 10 xu, thuốc ngủ 10 xu. Hồ sơ mới nhận 80 xu một lần; bình hồi khác để sau, hồi P1 dùng pet.
- Búa cấp 2 cần 2 xương + 2 sắt, sát thương tăng 15%. Không thu phí vào săn; hết xu vẫn săn thường/đào quặng để tiến triển.
- Mỗi lần bắt tạo cá thể A có mã riêng, chưa biến thể. Một ống tham chiếu cá thể trong kho; đổi không mất cá thể cũ.
- Trước P1-F dùng dữ liệu kiểm tra trong bộ nhớ, hiển thị rõ không lưu qua lần thoát; không dùng để đánh giá đã có lưu bền vững. P1-F kết nối lưu hồ sơ thật trong môi trường thử riêng; P1-G kiểm tra lỗi và hồi quy.

### Thứ tự thực hiện — không bắt đầu đồng thời tất cả

| Bước | Làm ở bước này | Chưa đưa vào | Điều kiện qua bước |
| --- | --- | --- | --- |
| P1-0 | Kiểm tra Studio, project/cấu trúc thư mục, định nghĩa dữ liệu, kho thử trong bộ nhớ và giao diện đọc/ghi có thể thay thế | DataStore thật, UI đẹp, bản đồ hoàn thiện | Dữ liệu thử khởi tạo được; cùng mã giao dịch chỉ áp một lần trong phiên; biết rõ dừng phiên thì mất dữ liệu thử |
| P1-A | Nhân vật, camera/phím, búa N/H/K, né/thể lực, mục tiêu đứng yên; nối combo ngắn sau khi từng đòn ổn | AI đuổi/đánh, pet, bẫy, thưởng thật | Rút/cất đúng; từng đòn chỉ trừ máu một lần; đúng N/H/K mới ra kết thúc; không đánh/né khi thiếu thể lực |
| P1-B | AI một quái: phát hiện, đuổi, báo/cắn/nghỉ, chết, trở về khi mất mục tiêu | Đầu/chân/đuôi, nhiều đòn/quái, bẫy, hệ/biến thể | Quái có báo đòn/nhịp nghỉ; né được; chết thì không gây sát thương tiếp; mắc kẹt không làm reset máu hoặc tạo quái mới |
| P1-C | Pet theo/đánh trước, rồi máu/choáng và gọi hồi | Né/đỡ/thu hút, tự rút hồi, chế đồ pet | Pet không đánh xuyên tường; hồi không vượt trần; choáng đúng 30 giây, độc lập hồi chiêu 119 giây thử |
| P1-D | Lượt săn thường, quái yếu, bẫy/thuốc, bắt, chết thứ tư, hết giờ/thu hoạch; dùng vật dụng thử | Nhiệm vụ chỉ bắt sống, kinh tế/cá thể lưu lâu dài | Đúng điều kiện mới bắt; ngắt/hết bẫy xử lý đúng; khóa kết quả một lần; pet dừng đánh khi cho uống |
| P1-E | Mổ/nhặt/thưởng có mã, thương nhân/chế bẫy, kho nguyên liệu, nâng búa | Cá thể trưng bày, DataStore thật, bảng rơi phức tạp | Chơi hai lượt trong phiên để nâng; thua giữ đồ nhặt; gửi lại yêu cầu không nhân đồ; hết xu vẫn đi săn được |
| P1-F | Cá thể/kho/một ống; thay lớp kho thử bằng lưu tài khoản ở môi trường test | Năm ống, tham quan base, dữ liệu người chơi thật | Sau xác nhận lưu, thoát/vào còn đồ/cấp/cá thể/ống; tải lỗi không ghi đè; giao dịch có dấu chống lặp cùng dữ liệu |
| P1-G | Kiểm tra lỗi và hồi quy toàn vòng chơi; lưu, mất kết nối, nhận trùng, quyền máy chủ | Săn đội, điện thoại hoàn chỉnh, mở rộng nội dung | Checklist 24.13 đạt với bằng chứng; lỗi mất/nhân đồ chưa giải quyết thì chưa đánh dấu P1 hoàn thành |

Vật dụng cấp phục vụ P1-D chỉ nằm trong chế độ kiểm tra; P1-E thay bằng nguồn mua/chế hợp lệ, không mang vật dụng debug sang hồ sơ lưu. Mọi bước hiện **chưa làm**, chưa có test đạt. Kiểm tra lại phần đã làm sau mỗi bước, tập trung vào các liên hệ vừa thay đổi.

### Định nghĩa hoàn thành P1 đầy đủ

| Hệ thống | Có thể bấm thử và xác nhận khi |
| --- | --- |
| Búa/thể lực | Rút/cất, N/H/K và combo ngắn hoạt động; một đòn một lần sát thương; hết thể lực từ chối hành động; ngừng tiêu hao thì hồi đúng |
| Quái | Phát hiện/đuổi/báo/cắn/nghỉ rõ; chết/bị bắt dừng AI; chỉ một kết quả cuối; không cần đánh bộ phận để qua P1 |
| Pet | Theo và đánh có nhịp; không đánh xuyên vật cản; gọi hồi 70%, choáng 30 giây; ngừng đánh lúc cho uống |
| Bẫy/bắt | Không có bẫy thì không đặt; một bẫy chỉ kích hoạt một lần; giữ 13 giây; chỉ bắt quái sống ≤10% và uống xong trong hạn |
| Nhiệm vụ/thưởng | Chết thứ tư/hết giờ xử lý đúng; thắng có 120 giây; hạ và bắt không thưởng trùng; đồ nhặt giữ khi thua |
| Nâng cấp/kho | Đủ nguyên liệu mới nâng, trừ/cộng một lần; đồ dư về kho đúng; cá thể có mã riêng |
| Ống/lưu | Chọn/đổi đúng cá thể; không mất cá thể cũ; thoát/vào sau lưu còn nguyên liệu, cấp búa và ống; xử lý lỗi không cấp trùng |
| Trải nghiệm PC | Người mới hiểu báo đòn/lý do thất bại, thực hiện combo và hoàn thành một lượt săn mà không cần sửa dữ liệu |

Mục tiêu trải nghiệm một lượt đầu khoảng 3–6 phút là giả thuyết để cân bằng, không thay đồng hồ 40 phút. Không rút ngắn âm thầm bẫy 13 giây, choáng pet 30 giây, thu hoạch 120 giây trong bản chơi; mô phỏng thời gian chỉ cho kiểm tra kỹ thuật tách biệt.

### Tình trạng bàn giao

Đã có project, map gốc và source L0.1; P1 săn/bắt/thưởng/lưu vẫn chưa triển khai. Hoàn thiện L0 trước, sau đó đối chiếu P1-0 và tái sử dụng các phần đã đạt để đi tiếp A–G. Không lấy kiểm tra ngoài Studio của L0 làm bằng chứng hoàn thành P1.

## 24. Đối chiếu hai đợt góp ý và quy tắc kỹ thuật bản thử — 27/09/2026

### 24.1. Kết quả đối chiếu với file thực tế

Đã nhận đủ hai đợt, mỗi đợt 12 ảnh; chỉ xử lý sau khi người dùng báo “xong”. Đây là góp ý, không tự động thành quyết định của người dùng. Người góp ý chỉ thấy bản trích: đợt đầu đến mục 20, đợt hai cắt giữa mục 19. File thực tế đã có đầy đủ mục 20–24, không cần thêm mục trùng vì bản trích bị cắt.

**Đợt đầu, v0.20:** xác nhận mục 23 đã có; thêm bảng trạng thái, vòng đời nhiệm vụ/bắt, công thức 10% đề xuất, giao dịch thưởng, kho/lưu, quyền máy chủ, nhịp búa, AI và chia bước pet. Nhật ký mục 15 giữ lịch sử. Các quy tắc bên dưới được cập nhật theo phạm vi P1 hiện hành.

**Đợt hai — 12 điểm nhận xét:**

| Điểm | Góp ý | Đối chiếu và xử lý v0.21 |
| --- | --- | --- |
| 1 | Câu “chưa chọn”, pet/lộ trình chưa đồng bộ | Sửa mục 17–18: đã chọn búa; gắn nhãn pet toàn game ở mục 10; đồng bộ bước tại mục 11 |
| 2 | Định nghĩa hoàn thành cụ thể | v0.20 đã có tiêu chí bước; thêm bảng hoàn thành từng hệ thống ngay cuối mục 23 |
| 3 | P1 quá lớn, cần chia 0–G | Chia lại P1-0 → G, việc làm/chưa làm/điều kiện qua bước; P1 tối thiểu đến D khác P1 đầy đủ đến G |
| 4 | Ranh giới PC/điện thoại | Đề xuất P1 bắt buộc PC, cảm ứng là mốc sau; giữ yêu cầu game đầy đủ có hai nền tảng |
| 5 | Bảng phím búa | Đã có và không trùng E kỹ năng/F tương tác; giữ R mạnh, X rút/cất, Q pet thay vì đổi theo bảng minh họa trong ảnh |
| 6 | Combo dài khó làm ngay | Đề xuất N → H → K kết thúc cho P1; giữ N → H → N → K → K cho mở rộng. Làm từng đòn trước khi nối |
| 7 | AI ít trạng thái | Một đòn cắn; chưa đầu/chân/đuôi. Weak là cờ song song, không bắt quái phải yếu trước khi chết |
| 8 | Bảng bắt thất bại | Đã có ở 24.4; giữ trên 10% vẫn bị bẫy giữ nhưng không bắt, không tự đổi theo ví dụ trong ảnh |
| 9 | Mã lượt chống thưởng trùng | Đã có mã lượt/mục tiêu/giao dịch; bổ sung mẫu mã có số lượt mổ/nguồn nhặt để không chặn thưởng hợp lệ |
| 10 | Dữ liệu phiên/tài khoản | Thêm bảng tại 24.7; mã lượt và đồ mang có phần cần lưu đối soát, không xóa tất cả khi thoát |
| 11 | Lỗi lưu và kho thử trước | Chuẩn bị cấu trúc ở P1-0, dùng bộ nhớ; nối DataStore ở F. Tải lỗi không tạo hồ sơ trắng, ghi lỗi không âm thầm xóa thưởng |
| 12 | Test lỗi và hồi quy | 24.13 thành checklist chưa đánh dấu, có bước/thao tác/kết quả mong đợi; không tuyên bố đã test |

Phần ngoài phạm vi và kết luận trong ảnh đã được đưa vào mục 23–24. Không mở thêm hệ thống lớn trước bản nhỏ. Những thay đổi phạm vi mới vẫn là cấu hình thử của trợ lý, chưa phải chốt toàn game.

### 24.2. Phạm vi P1 sau mốc sảnh/luyện tập L0

Mục 23 xác định cấu hình và thứ tự; mục 24 giải thích vận hành/kiểm tra. P1 đầy đủ không có nghĩa game đầy đủ.

- **P1 tối thiểu 0–D:** PC, búa/combo ngắn, một quái/một đòn, pet cơ bản, săn thường hạ hoặc bắt; dữ liệu thử trong bộ nhớ.
- **P1 đầy đủ 0–G:** thêm thưởng, thương nhân/chế bẫy, nâng cấp, cá thể/một ống và lưu qua lần thoát đã kiểm tra.
- **Ngoài P1:** điện thoại hoàn chỉnh, săn đội/10%, ba quái/map, quái giao chiến, hệ/biến thể, nhiều đòn, đầu/chân/đuôi, combo dài, bảy vũ khí, nhiệm vụ chỉ bắt sống, năm ống, sảnh 12 người, tham quan base, kỷ lục hoàn chỉnh, pet nâng cao.
- **Còn mở toàn game:** máu theo đội/phạm vi thưởng 10%, quái kết liễu nhau, đuôi, chia biến thể, bố trí base; chỉ cần giải quyết trước mốc liên quan.
- P1 chưa hoàn thành bước nào. L0 đang xây một phần nền tảng búa/pet nhưng chưa phải vòng săn; khi chuyển sang P1 cần đối chiếu tiêu chí và tái sử dụng. Kho bộ nhớ không chứng minh lưu qua lần thoát; PC đạt không có nghĩa điện thoại đã được kiểm tra.

### 24.3. Vòng đời nhiệm vụ dùng thử

Luồng: **Sảnh → Chuẩn bị → Đang săn → Thành công/Thu hoạch hoặc Thất bại → Ghi kết quả/Trả đồ dư → Sảnh**. Chỉ một lượt đang hoạt động cho một người. Mỗi lượt có `QuestRunId`, mục tiêu có `MonsterInstanceId`; không chỉ nhận diện bằng tên loài. P1-D dựng luồng với đồ thử; E nối kinh tế, F mới lưu qua lần thoát. Nhiệm vụ chỉ bắt sống để sau P1.

| Giai đoạn | Quy tắc thử và điều kiện chuyển |
| --- | --- |
| Sảnh/Chuẩn bị | Chọn săn thường tại bảng. Kiểm tra hồ sơ sẵn sàng, đồ sở hữu/hạn mức và chỗ cho cá thể khi đã có kho. Chuyển đồ từ kho sang hành trang, giữ tổng sở hữu; lỗi vào map hoàn trả một lần. P1-D dùng kho thử |
| Vào map | P1 dùng cùng một place với khu sảnh và khu săn tách bằng ranh giới; máy chủ đưa nhân vật tới trại. Một quái A xuất hiện ở điểm cố định, có tên và dấu mục tiêu. Chỉ bắt đầu đồng hồ 40 phút khi nhân vật sẵn sàng điều khiển |
| Đang săn | Mục tiêu được ghi rõ trên UI; không đổi mục tiêu giữa lượt. Ba lần chết đầu hồi sinh trại, lần thứ tư thất bại. Thử hồi sinh sau 5 giây, đầy máu/thể lực, giữ đồ đã nhặt và lượng vật dụng còn lại; không tạo lại quặng/quái |
| Ranh giới | Trại là vùng an toàn, quái không gây sát thương xuyên ranh giới vào trại. Người ra ngoài vùng hợp lệ được đưa về trại; không tự tính một lần chết và không tạo đồ mới. Đồng hồ vẫn chạy. Quái vượt phạm vi thì quay về theo 24.11, giữ máu hiện tại |
| Hoàn thành mục tiêu | P1 săn thường: tiêu diệt hoặc bắt đều thắng. Khóa kết quả một lần, ngừng đồng hồ và các đòn còn chờ. Nhiệm vụ bắt sống áp quy tắc riêng sau P1 |
| Thu hoạch | Chạy 120 giây; có nút về sớm. Xác còn để mổ tối đa ba lượt P1; thú đã bắt đổi sang trạng thái bất động, sau hoạt ảnh thu gọn thử 2 giây thì ẩn, không tạo xác để mổ. Cá thể thuộc kho dữ liệu, không phụ thuộc mô hình còn trên map |
| Thất bại | P1: chết lần thứ tư hoặc hết giờ; không có 120 giây thu hoạch, về sảnh sau bảng kết quả. Giữ đồ đã nhặt, không cấp gói hoàn thành. Hết bẫy/thuốc không làm thua săn thường |
| Trở về | Ghi phần thưởng hợp lệ, trả vật dụng chưa dùng về kho một lần, đóng lượt. Hiện trạng thái lưu nếu chưa xác nhận xong. Không mở lượt mới khi giao dịch kết thúc lượt trước còn chưa rõ kết quả |

- Khi success đã khóa, chết trong thu hoạch không đổi kết quả; thử cho hồi tại trại và đồng hồ thu hoạch tiếp tục. Vật phẩm chưa nhặt/mổ khi về sớm hoặc hết 120 giây không tự được cấp.
- Dùng thời gian máy chủ. Chỉ nhận hoàn tất thao tác trong hạn; thao tác bắt đầu trước hạn nhưng kết thúc sau hạn không được tính thắng. Nếu hoàn thành đúng thời điểm hết hạn, thử ưu tiên mục tiêu hoàn tất hợp lệ; sự kiện đến muộn không được lùi thời gian để thắng.
- Từ P1-F, người chủ động rời lượt/mất kết nối không nối lại cuộc săn; lần vào sau về sảnh, giữ dữ liệu đã ghi thành công và xử lý đồ mang còn lại theo bản ghi chuyến săn. Không tạo lại mục tiêu cũ để nhận thưởng lần hai. Trước F kho bộ nhớ không giữ dữ liệu qua lần thoát và UI phải ghi rõ. Giới hạn khi máy chủ lỗi trước lúc lưu xem 24.8.
- **Ngoài P1:** giết quái phụ không hoàn thành mục tiêu chính; cần chốt thưởng quái phụ trước map ba quái. Mục tiêu chính bị quái khác kết liễu là tình huống còn mở, không tự gán thắng/thua. Chưa có hai tình huống này trong P1 một quái.

### 24.4. Bắt giữ: kiểm tra và xử lý thất bại

Giữ yêu cầu đã chốt: quái **còn sống, máu ≤10%**, bẫy giữ **13 giây**, pet chủ ngừng đánh khi bắt đầu cho uống. Cấu hình P1: đặt 1 giây; cho uống 3 giây; hoàn tất mới trừ bình. Khoảng cách thử tối đa 4 studs (đơn vị khoảng cách Roblox) đến điểm miệng; điều chỉnh theo kích thước mô hình khi chơi.

| Tình huống | Xử lý thử |
| --- | --- |
| Bẫy đặt sai: trên không, trong vật cản, ngoài khu săn hoặc quá xa | Máy chủ từ chối, không trừ bẫy; hiển thị vị trí không hợp lệ. Thử giới hạn vị trí đặt trong 5 studs từ nhân vật, trên mặt đất đi được |
| Hủy đặt trước khi xong | Không tạo bẫy, không trừ vật dụng. Đặt xong mới trừ một Iron Trap, gắn mã bẫy với lượt và người đặt |
| Quái còn trên 10% trúng bẫy | Vẫn bị giữ 13 giây; chưa cho uống hợp lệ. Nếu hạ xuống ngưỡng khi bẫy còn thời gian thì được bắt đầu thao tác |
| Người chưa cất vũ khí/không có thuốc/ở ngoài tầm | Không bắt đầu cho uống; báo điều kiện thiếu. Không tự bỏ qua độ trễ cất 1 giây |
| Đang cho uống thì bị đánh, né, rút vũ khí, chết hoặc rời tầm | Hủy thao tác, chưa trừ bình; bẫy tiếp tục đếm phần thời gian còn lại. Muốn thử lại phải giữ tương tác đủ 3 giây từ đầu |
| Bẫy hết 13 giây trước khi uống xong | Hủy thao tác; quái thoát, không bắt, không trừ bình. Bẫy đã dùng không được trả lại. UI hiện thời gian bẫy còn lại, cảnh báo ở 3 giây cuối |
| Quái bị đánh trong bẫy | P1 không tự miễn sát thương/miễn chết. Nếu máu về 0 trước khi bắt hoàn tất thì xử lý tiêu diệt; không đồng thời cấp thưởng bắt. Pet kiểm tra trạng thái ngừng đánh cả lúc phát đòn lẫn lúc áp sát thương |
| Đặt bẫy cuối | P1 săn thường tiếp tục kể cả hết khả năng bắt. Nếu bẫy còn chờ/đang giữ mục tiêu và còn thuốc thì vẫn thử bắt được; không báo hết cơ hội chỉ vì túi đã hết bẫy |
| Hai yêu cầu bắt/tiêu diệt cùng tới | Máy chủ chỉ cho một chuyển trạng thái cuối: Captured hoặc Defeated. Kiểm tra lại sống, ngưỡng, bẫy và thuốc ở thời điểm hoàn tất; không chỉ kiểm tra lúc bắt đầu |
| Bắt xong nhưng mất kết nối | Phần thưởng/cá thể đã ghi thì nhận lại từ hồ sơ, không quay thưởng lại. Phần chưa xác nhận ghi được xử lý bằng cùng mã giao dịch; không hứa phục hồi được dữ liệu chưa từng được lưu |

**Sau P1, nhiệm vụ bắt sống:** giết mục tiêu thì thua; hết khả năng bắt khi không còn thuốc, hoặc không còn bẫy trong túi VÀ không có bẫy hợp lệ còn chờ/đang giữ mục tiêu. Săn đội cần xét vật dụng cả đội, chưa áp vào P1 săn thường.

**Trước săn đội mới chốt:** ai có quyền cho uống; người đặt bẫy và cho uống khác nhau; pet đồng đội có dừng không; vật dụng còn lại được xét cả đội thế nào. Đề xuất cho mọi thành viên còn sống, đủ điều kiện thao tác được hỗ trợ bắt, còn quyền nhận thưởng xét riêng theo đóng góp. Đây chưa phải quyết định của người dùng.

### 24.5. Ngưỡng 10% — đề xuất cho mốc săn đội

**Đã chốt:** chỉ cộng sát thương người chơi và pet của họ, không cộng hồi phục. **Chưa chốt:** mẫu số, loại thưởng bị ràng buộc và trường hợp rời đội. P1 solo chưa dùng quy tắc này để khóa thưởng.

Phương án đề xuất:

`Đủ đóng góp ⇔ sát thương máu thực nhận từ người chơi và pet của họ ≥ 0,10 × máu tối đa mục tiêu sau khi điều chỉnh theo đội lúc bắt đầu lượt.`

- Chốt đội và máu tối đa trước khi bắt đầu; không thay mẫu số giữa lượt khi ai đó rời/đến. Tham gia giữa lượt và tăng/giảm máu theo đội cần thiết kế riêng trước khi bật tính năng đó.
- Chỉ cộng lượng thật sự trừ vào máu mục tiêu sau giảm sát thương; không cộng phần đánh vượt máu còn lại, không cộng lần hai cho thanh bộ phận. Sát thương quái gây cho nhau không thuộc người chơi.
- Sát thương trước lúc bắt vẫn được tính. Đòn của pet gắn chủ sở hữu ở máy chủ; thử dừng phát đòn mới khi chủ chết, đòn đã phát hợp lệ trước đó vẫn tính nếu thực sự trúng. Khi thêm sát thương theo thời gian/phản sát thương phải gán nguồn trước, không suy đoán từ người đứng gần.
- Khóa bảng đóng góp tại thời điểm mục tiêu bị bắt/tiêu diệt, không đợi người bấm nhận thưởng. Nếu về sau cho nhận khi mất kết nối, cần lưu bảng đã khóa cùng kết quả.
- Ví dụ: mục tiêu 2.400 máu thì ngưỡng là 240; người gây 200 và pet gây 40 đạt ngưỡng. Khi bắt ở 10% máu, không đổi mẫu số thành 90% máu đã mất.
- **Cần quyết định trước săn đội:** ngưỡng khóa nguyên liệu quái, cá thể, gói nhiệm vụ hay cả ba; người không đạt có giữ đồ tự nhặt hay không. Yêu cầu hiện hành là giữ đồ đã nhặt khi thua, không tự mở rộng ngưỡng để tịch thu đồ đó. Quyền thao tác bắt và quyền nhận thưởng phải được xét riêng.

### 24.6. Phần thưởng và chống nhận lặp

Tách theo nguồn. Mẫu mã: `PlayerId + QuestRunId + SourceInstanceId + RewardType + ClaimIndex`; máy chủ tạo/kiểm tra, bấm lại không tạo mã mới. Nguồn là mã quái khi mổ/bắt, mã quặng/vật rơi khi nhặt hoặc mã lượt với gói nhiệm vụ. `ClaimIndex` phân biệt mổ 1, 2, 3; không chặn nhầm lượt 2/3 vì cùng loại thưởng. Bắt trọn gói dùng một mã cố định, ghi ba kết quả nguyên liệu và một cá thể bên trong.

Bảng sau mô tả P1 đầy đủ: P1-E chỉ thử nguyên liệu/kinh tế; P1-F thêm cá thể và lưu bền vững. Chưa có cá thể ở E thì chưa đánh dấu tiêu chí bộ sưu tập hoàn thành.

| Nguồn | Dữ liệu/kết quả cần ghi |
| --- | --- |
| Tiêu diệt mục tiêu | `MonsterDefeated`: khóa trạng thái quái; săn thường mở các lượt mổ, chưa tự cấp toàn bộ nguyên liệu. Nhiệm vụ bắt sống sau P1 dùng phương án thất bại, không mở giai đoạn mổ |
| Mổ xác | `CarveGranted`: một mã cho mỗi người/lượt mổ 1–3; hoàn tất tương tác mới cấp một nguyên liệu gốc 1 |
| Bắt thành công | `CaptureGranted`: ba lượt nguyên liệu độc lập và một cá thể P1; mỗi lượt chọn loại rồi xét 50% lượng 1 / 50% lượng 2. Không tạo thêm lượt mổ |
| Hoàn thành nhiệm vụ | `QuestBonusGranted`: 1 xương + 40 xu P1, một lần khi nhiệm vụ thành công, riêng với nguyên liệu mổ/bắt |
| Nhặt trên map | `PickupGranted`: mã quặng/vật rơi và người nhặt; chỉ cấp một lần. Đồ đã nhặt thuộc tiến trình kể cả thất bại nhiệm vụ |
| Chế tạo/nâng cấp | `CraftOrUpgradeCommitted`: trừ nguyên liệu và thêm sản phẩm/cấp trang bị trong cùng giao dịch, không gọi là thưởng nhiệm vụ |

- P1-E minh họa vật rơi bằng **một vảy gốc 1 khi quái lần đầu giảm qua 50% máu và vẫn sống**; phải nhặt, có mã riêng/cờ tạo một lần. Không cần đánh bộ phận; đây là nguồn thử có kiểm soát, chưa chốt tỷ lệ rơi toàn game. Nhặt vảy không dùng lượt mổ; đuôi để sau P1.
- Mỗi hồ sơ có danh sách giao dịch đã ghi. Trước F dấu này chỉ trong bộ nhớ; từ F lưu bền vững cùng thay đổi sở hữu. Khi thử lại cùng mã: trả kết quả cũ, không cấp lại và không quay lại ngẫu nhiên. Mã cá thể, loại/lượng thưởng phải được tạo một lần và giữ ổn định khi thử lưu lại.
- Trong P1 solo, kết quả bắt, thuốc bị tiêu hao, cá thể, nguyên liệu bắt và gói nhiệm vụ có thể cùng nằm trong một lần cập nhật hồ sơ. Các lượt mổ/nhặt về sau là giao dịch riêng. Không để Captured và Defeated cùng phát thưởng cho một quái.
- Ghi thay đổi sở hữu **cùng dấu giao dịch** trong một cập nhật hồ sơ; không ghi “đã thưởng” trước rồi để bước cấp vật phẩm ở nơi khác. Xử lý nối tiếp các giao dịch của một hồ sơ.
- UI hiển thị “đang ghi nhận” khi chưa xác nhận lưu; bấm lại chỉ xem trạng thái. Khi kết quả ghi chưa rõ, kiểm tra cùng mã trước khi thử lại; không tạo thưởng thay thế có mã mới.
- Không xóa dấu giao dịch của lượt còn có thể được gửi lại. Chỉ dọn theo chính sách lưu trữ khi lượt đã đóng và máy chủ có thể từ chối yêu cầu cũ; không để danh sách tăng mãi không giới hạn.
- Khi mở săn đội, mỗi người nhận có dấu riêng và cần cơ chế tiếp tục cấp phần còn thiếu. Không giả định cập nhật nhiều hồ sơ khác nhau là một giao dịch nguyên tử duy nhất.

### 24.7. Kho, dữ liệu phiên và dữ liệu tài khoản

| Lớp | Ví dụ | Cách xử lý |
| --- | --- | --- |
| Chỉ trong phiên | HP người/quái, thể lực, vị trí, AI, bẫy/đồng hồ, combo, pet, đóng góp đang tích | Giữ trên máy chủ; không ghi DataStore từng khung hình/đòn; không nối lại trận cũ |
| Tiến trình tài khoản | Xu, nguyên liệu, kho vật dụng, trang bị/cấp búa, cá thể/ống, cờ đã cấp đồ đầu | Kho thử trước F; từ F ghi khi có thay đổi có ý nghĩa, chỉ báo đã lưu sau xác nhận |
| Đối soát chuyến săn | Mã lượt, đồ chuyển khỏi kho/còn lại, kết quả và dấu giao dịch | Từ F phải lưu phần cần thiết để trả đồ/không cấp trùng; không bỏ hết vì thuộc một chuyến săn |

Mã lượt dùng cả trong phiên và dấu thưởng đã lưu; đồ mang có trạng thái chơi tạm nhưng thay đổi quyền sở hữu cần ghi nhận. Không lưu cả thế giới để nối lại cuộc săn. Kỷ lục là tiến trình tài khoản khi triển khai sau P1; hiện chưa chốt cách tính.

| Nhóm hồ sơ | Trường dự kiến |
| --- | --- |
| Phiên bản/hồ sơ | `DataVersion`, `Revision`, `StarterGranted`, thông tin phiên máy chủ đang giữ hồ sơ |
| Kinh tế/vật dụng | `Coins`, `Materials[itemId]`, `StoredConsumables[itemId]` — số lượng nguyên không âm |
| Trang bị | Danh sách sở hữu, `EquippedWeaponId`, `HammerUpgradeLevel`, giáp/pet cơ bản đã cấp |
| Cá thể | `OwnedSpecimens[specimenId]` gồm loài, biến thể, kích thước, thời điểm bắt và mã lượt nguồn; P1 dùng ngoại hình cơ bản cố định |
| Trưng bày | `DisplaySlot1 = specimenId` hoặc trống; mã phải thuộc kho người đó |
| Chuyến săn/giao dịch | `ActiveRun` gồm mã lượt, đồ mang còn lại, kết quả đang chờ; các dấu giao dịch cần phục hồi/chống lặp |

- Khởi đầu `DataVersion = 1`; số này là phiên bản cấu trúc lưu, khác phiên bản 0.21 của tài liệu. Chỉ cấp đồ đầu khi chắc chắn tài khoản chưa có hồ sơ, không cấp vì tải bị lỗi. Cấp đồ và đánh dấu `StarterGranted` cùng một giao dịch.
- Nguyên liệu xếp chồng theo mã loại; cá thể luôn có mã riêng. UI phân biệt cá thể cùng loài bằng thứ tự/ngày bắt và mã rút gọn. Thay cá thể trưng bày chỉ đổi tham chiếu, không di chuyển/xóa sở hữu.
- Kho cá thể thử từ P1-F tối đa 100; kiểm tra/dành chỗ trước lượt có thể bắt. Đầy thì báo trước: vẫn săn tiêu diệt nhưng không bắt thêm. Nhiệm vụ bắt sống sau P1 cần chặn vào khi hết chỗ. Đây là hạn mức thử, không phải giới hạn toàn game.
- P1 chưa có bán/thả/xóa cá thể hoặc giao dịch giữa người chơi. Nếu dữ liệu ống tham chiếu mã không tồn tại, để ống trống và ghi lỗi; không tự tạo một cá thể mới.
- Không âm thầm bỏ phần thưởng khi gặp đầy kho hoặc dữ liệu bất thường. Giữ giao dịch ở trạng thái chờ xử lý, báo rõ; không đánh dấu đã cấp. Giới hạn số lượng nguyên liệu/tiền cần được kiểm tra về kiểu và miền giá trị ở máy chủ, không lấy số người chơi gửi làm số lượng thật.
- Đồ mang dư trước chuyến săn trả kho theo quyết định đã chốt. Đồ chưa dùng sau chuyến săn trả kho là cấu hình P1; không nhân đôi bằng cách vừa giữ trong hành trang cũ vừa cộng lại kho.

### 24.8. Lưu, lỗi và khôi phục

Mục tiêu là giữ tiến trình và tránh cấp lặp; đây là thiết kế cần kiểm chứng, không phải cam kết không bao giờ mất dữ liệu.

**Trình tự:** P1-0 định nghĩa hồ sơ/lớp đọc ghi và dùng bảng trong bộ nhớ máy chủ, không cần dịch vụ MemoryStore và chưa nối DataStore. P1-E thử kinh tế trong phiên; P1-F thay lớp lưu bằng DataStore ở bản game test riêng; P1-G thử lỗi. Không tự chuyển sang hồ sơ tạm rồi ghi đè tài khoản thật khi tải lỗi; chế độ dữ liệu thử phải chọn rõ, không trộn đồ debug.

Các quy tắc dưới đây áp dụng khi kết nối lưu tài khoản từ P1-F:

1. **Tải trước khi chơi:** một hồ sơ chính cho mỗi tài khoản. Nếu tải lỗi, báo đang thử lại và khóa giao dịch/đi săn; không dùng hồ sơ trắng để ghi đè dữ liệu thật. Nếu thử lại vẫn lỗi, cho người chơi quay lại sau với thông báo rõ.
2. **Một máy chủ ghi:** giữ quyền sử dụng hồ sơ theo phiên có thời hạn, gia hạn khi còn hoạt động và kiểm tra quyền ở mọi lần ghi. Nếu mất quyền thì dừng sửa tiến trình; không để máy chủ cũ ghi đè máy chủ mới. Không chỉ dựa vào sự kiện người chơi rời game.
3. **Ghi nối tiếp:** dùng cơ chế cập nhật có kiểm tra dữ liệu hiện tại, như `UpdateAsync`, cho thay đổi cần bảo vệ khỏi ghi đè. Hàm cập nhật có thể được gọi lại; không quay thưởng, tạo mã mới hoặc gây hiệu ứng bên ngoài trong hàm đó. Có hàng đợi theo từng hồ sơ, kiểm tra phiên/revision và dấu giao dịch.
4. **Thời điểm lưu:** ghi giao dịch khi cấp đồ đầu, nhặt/mổ, hoàn tất bắt/thưởng, mua/chế/nâng cấp, chuyển đồ đi/về và đổi trưng bày. Thử tự lưu theo chu kỳ 60 giây cho trạng thái còn bẩn, có giãn thời điểm giữa người chơi; lưu khi rời/đóng máy chủ là bổ sung. Không lưu từng đòn đánh; khi mật độ nhặt tăng cần gom ghi và kiểm tra hạn mức dịch vụ.
5. **Lỗi tạm thời:** thử lại có thời gian chờ tăng dần và độ lệch ngẫu nhiên, có giới hạn; ưu tiên hoàn tất giao dịch cũ. Chưa chắc đã ghi hay chưa thì đọc/đối chiếu dấu giao dịch, không cấp mới. Khi hàng đợi không thể tiến, khóa thêm giao dịch kinh tế và báo người chơi.
6. **Thoát đột ngột:** lần vào sau đọc hồ sơ và bản ghi lượt còn dang dở; trả vật dụng chưa tiêu hao theo bản ghi đã lưu, xử lý kết quả đã ghi mà UI chưa hiển thị. Không tiếp tục chiến đấu ở lượt cũ. Dữ liệu chỉ có trong bộ nhớ lúc máy chủ sập có thể chưa phục hồi được; kiểm tra cửa sổ này trước mở chơi thật.
7. **Nâng cấu trúc:** chuyển lần lượt từ phiên bản cũ sang mới, giữ trường chưa thay đổi và kiểm tra dữ liệu sau chuyển. Tạo điểm khôi phục trước đợt đổi lớn, thử trên bản sao; không lấy dữ liệu người chơi thật làm dữ liệu kiểm tra.
8. **Sao lưu/khôi phục:** sử dụng phiên bản dữ liệu có sẵn theo chính sách Roblox và quy trình lưu bản sao trước thay đổi lớn. Khôi phục bằng người quản trị khi hồ sơ không còn phiên đang ghi; ghi lý do, nguồn phiên bản và kết quả đối chiếu. Việc khôi phục cả hồ sơ phải xét các giao dịch sau mốc đó để tránh tạo lại đồ đã dùng.

Giới hạn cần ghi trong kết quả thử: lưu khi thoát có thể không chạy khi máy chủ lỗi; `UpdateAsync` không tự giải quyết tất cả việc ghi cũ, quay thưởng lại hoặc tranh quyền phiên. Chỉ hiển thị “đã lưu” sau xác nhận ghi thành công. Chưa có cơ chế nào trong mục này được triển khai hoặc thử lỗi thực tế.

### 24.9. Máy chủ quyết định, máy người chơi gửi thao tác

Máy người chơi xử lý nút, camera, dự đoán hoạt ảnh và hiển thị; máy chủ giữ dữ liệu thật. Mục đích là cùng một quy tắc áp dụng cho mọi người, kể cả khi yêu cầu gửi trễ hoặc bị gửi lặp.

| Yêu cầu từ máy người chơi | Máy chủ phải kiểm tra trước khi chấp nhận |
| --- | --- |
| Đánh/né/chạy | Nhân vật sống, vũ khí đang trang bị, trạng thái hợp lệ, thể lực, nhịp đòn, thứ tự combo; kiểm tra hướng/khoảng cách và va chạm trước khi tính sát thương |
| Đặt bẫy/cho uống | Đang trong đúng lượt, đã cất vũ khí, còn vật dụng, vị trí/tầm, mặt đất, quái sống và đủ ngưỡng, bẫy còn hiệu lực, thời lượng thao tác |
| Gọi pet | Chủ/pet đúng sở hữu, trạng thái, hồi chiêu, không có lệnh trùng, chủ còn sống tại lúc nhận hồi |
| Nhặt/mổ | Vật hoặc xác còn hợp lệ, người ở đủ gần, tương tác đã xong, lượt nhận còn lại và mã giao dịch chưa xử lý |
| Mua/chế/nâng | Gần điểm tương tác, công thức/giá do máy chủ chọn, đủ tiền/nguyên liệu, giới hạn cấp và giao dịch hợp lệ |
| Trưng bày/nhận kết quả | Mã cá thể thuộc người chơi; kết quả lấy từ bản ghi máy chủ. Nút nhận không quyết định lượng/loại thưởng |

Máy chủ tự quyết định máu quái, lượng sát thương, phần trăm đóng góp, thời gian, vật phẩm/cá thể và kết thúc nhiệm vụ. Kiểm tra kiểu dữ liệu, số hữu hạn, miền giá trị và giới hạn tần suất yêu cầu; khoảng cách phải dùng vị trí được máy chủ kiểm tra, không tin vị trí tùy ý do client gửi. Không để client tự báo “đã gây 1.000 sát thương” rồi cộng thẳng.

### 24.10. Búa: pha đòn và vùng trúng P1

Chỉ pha gây sát thương được xét trúng. Giữ phím/chỉ số mục 23; P1 làm hết động tác trước khi nhận đòn/né kế tiếp, chưa hủy hoạt ảnh hoặc đệm nút.

| Đòn | Chuẩn bị | Gây sát thương | Thu đòn | Tổng |
| --- | ---: | ---: | ---: | ---: |
| N | 0,20 giây | 0,10 giây | 0,25 giây | 0,55 giây |
| H | 0,45 giây | 0,15 giây | 0,50 giây | 1,10 giây |
| K thường | 0,25 giây | 0,10 giây | 0,35 giây | 0,70 giây |
| K kết thúc | 0,45 giây | 0,20 giây | 0,55 giây | 1,20 giây |

- Vùng thử: thể tích quanh đầu búa bán kính 2 studs quét theo cung; điểm trúng tối đa 8 studs từ nhân vật, không xuyên vật cản. Hiện vùng debug để so với hoạt ảnh.
- Mỗi mã đòn chỉ trừ máu một lần trên mỗi mục tiêu dù chạm nhiều phần/khung hình. P1 chưa tích thanh bộ phận; thêm về sau vẫn không trừ máu lần hai.
- Được quay trong chuẩn bị, khóa hướng từ pha gây sát thương. Thể lực trừ khi chấp nhận đòn, không hoàn vì hụt. Thử cho đi chậm 50% tốc độ thường trong đòn, không chạy nhanh; điều chỉnh khi chơi.
- N → H → K kết thúc: **246 sát thương / 44 thể lực / 2,85 giây động tác**. K ngoài chuỗi gây 50; K → K không tự mở kết thúc.
- Giữ Shift lúc đang đánh: chờ hết đòn, nếu còn giữ thì cất đủ 1 giây rồi chạy. Thả trước khi đòn hết thì không tự cất; thả giữa lúc cất vẫn hoàn tất cất nhưng không chạy. Đây là cách xử lý thử.
- Chuỗi dài, hủy thu đòn, nhiều hit và gây gục để sau P1. Chưa kết luận cân bằng với sáu vũ khí chưa làm.

### 24.11. AI quái: giới hạn trạng thái P1

**P1-B:** Idle → Chase → Warning → Attack → Recovery → Chase, thêm Return khi mất mục tiêu và Defeated khi chết. Phát hiện là điều kiện chuyển, chưa cần trạng thái riêng. **P1-D:** thêm Trapped, Captured và cờ Weak.

**Yếu máu là cờ song song:** quái có thể chết từ mọi trạng thái còn sống, không bắt buộc Weak trước Defeated. P1 chưa có gục bộ phận, quái giao chiến, nhiều mục tiêu, chạy sang khu khác, biến thể/nguyên tố.

| Trạng thái | Quy tắc thử |
| --- | --- |
| Idle — chờ | Người sống trong khu săn, trong 60 studs và không bị vật cản kín che thì Chase. Bị người đánh hợp lệ cũng giao chiến |
| Chase — đuổi | Theo người solo; ≤8 studs có tầm/đường đánh thì Warning. Mất mục tiêu 10 giây hoặc xa điểm xuất hiện hơn 120 studs thì Return |
| Warning — báo | Báo cắn 0,8 giây, chốt hướng trước pha trúng; sang Attack nếu chưa ngắt, không xoay vô hạn bám người đã né |
| Attack — cắn | Cửa sổ 0,30 giây gây 18 sát thương, mỗi nạn nhân tối đa một lần; tiếp đến Recovery |
| Recovery — nghỉ | Nghỉ 1,5 giây, vẫn nhận sát thương; xong thì Chase/Return |
| Return — về vùng | Không hồi máu/đổi mã. Kẹt không tiến triển 5 giây thì thử đặt về điểm an toàn, giữ HP và hủy đòn cũ; vẫn tái giao chiến trong vùng hợp lệ |
| Trapped — bẫy | Hủy đòn đang dở, cúi đầu 13 giây. Bắt hợp lệ → Captured; HP 0 → Defeated; hết bẫy → Chase/Return. Một bẫy không kích hoạt lại; bẫy mới không nối/reset thời gian khi quái đang mắc bẫy |
| Captured / Defeated | Kết quả loại trừ nhau, dừng AI/đòn chưa áp sát thương; chỉ có tương tác hậu kết quả hợp lệ |

Weak bật khi 0 < HP ≤10% MaxHP: khập khiễng, thử đi còn 60% tốc độ, hiện dấu đủ bắt; không tự tắt chiến đấu. Vùng cắn phải khớp hoạt ảnh khi xem trực tiếp.

Ưu tiên: kết quả đã khóa → chết → bẫy/bắt → hành vi thường. Đòn hẹn giờ phải kiểm tra lại trạng thái trước khi trừ máu. Chủ chết thì quái về vùng, HP không reset; không cho đứng trong trại đánh xuyên ra khi quái không thể đáp trả.

### 24.12. Pet: phần bắt buộc và phần để sau

- **P1-C, bước nhỏ 1:** theo chủ, đánh 12 mỗi 4 giây trong tầm 6 studs. C dùng mục tiêu thử hiện tại, D gắn mục tiêu vào lượt săn; chỉ đánh khi chủ giao chiến, không mở trận xa. Kiểm tra tầm/vật cản trước khi trừ máu; đi vòng khi đường bị chắn, không xuyên tường.
- **P1-C, bước nhỏ 2:** máu 100, sát thương không hạ dưới 1; ở 1 thì choáng 30 giây, đòn mới không reset thời gian; đứng dậy đầy máu.
- **P1-C, bước nhỏ 3:** gọi hồi 70% tối đa có trần máu, hồi chiêu thử 119 giây, UI báo. Chưa đủ ba bước thì chưa hoàn thành C.
- **P1-D:** nối cho uống; dừng phát đòn và hủy sát thương pet chưa xảy ra lên mục tiêu đang bắt. Hủy cho uống thì pet trở lại hành vi phù hợp. Không nhận lệnh hồi mới trong lúc chủ cho uống.
- Chủ chết/pet choáng trước khi hồi thì hủy lệnh; chưa hồi chưa bắt đầu hồi chiêu. Thuốc áp máu một lần; đầy máu thì báo không cần hồi. Choáng/hồi sinh chủ không reset kỹ năng, không xếp lệnh chờ để tự hồi ngay khi đứng dậy.
- Chủ chết thì pet ngừng phát đòn, theo về trại khi có thể; nếu đang choáng vẫn chờ hết. Ưu tiên: choáng → ngừng đánh khi chủ cho uống → lệnh hồi → đánh/theo.
- **Sau P1:** tự tìm chỗ an toàn hồi, né/đỡ/thu hút và chế/đổi vũ khí-mũ-giáp. Giữ ở mục 22; không yêu cầu để qua P1-C.

### 24.13. Checklist lỗi và hồi quy — chưa kiểm tra đạt mục nào

Sau mỗi bước thử phần mới và chạy lại trường hợp cũ bị ảnh hưởng. P1-G chạy toàn bộ mục thuộc P1; không đánh dấu đạt chỉ vì đã viết code/mô tả. Ghi bản build/bước, thao tác, mong đợi, thực tế, đạt/lỗi và cách tái hiện. Lưu qua lần thoát chỉ kiểm tra được từ P1-F với hồ sơ test riêng.

**P1-A/B — chiến đấu và AI:**

- [ ] Một đòn chạm nhiều phần/nhiều khung hình: chỉ giảm máu một lần đúng lượng; đánh hụt không giảm.
- [ ] Spam nút khi đang ra đòn: không vượt nhịp hoặc chạy nhiều đòn đồng thời.
- [ ] N → H → K đúng hạn ra kết thúc; sai/quá hạn/K → K không ra; thiếu thể lực không tiến chuỗi.
- [ ] Cạn thể lực không đánh/né; chạy cạn thì đi; sau 0,75 giây ngừng tiêu hao hồi 20/giây, không vượt 100.
- [ ] Giữ/thả Shift ở các thời điểm 24.10 không bỏ qua cất 1 giây, không chạy khi đang rút vũ khí.
- [ ] Quái báo/cắn/nghỉ rõ; người đã né ra ngoài vùng trúng không bị đánh vì vị trí cũ lúc báo.
- [ ] Quái chết/đòn ngắt trước khi trúng: đòn hẹn giờ không gây thêm sát thương.
- [ ] Quái kẹt/mất mục tiêu: về vùng với cùng mã/HP, không tái tạo quặng/vật rơi để farm.

**P1-C/D — pet, bắt và nhiệm vụ:**

- [ ] Pet theo/đánh đúng nhịp, không đánh xuyên tường, mỗi chu kỳ chỉ trừ máu một lần.
- [ ] Gọi hồi nhiều lần chỉ có một lệnh; hồi 70% tối đa, không vượt trần.
- [ ] Đòn lớn không làm pet chết; choáng đủ 30 giây, đòn mới không kéo dài; đứng dậy không reset kỹ năng.
- [ ] Chủ chết/pet choáng lúc mang thuốc: hủy đúng, không hồi người chết; hồi sinh không làm mới kỹ năng.
- [ ] Hết bẫy/đặt sai/hủy đặt: không tạo bẫy hoặc trừ nhầm; đặt xong trừ đúng một.
- [ ] Quái >10% vẫn có thể bị giữ nhưng không cho uống; sống đúng 10% được; HP 0 không bắt.
- [ ] Một bẫy kích hoạt một lần, giữ đúng 13 giây; bẫy mới không nối thời gian trên quái đang bị giữ.
- [ ] Ra xa/bị đánh/hết bẫy trước uống xong: hủy không trừ bình; thử lại cần đủ 3 giây từ đầu.
- [ ] Pet ngừng cả đòn đang chuẩn bị khi cho uống; hủy thao tác thì trở lại hành vi phù hợp.
- [ ] Bắt/tiêu diệt đồng thời: một kết quả, không vừa thưởng bắt vừa mở mổ.
- [ ] Ba lần chết đầu tiếp tục, thứ tư thua; hết 40 phút thua; hết bẫy/thuốc không làm thua săn thường.
- [ ] Hoàn thành đúng/sau hạn theo 24.3; thắng có 120 giây/về sớm, không đổi kết quả vì chết sau đó.

**P1-E/F — thưởng, nâng cấp, cá thể:**

- [ ] Ba lượt mổ nhận đủ ba phần; gửi lại lượt 1 không cấp thêm/không chặn lượt 2–3; không có lượt 4.
- [ ] Bắt một lần đúng một cá thể/ba lượt nguyên liệu; gói nhiệm vụ riêng một lần. Từng lượt quay lượng độc lập; vài lần thử ngẫu nhiên không bắt buộc ra đúng tỷ lệ 50/50.
- [ ] Cùng mã nhặt/giao dịch gửi lại không tăng đồ; mã các điểm quặng khác nhau vẫn nhận riêng.
- [ ] Nhặt rồi thua giữ đồ; trả đồ mang dư/chưa dùng một lần, gọi kết thúc/về sảnh lần hai không cộng lại.
- [ ] Thiếu nguyên liệu không nâng; đủ thì trừ/tăng cấp một lần; hết xu vẫn săn thường để tiếp tục.
- [ ] Đổi ống đúng mã cá thể và giữ con cũ trong kho; đầy báo trước, không tự xóa/cấp lại.
- [ ] Từ F, sau xác nhận lưu, thoát/vào giữ vật liệu, cấp búa, cá thể/ống; không cấp bộ đầu lần nữa.

**P1-F/G — lỗi dữ liệu, quyền máy chủ, hồi quy:**

- [ ] Tải lỗi không tạo hồ sơ trắng để ghi đè, không cấp thưởng/nâng cấp vào tài khoản chưa tải.
- [ ] Ghi lỗi/chưa rõ kết quả: có thông báo/log, giữ giao dịch chờ; thử lại cùng mã không quay lại thưởng/nhân đồ.
- [ ] Ngắt kết nối trước/sau ghi thưởng/chế/nhặt: đối soát dữ liệu đã lưu, không cấp lại. Ghi rõ trường hợp chưa lưu có thể mất, không báo “đã lưu” giả.
- [ ] Hai phiên cùng xin hồ sơ/quyền phiên hết hạn: chỉ phiên hợp lệ ghi, phiên cũ không ghi đè.
- [ ] Chuyển phiên bản/khôi phục chỉ trên hồ sơ test; không trộn vật dụng debug/dữ liệu người chơi thật.
- [ ] Yêu cầu từ xa, sai sở hữu, giả lượng thưởng, sai kiểu hoặc spam: máy chủ từ chối, tiến trình thật không đổi.
- [ ] Chơi lại PC toàn vòng sau thay đổi liên quan: hồ sơ → săn/hạ hoặc bắt → thắng/thua → về → nâng/ống → lưu/vào lại; lỗi đã sửa không tái xuất hiện.

**Không phải điều kiện P1:** combo dài, bộ phận/đuôi, nhiệm vụ chỉ bắt sống, săn đội/10%, quái giao chiến, điện thoại. Mốc cảm ứng sau P1 phải thử riêng nút/camera/thao tác, không suy từ PC đạt.

### 24.14. Tài liệu kỹ thuật tham chiếu

Tra cứu ngày 27/09/2026; dùng làm căn cứ cho thiết kế kỹ thuật, không biến ví dụ tài liệu thành lời bảo đảm bản game đã hoạt động.

- [Roblox — Client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary): kiểm tra dữ liệu, ngữ cảnh và tần suất yêu cầu tại máy chủ.
- [Roblox — Data stores](https://create.roblox.com/docs/cloud-services/data-stores): lưu bền vững, cập nhật dữ liệu và các giới hạn dịch vụ cần kiểm tra khi triển khai.
- [Roblox — Player data and purchasing](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing): quản lý dữ liệu người chơi, khóa phiên, xử lý lỗi và ghi dữ liệu theo thứ tự. Phần P1 bên trên là thiết kế riêng, chưa dùng mã ví dụ này để tuyên bố sẵn sàng phát hành.


## 25. Giai đoạn hiện tại — sảnh 12 base và bãi luyện tập L0

### 25.1. Quyết định và giới hạn

**Đã chốt bởi người dùng:** giảm sảnh từ 16 xuống 12 người; mỗi người một base. Có map cơ bản 12 base nhưng muốn sáng tạo hơn. Ưu tiên nâng map/sảnh và làm khu di chuyển sang luyện tập, rồi vũ khí, giáp, đòn đánh, hình nộm và pet. Người dùng sẽ tiếp tục làm rõ thiết kế toàn game. Không chờ chốt hết hệ thống săn mới làm phần nền tảng này.

**Phương án thử của trợ lý:** giữ trại trong rừng và vị trí các base, bổ sung sân đón dễ nhận biết cùng cổng có biển. Bãi tập nằm tách xa trong cùng một Place để thử đi/về cục bộ; chưa quyết định đây là kiến trúc map cuối. Búa là vũ khí thử đầu; giáp/pet dùng mô hình khối tự dựng. Chưa phải đồ họa cuối cùng.

**Ngoài lần triển khai L0 này:** nhiệm vụ săn, boss thật, bẫy/bắt, tỷ lệ rơi đồ, chế/nâng cấp, kho cá thể/ống nghiệm, DataStore, quái đánh nhau, các vũ khí còn lại, hệ/biến dị, pet hồi/choáng và hệ trang bị pet, hoàn thiện điện thoại. Mọi yêu cầu này vẫn giữ trong hồ sơ.

### 25.2. Bản phát triển đã tạo

| Phần | Nội dung trong L0.1 | Trạng thái |
| --- | --- | --- |
| Map nguồn | Bản sao HunDino1.rbxl trên Desktop; nguyên bản không thay đổi | Đã sao lưu và đối chiếu |
| Sảnh | Đủ 12 base giữ vị trí; sân đón, cổng, biển số/chủ base; một điểm xuất hiện chung | Đã dựng file; cần Play/duyệt thẩm mỹ |
| Cây cảnh | 14 cụm cây/đá cản sân đón dời sang mép rừng trong bản phát triển; giữ đủ đối tượng map gốc | Đã kiểm tra số đối tượng |
| Base trong phiên | Gán base trống, trả khi rời; giới hạn 12 ở script | Có code; chưa thử 12 client. Cần đặt MaxPlayers = 12 khi xuất bản |
| Khu luyện tập | Cổng G đi/về trong cùng Place, 3 hình nộm, giá giáp, bảng reset thống kê | Có map + code; cần thử trực tiếp |
| Búa | R rút/cất 1 giây; chuột trái/Q/E; thường → mạnh → kỹ năng kết thúc; kiểm tra tầm, hướng, vật cản | Logic combo kiểm tra đạt; chưa kiểm chứng cảm giác/hit trong engine |
| Di chuyển | Shift tự cất rồi chạy; Ctrl ghim tâm; Space lướt thử; dùng/hồi thể lực | Có code; chưa có hoạt ảnh lộn/né hoàn chỉnh hoặc i-frame |
| Giáp | Mẫu giáp ngực/vai, mặc/tháo ở giá trang bị | Chỉ ngoại hình thử, chưa chỉ số phòng thủ/chế tạo |
| Pet | Theo chủ, qua cổng cùng chủ, đánh hình nộm chủ vừa đánh theo chu kỳ; có kiểm tra vật cản | Cần thử đường đi; chưa tìm đường vòng, có thể mắc cây/tường |
| Giao diện | Vị trí/base, phím, trạng thái búa/giáp, thể lực, sát thương riêng người/pet và số nổi | Có code; cần kiểm tra màn hình thật |

### 25.3. Phím và thông số L0 dùng thử

- WASD di chuyển; R rút/cất; Shift chạy sau cất; Ctrl ghim tâm tự tạo. Shift Lock mặc định tắt trong bản phát triển.
- Chuột trái thường (36 sát thương / 8 thể lực / 0,55 giây), Q mạnh (70 / 16 / 1,10), E kỹ năng (50 / 12 / 0,70). Đúng chuỗi thường → mạnh → E thì đòn cuối là 140 / 20 / 1,20. Chờ đòn trước kết thúc; cửa sổ nối 1 giây sau khi kết thúc đòn trước.
- Thể lực tối đa 100; hồi 20/giây sau 0,75 giây nghỉ. Chạy tốn 10/giây. Space lướt tốn 20, kéo dài 0,4 giây; đây là chuyển động thử, chưa phải bộ hoạt ảnh né cuối.
- Hình nộm 1000 máu, về đầy khi hết; không có thưởng. Pet 12 sát thương mỗi 4 giây vào mục tiêu chủ vừa đánh khi còn gần.
- G tương tác cổng/giá giáp/reset; thay giáp và reset cần cất búa. Bảng reset chỉ xóa thống kê của chính người thao tác.
- Chuột phải vẫn xoay camera mặc định; chưa có cung hoặc chế độ ngắm riêng trong L0. Phím/cơ chế toàn game giữ ở mục 17–18.

### 25.4. Kiểm tra và bước tiếp tục

**Đã đạt:** 9 nhóm kiểm tra bằng Lune: biên dịch toàn bộ source Luau, combo đúng/sai/hết hạn, chặn đánh trong thời gian chờ, không đánh khi cất/chạy/thiếu thể lực, hồi đúng nhịp và có trần, bảo toàn đối tượng và vị trí 12 base, đúng một điểm spawn/cổng/ba hình nộm, code trong map khớp source.

**Chưa xác nhận:** mở và Play trong Roblox Studio, cảm giác búa/camera/lướt, đường đi pet, đường vào/ra cổng, hoạt động nhiều client và hiệu năng 12 người. Công cụ điều khiển cửa sổ bị lỗi nhập liệu/foreground; không coi các kiểm tra ngoài engine là bằng chứng Play đã đạt. Checklist thao tác đầy đủ ở README.

**Tiếp tục đúng chỗ đang dở:** mở HunDino_L0.rbxlx → Play → sửa lỗi đỏ nếu có → thử vòng sảnh/cổng/búa/hình nộm/pet → lấy ý kiến về bố cục → cải thiện map/hoạt ảnh. Tái sử dụng source hiện có. Không chạy lại trình dựng map nếu đang có sửa thủ công chưa được lưu riêng; không thay map đang làm bằng template Rojo trống.

### 25.5. File làm việc

- Thư mục dự án đang làm: C:/Users/khanh/OneDrive/Documents/ChatGPT/game roblox/HunDino.
- Map phát triển: HunDino_L0.rbxlx. Map nguồn bảo toàn: HunDino_original.rbxl. Bản Desktop HunDino1.rbxl vẫn giữ nguyên.
- Hồ sơ trong thư mục HunDino là bản dùng cùng code; bản THIET_KE_GAME.md ở thư mục cha được đồng bộ cùng nội dung v0.22 lần này. Các lần cập nhật sau cần giữ hai bản khớp, tránh đọc nhầm bản cũ ở Desktop.
- Chỉ source mới trong Training.server.luau, Training.client.luau, TrainingConfig.luau, CombatRules.luau được dùng cho L0; script chào mẫu cũ không có gameplay.
- Không có dữ liệu lưu tài khoản; base, trang bị mẫu, sát thương tập và thể lực đều chỉ trong phiên. Không có tài sản kiếm được hoặc trao thưởng nên không liên quan bảo toàn chiến lợi phẩm của P1.

### 25.6. Cập nhật phạm vi luyện tập v2.2 — 07/10/2026

Theo yêu cầu mới của người dùng, mở rộng bãi tập và đưa cả bảy vũ khí tại mục 18 vào để lựa chọn, thử đòn trên hình nộm. Giới hạn búa đầu tiên ở L0/P1 trước đây là lịch sử triển khai; không còn giới hạn bộ vũ khí của **bãi tập v2.2**.

- Bãi tập 460 × 420 studs, sân võ ba hình nộm, bốn làn cung 30/60/90/120 studs, nhà vũ khí, giá giáp, hồ/cây/đèn trang trí và cổng đi/về. Sảnh giữ 12 base.
- Bảy mẫu: búa, kiếm & khiên, katana, thương cán dài, song dao, cung, rìu đại hai lưỡi. Có mô hình, thường/mạnh/kỹ năng, thể lực và nhịp riêng. Búa giữ chuỗi thử thường → mạnh → kỹ năng kết thúc. Cung có ngắm và buff một mũi sau ngắm/lướt.
- I chọn vũ khí khi đang cất và ở bãi tập; R rút/cất, chuột trái/Q/E đánh, V nhảy, Space lướt, G tương tác. Kiếm & khiên dùng F giữ thế đỡ thử; chưa có giảm sát thương từ địch vì bãi chưa có địch tấn công.
- Thông số/hoạt ảnh này phục vụ thử nghiệm, không tự chốt combo đầy đủ, cân bằng, cơ chế kỹ năng cuối hoặc kiến trúc nhiệm vụ săn. Trang bị/giáp/pet vẫn chưa có dữ liệu lưu tài khoản.
- File đang phát triển: **HunDino_DarkJungle_v2_2.rbxlx trên Desktop/game roblox/HunDino**. Source hiện hành ở Documents/ChatGPT/game roblox/HunDino; xem TRAINING_SANCTUARY.md để đọc kết quả kiểm tra và cách cập nhật an toàn. Không dùng bản L0 hoặc đồng bộ cấu hình Rojo cũ vào map mới.

### 25.7. Tiếp tục bản người dùng v2.3 — 08/10/2026

- File làm việc mới: **HunDino_DarkJungle_v2_3.rbxl** tại Desktop/game roblox/HunDino, do người dùng lưu từ v2.2. Tiếp tục nội dung hiện có, không dựng lại map hoặc quay về L0.
- Giữ bãi tập lớn, bảy vũ khí, giáp/pet mẫu và camera cung lệch vai. Ngắm chuyển mượt, tâm giữa màn hình trùng tia bắn; R cất cung hoặc Shift chạy sẽ hủy ngắm. Menu Esc được nhả chuột.
- Dùng định dạng Roblox Place `.rbxl` cho bản chỉnh tiếp: bản XML cũ có trường hợp bảng tiếng Việt bị đổi mã khi Studio lưu. Source và hướng dẫn hiện hành ở Documents/ChatGPT/game roblox/HunDino. Mọi thông số vũ khí vẫn chỉ là thử nghiệm.
