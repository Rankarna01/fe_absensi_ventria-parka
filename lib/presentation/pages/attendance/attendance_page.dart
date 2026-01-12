import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/attendance_service.dart';
import '../dashboard/user_dashboard_page.dart';

class AttendancePage extends StatefulWidget {
  final String attendanceType; // "IN" atau "OUT"

  const AttendancePage({super.key, required this.attendanceType});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraReady = false;
  bool _isLoading = false;
  Position? _currentPosition;
  final AttendanceService _service = AttendanceService();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _getCurrentLocation();
  }

  // 1. Inisialisasi Kamera Depan
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    // Cari kamera depan
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) {
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  // 2. Ambil Lokasi GPS
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    if (mounted) {
      setState(() => _currentPosition = position);
    }
  }

  // 3. Proses Absen (Jepret & Kirim)
  Future<void> _submitAttendance() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sedang mencari lokasi... Tunggu sebentar."), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // A. Ambil Foto
      final image = await _controller!.takePicture();
      
      // B. Kirim ke Backend
      final result = await _service.submitAttendance(
        type: widget.attendanceType,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photoFile: File(image.path),
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (!mounted) return;
        // Sukses -> Balik ke Dashboard & Refresh
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Berhasil Absen ${widget.attendanceType}!"), backgroundColor: AppColors.success),
        );
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const UserDashboardPage())
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(result['message']), backgroundColor: AppColors.error),
        );
      }

    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 1: KAMERA FULL SCREEN
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_controller!),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),

          // LAYER 2: OVERLAY GUIDANCE (BINGKAI WAJAH)
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Pastikan wajah terlihat jelas",
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ),

          // LAYER 3: INFO LOKASI & TOMBOL ACTION
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info Lokasi
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Lokasi Anda", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                            Text(
                              _currentPosition != null 
                                ? "${_currentPosition!.latitude}, ${_currentPosition!.longitude}"
                                : "Mencari GPS...",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tombol Jepret
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.attendanceType == 'IN' ? AppColors.success : AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                "AMBIL FOTO & ${widget.attendanceType == 'IN' ? 'CHECK IN' : 'CHECK OUT'}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, color: Colors.white
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BACK BUTTON
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          )
        ],
      ),
    );
  }
}