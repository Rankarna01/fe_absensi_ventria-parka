class ApiConstants {
  static const String baseUrl = "https://lawngreen-crab-623963.hostingersite.com";

  
  static const String login = "$baseUrl/auth/login.php";
  static const String updateProfile = "$baseUrl/auth/update_profile.php";
  
  // Attendance
  static const String checkIn = "$baseUrl/attendance/checkin.php"; 
  static const String checkOut = "$baseUrl/attendance/checkout.php";
  static const String history = "$baseUrl/attendance/history.php"; 
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