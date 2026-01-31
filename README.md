# Pickleball Club Management System

Hệ thống quản lý câu lạc bộ Pickleball "Vợt Thủ Phố Núi"

## Mô tả

Dự án bao gồm:
- **PikApi**: ASP.NET Core Web API (Backend)
- **pik_app**: Flutter Mobile App (Frontend)

## Tính năng

### Member
- Đăng ký / Đăng nhập
- Quản lý ví điện tử (nạp tiền, xem lịch sử)
- Đặt sân pickleball
- Tham gia giải đấu
- Xem kết quả trận đấu real-time (SignalR)

### Admin
- Duyệt yêu cầu nạp tiền
- Tạo và quản lý giải đấu
- Bốc thăm chia cặp
- Cập nhật kết quả trận đấu
- Xem thống kê doanh thu

## Công nghệ sử dụng

### Backend
- ASP.NET Core 9
- Entity Framework Core
- SQL Server
- SignalR (Real-time)
- JWT Authentication

### Frontend
- Flutter 3.x
- Provider (State Management)
- Dio (HTTP Client)
- SignalR Client

## Hướng dẫn chạy

### Backend
```bash
cd PikApi
dotnet ef database update
dotnet run
```
API: http://localhost:5054/swagger

### Frontend
```bash
cd pik_app
flutter pub get
flutter run
```

## Tài khoản test

- **Admin**: admin@pcm.com / Admin@123

## Sinh viên

- MSSV: 1771020556
- Họ tên: Hải Quân
