class ApiConstants {
  // --- KONFIGURASI LIVE SERVER ---
  
  // Masukkan domain hosting kamu di sini.
  // PENTING: 
  // 1. Gunakan 'https://' karena hostingersite sudah support SSL (lebih aman).
  // 2. Jangan pakai slash '/' di paling ujung.
  
  // OPSI A: Jika kamu upload isi folder 'absensi_api' langsung ke 'public_html'
  static const String baseUrl = "https://lawngreen-crab-623963.hostingersite.com";

  // OPSI B: Jika kamu upload folder 'absensi_api' ke dalam 'public_html'
  // static const String baseUrl = "https://lawngreen-crab-623963.hostingersite.com/absensi_api";

  // --- ENDPOINTS (Jangan diubah) ---
  // Endpoint ini akan otomatis mengikuti baseUrl di atas.
  
  // Auth
  static const String login = "$baseUrl/auth/login.php";
  static const String updateProfile = "$baseUrl/auth/update_profile.php";
  
  // Attendance
  static const String checkIn = "$baseUrl/attendance/checkin.php"; // Perhatikan nama file di server (checkin/submit_attendance)
  static const String checkOut = "$baseUrl/attendance/checkout.php";
  static const String history = "$baseUrl/attendance/history.php"; // get_history.php?
  static const String submitAttendance = "$baseUrl/attendance/submit_attendance.php";
  static const String getTodayStatus = "$baseUrl/attendance/get_today_status.php";

  // Admin
  static const String dashboardStats = "$baseUrl/admin/get_dashboard_stats.php";
  static const String employeeList = "$baseUrl/admin/get_employees.php";
  static const String addEmployee = "$baseUrl/admin/add_employee.php";
  static const String officeSettings = "$baseUrl/admin/get_settings.php";
  static const String updateSettings = "$baseUrl/admin/update_settings.php";
  static const String pendingLeaves = "$baseUrl/admin/get_pending_leaves.php";
  static const String updateLeaveStatus = "$baseUrl/admin/update_leave_status.php";
  static const String attendanceReport = "$baseUrl/admin/get_attendance_report.php";
  static const String monthlyReport = "$baseUrl/admin/get_monthly_report.php";

  // Leaves (User)
  static const String submitLeave = "$baseUrl/leaves/submit_leave.php";
  static const String userLeaves = "$baseUrl/leaves/get_user_leaves.php";
}