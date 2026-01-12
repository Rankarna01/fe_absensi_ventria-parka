import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/admin_service.dart';

class LeaveApprovalPage extends StatefulWidget {
  const LeaveApprovalPage({super.key});

  @override
  State<LeaveApprovalPage> createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
  final AdminService _service = AdminService();
  late Future<List<dynamic>> _pendingLeavesFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _pendingLeavesFuture = _service.getPendingLeaves();
    });
  }

  // Fungsi Proses Approval
  Future<void> _processLeave(int id, String status) async {
    // Tampilkan konfirmasi dialog dulu
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text(status == 'approved' ? "Setujui Izin?" : "Tolak Izin?"),
        content: Text(status == 'approved' 
          ? "Karyawan akan menerima notifikasi disetujui." 
          : "Pengajuan ini akan ditolak."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text("Ya, Lanjutkan", style: TextStyle(color: status == 'approved' ? AppColors.success : AppColors.error))
          ),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    // Loading indicator sederhana
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memproses...")));

    final success = await _service.updateLeaveStatus(id, status);

    if (success) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Berhasil ${status == 'approved' ? 'Disetujui' : 'Ditolak'}"), backgroundColor: AppColors.success)
      );
      _refreshData(); // Refresh list agar item hilang
    } else {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memproses"), backgroundColor: AppColors.error)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text("Persetujuan Izin", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _pendingLeavesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Tidak ada pengajuan pending.", style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          final leaves = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final item = leaves[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Nama & Jabatan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("${item['position']} • NIP: ${item['nip']}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item['type'].toString().toUpperCase(),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accent),
                            ),
                          )
                        ],
                      ),
                      
                      const Divider(height: 20),
                      
                      // Detail Izin
                      _buildInfoRow(Icons.calendar_today, "${item['start_date']}  s/d  ${item['end_date']}"),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.notes, item['reason']),
                      
                      // Jika ada bukti foto
                      if (item['attachment_url'] != null && item['attachment_url'] != "")
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: InkWell(
                            onTap: () {
                              showDialog(context: context, builder: (_) => Dialog(
                                child: Image.network("${ApiConstants.baseUrl}/${item['attachment_url']}"),
                              ));
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.image, size: 16, color: Colors.blue),
                                const SizedBox(width: 5),
                                Text("Lihat Bukti Foto", style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12, decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Tombol Aksi (Approve / Reject)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _processLeave(int.parse(item['id']), 'rejected'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                foregroundColor: AppColors.error,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                              child: const Text("TOLAK"),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _processLeave(int.parse(item['id']), 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                              child: const Text("SETUJUI"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87))),
      ],
    );
  }
}