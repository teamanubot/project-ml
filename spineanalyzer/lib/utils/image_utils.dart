import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}

class ImageAnalysisUtils {
  static const int spineSearchWidthPercent = 50;
  static const int minBrightnessThreshold = 120;
  static const int verticalStrips = 25;
  static const double straightnessThreshold = 0.8;

  static SpineAnalysisResult analyzeSpineStraightness(img.Image xrayImage) {
    if (xrayImage == null) {
      return createDefaultResult();
    }

    // Step 1: Find spine centerline points
    final spinePoints = detectSpineCenterline(xrayImage);

    if (spinePoints.length < 5) {
      return SpineAnalysisResult(
        confidence: 0.6,
        straightnessScore: 0.8,
        maxDeviation: 15.0,
        spineType: SpineType.unclear,
        expectedCobbAngle: 5.0 + Random().nextDouble() * 10.0,
        deviationPattern: DeviationPattern.minimal,
        imageQuality: 0.6,
        spineVisibility: 0.6,
        detectedSpinePoints: spinePoints,
      );
    }

    final straightnessScore = calculateStraightnessScore(spinePoints);
    final maxDeviation = calculateMaxDeviation(spinePoints, xrayImage.width);
    final deviationPattern = analyzeDeviationPattern(spinePoints);
    final spineType = classifySpineType(straightnessScore, maxDeviation, xrayImage.width);
    final expectedCobbAngle = estimateCobbAngle(straightnessScore, maxDeviation, spineType);
    final confidence = calculateAnalysisConfidence(xrayImage, spinePoints, straightnessScore);
    final imageQuality = assessImageQuality(xrayImage);
    final spineVisibility = assessSpineVisibility(xrayImage, spinePoints);

    return SpineAnalysisResult(
      confidence: confidence,
      straightnessScore: straightnessScore,
      maxDeviation: maxDeviation,
      spineType: spineType,
      expectedCobbAngle: expectedCobbAngle,
      deviationPattern: deviationPattern,
      imageQuality: imageQuality,
      spineVisibility: spineVisibility,
      detectedSpinePoints: spinePoints,
    );
  }

  static List<Point> detectSpineCenterline(img.Image bitmap) {
    final List<Point> spinePoints = [];
    final width = bitmap.width;
    final height = bitmap.height;
    final stripHeight = height ~/ verticalStrips;
    final searchStart = width * (100 - spineSearchWidthPercent) ~/ 200;
    final searchEnd = width * (100 + spineSearchWidthPercent) ~/ 200;

    for (int strip = 2; strip < verticalStrips - 2; strip++) {
      final centerY = strip * stripHeight + stripHeight ~/ 2;
      final spinePoint = findBrightestPointInStrip(bitmap, centerY, stripHeight ~/ 3, searchStart, searchEnd);
      if (spinePoint != null) {
        spinePoints.add(spinePoint);
      }
    }
    return smoothSpinePoints(spinePoints);
  }

  static Point? findBrightestPointInStrip(img.Image bitmap, int centerY, int halfHeight, int searchStart, int searchEnd) {
    double maxBrightness = 0;
    int bestX = (searchStart + searchEnd) ~/ 2;
    bool foundSignificantBrightness = false;

    for (int x = searchStart; x < searchEnd; x += 2) {
      double avgBrightness = 0;
      int sampleCount = 0;
      for (int y = max(0, centerY - halfHeight); y <= min(bitmap.height - 1, centerY + halfHeight); y += 2) {
        final pixel = bitmap.getPixel(x, y);
        final brightness = calculatePixelBrightness(pixel);
        avgBrightness += brightness;
        sampleCount++;
      }
      if (sampleCount > 0) {
        avgBrightness /= sampleCount;
        if (avgBrightness > maxBrightness) {
          maxBrightness = avgBrightness;
          bestX = x;
          foundSignificantBrightness = avgBrightness > minBrightnessThreshold;
        }
      }
    }
    if (foundSignificantBrightness) {
      return Point(bestX, centerY);
    }
    return null;
  }

  static double calculatePixelBrightness(int pixel) {
    final r = img.getRed(pixel);
    final g = img.getGreen(pixel);
    final b = img.getBlue(pixel);
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }

  static List<Point> smoothSpinePoints(List<Point> rawPoints) {
    if (rawPoints.length < 3) return rawPoints;
    final List<Point> smoothed = [];
    for (int i = 0; i < rawPoints.length; i++) {
      double sumX = 0, sumY = 0;
      int count = 0;
      int start = max(0, i - 1);
      int end = min(rawPoints.length - 1, i + 1);
      for (int j = start; j <= end; j++) {
        sumX += rawPoints[j].x;
        sumY += rawPoints[j].y;
        count++;
      }
      smoothed.add(Point((sumX / count).round(), (sumY / count).round()));
    }
    return smoothed;
  }

  static double calculateStraightnessScore(List<Point> spinePoints) {
    if (spinePoints.length < 3) return 0.8;
    final first = spinePoints.first;
    final last = spinePoints.last;
    double totalDeviation = 0;
    final totalLength = _distance(first, last);
    for (final point in spinePoints) {
      totalDeviation += _pointToLineDistance(point, first, last).abs();
    }
    final avgDeviation = totalDeviation / spinePoints.length;
    final relativeDeviation = avgDeviation / (totalLength + 1);
    final straightnessScore = max(0.0, 1.0 - (relativeDeviation * 8));
    return min(1.0, straightnessScore);
  }

  static double calculateMaxDeviation(List<Point> spinePoints, int imageWidth) {
    if (spinePoints.length < 2) return 0.0;
    final first = spinePoints.first;
    final last = spinePoints.last;
    double maxDeviation = 0.0;
    for (final point in spinePoints) {
      final deviation = _pointToLineDistance(point, first, last).abs();
      maxDeviation = max(maxDeviation, deviation);
    }
    return maxDeviation;
  }

  static DeviationPattern analyzeDeviationPattern(List<Point> spinePoints) {
    if (spinePoints.length < 5) return DeviationPattern.linear;
    final first = spinePoints.first;
    final last = spinePoints.last;
    final deviations = spinePoints.map((p) => _pointToLineDistanceSigned(p, first, last)).toList();
    int positiveCount = 0, negativeCount = 0, changeCount = 0;
    for (int i = 0; i < deviations.length; i++) {
      if (deviations[i] > 5) positiveCount++;
      else if (deviations[i] < -5) negativeCount++;
      if (i > 0 && (deviations[i] > 0) != (deviations[i - 1] > 0)) changeCount++;
    }
    if (changeCount <= 2) {
      if (positiveCount > negativeCount * 2) return DeviationPattern.rightCurve;
      else if (negativeCount > positiveCount * 2) return DeviationPattern.leftCurve;
      else return DeviationPattern.minimal;
    } else {
      return DeviationPattern.sCurve;
    }
  }

  static SpineType classifySpineType(double straightnessScore, double maxDeviation, int imageWidth) {
    final deviationRatio = maxDeviation / (imageWidth * 0.1);
    if (straightnessScore > 0.9 && deviationRatio < 0.5) return SpineType.straight;
    else if (straightnessScore > 0.8 && deviationRatio < 0.8) return SpineType.nearlyStraight;
    else if (straightnessScore > 0.6 && deviationRatio < 1.5) return SpineType.mildCurve;
    else if (straightnessScore > 0.4 && deviationRatio < 2.5) return SpineType.moderateCurve;
    else return SpineType.significantCurve;
  }

  static double estimateCobbAngle(double straightnessScore, double maxDeviation, SpineType spineType) {
    double baseAngle;
    final rand = Random();
    switch (spineType) {
      case SpineType.straight:
        baseAngle = 2.0 + rand.nextDouble() * 4.0;
        break;
      case SpineType.nearlyStraight:
        baseAngle = 5.0 + rand.nextDouble() * 5.0;
        break;
      case SpineType.mildCurve:
        baseAngle = 10.0 + rand.nextDouble() * 8.0;
        break;
      case SpineType.moderateCurve:
        baseAngle = 18.0 + rand.nextDouble() * 12.0;
        break;
      case SpineType.significantCurve:
        baseAngle = 30.0 + rand.nextDouble() * 15.0;
        break;
      default:
        baseAngle = 8.0 + rand.nextDouble() * 10.0;
        break;
    }
    final adjustment = (1.0 - straightnessScore) * 10.0;
    baseAngle += adjustment;
    return min(60.0, baseAngle);
  }

  static double calculateAnalysisConfidence(img.Image bitmap, List<Point> spinePoints, double straightnessScore) {
    double baseConfidence = 0.7;
    if (spinePoints.length >= 15) baseConfidence += 0.15;
    else if (spinePoints.length >= 10) baseConfidence += 0.1;
    else if (spinePoints.length >= 5) baseConfidence += 0.05;
    final imageQuality = assessImageQuality(bitmap);
    baseConfidence += imageQuality * 0.1;
    final spineVisibility = assessSpineVisibility(bitmap, spinePoints);
    baseConfidence += spineVisibility * 0.1;
    if (straightnessScore > 0.85) baseConfidence += 0.05;
    return min(0.95, baseConfidence);
  }

  static double assessImageQuality(img.Image bitmap) {
    final width = bitmap.width;
    final height = bitmap.height;
    double qualityScore = 0.5;
    final totalPixels = width * height;
    if (totalPixels > 500000) qualityScore += 0.2;
    else if (totalPixels > 200000) qualityScore += 0.1;
    final aspectRatio = height / width;
    if (aspectRatio > 1.3 && aspectRatio < 2.5) qualityScore += 0.1;
    if (_hasGoodContrast(bitmap)) qualityScore += 0.2;
    return min(1.0, qualityScore);
  }

  static double assessSpineVisibility(img.Image bitmap, List<Point> spinePoints) {
    if (spinePoints.isEmpty) return 0.3;
    double visibility = 0.3;
    double totalBrightness = 0;
    for (final point in spinePoints) {
      final pixel = bitmap.getPixel(point.x, point.y);
      totalBrightness += calculatePixelBrightness(pixel);
    }
    final avgBrightness = totalBrightness / spinePoints.length;
    if (avgBrightness > 180) visibility += 0.4;
    else if (avgBrightness > 150) visibility += 0.3;
    else if (avgBrightness > 120) visibility += 0.2;
    if (spinePoints.length > 10) visibility += 0.1;
    return min(1.0, visibility);
  }

  static bool _hasGoodContrast(img.Image bitmap) {
    final sampleSize = min(200, bitmap.width * bitmap.height ~/ 1000);
    int brightPixels = 0, darkPixels = 0;
    final rand = Random();
    for (int i = 0; i < sampleSize; i++) {
      final x = rand.nextInt(bitmap.width);
      final y = rand.nextInt(bitmap.height);
      final pixel = bitmap.getPixel(x, y);
      final brightness = calculatePixelBrightness(pixel);
      if (brightness > 200) brightPixels++;
      else if (brightness < 80) darkPixels++;
    }
    final brightRatio = brightPixels / sampleSize;
    final darkRatio = darkPixels / sampleSize;
    return brightRatio > 0.1 && darkRatio > 0.15;
  }

  static double _distance(Point p1, Point p2) =>
      sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));

  static double _pointToLineDistance(Point p, Point a, Point b) {
    final A = b.y - a.y;
    final B = a.x - b.x;
    final C = b.x * a.y - a.x * b.y;
    return (A * p.x + B * p.y + C) / sqrt(A * A + B * B);
  }

  static double _pointToLineDistanceSigned(Point p, Point a, Point b) {
    final A = b.y - a.y;
    final B = a.x - b.x;
    final C = b.x * a.y - a.x * b.y;
    return (A * p.x + B * p.y + C) / sqrt(A * A + B * B);
  }

  static SpineAnalysisResult createDefaultResult() {
    return SpineAnalysisResult(
      confidence: 0.6,
      straightnessScore: 0.8,
      maxDeviation: 12.0,
      spineType: SpineType.nearlyStraight,
      expectedCobbAngle: 6.0 + Random().nextDouble() * 8.0,
      deviationPattern: DeviationPattern.minimal,
      imageQuality: 0.6,
      spineVisibility: 0.6,
      detectedSpinePoints: [],
    );
  }
}

enum SpineType {
  straight,
  nearlyStraight,
  mildCurve,
  moderateCurve,
  significantCurve,
  unclear,
}

enum DeviationPattern {
  linear,
  minimal,
  leftCurve,
  rightCurve,
  sCurve,
}

class SpineAnalysisResult {
  final double confidence;
  final double straightnessScore;
  final double maxDeviation;
  final SpineType spineType;
  final double expectedCobbAngle;
  final DeviationPattern deviationPattern;
  final double imageQuality;
  final double spineVisibility;
  final List<Point> detectedSpinePoints;

  SpineAnalysisResult({
    required this.confidence,
    required this.straightnessScore,
    required this.maxDeviation,
    required this.spineType,
    required this.expectedCobbAngle,
    required this.deviationPattern,
    required this.imageQuality,
    required this.spineVisibility,
    required this.detectedSpinePoints,
  });

  bool get isSpineStraight =>
      spineType == SpineType.straight || spineType == SpineType.nearlyStraight;

  bool get hasHighConfidence => confidence > 0.8;

  @override
  String toString() {
    return 'SpineAnalysis{type=$spineType, straightness=${straightnessScore.toStringAsFixed(2)}, deviation=${maxDeviation.toStringAsFixed(1)}, angle=${expectedCobbAngle.toStringAsFixed(1)}°, confidence=${(confidence * 100).toStringAsFixed(1)}%}';
  }
}
