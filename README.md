# Ứng dụng Trò chơi Di động: Card Saga

## 1. Tổng quan Dự án
Card Saga là một dự án phát triển ứng dụng trò chơi di động (mobile game).  
Trò chơi kết hợp giữa hai thể loại chính: lật thẻ ghi nhớ (card matching) và ghép hình (jigsaw puzzle) theo chủ đề.

Mục tiêu của trò chơi:
- Người chơi tham gia hành trình vượt qua các màn chơi (ải) trên bản đồ tiến trình.
- Thu thập Xu (Coins), Sao (Stars) và Mảnh ghép (Puzzle Pieces) để mở khóa các tính năng và chủ đề mới.

---

## 2. Lối chơi & Tính năng Cốt lõi

### A. Lối chơi Cơ bản (Core Gameplay Loop)
- Bản đồ & Ải: Lối chơi thiết kế theo dạng bản đồ tiến trình (giống Candy Crush Saga), mỗi nút tròn là một ải thử thách.
- Vượt ải: Trong mỗi ải, người chơi tìm và lật các cặp thẻ giống nhau trong thời gian giới hạn.
- Phần thưởng khi hoàn thành:
  - Xu: Tối đa 30 xu (dùng để mua vật phẩm).
  - Sao: Tối đa 3 sao (dựa trên thời gian hoàn thành).
  - Mảnh ghép: Nhận ngẫu nhiên 0–2 mảnh ghép.

---

### B. Hệ thống Tiến trình & Tùy chỉnh (Progression & Customization)
- Hệ thống Chủ đề (Themes):  
  Cung cấp nhiều chủ đề hình ảnh khác nhau (ví dụ: Mặc định, Trái cây, Cảm xúc) cho thẻ lật và hình ghép.

- Hệ thống Sao (Star System):  
  Sao hoạt động như điểm kinh nghiệm (XP) của người chơi.  
  Khi tích lũy đủ sao, người chơi mở khóa chủ đề mới trong cửa hàng.

- Tính năng Ghép hình (Puzzle):
  - Mỗi chủ đề có 1–2 bức hình để sưu tầm mảnh ghép.
  - Người chơi dùng mảnh ghép kiếm được từ các ải để hoàn thành bức hình.
  - Khi hoàn thành, có thể lưu hình ảnh về thiết bị cá nhân.

---

### C. Hệ thống Vật phẩm & Tiền tệ (Economy & Items)
- Hệ thống Xu (Coins):  
  Là đơn vị tiền tệ chính trong game.

- Cửa hàng (Shop):  
  - Mua vật phẩm hỗ trợ bằng Xu.  
  - Mở khóa chủ đề mới bằng Sao.

- Vật phẩm hỗ trợ (Support Items):
  - Đóng băng thời gian (50 xu): Tạm dừng đồng hồ đếm ngược.  
  - Nhân đôi xu thưởng (80 xu): Gấp đôi lượng xu nhận được khi thắng ải.

---

### D. Tính năng khác
- Đa ngôn ngữ (Multilanguage):  
  Hỗ trợ chuyển đổi nhanh giữa Tiếng Việt và Tiếng Anh bằng một nút bấm.

---

## 3. Yêu cầu hệ thống

- **Ngôn ngữ & Framework**
  - Dart >= 3.0.0
  - Flutter >= 3.10.0

- **Hệ điều hành phát triển**
  - Windows 11

- **IDE / Công cụ**
  - Android Studio/Visual Studio Code
  - Git để quản lý mã nguồn

- **Yêu cầu chạy ứng dụng**
  - **Android**: Android SDK 33+, thiết bị thật hoặc trình giả lập (AVD)
  - **Web** (tùy chọn): Trình duyệt Chrome mới nhất

---

## 4. Thành viên nhóm
- Thành viên: Nguyễn Ngọc Linh
- Thành viên: Lê Thị Ngọc Linh
- Thành viên: Vũ Thị Trang
