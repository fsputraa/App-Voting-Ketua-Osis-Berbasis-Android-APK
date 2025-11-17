import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'rekap_voting_screen.dart';
import 'admin_crud_kandidat_screen.dart';
import 'admin_crud_users_screen.dart';
import 'admin_crud_admins_screen.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('users')
          .select('id, nisn, nama_lengkap, sudah_memilih')
          .order('nama_lengkap', ascending: true); // FIXED: A-Z sort
      setState(() {
        users = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }
  }

  Future<void> showExitConfirmationDialog() async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.bottomSlide,
      dismissOnTouchOutside: false,
      dialogBackgroundColor: const Color(0xFF1E1B2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      dialogBorderRadius: BorderRadius.circular(20),
      headerAnimationLoop: false,
      customHeader: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ],
        ),
        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 36),
      ),
      title: 'Keluar dari Akun',
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      desc: 'Yakin ingin keluar dari akun ini?',
      descTextStyle: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade300,
      ),
      btnCancelOnPress: () {},
      btnCancelIcon: Icons.close,
      btnCancelText: 'Batal',
      btnCancelColor: Colors.grey.shade700,
      btnOkOnPress: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          (route) => false,
        );
      },
      btnOkIcon: Icons.logout_rounded,
      btnOkText: 'Keluar',
      btnOkColor: Colors.deepPurple,
    ).show();
  }

  Future<bool> onWillPop() async {
    showExitConfirmationDialog();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final total = users.length;
    final sudahMemilih = users.where((u) => u['sudah_memilih'] == true).length;
    final belumMemilih = total - sudahMemilih;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text("Dashboard Admin"),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: fetchUsers,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Data',
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: Colors.black87,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.deepPurple),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.setting_2, size: 40, color: Colors.white),
                    SizedBox(height: 12),
                    Text('Admin Panel',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              _drawerTile(Iconsax.element_3, 'Dashboard', () => Navigator.pop(context)),
              _drawerTile(Iconsax.shield_tick, 'Manajemen Admin', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCrudAdminsScreen()));
              }),
              _drawerTile(Iconsax.user_tag, 'Manajemen Siswa', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCrudUsersScreen()));
              }),
              _drawerTile(Iconsax.profile_2user, 'Manajemen Kandidat', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCrudKandidatScreen()));
              }),
              _drawerTile(Iconsax.diagram, 'Rekap Voting', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RekapVotingScreen()));
              }),
              const Divider(color: Colors.white30),
              ListTile(
                leading: const Icon(Iconsax.logout, color: Colors.redAccent),
                title: const Text('Keluar', style: TextStyle(color: Colors.redAccent)),
                onTap: showExitConfirmationDialog,
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : users.isEmpty
                ? const Center(
                    child: Text("Belum ada data siswa.",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeInDown(
                              child: Row(
                                children: [
                                  _infoBox("Total Siswa", total, Colors.blueAccent),
                                  _infoBox("Sudah Memilih", sudahMemilih, Colors.greenAccent),
                                  _infoBox("Belum Memilih", belumMemilih, Colors.pinkAccent),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeInRight(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RekapVotingScreen()),
                                  );
                                },
                                icon: const Icon(Iconsax.activity),
                                label: const Text("Lihat Rekap Voting"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          itemBuilder: (_, i) {
                            final user = users[i];
                            return FadeInUp(
                              delay: Duration(milliseconds: 70 * i),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.deepPurple,
                                      child: Icon(Iconsax.user, color: Colors.white),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['nama_lengkap'] ?? '-',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "NISN: ${user['nisn'] ?? '-'}",
                                            style: const TextStyle(
                                                color: Colors.white60, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: user['sudah_memilih'] == true
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        user['sudah_memilih'] == true
                                            ? "Sudah Memilih"
                                            : "Belum Memilih",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  ListTile _drawerTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _infoBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
