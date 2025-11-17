import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../services/supabase_service.dart';
import 'voting_screen.dart';
import 'login_selector_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nisnController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  bool isLoading = false;

  void _login() async {
    final nisn = nisnController.text.trim();
    final nama = namaController.text.trim();

    if (nisn.isEmpty || nama.isEmpty) {
      _showMessage("NISN dan Nama tidak boleh kosong", ContentType.warning);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('nisn', nisn)
          .eq('nama_lengkap', nama)
          .maybeSingle();

      if (response == null) {
        _showMessage("Data tidak ditemukan. Periksa kembali.", ContentType.failure);
      } else {
        _showMessage("Login berhasil!", ContentType.success);
        Future.delayed(const Duration(milliseconds: 1200), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => VotingScreen(nisn: nisn)),
          );
        });
      }
    } catch (e) {
      _showMessage("Login gagal: ${e.toString()}", ContentType.failure);
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String msg, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      content: AwesomeSnackbarContent(
        title: type == ContentType.success
            ? 'Berhasil'
            : type == ContentType.failure
                ? 'Gagal'
                : 'Perhatian',
        message: msg,
        contentType: type,
      ),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginSelectorScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -120,
                left: -100,
                child: _buildGlowCircle(Colors.cyanAccent.withOpacity(0.3), 300),
              ),
              Positioned(
                bottom: -130,
                right: -100,
                child: _buildGlowCircle(Colors.blueAccent.withOpacity(0.25), 280),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElasticIn(
                          duration: const Duration(milliseconds: 1000),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.6),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Login Siswa',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Voting Ketua OSIS SMPN 7 Prabumulih',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  SlideInLeft(
                                    duration: const Duration(milliseconds: 700),
                                    child: _buildInputField(
                                      controller: nisnController,
                                      hint: 'Masukkan NISN',
                                      icon: Icons.perm_identity_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SlideInRight(
                                    duration: const Duration(milliseconds: 700),
                                    child: _buildInputField(
                                      controller: namaController,
                                      hint: 'Masukkan Nama Lengkap',
                                      icon: Icons.person_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SlideInUp(
                                    duration: const Duration(milliseconds: 700),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: isLoading ? null : _login,
                                        icon: const Icon(Icons.login_rounded),
                                        label: isLoading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Masuk',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          backgroundColor: const Color(0xFF06B6D4),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
        ),
      ),
    );
  }
}
