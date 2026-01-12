import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import untuk format tanggal Indonesia
import 'package:intl/date_symbol_data_local.dart'; 

import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';

// Import Halaman Dashboard
import '../dashboard/user_dashboard_page.dart';
import '../dashboard/admin_dashboard_page.dart'; // Pastikan file ini ada

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscure = true; 

  final AuthService _authService = AuthService();

  Future<void> _handleLogin() async {
    // 1. Validasi Input Kosong
    if (_nipController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIP dan Password harus diisi"), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Panggil API Login
    final result = await _authService.login(
      _nipController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    // 3. Cek Hasil Login
    if (result['success'] == true) {
      if (!mounted) return;
      
      // A. Inisialisasi Locale (PENTING: Agar tidak error tanggal di dashboard)
      await initializeDateFormatting('id_ID', null);

      // B. Cek Role User (Admin atau User Biasa)
      // Pastikan backend mengirim field 'role' di dalam object 'data'
      String role = result['data']['role']; 

      if (!mounted) return;

      if (role == 'admin') {
        // -> Masuk ke Dashboard Admin
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const AdminDashboardPage())
        );
      } else {
        // -> Masuk ke Dashboard User (Karyawan)
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const UserDashboardPage())
        );
      }

    } else {
      // Login Gagal
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER (Navy Blue) ---
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined, size: 80, color: AppColors.accent),
                  const SizedBox(height: 10),
                  Text(
                    "Absensi App",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Face & Location Detection",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // --- FORM LOGIN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Silakan Masuk",
                      style: GoogleFonts.poppins(
                        color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w600
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Input NIP
                    TextField(
                      controller: _nipController,
                      decoration: InputDecoration(
                        labelText: "NIP Karyawan",
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Input Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          "Lupa Password?", 
                          style: GoogleFonts.poppins(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tombol Login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "LOGIN",
                              style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Text(
              "Versi 1.0.0",
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}