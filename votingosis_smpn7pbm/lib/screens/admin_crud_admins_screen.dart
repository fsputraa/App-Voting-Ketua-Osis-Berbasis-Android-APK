import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:votingosis_smpn7pbm/services/supabase_service.dart';

class AdminCrudAdminsScreen extends StatefulWidget {
  const AdminCrudAdminsScreen({super.key});

  @override
  State<AdminCrudAdminsScreen> createState() => _AdminCrudAdminsScreenState();
}

class _AdminCrudAdminsScreenState extends State<AdminCrudAdminsScreen> {
  List<Map<String, dynamic>> admins = [];
  bool isLoading = false;
  bool _passwordVisible = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  int? editingId;

  @override
  void initState() {
    super.initState();
    fetchAdmins();
  }

  Future<void> fetchAdmins() async {
    setState(() => isLoading = true);
    final response = await supabase.from('admins').select();
    setState(() {
      admins = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> addOrUpdateAdmin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) return;

    if (editingId != null) {
      await supabase.from('admins').update({
        'username': username,
        'password': password,
      }).eq('id', editingId);
    } else {
      await supabase.from('admins').insert({
        'username': username,
        'password': password,
      });
    }

    Navigator.of(context).pop();
    _usernameController.clear();
    _passwordController.clear();
    editingId = null;
    fetchAdmins();
  }

  void showForm({Map<String, dynamic>? data}) {
    if (data != null) {
      editingId = data['id'];
      _usernameController.text = data['username'];
      _passwordController.text = data['password'];
    } else {
      _usernameController.clear();
      _passwordController.clear();
      editingId = null;
    }

    _passwordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
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
                  color: Colors.deepPurpleAccent.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FontAwesomeIcons.userShield, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    editingId != null ? 'Edit Admin' : 'Tambah Admin',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(FontAwesomeIcons.user, color: Colors.white),
                      hintText: 'Username',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.deepPurple.shade700,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(FontAwesomeIcons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.deepPurple.shade700,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  Colors.pinkAccent.shade200,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(FontAwesomeIcons.floppyDisk, color: Colors.white),
                    label: const Text("Simpan", style: TextStyle(color: Colors.white)),
                    onPressed: addOrUpdateAdmin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> deleteAdmin(int id) async {
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
              const Text("Yakin ingin menghapus admin ini?",
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
      await supabase.from('admins').delete().eq('id', id);
      fetchAdmins();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade800,
        elevation: 4,
        title: const Text('Manajemen Admin', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => showForm(),
            tooltip: "Tambah Admin",
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
              : RefreshIndicator(
                  onRefresh: fetchAdmins,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: admins.length,
                    itemBuilder: (context, index) {
                      final admin = admins[index];
                      return Card(
                        color: Colors.deepPurple.shade900.withOpacity(0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(FontAwesomeIcons.shieldHalved, color: Colors.white),
                          title: Text(admin['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text("ID: ${admin['id']}", style: const TextStyle(color: Colors.white54)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.penToSquare, color: Colors.amber),
                                onPressed: () => showForm(data: admin),
                              ),
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.trashCan, color: Colors.redAccent),
                                onPressed: () => deleteAdmin(admin['id']),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
                    },
                  ),
                );
        },
      ),
    );
  }
}
