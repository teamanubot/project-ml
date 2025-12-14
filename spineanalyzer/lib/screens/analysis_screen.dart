import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/custom_snackbar.dart';
import 'package:image/image.dart' as img;
import 'package:spineanalyzer/resources/strings/analysis_strings.dart';
import '../ml/straight_spine_detector.dart';
import '../ml/spine_classification_helper.dart';

class AnalysisScreen extends StatefulWidget {
  final int userId;
  final String imagePath;
  final String? imageUri;
  const AnalysisScreen({Key? key, required this.userId, required this.imagePath, this.imageUri}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  img.Image? originalImage;
  img.Image? processedImage;
  double calculatedAngle = 0.0;
  double confidenceScore = 0.0;
  bool isAnalyzed = false;
  bool showProcessedImage = false;
  List<StraightKeypoint> keypoints = [];
  StraightSpineResult? straightSpineResult;
  String classification = '';
  double classificationConfidence = 0.0;
  final TextEditingController notesController = TextEditingController();
  bool isLoading = false;
  String mlStatus = AnalysisStrings.initializing;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => isLoading = true);
    try {
      // TODO: Load image from file path or URI using image_picker atau file picker
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      _showToast(AnalysisStrings.errorLoadImage);
    }
  }

  Future<void> _analyzeSpine() async {
    setState(() { isLoading = true; mlStatus = AnalysisStrings.analyzing; });
    try {
      final detector = StraightSpineDetector();
      final helper = SpineClassificationHelper();
      final img.Image? inputImage = originalImage;
      if (inputImage == null) {
        setState(() { isLoading = false; });
        _showToast(AnalysisStrings.errorNoImage);
        return;
      }
      final result = detector.detectStraightSpine(inputImage);
      final classResult = helper.classifySpine(inputImage);
      setState(() {
        calculatedAngle = result.cobbAngle;
        confidenceScore = result.confidence;
        keypoints = result.keypoints;
        straightSpineResult = result;
        classification = classResult.className;
        classificationConfidence = classResult.confidence;
        processedImage = _createStraightSpineVisualization(inputImage, result.keypoints, result.cobbAngle);
        isAnalyzed = true;
        mlStatus = '${AnalysisStrings.analysisComplete}: ${result.linearityAnalysis.spineDescription} (${result.cobbAngle.toStringAsFixed(1)}°)';
        isLoading = false;
      });
    } catch (e) {
      setState(() { isLoading = false; });
      _showToast(AnalysisStrings.errorAnalysisFailed);
    }
  }

  img.Image _createStraightSpineVisualization(img.Image original, List<StraightKeypoint> keypoints, double angle) {
    final vis = img.copyResize(original, width: original.width, height: original.height);
    // TODO: Tambahkan visualisasi keypoint dan garis dengan CustomPainter jika ingin lebih interaktif
    return vis;
  }

  void _showToast(String msg) {
    CustomSnackbar.show(context, message: msg, type: SnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AnalysisStrings.appBarTitle)),
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
                      child: const Text(AnalysisStrings.analyzeButton),
                    ),
                    if (isAnalyzed) ...[
                      const SizedBox(height: 16),
                      Text('${AnalysisStrings.angleLabel}: ${calculatedAngle.toStringAsFixed(1)}°'),
                      Text('${AnalysisStrings.confidenceLabel}: ${(confidenceScore * 100).toStringAsFixed(1)}%'),
                      Text('${AnalysisStrings.classificationLabel}: $classification (${(classificationConfidence * 100).toStringAsFixed(1)}%)'),
                      if (processedImage != null)
                        Image.memory(Uint8List.fromList(img.encodeJpg(processedImage!))),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: AnalysisStrings.notesLabel),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {}, // TODO: Implementasi simpan analisis
                        child: const Text(AnalysisStrings.saveButton),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
