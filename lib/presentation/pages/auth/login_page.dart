import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
// import '../dashboard/dashboard_page.dart'; // Nanti kita buat ini

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller untuk input text
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscure = true; // Untuk sembunyikan password

  final AuthService _authService = AuthService();

  // Fungsi saat tombol Login ditekan
  Future<void> _handleLogin() async {
    if (_nipController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIP dan Password harus diisi"), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(
      _nipController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Login Sukses
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Berhasil!"), backgroundColor: AppColors.success),
      );
      
      // Navigasi ke Dashboard (Sementara kita print dulu sebelum file dashboard dibuat)
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
      print("Navigasi ke Dashboard User: ${result['data']['name']}");

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
            // 1. Header Bagian Atas (Navy Blue)
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
                  // Icon atau Logo
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
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Form Login
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
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Input NIP
                    TextField(
                      controller: _nipController,
                      decoration: InputDecoration(
                        labelText: "NIP Karyawan",
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        onPressed: () {
                          // Fitur Lupa Password bisa ditambahkan nanti
                        },
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "LOGIN",
                              style: GoogleFonts.poppins(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Pastikan teks putih
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer text
            Text(
              "Versi 1.0.0",
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}