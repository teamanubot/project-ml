import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;
  const HistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AnalysisItem> analysisList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAnalysisHistory();
  }

  Future<void> loadAnalysisHistory() async {
    setState(() => isLoading = true);
    final api = ApiService();
    final List<dynamic> data = await api.getUserHistory(widget.userId);
    setState(() {
      analysisList = data.map((row) => AnalysisItem.fromMap(row)).toList();
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF5F7FA),
            Color(0xFFE3F0FF),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Icon(Icons.history, size: 80, color: Color(0xFF1976D2)),
              ),
              Container(
                width: 340,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'History',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Berikut adalah riwayat analisis tulang belakang Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else if (analysisList.isEmpty)
                      const Text('Data analysis tidak ada', style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: analysisList.length,
                        itemBuilder: (context, index) {
                          final item = analysisList[index];
                          return AnalysisCard(item: item);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalysisItem {
  final int id;
  final double angle;
  final String date;
  final String notes;
  final String imagePath;

  AnalysisItem({
    required this.id,
    required this.angle,
    required this.date,
    required this.notes,
    required this.imagePath,
  });

  factory AnalysisItem.fromMap(Map<String, dynamic> map) {
    return AnalysisItem(
      id: map['id'] as int,
      angle: (map['angle'] as num).toDouble(),
      date: map['analysis_date'] ?? '',
      notes: map['notes'] ?? '',
      imagePath: map['image_path'] ?? '',
    );
  }
}

class AnalysisCard extends StatelessWidget {
  final AnalysisItem item;
  const AnalysisCard({Key? key, required this.item}) : super(key: key);

  String formatDateToWIB(String dateString) {
    if (dateString.isEmpty) return 'Tanggal tidak tersedia';
    try {
      final inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final utcDate = inputFormat.parseUtc(dateString);
      final wibDate = utcDate.toLocal().add(const Duration(hours: 7 - 0));
      final outputFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
      return outputFormat.format(wibDate) + ' WIB';
    } catch (e) {
      try {
        final simpleFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
        final date = simpleFormat.parse(dateString);
        final outputFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
        return outputFormat.format(date) + ' WIB';
      } catch (ex) {
        return dateString;
      }
    }
  }

  String getInterpretation(double angle) {
    if (angle < 10) {
      return 'Normal';
    } else if (angle < 20) {
      return 'Skoliosis Ringan';
    } else if (angle < 30) {
      return 'Skoliosis Sedang';
    } else {
      return 'Skoliosis Berat';
    }
  }

  Color getColorForAngle(double angle, BuildContext context) {
    if (angle < 10) {
      return Colors.green[800]!;
    } else if (angle < 20) {
      return Colors.orange[800]!;
    } else {
      return Colors.red[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColorForAngle(item.angle, context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kemiringan: ${item.angle.toStringAsFixed(2)}°', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Tanggal: ${formatDateToWIB(item.date)}'),
            const SizedBox(height: 4),
            Text(item.notes.isNotEmpty ? 'Catatan: ${item.notes}' : 'Catatan: -'),
            const SizedBox(height: 4),
            Text('Status: ${getInterpretation(item.angle)}', style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
