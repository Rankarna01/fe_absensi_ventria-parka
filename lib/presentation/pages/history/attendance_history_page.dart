import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart'; // Untuk URL gambar
import '../../../data/services/attendance_service.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final AttendanceService _service = AttendanceService();
  
  // Future untuk menampung data
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _service.getHistory();
  }

  // Fungsi Refresh tarik ke bawah
  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _service.getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text(
          "Riwayat Absensi", 
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Center(child: Text("Gagal memuat data", style: GoogleFonts.poppins()));
            }

            // 3. Empty State
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text("Belum ada riwayat absensi", style: GoogleFonts.poppins(color: Colors.grey)),
                  ],
                ),
              );
            }

            // 4. Data Ada -> Tampilkan List
            final data = snapshot.data!;
            
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final isCheckIn = item['type'] == 'IN';

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    // FOTO BUKTI
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        "${ApiConstants.baseUrl}/${item['photo_url']}",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 50, height: 50, 
                          color: Colors.grey[200], 
                          child: const Icon(Icons.broken_image, size: 20)
                        ),
                      ),
                    ),
                    
                    // DETAIL ABSEN
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['date'], 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCheckIn ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isCheckIn ? "MASUK" : "PULANG",
                            style: GoogleFonts.poppins(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              color: isCheckIn ? AppColors.success : AppColors.error
                            ),
                          ),
                        )
                      ],
                    ),
                    
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 5),
                          Text(
                            item['time'], 
                            style: GoogleFonts.poppins(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.w600)
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}