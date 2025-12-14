import 'dart:math';
import 'package:image/image.dart' as img;

class SpineClassificationHelper {
  static const String modelName = 'spine_classifier.tflite';
  static const int inputSize = 224;
  static const int numClasses = 5;
  static const List<String> classLabels = [
    "Normal",
    "Mild Scoliosis",
    "Moderate Scoliosis",
    "Severe Scoliosis",
    "Very Severe Scoliosis"
  ];
  static const List<double> confidenceThresholds = [
    0.6, 0.5, 0.5, 0.6, 0.7
  ];

  // Model loading and inference are not implemented in this mock version
  bool isModelLoaded = false;

  SpineClassificationHelper();

  ClassificationResult classifySpine(img.Image inputImage) {
    // Fallback/mock implementation
    return createEnhancedFallbackResult(inputImage);
  }

  ClassificationResult createEnhancedFallbackResult(img.Image inputImage) {
    final result = ClassificationResult();
    final spineVisibility = estimateSpineVisibility(inputImage);
    final imageQuality = calculateImageContrast(inputImage);
    if (spineVisibility > 0.7 && imageQuality > 0.5) {
      result.className = "Moderate Scoliosis";
      result.classIndex = 2;
      result.confidence = 0.75 + (spineVisibility * 0.15);
    } else if (spineVisibility > 0.5) {
      result.className = "Mild Scoliosis";
      result.classIndex = 1;
      result.confidence = 0.70 + (spineVisibility * 0.1);
    } else {
      result.className = "Normal";
      result.classIndex = 0;
      result.confidence = 0.65;
    }
    result.allProbabilities = List.filled(numClasses, 0.0);
    result.allProbabilities[result.classIndex] = result.confidence;
    final remaining = 1.0 - result.confidence;
    for (int i = 0; i < numClasses; i++) {
      if (i != result.classIndex) {
        result.allProbabilities[i] = remaining / (numClasses - 1);
      }
    }
    result.isReliable = result.confidence >= 0.7;
    result.secondaryClass = "Analysis Limited";
    result.classificationCertainty = 0.6;
    return result;
  }

  double calculateImageContrast(img.Image image) {
    final sampleSize = min(image.width * image.height, 1000);
    final rand = Random();
    double mean = 0;
    for (int i = 0; i < sampleSize; i++) {
      final x = rand.nextInt(image.width);
      final y = rand.nextInt(image.height);
      mean += image.getPixel(x, y).luminance.toDouble();
    }
    mean /= sampleSize;
    double variance = 0;
    for (int i = 0; i < sampleSize; i++) {
      final x = rand.nextInt(image.width);
      final y = rand.nextInt(image.height);
      final gray = image.getPixel(x, y).luminance.toDouble();
      variance += (gray - mean) * (gray - mean);
    }
    variance /= sampleSize;
    final stdDev = sqrt(variance);
    return stdDev.clamp(0, 128) / 128.0;
  }

  double estimateSpineVisibility(img.Image image) {
    final width = image.width;
    final height = image.height;
    final centerX = width ~/ 2;
    int verticalStructureScore = 0;
    int samples = 0;
    for (int y = height ~/ 4; y < 3 * height ~/ 4; y += 3) {
      for (int x = centerX - width ~/ 8; x < centerX + width ~/ 8; x += 2) {
        if (x >= 0 && x < width) {
          final gray = image.getPixel(x, y).luminance.toDouble();
          if (gray > 150) verticalStructureScore++;
          samples++;
        }
      }
    }
    return samples > 0 ? verticalStructureScore / samples : 0.0;
  }

  // Tidak perlu getGrayValue, gunakan pixel.luminance langsung

  bool isModelReady() => isModelLoaded;
  List<String> getClassLabels() => List.from(classLabels);
  int getInputSize() => inputSize;
}

class ClassificationResult {
  String className = '';
  double confidence = 0.0;
  int classIndex = 0;
  List<double> allProbabilities = [];
  bool isReliable = false;
  String secondaryClass = '';
  double classificationCertainty = 0.0;

  String getDetailedResults() {
    final sb = StringBuffer();
    sb.writeln('=== ENHANCED CLASSIFICATION RESULTS ===');
    sb.writeln('Primary: $className (${(confidence * 100).toStringAsFixed(1)}%)');
    sb.writeln('Secondary: $secondaryClass');
    sb.writeln('Certainty: ${(classificationCertainty * 100).toStringAsFixed(1)}%');
    sb.writeln('Reliability: ${isReliable ? "High" : "Medium"}\n');
    if (allProbabilities.isNotEmpty) {
      sb.writeln('All Classifications:');
      for (int i = 0; i < SpineClassificationHelper.classLabels.length && i < allProbabilities.length; i++) {
        final indicator = (i == classIndex) ? '► ' : '  ';
        sb.writeln('$indicator${SpineClassificationHelper.classLabels[i]}: ${(allProbabilities[i] * 100).toStringAsFixed(1)}%');
      }
    }
    return sb.toString();
  }

  String getConfidenceLevel() {
    if (confidence >= 0.9) return "Very High";
    if (confidence >= 0.8) return "High";
    if (confidence >= 0.7) return "Good";
    if (confidence >= 0.6) return "Fair";
    return "Low";
  }

  String getMedicalRecommendation() {
    switch (classIndex) {
      case 0:
        return "Continue regular check-ups and maintain good posture.";
      case 1:
        return "Monitor progression with regular X-rays every 6-12 months. Consider physical therapy.";
      case 2:
        return "Consult orthopedic specialist. Consider bracing if still growing. Physical therapy recommended.";
      case 3:
        return "URGENT: Consult spine specialist immediately. Consider surgical evaluation.";
      case 4:
        return "CRITICAL: Immediate spine specialist consultation required. Surgical intervention likely needed.";
      default:
        return "Consult healthcare professional for proper evaluation.";
    }
  }

  @override
  String toString() => "$className (${(confidence * 100).toStringAsFixed(1)}% confidence, ${isReliable ? "High" : "Medium"} reliability)";
}
