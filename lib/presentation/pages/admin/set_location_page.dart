import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Wajib install: flutter pub add geolocator
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/admin_service.dart';

class SetLocationPage extends StatefulWidget {
  const SetLocationPage({super.key});

  @override
  State<SetLocationPage> createState() => _SetLocationPageState();
}

class _SetLocationPageState extends State<SetLocationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(text: "100");
  
  // Variabel menyimpan lokasi Admin saat ini
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  final AdminService _adminService = AdminService();

  // 1. Fungsi Mengambil GPS Saat Ini
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    // Cek Izin Lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izin lokasi ditolak"), backgroundColor: AppColors.error));
        setState(() => _isGettingLocation = false);
        return;
      }
    }

    // Ambil Koordinat
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal ambil lokasi: $e"), backgroundColor: AppColors.error));
    }
  }

  // 2. Fungsi Simpan ke Database
  Future<void> _saveLocation() async {
    if (_currentPosition == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data belum lengkap!"), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);

    final result = await _adminService.addOfficeLocation(
      name: _nameController.text,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      radius: int.parse(_radiusController.text),
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lokasi Kantor Berhasil Disimpan!"), backgroundColor: AppColors.success));
      Navigator.pop(context); // Kembali ke dashboard admin
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text("Set Lokasi Kantor", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // CARD VISUALISASI LOKASI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.map_outlined, size: 50, color: AppColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    "Koordinat Saat Ini",
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  
                  // Tampilkan Latitude / Longitude
                  _currentPosition == null
                      ? Text("- , -", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold))
                      : Column(
                          children: [
                            Text(
                              "${_currentPosition!.latitude}",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${_currentPosition!.longitude}",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                  
                  const SizedBox(height: 20),
                  
                  // TOMBOL AMBIL LOKASI
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.my_location),
                      label: Text(_isGettingLocation ? "Mencari GPS..." : "Ambil Lokasi Saya Sekarang"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // FORM INPUT
            Text("Detail Kantor", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 15),

            // Input Nama
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Nama Kantor / Cabang",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.business, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 15),

            // Input Radius
            TextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Radius Toleransi (Meter)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.radar, color: AppColors.primary),
                helperText: "Jarak maksimal user bisa absen dari titik ini",
              ),
            ),

            const SizedBox(height: 30),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isLoading || _currentPosition == null) ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("SIMPAN SEBAGAI LOKASI SAH", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}