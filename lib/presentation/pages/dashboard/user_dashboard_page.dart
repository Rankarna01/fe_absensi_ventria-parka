import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../history/attendance_history_page.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/login_page.dart';
import '../profile/profile_page.dart';
import '../leaves/leave_page.dart';
import '../../../data/services/attendance_service.dart';
import '../attendance/attendance_page.dart'; // Pastikan path ini benar

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  // Variabel Data User
  String _userName = "Loading...";
  String _userJob = "Loading...";
  
  // Variabel Status Absensi
  final AttendanceService _attendanceService = AttendanceService();
  bool _isCheckIn = false; // false = Belum masuk (Tombol Hijau), true = Sudah masuk (Tombol Merah)
  String _timeIn = "--:--";
  String _timeOut = "--:--";
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkTodayStatus(); // Cek status saat halaman dibuka
  }

  // 1. Ambil data user dari Shared Preferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');
    
    if (userDataString != null) {
      final Map<String, dynamic> user = jsonDecode(userDataString);
      if (mounted) {
        setState(() {
          _userName = user['name'];
          _userJob = user['position'] ?? 'Karyawan'; // Default jika null
        });
      }
    }
  }

  // 2. Cek Status Absen Hari Ini ke API
  Future<void> _checkTodayStatus() async {
    if (!mounted) return;
    setState(() => _isLoadingStatus = true);

    final result = await _attendanceService.getTodayStatus();
    
    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          _isCheckIn = data['is_check_in'] ?? false;
          _timeIn = data['time_in'] ?? "--:--";
          _timeOut = data['time_out'] ?? "--:--";
        }
        _isLoadingStatus = false;
      });
    }
  }

  // 3. Fungsi Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const LoginPage()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: RefreshIndicator(
        onRefresh: _checkTodayStatus, // Pull to Refresh
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- HEADER SECTION (Navy Blue) ---
              Container(
                height: 250,
                padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Top Bar: Info User & Logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Halo, $_userName",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _userJob,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            // UPDATE: withValues
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: _logout,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Tanggal Hari Ini
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('HH:mm').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
      
              // --- MAIN CONTENT (Overlapping) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // 1. STATUS CARD (Absensi Hari Ini)
                    Transform.translate(
                      offset: const Offset(0, -40), // Efek Overlap ke atas
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              // UPDATE: withValues
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: _isLoadingStatus 
                          ? const Center(child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: LinearProgressIndicator(),
                            ))
                          : Row(
                              children: [
                                // Jam Masuk
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.login, color: AppColors.success, size: 28),
                                      const SizedBox(height: 8),
                                      Text("Masuk", style: GoogleFonts.poppins(color: Colors.grey)),
                                      Text(
                                        _timeIn, 
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                                // Divider Vertical
                                Container(width: 1, height: 40, color: Colors.grey[300]),
                                // Jam Pulang
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.logout, color: AppColors.error, size: 28),
                                      const SizedBox(height: 8),
                                      Text("Pulang", style: GoogleFonts.poppins(color: Colors.grey)),
                                      Text(
                                        _timeOut, 
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
      
                    // 2. TOMBOL BESAR (Primary CTA)
                    // Logika: 
                    // - Jika Belum Masuk -> Tombol Hijau (Check In)
                    // - Jika Sudah Masuk -> Tombol Merah (Check Out)
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _isLoadingStatus ? null : () {
                        // Tentukan Tipe Absen berdasarkan Status tombol
                        String type = _isCheckIn ? "OUT" : "IN";
                        
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => AttendancePage(attendanceType: type)
                          )
                        ).then((_) {
                           // Refresh data saat kembali dari halaman kamera
                           _checkTodayStatus();
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120, // Ukuran Besar
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isCheckIn 
                                ? [const Color(0xFFEF5350), const Color(0xFFD32F2F)] // Merah
                                : [const Color(0xFF66BB6A), const Color(0xFF43A047)], // Hijau
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              // UPDATE: withValues
                              color: _isCheckIn 
                                  ? Colors.red.withValues(alpha: 0.3) 
                                  : Colors.green.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fingerprint, 
                              size: 40, 
                              // UPDATE: withValues
                              color: Colors.white.withValues(alpha: 0.9)
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isCheckIn ? "CHECK OUT (PULANG)" : "CHECK IN (MASUK)",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              _isCheckIn ? "Waktunya istirahat" : "Selamat bekerja!",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
      
                    const SizedBox(height: 30),
      
                    // 3. MENU GRID (Riwayat, Profil, dll)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMenuCard(
                          icon: Icons.history, 
                          label: "Riwayat", 
                          color: Colors.blueAccent,
                          onTap: () {
                            // NAVIGASI KE HALAMAN HISTORY
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => const AttendanceHistoryPage())
                            );
                          }
                        ),
                       _buildMenuCard(
                          icon: Icons.assignment_ind, 
                          label: "Izin/Cuti", 
                          color: Colors.orangeAccent,
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => const LeavePage())
                            );
                          }
                        ),
                        _buildMenuCard(
                          icon: Icons.person, 
                          label: "Profil", 
                          color: AppColors.primary,
                          onTap: () {
                            // NAVIGASI KE PROFILE PAGE
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => const ProfilePage())
                            ).then((_) {
                              // Refresh Data Dashboard jika nama user berubah
                              _loadUserData();
                            });
                          }
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50), // Spasi bawah agar scroll enak
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk Menu Kecil
  Widget _buildMenuCard({
    required IconData icon, 
    required String label, 
    required Color color,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
              // UPDATE: withValues
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // UPDATE: withValues
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12, 
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary
              ),
            ),
          ],
        ),
      ),
    );
  }
}