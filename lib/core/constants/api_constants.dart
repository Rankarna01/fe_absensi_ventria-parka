class ApiConstants {
  // Ganti dengan IP Address laptopmu jika pakai Emulator (jangan localhost)
  // Contoh: http://192.168.1.5/absensi_api
  static const String baseUrl = "http://localhost/absensi_api";
  
  // Endpoints
  static const String login = "$baseUrl/auth/login.php";
  static const String checkIn = "$baseUrl/attendance/checkin.php";
  static const String checkOut = "$baseUrl/attendance/checkout.php";
  static const String history = "$baseUrl/attendance/history.php";
}