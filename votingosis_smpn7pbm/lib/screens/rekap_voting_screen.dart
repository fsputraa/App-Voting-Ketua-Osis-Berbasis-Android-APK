// (Potongan awal tetap sama)
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui' as ui;
import 'dart:typed_data' as tdata;

class RekapVotingScreen extends StatefulWidget {
  const RekapVotingScreen({super.key});

  @override
  State<RekapVotingScreen> createState() => _RekapVotingScreenState();
}

class _RekapVotingScreenState extends State<RekapVotingScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<dynamic> kandidatList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('kandidat')
          .select()
          .order('jumlah_vote', ascending: false);
      setState(() {
        kandidatList = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  int getTotalVotes() {
    return kandidatList.fold<int>(
      0,
      (sum, item) => sum + ((item['jumlah_vote'] ?? 0) as int),
    );
  }

  List<PieChartSectionData> getPieChartSections() {
    final totalVotes = getTotalVotes();
    return kandidatList.asMap().entries.map((entry) {
      final index = entry.key;
      final kandidat = entry.value;
      final voteCount = kandidat['jumlah_vote'] ?? 0;
      final percentage =
          totalVotes == 0 ? 0.0 : (voteCount / totalVotes) * 100;
      final color = Colors.primaries[index % Colors.primaries.length];

      return PieChartSectionData(
        color: color.withOpacity(0.95),
        value: percentage,
        title: "${percentage.toStringAsFixed(1)}%",
        radius: 75,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        badgeWidget: const Icon(Icons.person, color: Colors.white, size: 22),
        badgePositionPercentageOffset: .98,
      );
    }).toList();
  }

  String getRankText(int index) {
    switch (index) {
      case 0:
        return '🥇 Juara 1';
      case 1:
        return '🥈 Juara 2';
      case 2:
        return '🥉 Juara 3';
      default:
        return '';
    }
  }

  Widget buildChartLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: kandidatList.asMap().entries.map((entry) {
        final index = entry.key;
        final kandidat = entry.value;
        final color = Colors.primaries[index % Colors.primaries.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                kandidat['nama'],
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> generatePdf() async {
    await initializeDateFormatting('id_ID', null);
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate =
        DateFormat('dd MMMM yyyy – HH:mm', 'id_ID').format(now);

    final ByteData logoData = await rootBundle.load('assets/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header: Logo kiri + Judul tengah
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), width: 60),
                  pw.Column(
                    children: [
                      pw.Text(
                        'SMP NEGERI 7 PRABUMULIH',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Rekapitulasi Hasil Voting Ketua OSIS',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Dicetak: $formattedDate',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 60), // Placeholder supaya simetris
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2), // Garis tebal (kop surat)
              pw.SizedBox(height: 18),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
                headerDecoration: pw.BoxDecoration(color: PdfColors.indigo),
                cellStyle: const pw.TextStyle(fontSize: 11),
                cellAlignment: pw.Alignment.centerLeft,
                data: <List<String>>[
                  <String>['No', 'Nama Kandidat', 'Jumlah Suara', 'Peringkat'],
                  ...kandidatList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final kandidat = entry.value;
                    return [
                      '${index + 1}',
                      '${kandidat['nama']}',
                      '${kandidat['jumlah_vote']}',
                      getRankText(index),
                    ];
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Suara: ${getTotalVotes()}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Rekap Voting"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: kandidatList.isEmpty ? null : generatePdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : kandidatList.isEmpty
              ? const Center(
                  child: Text("Belum ada data kandidat.",
                      style: TextStyle(color: Colors.white70)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade800,
                                Colors.blueAccent
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "📊 Statistik Suara",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ZoomIn(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white.withOpacity(0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.tealAccent.withOpacity(0.15),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              )
                            ],
                            border:
                                Border.all(color: Colors.white24, width: 1),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            height: 280,
                            child: PieChart(
                              PieChartData(
                                sections: getPieChartSections(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 50,
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeIn(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          "Total Suara: ${getTotalVotes()}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 600),
                        child: buildChartLegend(),
                      ),
                      const SizedBox(height: 30),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: const Text(
                          "Detail Perolehan",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...kandidatList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final kandidat = entry.value;
                        final fotoUrl = kandidat['foto'] ?? '';
                        return ZoomIn(
                          duration:
                              Duration(milliseconds: 300 + (index * 100)),
                          child: Card(
                            color: Colors.white10,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 4,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundImage: fotoUrl.isNotEmpty
                                    ? NetworkImage(fotoUrl)
                                    : null,
                                backgroundColor: Colors.grey[900],
                                child: fotoUrl.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.white70)
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    kandidat['nama'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (index < 3)
                                    Text(
                                      getRankText(index),
                                      style: const TextStyle(
                                          color: Colors.amber, fontSize: 12),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                "Jumlah Suara: ${kandidat['jumlah_vote']}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
