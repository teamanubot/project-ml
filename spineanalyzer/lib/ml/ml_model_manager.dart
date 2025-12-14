import 'dart:async';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLModelManager {
  static final MLModelManager _instance = MLModelManager._internal();
  factory MLModelManager() => _instance;
  MLModelManager._internal();

  static const String spineClassifierModel = 'spine_classifier.tflite';
  static const String keypointDetectorModel = 'spine_keypoint_detector.tflite';
  static const String angleCalculatorModel = 'spine_angle_calculator.tflite';

  Interpreter? spineClassifier;
  Interpreter? keypointDetector;
  Interpreter? angleCalculator;

  final Map<String, bool> modelLoadStatus = {
    'classifier': false,
    'keypoint': false,
    'angle': false,
  };

  Future<void> loadAllModels() async {
    modelLoadStatus['classifier'] = await _loadSpineClassifier();
    modelLoadStatus['keypoint'] = await _loadKeypointDetector();
    modelLoadStatus['angle'] = await _loadAngleCalculator();
  }

  Future<bool> _loadSpineClassifier() async {
    try {
      spineClassifier?.close();
      spineClassifier = await Interpreter.fromAsset(spineClassifierModel, options: InterpreterOptions()..threads = 4);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadKeypointDetector() async {
    try {
      keypointDetector?.close();
      keypointDetector = await Interpreter.fromAsset(keypointDetectorModel, options: InterpreterOptions()..threads = 4);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _loadAngleCalculator() async {
    try {
      angleCalculator?.close();
      angleCalculator = await Interpreter.fromAsset(angleCalculatorModel, options: InterpreterOptions()..threads = 4);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool isModelLoaded(String modelType) => modelLoadStatus[modelType] ?? false;

  String getModelStatus() {
    return 'Classifier: [32m${isModelLoaded("classifier") ? "✓" : "✗"}[0m\n'
        'Keypoint: [32m${isModelLoaded("keypoint") ? "✓" : "✗"}[0m\n'
        'Angle: [32m${isModelLoaded("angle") ? "✓" : "✗"}[0m\n'
        'Hardware: CPU';
  }

  Future<SpineAnalysisResult> analyzeSpine(img.Image inputImage) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final width = inputImage.width;
    final height = inputImage.height;
    // TODO: Integrasi dengan AccurateSpineDetector dan SpineClassificationHelper versi Dart
    // Dummy/fallback
    final result = SpineAnalysisResult(
      timestamp: now,
      imageWidth: width,
      imageHeight: height,
      primaryAngle: 15.0 + Random().nextDouble() * 20,
      confidence: 0.5,
      classification: "Analysis Limited",
      classificationConfidence: 0.5,
      allProbabilities: [],
      keypoints: [],
      angles: null,
      assessment: SpineAssessment(
        severity: "Limited Analysis",
        riskLevel: "Unknown",
        overallConfidence: 0.5,
        color: 0xFF888888,
        recommendations: "Please ensure ML models are properly installed for accurate analysis.",
        requiresImmediateAttention: false,
      ),
    );
    return result;
  }

  void cleanup() {
    spineClassifier?.close();
    keypointDetector?.close();
    angleCalculator?.close();
    modelLoadStatus.updateAll((key, value) => false);
  }
}

class SpineAnalysisResult {
  final int timestamp;
  final int imageWidth;
  final int imageHeight;
  final double primaryAngle;
  final double confidence;
  final String classification;
  final double classificationConfidence;
  final List<double> allProbabilities;
  final List<dynamic> keypoints;
  final dynamic angles;
  final SpineAssessment assessment;

  SpineAnalysisResult({
    required this.timestamp,
    required this.imageWidth,
    required this.imageHeight,
    required this.primaryAngle,
    required this.confidence,
    required this.classification,
    required this.classificationConfidence,
    required this.allProbabilities,
    required this.keypoints,
    required this.angles,
    required this.assessment,
  });

  bool isSuccessful() => primaryAngle > 0 && confidence > 0;

  String getSummary() => "Angle: [34m${primaryAngle.toStringAsFixed(1)}°[0m, Confidence: [34m${(confidence * 100).toStringAsFixed(1)}%[0m, Classification: $classification";
}

class SpineAssessment {
  final String severity;
  final String riskLevel;
  final double overallConfidence;
  final int color;
  final String recommendations;
  final bool requiresImmediateAttention;

  SpineAssessment({
    required this.severity,
    required this.riskLevel,
    required this.overallConfidence,
    required this.color,
    required this.recommendations,
    required this.requiresImmediateAttention,
  });

  bool isNormal() => severity == "Normal";

  String getUrgencyLevel() {
    if (requiresImmediateAttention) return "Critical";
    if (riskLevel == "High") return "High";
    if (riskLevel == "Medium") return "Medium";
    return "Low";
  }
}
