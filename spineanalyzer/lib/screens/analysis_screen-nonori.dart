import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../ml/ml_model_manager.dart';


class _AnalysisScreenState extends State<AnalysisScreen> {
  img.Image? originalImage;
  double calculatedAngle = 0.0;
  double confidenceScore = 0.0;
  bool isAnalyzed = false;
  String classification = '';
  double classificationConfidence = 0.0;
  final TextEditingController notesController = TextEditingController();
  bool isLoading = false;
  String mlStatus = 'Memuat model Machine Learning...';
  SpineAnalysisResult? analysisResult;

  @override
  void initState() {
    super.initState();
    _initML();
  }

  Future<void> _initML() async {
    setState(() { mlStatus = 'Memuat model Machine Learning...'; isLoading = true; });
    await MLModelManager().loadAllModels();
    setState(() { mlStatus = 'Model siap. Memuat gambar...'; });
    await _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => isLoading = true);
    try {
      // TODO: Load image from file path or URI using image_picker atau file picker
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      _showToast('Error loading image');
    }
  }

  Future<void> _analyzeSpine() async {
    setState(() { isLoading = true; mlStatus = 'Analisis AI sedang berjalan...'; });
    try {
      final img.Image? inputImage = originalImage;
      if (inputImage == null) {
        setState(() { isLoading = false; });
        _showToast('Tidak ada gambar untuk dianalisis');
        return;
      }
      final result = await MLModelManager().analyzeSpine(inputImage);
      setState(() {
        calculatedAngle = result.primaryAngle;
        confidenceScore = result.confidence;
        classification = result.classification;
        classificationConfidence = result.classificationConfidence;
        analysisResult = result;
        isAnalyzed = true;
        mlStatus = 'Analisis selesai: ${result.classification} (${result.primaryAngle.toStringAsFixed(1)}°)';
        isLoading = false;
      });
    } catch (e) {
      setState(() { isLoading = false; });
      _showToast('Analisis gagal. Silakan coba lagi.');
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Spine Analysis - Accurate Detection')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mlStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (originalImage != null)
                      Image.memory(Uint8List.fromList(img.encodeJpg(originalImage!))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : _analyzeSpine,
                      child: const Text('🔬 Analyze'),
                    ),
                    if (isAnalyzed && analysisResult != null) ...[
                      const SizedBox(height: 16),
                      Text('Kemiringan Tulang: ${calculatedAngle.toStringAsFixed(1)}°'),
                      Text('Confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%'),
                      Text('Classification: $classification (${(classificationConfidence * 100).toStringAsFixed(1)}%)'),
                      const SizedBox(height: 8),
                      Text('Assessment: ${analysisResult!.assessment.severity}'),
                      Text('Rekomendasi: ${analysisResult!.assessment.recommendations}'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Catatan'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {}, // TODO: Implementasi simpan analisis
                        child: const Text('💾 Simpan Analisis'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
