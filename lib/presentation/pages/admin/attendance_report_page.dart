import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/admin_service.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  final AdminService _service = AdminService();
  DateTime _selectedDate = DateTime.now();
  late Future<List<dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    // Format tanggal ke YYYY-MM-DD untuk API
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      _reportFuture = _service.getAttendanceReport(formattedDate);
    });
  }

  // Fungsi Memilih Tanggal
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData(); // Refresh data sesuai tanggal baru
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text("Laporan Absensi", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          )
        ],
      ),
      body: Column(
        children: [
          // --- HEADER TANGGAL ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Menampilkan Data:", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _pickDate, 
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text("Ubah"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    elevation: 0
                  ),
                )
              ],
            ),
          ),
          
          // --- LIST ABSENSI ---
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("Tidak ada data absensi pada tanggal ini.", style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final isCheckIn = item['type'] == 'IN';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        // Foto User
                        leading: GestureDetector(
                          onTap: () {
                             // Nanti bisa tambah fitur zoom foto jika diklik
                             showDialog(context: context, builder: (_) => Dialog(
                               child: Image.network("${ApiConstants.baseUrl}/${item['photo_url']}"),
                             ));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              "${ApiConstants.baseUrl}/${item['photo_url']}",
                              width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => Container(color: Colors.grey[200], width: 50, height: 50, child: const Icon(Icons.person)),
                            ),
                          ),
                        ),
                        
                        // Nama & NIP
                        title: Text(item['user_name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nip'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCheckIn ? Colors.green[50] : Colors.red[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isCheckIn ? Colors.green : Colors.red, width: 0.5)
                                  ),
                                  child: Text(
                                    isCheckIn ? "MASUK" : "PULANG",
                                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: isCheckIn ? Colors.green : Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(item['time'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                        
                        // Status (Ontime/Late)
                        trailing: item['status'] == 'ontime' 
                          ? const Icon(Icons.check_circle, color: AppColors.success)
                          : const Icon(Icons.warning, color: Colors.orange),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}