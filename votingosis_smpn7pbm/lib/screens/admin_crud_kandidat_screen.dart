import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:votingosis_smpn7pbm/services/supabase_service.dart';

class AdminCrudKandidatScreen extends StatefulWidget {
  const AdminCrudKandidatScreen({super.key});

  @override
  State<AdminCrudKandidatScreen> createState() => _AdminCrudKandidatScreenState();
}

class _AdminCrudKandidatScreenState extends State<AdminCrudKandidatScreen> {
  List<Map<String, dynamic>> kandidat = [];
  bool isLoading = false;

  final _namaController = TextEditingController();
  final _visiController = TextEditingController();
  final _misiController = TextEditingController();
  File? _selectedImage;
  String? editingId;

  @override
  void initState() {
    super.initState();
    fetchKandidat();
  }

  Future<void> fetchKandidat() async {
    setState(() => isLoading = true);
    final response = await supabase.from('kandidat').select().order('jumlah_vote', ascending: false);
    setState(() {
      kandidat = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<String?> uploadFoto(File file) async {
    try {
      final fileExt = p.extension(file.path);
      final uuid = const Uuid().v4();
      final filePath = 'kandidat/$uuid$fileExt';
      final bytes = await file.readAsBytes();

      await supabase.storage.from('photos').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return supabase.storage.from('photos').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('❌ Upload foto gagal: $e');
      return null;
    }
  }

  Future<void> addOrUpdateKandidat() async {
    final nama = _namaController.text.trim();
    final visi = _visiController.text.trim();
    final misi = _misiController.text.trim();
    if (nama.isEmpty || visi.isEmpty || misi.isEmpty) return;

    String fotoUrl = '';

    if (_selectedImage != null) {
      final uploaded = await uploadFoto(_selectedImage!);
      if (uploaded != null) fotoUrl = uploaded;
    }

    if (editingId != null) {
      final updateData = {'nama': nama, 'visi': visi, 'misi': misi};
      if (fotoUrl.isNotEmpty) updateData['foto'] = fotoUrl;
      await supabase.from('kandidat').update(updateData).eq('id', editingId);
    } else {
      await supabase.from('kandidat').insert({
        'nama': nama,
        'visi': visi,
        'misi': misi,
        'foto': fotoUrl,
        'jumlah_vote': 0,
      });
    }

    Navigator.of(context).pop();
    resetForm();
    fetchKandidat();
  }

  void showForm({Map<String, dynamic>? data}) {
    if (data != null) {
      editingId = data['id'];
      _namaController.text = data['nama'];
      _visiController.text = data['visi'];
      _misiController.text = data['misi'];
      _selectedImage = null;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    editingId != null ? 'Edit Kandidat' : 'Tambah Kandidat',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _namaController,
                    onChanged: (_) => setStateDialog(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputStyle('Nama Kandidat'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _visiController,
                    onChanged: (_) => setStateDialog(() {}),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: _inputStyle('Visi'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _misiController,
                    onChanged: (_) => setStateDialog(() {}),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: _inputStyle('Misi'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (result != null) {
                        setStateDialog(() => _selectedImage = File(result.path));
                      }
                    },
                    icon: const FaIcon(FontAwesomeIcons.image, color: Colors.white),
                    label: const Text("Pilih Foto", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, height: 160, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AnimatedOpacity(
                    opacity: (_namaController.text.trim().isNotEmpty &&
                            _visiController.text.trim().isNotEmpty &&
                            _misiController.text.trim().isNotEmpty)
                        ? 1.0
                        : 0.4,
                    duration: 300.ms,
                    child: ElevatedButton.icon(
                      onPressed: (_namaController.text.trim().isNotEmpty &&
                              _visiController.text.trim().isNotEmpty &&
                              _misiController.text.trim().isNotEmpty)
                          ? () => addOrUpdateKandidat()
                          : null,
                      icon: const FaIcon(FontAwesomeIcons.save),
                      label: const Text("Simpan"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent.shade200,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) => resetForm());
  }

  void resetForm() {
    _namaController.clear();
    _visiController.clear();
    _misiController.clear();
    _selectedImage = null;
    editingId = null;
  }

  Future<void> deleteKandidat(String id) async {
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
              const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              const Text("Konfirmasi Hapus",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              const Text("Yakin ingin menghapus kandidat ini?",
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
      await supabase.from('kandidat').delete().eq('id', id);
      fetchKandidat();
    }
  }

  InputDecoration _inputStyle(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Manajemen Kandidat", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circlePlus, color: Colors.white),
            onPressed: () => showForm(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: kandidat.length,
              itemBuilder: (context, index) {
                final data = kandidat[index];
                return Card(
                  color: Colors.deepPurple.shade700.withOpacity(0.9),
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 12,
                  shadowColor: Colors.purpleAccent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(data['foto']),
                    ),
                    title: Text(data['nama'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("Vote: ${data['jumlah_vote']}",
                        style: const TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.amber),
                            onPressed: () => showForm(data: data)),
                        IconButton(
                            icon: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.redAccent),
                            onPressed: () => deleteKandidat(data['id'])),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).moveY(begin: 30);
              },
            ),
    );
  }
}
