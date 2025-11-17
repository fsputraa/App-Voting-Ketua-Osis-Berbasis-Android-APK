import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:votingosis_smpn7pbm/screens/login_screen.dart';
import 'package:votingosis_smpn7pbm/services/supabase_service.dart';
import 'package:animate_do/animate_do.dart';

class VotingScreen extends StatefulWidget {
  final String nisn;
  const VotingScreen({super.key, required this.nisn});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  List<dynamic> kandidatList = [];
  bool isLoading = true;
  bool sudahVote = false;
  String? kandidatTerpilihId;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await fetchCandidates();
    await checkUserVoteStatus();
  }

  Future<void> fetchCandidates() async {
    setState(() => isLoading = true);
    final res = await supabase.from('kandidat').select().order('jumlah_vote', ascending: false);
    kandidatList = res;
    setState(() => isLoading = false);
  }

  Future<void> checkUserVoteStatus() async {
    final user = await supabase.from('users').select('id, sudah_memilih').eq('nisn', widget.nisn).single();
    if (user['sudah_memilih'] == true) {
      final vote = await supabase
          .from('votes')
          .select('candidate_id')
          .eq('user_id', user['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (vote != null) {
        setState(() {
          sudahVote = true;
          kandidatTerpilihId = vote['candidate_id'];
        });
      }
    }
  }

  Future<bool> onBackPressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2E3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.logout, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Keluar Aplikasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Yakin ingin keluar dari aplikasi?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Batal", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            icon: Icon(Iconsax.logout, color: Colors.white),
            label: Text("Keluar", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return true;
    }

    return false;
  }

  void showCandidateDetail(Map<String, dynamic> kandidat) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF20222F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(kandidat['foto'], height: 220, width: double.infinity, fit: BoxFit.cover),
              ),
              SizedBox(height: 16),
              Text(kandidat['nama'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Divider(color: Colors.white24, height: 24, thickness: 1.2),
              Text("Visi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              SizedBox(height: 6),
              Text(kandidat['visi'], style: TextStyle(color: Colors.white70, fontSize: 15)),
              SizedBox(height: 16),
              Text("Misi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
              SizedBox(height: 6),
              Text(kandidat['misi'], style: TextStyle(color: Colors.white70, fontSize: 15)),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.close, color: Colors.white),
                  label: Text("Tutup", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3A3C4A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> voteCandidate(String kandidatId) async {
    final user = await supabase.from('users').select('id, sudah_memilih').eq('nisn', widget.nisn).single();

    if (user['sudah_memilih'] == true) {
      await checkUserVoteStatus();
      final kandidatNama = kandidatList.firstWhere((k) => k['id'] == kandidatTerpilihId)['nama'];
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2B2E3F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Iconsax.tick_circle, color: Colors.amberAccent),
              SizedBox(width: 10),
              Text("Sudah Memilih", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Kamu sudah memilih $kandidatNama. Tidak bisa memilih lagi.",
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final kandidat = kandidatList.firstWhere((k) => k['id'] == kandidatId);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2E3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.verify, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text("Konfirmasi Pilihan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Yakin memilih ${kandidat['nama']} sebagai Ketua OSIS?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Batal", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            icon: Icon(Iconsax.tick_circle, color: Colors.white),
            label: Text("Pilih", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await supabase.from('votes').insert({
      'user_id': user['id'],
      'candidate_id': kandidatId,
      'created_at': DateTime.now().toIso8601String()
    });

    await supabase.from('users').update({'sudah_memilih': true}).eq('id', user['id']);
    await supabase.rpc('increment_vote', params: {'target_id': kandidatId});
    await checkUserVoteStatus();
    await fetchCandidates();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2E3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.like_1, color: Colors.lightGreenAccent),
            SizedBox(width: 10),
            Text("Terima Kasih", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Terima kasih sudah memilih Ketua OSIS. Suara kamu sangat berarti!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPressed,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text("E-Voting OSIS"),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        drawer: Drawer(
          backgroundColor: Colors.black87,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.deepPurple),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.user, size: 40, color: Colors.white),
                    SizedBox(height: 12),
                    Text('Siswa',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Iconsax.element_3, color: Colors.white),
                title: Text("Beranda", style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Iconsax.logout, color: Colors.redAccent),
                title: Text("Keluar", style: TextStyle(color: Colors.redAccent)),
                onTap: () => onBackPressed(),
              ),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.tealAccent))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: kandidatList.length,
                itemBuilder: (ctx, index) {
                  final kandidat = kandidatList[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 80 * index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(kandidat['foto'],
                                height: 200, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(kandidat['nama'],
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => voteCandidate(kandidat['id']),
                                        icon: Icon(Iconsax.tick_circle),
                                        label: Text("Vote"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          elevation: 4,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => showCandidateDetail(kandidat),
                                        icon: Icon(Iconsax.eye),
                                        label: Text("Detail"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurpleAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          elevation: 4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
