import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:votingosis_smpn7pbm/services/supabase_service.dart';

class AdminCrudUsersScreen extends StatefulWidget {
  const AdminCrudUsersScreen({super.key});

  @override
  State<AdminCrudUsersScreen> createState() => _AdminCrudUsersScreenState();
}

class _AdminCrudUsersScreenState extends State<AdminCrudUsersScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = false;

  final _nisnController = TextEditingController();
  final _namaController = TextEditingController();
  String? editingId;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    final response = await supabase.from('users').select().order('created_at');
    setState(() {
      users = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> addOrUpdateUser() async {
    final nisn = _nisnController.text.trim();
    final nama = _namaController.text.trim();
    if (nisn.isEmpty || nama.isEmpty) return;

    if (editingId != null) {
      await supabase.from('users').update({
        'nisn': nisn,
        'nama_lengkap': nama,
      }).eq('id', editingId);
    } else {
      await supabase.from('users').insert({
        'nisn': nisn,
        'nama_lengkap': nama,
        'sudah_memilih': false,
      });
    }

    Navigator.pop(context);
    _nisnController.clear();
    _namaController.clear();
    editingId = null;
    fetchUsers();
  }

  void showForm({Map<String, dynamic>? data}) {
    if (data != null) {
      editingId = data['id'];
      _nisnController.text = data['nisn'];
      _namaController.text = data['nama_lengkap'];
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4B0082), Color(0xFF1C1C1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurpleAccent.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FontAwesomeIcons.userGraduate, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  editingId != null ? 'Edit Siswa' : 'Tambah Siswa',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nisnController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle("NISN", FontAwesomeIcons.idCard),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _namaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle("Nama Lengkap", FontAwesomeIcons.user),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  Colors.pinkAccent.shade200,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(FontAwesomeIcons.floppyDisk, color: Colors.white),
                  label: const Text("Simpan", style: TextStyle(color: Colors.white)),
                  onPressed: addOrUpdateUser,
                )
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      _nisnController.clear();
      _namaController.clear();
      editingId = null;
    });
  }

  Future<void> deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              const Text("Konfirmasi Hapus",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              const Text("Yakin ingin menghapus siswa ini?",
                  style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                    child: const Text("Batal"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await supabase.from('users').delete().eq('id', id);
      fetchUsers();
    }
  }

  Future<void> resetVoting(String id) async {
    await supabase.from('users').update({'sudah_memilih': false}).eq('id', id);
    fetchUsers();
  }

  InputDecoration _inputStyle(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.deepPurple.shade700,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Manajemen Siswa", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade800,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => showForm(),
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            tooltip: "Tambah Siswa",
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : RefreshIndicator(
              onRefresh: fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    color: Colors.deepPurple.shade900.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 8,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        user['nama_lengkap'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("NISN: ${user['nisn']}", style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            "Status: ${user['sudah_memilih'] ? 'Sudah Memilih' : 'Belum Memilih'}",
                            style: TextStyle(
                              color: user['sudah_memilih'] ? Colors.greenAccent : Colors.orangeAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            icon: const Icon(FontAwesomeIcons.penToSquare, color: Colors.amber),
                            onPressed: () => showForm(data: user),
                          ),
                          IconButton(
                            icon: const Icon(FontAwesomeIcons.rotateLeft, color: Colors.cyanAccent),
                            onPressed: () => resetVoting(user['id']),
                          ),
                          IconButton(
                            icon: const Icon(FontAwesomeIcons.trashCan, color: Colors.redAccent),
                            onPressed: () => deleteUser(user['id']),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
                },
              ),
            ),
    );
  }
}
