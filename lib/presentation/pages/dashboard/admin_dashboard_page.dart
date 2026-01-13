import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; // [IMPORT BARU]

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../auth/login_page.dart';
import '../admin/set_location_page.dart'; 
import '../admin/employee_list_page.dart'; 
import '../admin/attendance_report_page.dart';
import '../admin/leave_approval_page.dart';
import '../admin/office_settings_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Variabel Data Stats (Default 0)
  int _totalEmployees = 0;
  int _totalPresent = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  // Fetch Data dari API
  Future<void> _fetchDashboardStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("${ApiConstants.baseUrl}/admin/get_dashboard_stats.php"));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _totalEmployees = int.parse(data['data']['total_employees'].toString());
            _totalPresent = int.parse(data['data']['total_present'].toString());
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      setState(() => _isLoading = false);
    }
  }

  // Fungsi Logout
  void _logout() {
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
      
      // --- 1. SIDEBAR MENU (DRAWER) ---
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Header Sidebar
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              accountName: Text("Super Admin", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              accountEmail: Text("admin@kantor.com", style: GoogleFonts.poppins()),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 40),
              ),
            ),
            
            // Menu Items
            _buildDrawerItem(Icons.dashboard, "Dashboard", true, () {
              Navigator.pop(context); 
            }),
            _buildDrawerItem(Icons.people, "Data Pegawai", false, () {
               Navigator.pop(context); 
               Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeListPage()));
            }),
            _buildDrawerItem(Icons.location_on, "Lokasi Kantor", false, () {
               Navigator.pop(context); 
               Navigator.push(context, MaterialPageRoute(builder: (context) => const SetLocationPage()));
            }),
            _buildDrawerItem(Icons.playlist_add_check, "Persetujuan Izin", false, () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveApprovalPage()));
            }),
            _buildDrawerItem(Icons.description, "Laporan Absensi", false, () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceReportPage()));
            }),
            _buildDrawerItem(Icons.settings, "Pengaturan Jam Kerja", false, () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => const OfficeSettingsPage()));
            }),
            
            const Spacer(),
            const Divider(),
            _buildDrawerItem(Icons.logout, "Keluar", false, _logout, color: AppColors.error),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // --- 2. HEADER & APP BAR ---
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Admin Panel", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _fetchDashboardStats, 
            icon: const Icon(Icons.refresh, color: Colors.white)
          )
        ],
      ),

      // --- 3. DASHBOARD CONTENT ---
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchDashboardStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ringkasan Hari Ini", 
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)
                  ),
                  const SizedBox(height: 15),

                  // A. Grid Statistik Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard("Total Pegawai", "$_totalEmployees", Icons.people_outline, Colors.blue),
                      _buildStatCard("Hadir Hari Ini", "$_totalPresent", Icons.check_circle_outline, AppColors.success),
                      _buildStatCard("Belum Hadir", "${_totalEmployees - _totalPresent}", Icons.access_time, AppColors.accent),
                      _buildStatCard("Izin / Sakit", "0", Icons.note_alt_outlined, Colors.orange), // Update logic if needed
                    ],
                  ),

                  const SizedBox(height: 25),

                  // B. GRAFIK CHART (PIE CHART) [BARU]
                  Text(
                    "Persentase Kehadiran", 
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)
                  ),
                  const SizedBox(height: 15),
                  _buildAttendanceChart(),

                  const SizedBox(height: 30),

                  // C. Aktivitas Terbaru
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Aktivitas Terbaru", 
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)
                      ),
                      TextButton(
                        onPressed: (){}, 
                        child: Text("Lihat Semua", style: GoogleFonts.poppins(color: AppColors.primary))
                      )
                    ],
                  ),
                  
                  // List Item Contoh (Placeholder)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2)
                        )
                      ]
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondary, 
                        child: Icon(Icons.person, color: Colors.grey[600])
                      ),
                      title: Text("Budi Santoso", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text("Check-In • 07:55 WIB", style: GoogleFonts.poppins(fontSize: 12)),
                      trailing: const Chip(
                        label: Text("Tepat Waktu", style: TextStyle(color: Colors.white, fontSize: 10)),
                        backgroundColor: AppColors.success,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  // --- WIDGET CHART BARU ---
  Widget _buildAttendanceChart() {
    // Hitung persentase
    int absent = _totalEmployees - _totalPresent;
    // Hindari division by zero
    double presentPercent = _totalEmployees == 0 ? 0 : (_totalPresent / _totalEmployees) * 100;
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Row(
        children: [
          // 1. GRAFIK LINGKARAN
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: [
                      // Bagian Hadir (Hijau)
                      PieChartSectionData(
                        color: AppColors.success,
                        value: _totalPresent.toDouble(),
                        title: "${presentPercent.toStringAsFixed(0)}%",
                        radius: 50,
                        titleStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      // Bagian Belum Hadir (Abu-abu/Merah Muda)
                      PieChartSectionData(
                        color: AppColors.secondary, // atau Colors.red[100]
                        value: absent.toDouble(),
                        title: "",
                        radius: 40,
                      ),
                    ],
                  ),
                ),
                // Text di tengah Donat
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Total", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                    Text("$_totalEmployees", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(width: 20),

          // 2. KETERANGAN (LEGEND)
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(color: AppColors.success, label: "Hadir", value: "$_totalPresent"),
                const SizedBox(height: 15),
                _buildLegendItem(color: AppColors.secondary, label: "Belum Hadir", value: "$absent"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label, required String value}) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        )
      ],
    );
  }

  // --- WIDGET DRAWER & STATS LAMA ---

  Widget _buildDrawerItem(IconData icon, String title, bool isActive, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? (isActive ? AppColors.primary : Colors.grey)),
      title: Text(
        title, 
        style: GoogleFonts.poppins(
          color: color ?? (isActive ? AppColors.primary : Colors.black87),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal
        )
      ),
      selected: isActive,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1), 
      onTap: onTap,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value, 
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              Text(
                title, 
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)
              ),
            ],
          )
        ],
      ),
    );
  }
}