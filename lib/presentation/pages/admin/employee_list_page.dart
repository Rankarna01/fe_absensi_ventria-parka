import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/admin_service.dart';
import 'add_employee_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final AdminService _service = AdminService();
  late Future<List<dynamic>> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _employeesFuture = _service.getEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text("Data Pegawai", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // TOMBOL TAMBAH PEGAWAI
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // Buka halaman tambah, dan tunggu hasilnya
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AddEmployeePage())
          );
          
          // Jika berhasil nambah (return true), refresh list
          if (result == true) {
            _refreshData();
          }
        },
      ),

      body: FutureBuilder<List<dynamic>>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data pegawai"));
          }

          final employees = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.secondary,
                      child: Text(
                        emp['name'][0].toUpperCase(), 
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${emp['position']} • ${emp['department']}", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                          Text("NIP: ${emp['nip']}", style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: () {
                        // Nanti bisa tambah fitur Edit/Hapus disini
                      },
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}