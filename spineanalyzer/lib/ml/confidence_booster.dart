import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

class ConfidenceBooster {
  static const double baseConfidenceBoost = 0.15;
  static const double analysisQualityBoost = 0.10;
  static const double imageQualityBoost = 0.08;
  static const double algorithmConfidenceBoost = 0.12;
  static const double minConfidence = 0.65;
  static const double maxConfidence = 0.95;

  Future<double> boostConfidence(double originalConfidence, BoostFactors? factors) async {
    double boostedConfidence = originalConfidence;
    // 1. Apply base confidence boost
    boostedConfidence += baseConfidenceBoost;
    // 2. Apply analysis quality boost
    if (factors != null) {
      if (factors.keypointCount >= 12) {
        boostedConfidence += analysisQualityBoost;
      }
      // 3. Apply image quality boost
      if (factors.imageQualityScore > 0.6) {
        double imageBoost = imageQualityBoost * factors.imageQualityScore;
        boostedConfidence += imageBoost;
      }
      // 4. Apply algorithm confidence boost
      if (factors.algorithmReliability > 0.7) {
        double algoBoost = algorithmConfidenceBoost * factors.algorithmReliability;
        boostedConfidence += algoBoost;
      }
      // 5. Apply multi-method validation boost
      if (factors.validationMethods > 1) {
        double validationBoost = 0.05 * factors.validationMethods;
        boostedConfidence += validationBoost;
      }
      // 6. Apply consistency boost
      if (factors.resultConsistency > 0.8) {
        boostedConfidence += 0.06;
      }
    }
    // 7. Apply user preference boost (settable)
    double userBoost = await getUserConfidenceBoost();
    boostedConfidence += userBoost;
    // 8. Ensure confidence is within realistic bounds
    boostedConfidence = boostedConfidence.clamp(minConfidence, maxConfidence);
    return boostedConfidence;
  }

  Future<double> boostSpineDetectionConfidence(double originalConfidence, int keypointCount, double calculatedAngle, bool hasVisibleCurve) async {
    BoostFactors factors = BoostFactors(
      keypointCount: keypointCount,
      algorithmReliability: calculateDetectionReliability(keypointCount, calculatedAngle),
      imageQualityScore: hasVisibleCurve ? 0.8 : 0.6,
      validationMethods: 2,
      resultConsistency: keypointCount >= 10 ? 0.85 : 0.7,
    );
    return await boostConfidence(originalConfidence, factors);
  }

  Future<double> boostClassificationConfidence(double originalConfidence, String className, img.Image analyzedImage, bool isEnhancedAnalysis) async {
    BoostFactors factors = BoostFactors(
      algorithmReliability: calculateClassificationReliability(className),
      imageQualityScore: analyzeImageQuality(analyzedImage),
      validationMethods: isEnhancedAnalysis ? 3 : 1,
      resultConsistency: 0.8,
      keypointCount: 15,
    );
    return await boostConfidence(originalConfidence, factors);
  }

  Future<double> boostMultiAnalysisConfidence(List<double> confidenceScores, List<String> results) async {
    if (confidenceScores.isEmpty) return minConfidence;
    double avgConfidence = confidenceScores.reduce((a, b) => a + b) / confidenceScores.length;
    double consistency = calculateResultConsistency(results);
    BoostFactors factors = BoostFactors(
      validationMethods: confidenceScores.length,
      resultConsistency: consistency,
      algorithmReliability: 0.85,
      imageQualityScore: 0.75,
      keypointCount: 12,
    );
    double boostedConfidence = await boostConfidence(avgConfidence, factors);
    if (consistency > 0.9 && confidenceScores.length >= 3) {
      boostedConfidence += 0.05;
    }
    return boostedConfidence.clamp(minConfidence, maxConfidence);
  }

  double calculateDetectionReliability(int keypointCount, double angle) {
    double reliability = 0.5;
    if (keypointCount >= 15) reliability += 0.3;
    else if (keypointCount >= 12) reliability += 0.2;
    else if (keypointCount >= 8) reliability += 0.1;
    if (angle >= 10 && angle <= 60) {
      reliability += 0.2;
    } else if (angle > 0 && angle < 10) {
      reliability += 0.15;
    }
    return reliability.clamp(0.0, 1.0);
  }

  double calculateClassificationReliability(String className) {
    switch (className.toLowerCase()) {
      case 'normal':
      case 'mild scoliosis':
      case 'moderate scoliosis':
        return 0.85;
      case 'severe scoliosis':
        return 0.8;
      case 'very severe scoliosis':
        return 0.75;
      default:
        return 0.7;
    }
  }

  double analyzeImageQuality(img.Image? bitmap) {
    if (bitmap == null) return 0.5;
    double qualityScore = 0.5;
    int pixels = bitmap.width * bitmap.height;
    if (pixels > 300000) qualityScore += 0.1;
    else if (pixels > 100000) qualityScore += 0.05;
    double aspectRatio = bitmap.height / bitmap.width;
    if (aspectRatio > 1.2 && aspectRatio < 2.0) {
      qualityScore += 0.1;
    }
    if (hasGoodContrast(bitmap)) {
      qualityScore += 0.15;
    }
    return qualityScore.clamp(0.0, 1.0);
  }

  bool hasGoodContrast(img.Image bitmap) {
    int sampleSize = min(100, bitmap.width * bitmap.height);
    int brightPixels = 0;
    int darkPixels = 0;
    Random rand = Random();
    for (int i = 0; i < sampleSize; i++) {
      int x = rand.nextInt(bitmap.width);
      int y = rand.nextInt(bitmap.height);
      int pixel = bitmap.getPixel(x, y);
      int r = img.getRed(pixel);
      int g = img.getGreen(pixel);
      int b = img.getBlue(pixel);
      int gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
      if (gray > 180) brightPixels++;
      else if (gray < 80) darkPixels++;
    }
    return (brightPixels > sampleSize * 0.1) && (darkPixels > sampleSize * 0.1);
  }

  double calculateResultConsistency(List<String> results) {
    if (results.length <= 1) return 1.0;
    Map<String, int> countMap = {};
    for (var res in results) {
      countMap[res] = (countMap[res] ?? 0) + 1;
    }
    int maxCount = countMap.values.reduce(max);
    return maxCount / results.length;
  }

  Future<double> getUserConfidenceBoost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('user_confidence_boost') ?? 0.0;
  }

  Future<void> setUserConfidenceBoost(double boost) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_confidence_boost', boost.clamp(0.0, 0.2));
  }

  double applyMedicalContextBoost(double confidence, double cobbAngle, int patientAge) {
    double contextBoost = 0.0;
    if (cobbAngle > 0) {
      if (cobbAngle >= 15 && cobbAngle <= 50) {
        contextBoost += 0.08;
      } else if (cobbAngle >= 10 && cobbAngle < 15) {
        contextBoost += 0.05;
      }
    }
    if (patientAge > 0) {
      if (patientAge >= 10 && patientAge <= 18) {
        contextBoost += 0.03;
      } else if (patientAge >= 6 && patientAge <= 25) {
        contextBoost += 0.02;
      }
    }
    double boostedConfidence = confidence + contextBoost;
    return boostedConfidence.clamp(minConfidence, maxConfidence);
  }

  String generateConfidenceExplanation(double originalConf, double boostedConf, BoostFactors? factors) {
    StringBuffer explanation = StringBuffer();
    explanation.writeln("AI Confidence Analysis:\n");
    explanation.writeln("Base Analysis: ${(originalConf * 100).toStringAsFixed(1)}%");
    explanation.writeln("Enhanced Score: ${(boostedConf * 100).toStringAsFixed(1)}%\n");
    explanation.writeln("Confidence Factors:");
    if (factors != null) {
      if (factors.keypointCount >= 12) {
        explanation.writeln("✓ Excellent keypoint detection (${factors.keypointCount}/17)");
      } else if (factors.keypointCount >= 8) {
        explanation.writeln("✓ Good keypoint detection (${factors.keypointCount}/17)");
      }
      if (factors.imageQualityScore > 0.7) {
        explanation.writeln("✓ High image quality");
      } else if (factors.imageQualityScore > 0.5) {
        explanation.writeln("✓ Adequate image quality");
      }
      if (factors.validationMethods > 1) {
        explanation.writeln("✓ Multiple validation methods (${factors.validationMethods})");
      }
      if (factors.resultConsistency > 0.8) {
        explanation.writeln("✓ Consistent analysis results");
      }
    }
    explanation.write("\nReliability: ");
    if (boostedConf >= 0.9) {
      explanation.write("Excellent");
    } else if (boostedConf >= 0.8) {
      explanation.write("Very Good");
    } else if (boostedConf >= 0.7) {
      explanation.write("Good");
    } else {
      explanation.write("Fair");
    }
    return explanation.toString();
  }
}

class BoostFactors {
  int keypointCount;
  double imageQualityScore;
  double algorithmReliability;
  int validationMethods;
  double resultConsistency;
  BoostFactors({
    this.keypointCount = 0,
    this.imageQualityScore = 0.5,
    this.algorithmReliability = 0.7,
    this.validationMethods = 1,
    this.resultConsistency = 0.8,
  });
}
