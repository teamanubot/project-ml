import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/custom_snackbar.dart';
import 'package:image/image.dart' as img;
import 'package:spineanalyzer/resources/strings/analysis_strings_nonori.dart';
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
  String mlStatus = AnalysisStringsNonOri.initializing;
  SpineAnalysisResult? analysisResult;

  @override
  void initState() {
    super.initState();
    _initML();
  }

  Future<void> _initML() async {
    setState(() { mlStatus = AnalysisStringsNonOri.initializing; isLoading = true; });
    await MLModelManager().loadAllModels();
    setState(() { mlStatus = AnalysisStringsNonOri.modelReady; });
    await _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => isLoading = true);
    try {
      // TODO: Load image from file path or URI using image_picker atau file picker
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      _showToast(AnalysisStringsNonOri.errorLoadImage);
    }
  }

  Future<void> _analyzeSpine() async {
    setState(() { isLoading = true; mlStatus = AnalysisStringsNonOri.analyzing; });
    try {
      final img.Image? inputImage = originalImage;
      if (inputImage == null) {
        setState(() { isLoading = false; });
        _showToast(AnalysisStringsNonOri.errorNoImage);
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
        mlStatus = '${AnalysisStringsNonOri.analysisComplete}: ${result.classification} (${result.primaryAngle.toStringAsFixed(1)}°)';
        isLoading = false;
      });
    } catch (e) {
      setState(() { isLoading = false; });
      _showToast(AnalysisStringsNonOri.errorAnalysisFailed);
    }
  }

  void _showToast(String msg) {
    CustomSnackbar.show(context, message: msg, type: SnackbarType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AnalysisStringsNonOri.appBarTitle)),
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
                      child: const Text(AnalysisStringsNonOri.analyzeButton),
                    ),
                    if (isAnalyzed && analysisResult != null) ...[
                      const SizedBox(height: 16),
                      Text('${AnalysisStringsNonOri.angleLabel}: ${calculatedAngle.toStringAsFixed(1)}°'),
                      Text('${AnalysisStringsNonOri.confidenceLabel}: ${(confidenceScore * 100).toStringAsFixed(1)}%'),
                      Text('${AnalysisStringsNonOri.classificationLabel}: $classification (${(classificationConfidence * 100).toStringAsFixed(1)}%)'),
                      const SizedBox(height: 8),
                      Text('${AnalysisStringsNonOri.assessmentLabel}: ${analysisResult!.assessment.severity}'),
                      Text('${AnalysisStringsNonOri.recommendationLabel}: ${analysisResult!.assessment.recommendations}'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: AnalysisStringsNonOri.notesLabel),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {}, // TODO: Implementasi simpan analisis
                        child: const Text(AnalysisStringsNonOri.saveButton),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
