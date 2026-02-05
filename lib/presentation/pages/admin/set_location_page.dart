import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
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
  
  // Koordinat (Bisa dari Database atau GPS Baru)
  Position? _currentPosition;
  
  bool _isLoading = false;
  bool _isGettingLocation = false;

  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _fetchExistingLocation(); // <--- PANGGIL DATA SAAT PAGE DIBUKA
  }

  // FUNGSI BARU: Ambil data tersimpan
  Future<void> _fetchExistingLocation() async {
    final data = await _adminService.getOfficeLocation();
    if (data != null) {
      setState(() {
        _nameController.text = data['name'];
        _radiusController.text = data['radius_meter'].toString();
        // Buat objek Position palsu dari data DB agar UI update
        _currentPosition = Position(
          longitude: double.parse(data['longitude']),
          latitude: double.parse(data['latitude']),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0, 
          altitudeAccuracy: 0, 
          headingAccuracy: 0
        );
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izin lokasi ditolak"), backgroundColor: AppColors.error));
        setState(() => _isGettingLocation = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _isGettingLocation = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Lokasi GPS Terkini Berhasil Didapat!"), backgroundColor: Colors.blue)
      );

    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal ambil lokasi: $e"), backgroundColor: AppColors.error));
    }
  }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lokasi Kantor Diperbarui!"), backgroundColor: AppColors.success));
      // Tidak perlu pop agar admin bisa lihat hasil updatenya
    } else {
      if (!mounted) return;
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
            // CARD VISUALISASI
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
                  const Icon(Icons.location_on, size: 50, color: AppColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    "Titik Kantor Aktif",
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  
                  // Tampilkan Data
                  _currentPosition == null
                      ? Text("Belum disetting", style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic))
                      : Column(
                          children: [
                            Text(
                              "${_currentPosition!.latitude}, ${_currentPosition!.longitude}",
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                "Tersimpan",
                                style: GoogleFonts.poppins(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                  
                  const SizedBox(height: 20),
                  
                  // TOMBOL UPDATE GPS
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.my_location),
                      label: Text(_isGettingLocation ? "Mencari GPS..." : "Update dengan Posisi Saya Sekarang"),
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
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Nama Kantor",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.business, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Radius Toleransi (Meter)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.radar, color: AppColors.primary),
                helperText: "Jarak maksimal user bisa absen",
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
                    : Text("SIMPAN PERUBAHAN", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}