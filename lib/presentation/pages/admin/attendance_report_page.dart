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

  // Variabel untuk status loading export
  bool _isExporting = false;

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

  // --- FITUR EXPORT EXCEL (CSV) ---

  // 1. Tampilkan Dialog Pilih Bulan/Tahun
  Future<void> _showExportDialog() async {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    await showDialog(
      context: context,
      builder: (context) {
        // Menggunakan StatefulBuilder agar dropdown bisa update state lokal dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Export Laporan Bulanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Pilih periode laporan yang ingin diunduh:", style: GoogleFonts.poppins(fontSize: 12)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Dropdown Bulan
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(DateFormat('MMMM', 'id_ID').format(DateTime(2024, index + 1, 1))),
                            );
                          }),
                          onChanged: (val) => setStateDialog(() => selectedMonth = val!),
                          decoration: const InputDecoration(labelText: "Bulan", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dropdown Tahun
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          items: [2024, 2025, 2026, 2027].map((y) {
                            return DropdownMenuItem(value: y, child: Text(y.toString()));
                          }).toList(),
                          onChanged: (val) => setStateDialog(() => selectedYear = val!),
                          decoration: const InputDecoration(labelText: "Tahun", border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    _processExport(selectedMonth, selectedYear); // Lanjut proses export
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("Download CSV", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  // 2. Proses Download & Buka File
  Future<void> _processExport(int m, int y) async {
    setState(() => _isExporting = true);
    
    // Tampilkan notif loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sedang mengunduh laporan... Mohon tunggu."), duration: Duration(seconds: 2))
    );

    // Panggil Service Export yang sudah dibuat di admin_service.dart
    final success = await _service.exportReport(m, y);

    setState(() => _isExporting = false);

    if (!success) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengunduh file atau data kosong."), backgroundColor: AppColors.error)
      );
    } 
    // Jika sukses, file otomatis terbuka oleh open_file di service layer
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
          // TOMBOL EXPORT BARU
          IconButton(
            icon: _isExporting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.download),
            tooltip: "Export Excel (CSV)",
            onPressed: _isExporting ? null : _showExportDialog,
          ),
          // TOMBOL PILIH TANGGAL (HARIAN)
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
                    Text("Menampilkan Data Harian:", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
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
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05), // FIX: withOpacity -> withValues
                              blurRadius: 5)
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        // Foto User
                        leading: GestureDetector(
                          onTap: () {
                             // Fitur zoom foto
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