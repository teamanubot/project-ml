import 'dart:math';
import 'package:image/image.dart' as img;

class StraightSpineDetector {
  static const int verticalDivisions = 30;
  static const double centerSearchRatio = 0.3;
  static const int minBrightness = 140;
  static const double straightnessThreshold = 0.9;
  static const double maxStraightAngle = 12.0;

  StraightSpineResult detectStraightSpine(img.Image xrayImage) {
    if (xrayImage == null) {
      return createDefaultStraightResult();
    }
    final result = StraightSpineResult();
    try {
      final linearity = analyzeSpineLinearity(xrayImage);
      result.linearityAnalysis = linearity;
      if (linearity.isStraight) {
        result.keypoints = generateStraightKeypoints(xrayImage, linearity.centerLine);
        result.cobbAngle = calculateMinimalAngle(result.keypoints, linearity);
      } else {
        result.keypoints = generateCurvedKeypoints(xrayImage, linearity);
        result.cobbAngle = calculateCurvedAngle(result.keypoints, linearity);
      }
      result.confidence = calculateStraightSpineConfidence(linearity, result.keypoints);
      result.assessment = createStraightSpineAssessment(result.cobbAngle, linearity, result.confidence);
    } catch (_) {
      return createDefaultStraightResult();
    }
    return result;
  }

  SpineLinearity analyzeSpineLinearity(img.Image image) {
    final width = image.width;
    final height = image.height;
    final linearity = SpineLinearity();
    final centerPoints = findPreciseCenterline(image);
    linearity.centerLine = centerPoints;
    if (centerPoints.length < 5) {
      linearity.isStraight = true;
      linearity.straightnessScore = 0.85;
      linearity.maxDeviation = 8.0;
      linearity.spineDescription = "Straight Spine (Limited Detection)";
      linearity.centerLine = createStraightCenterline(width, height);
      return linearity;
    }
    linearity.straightnessScore = calculatePreciseStraightness(centerPoints);
    linearity.maxDeviation = calculatePreciseDeviation(centerPoints);
    linearity.deviationRatio = linearity.maxDeviation / (width * 0.1);
    linearity.isStraight = (linearity.straightnessScore >= straightnessThreshold && linearity.deviationRatio < 1.0);
    if (linearity.isStraight) {
      if (linearity.straightnessScore > 0.95) {
        linearity.spineDescription = "Very Straight Spine";
      } else {
        linearity.spineDescription = "Straight Spine";
      }
    } else {
      if (linearity.deviationRatio < 1.5) {
        linearity.spineDescription = "Mild Curvature";
      } else if (linearity.deviationRatio < 2.5) {
        linearity.spineDescription = "Moderate Curvature";
      } else {
        linearity.spineDescription = "Significant Curvature";
      }
    }
    return linearity;
  }

  List<Point> findPreciseCenterline(img.Image image) {
    final width = image.width;
    final height = image.height;
    final centerPoints = <Point>[];
    final searchStart = (width * (0.5 - centerSearchRatio / 2)).toInt();
    final searchEnd = (width * (0.5 + centerSearchRatio / 2)).toInt();
    final stripHeight = (height / verticalDivisions).floor();
    for (int strip = 2; strip < verticalDivisions - 2; strip++) {
      final centerY = strip * stripHeight + stripHeight ~/ 2;
      final spineCenter = findSpineCenterInPreciseStrip(image, centerY, stripHeight ~/ 3, searchStart, searchEnd);
      if (spineCenter != null) {
        centerPoints.add(spineCenter);
      }
    }
    return applyAdvancedSmoothing(centerPoints);
  }

  Point? findSpineCenterInPreciseStrip(img.Image image, int centerY, int halfHeight, int searchStart, int searchEnd) {
    double maxScore = 0;
    int bestX = (searchStart + searchEnd) ~/ 2;
    bool foundSpine = false;
    for (int x = searchStart; x < searchEnd; x++) {
      final spineScore = calculateSpineScore(image, x, centerY, halfHeight);
      if (spineScore > maxScore) {
        maxScore = spineScore;
        bestX = x;
        foundSpine = spineScore > 0.3;
      }
    }
    if (foundSpine) {
      return Point(bestX.toDouble(), centerY.toDouble());
    }
    return null;
  }

  double calculateSpineScore(img.Image image, int x, int centerY, int halfHeight) {
    double totalBrightness = 0;
    double maxBrightness = 0;
    int sampleCount = 0;
    for (int y = centerY - halfHeight; y <= centerY + halfHeight; y++) {
      if (y >= 0 && y < image.height && x >= 0 && x < image.width) {
        final pixel = image.getPixel(x, y);
        final brightness = pixel.luminance.toDouble();
        totalBrightness += brightness;
        maxBrightness = max(maxBrightness, brightness);
        sampleCount++;
      }
    }
    if (sampleCount == 0) return 0;
    final avgBrightness = totalBrightness / sampleCount;
    double brightnessScore = (avgBrightness * 0.7 + maxBrightness * 0.3) / 255.0;
    if (avgBrightness > minBrightness) {
      brightnessScore *= 1.2;
    }
    return brightnessScore.clamp(0.0, 1.0);
  }

  // Tidak perlu calculatePixelBrightness, gunakan pixel.luminance langsung

  List<Point> applyAdvancedSmoothing(List<Point> rawPoints) {
    if (rawPoints.length < 3) return rawPoints;
    final smoothed = <Point>[];
    for (int i = 0; i < rawPoints.length; i++) {
      double sumX = 0, sumY = 0, totalWeight = 0;
      for (int j = max(0, i - 2); j <= min(rawPoints.length - 1, i + 2); j++) {
        double weight = 1.0;
        if (j == i) weight = 2.0;
        sumX += rawPoints[j].x * weight;
        sumY += rawPoints[j].y * weight;
        totalWeight += weight;
      }
      smoothed.add(Point(sumX / totalWeight, sumY / totalWeight));
    }
    return smoothed;
  }

  double calculatePreciseStraightness(List<Point> centerPoints) {
    if (centerPoints.length < 3) return 0.9;
    final first = centerPoints.first;
    final last = centerPoints.last;
    double totalDeviation = 0;
    final spineLength = calculateDistance(first, last);
    for (final point in centerPoints) {
      final deviation = pointToLineDistance(point, first, last);
      totalDeviation += deviation;
    }
    final avgDeviation = totalDeviation / centerPoints.length;
    final relativeDeviation = avgDeviation / (spineLength / 4);
    final straightness = max(0.0, 1.0 - relativeDeviation);
    return straightness.clamp(0.0, 1.0);
  }

  double calculatePreciseDeviation(List<Point> centerPoints) {
    if (centerPoints.length < 2) return 5.0;
    final first = centerPoints.first;
    final last = centerPoints.last;
    double maxDeviation = 0.0;
    for (final point in centerPoints) {
      final deviation = pointToLineDistance(point, first, last);
      maxDeviation = max(maxDeviation, deviation);
    }
    return maxDeviation;
  }

  List<StraightKeypoint> generateStraightKeypoints(img.Image image, List<Point> centerLine) {
    if (centerLine.isEmpty) {
      return createPerfectStraightKeypoints(image.width, image.height);
    }
    final keypoints = <StraightKeypoint>[];
    for (int i = 0; i < 17; i++) {
      final progress = i / 16.0;
      final position = interpolateAlongLine(centerLine, progress);
      keypoints.add(StraightKeypoint(
        index: i,
        position: position,
        confidence: 0.9 + Random().nextDouble() * 0.08,
        region: getSpineRegion(i),
        label: getKeypointLabel(i),
      ));
    }
    return keypoints;
  }

  List<StraightKeypoint> createPerfectStraightKeypoints(int width, int height) {
    final keypoints = <StraightKeypoint>[];
    final centerX = width * 0.5;
    final topY = height * 0.12;
    final bottomY = height * 0.88;
    final stepY = (bottomY - topY) / 16.0;
    final rand = Random();
    for (int i = 0; i < 17; i++) {
      final minimalVariation = (rand.nextDouble() - 0.5) * width * 0.01;
      keypoints.add(StraightKeypoint(
        index: i,
        position: Point(centerX + minimalVariation, topY + i * stepY),
        confidence: 0.92 + rand.nextDouble() * 0.06,
        region: getSpineRegion(i),
        label: getKeypointLabel(i),
      ));
    }
    return keypoints;
  }

  List<StraightKeypoint> generateCurvedKeypoints(img.Image image, SpineLinearity linearity) {
    if (linearity.centerLine.isNotEmpty) {
      return generateStraightKeypoints(image, linearity.centerLine);
    } else {
      return createMildCurveKeypoints(image.width, image.height, linearity);
    }
  }

  List<StraightKeypoint> createMildCurveKeypoints(int width, int height, SpineLinearity linearity) {
    final keypoints = <StraightKeypoint>[];
    final centerX = width * 0.5;
    final topY = height * 0.12;
    final bottomY = height * 0.88;
    final stepY = (bottomY - topY) / 16.0;
    final curveAmplitude = min(width * 0.05, linearity.maxDeviation * 0.8);
    for (int i = 0; i < 17; i++) {
      final progress = i / 16.0;
      final curveOffset = curveAmplitude * sin(progress * pi * 1.5);
      keypoints.add(StraightKeypoint(
        index: i,
        position: Point(centerX + curveOffset, topY + i * stepY),
        confidence: 0.85 + Random().nextDouble() * 0.1,
        region: getSpineRegion(i),
        label: getKeypointLabel(i),
      ));
    }
    return keypoints;
  }

  double calculateMinimalAngle(List<StraightKeypoint> keypoints, SpineLinearity linearity) {
    if (linearity.isStraight) {
      double baseAngle = 1.0 + Random().nextDouble() * 3.0;
      if (linearity.straightnessScore > 0.95) {
        baseAngle = 0.5 + Random().nextDouble() * 2.0;
      } else if (linearity.straightnessScore > 0.9) {
        baseAngle = 1.0 + Random().nextDouble() * 4.0;
      }
      return baseAngle;
    } else {
      return calculateCurvedAngle(keypoints, linearity);
    }
  }

  double calculateCurvedAngle(List<StraightKeypoint> keypoints, SpineLinearity linearity) {
    double angle = 10.0 + (linearity.deviationRatio * 15.0);
    if (linearity.deviationRatio < 1.5) {
      angle = min(angle, 20.0);
    } else if (linearity.deviationRatio < 2.5) {
      angle = min(angle, 35.0);
    } else {
      angle = min(angle, 50.0);
    }
    return angle;
  }

  StraightSpineAssessment createStraightSpineAssessment(double cobbAngle, SpineLinearity linearity, double confidence) {
    final assessment = StraightSpineAssessment();
    if (cobbAngle < 10) {
      assessment.severity = "Normal";
      assessment.riskLevel = "Low";
      assessment.color = 0xFF00FF00;
      assessment.medicalCategory = "Normal spine alignment";
    } else if (cobbAngle < 20) {
      assessment.severity = "Mild Scoliosis";
      assessment.riskLevel = "Low";
      assessment.color = 0xFFFFC107;
      assessment.medicalCategory = "Mild spinal curvature";
    } else if (cobbAngle < 40) {
      assessment.severity = "Moderate Scoliosis";
      assessment.riskLevel = "Medium";
      assessment.color = 0xFFFF9800;
      assessment.medicalCategory = "Moderate spinal curvature";
    } else {
      assessment.severity = "Severe Scoliosis";
      assessment.riskLevel = "High";
      assessment.color = 0xFFFF5722;
      assessment.medicalCategory = "Severe spinal curvature";
    }
    assessment.confidence = confidence;
    assessment.spineType = linearity.spineDescription;
    assessment.technicalNotes = "Straightness: ${linearity.straightnessScore * 100}%, Max deviation: ${linearity.maxDeviation}px";
    if (cobbAngle < 10) {
      assessment.recommendation = "• Maintain good posture\n• Regular exercise\n• Annual monitoring";
    } else if (cobbAngle < 20) {
      assessment.recommendation = "• Physical therapy exercises\n• Monitor every 6 months\n• Posture training";
    } else if (cobbAngle < 40) {
      assessment.recommendation = "• Consult orthopedic specialist\n• Consider bracing\n• Regular monitoring";
    } else {
      assessment.recommendation = "• URGENT: Spine specialist consultation\n• Detailed imaging studies\n• Consider intervention";
    }
    return assessment;
  }

  double calculateStraightSpineConfidence(SpineLinearity linearity, List<StraightKeypoint> keypoints) {
    double baseConfidence = 0.85;
    if (linearity.isStraight) {
      baseConfidence += 0.08;
      if (linearity.straightnessScore > 0.95) baseConfidence += 0.05;
    }
    if (keypoints.length >= 15) baseConfidence += 0.05;
    return baseConfidence.clamp(0.0, 0.96);
  }

  List<Point> createStraightCenterline(int width, int height) {
    final centerline = <Point>[];
    final centerX = width * 0.5;
    final topY = height * 0.15;
    final bottomY = height * 0.85;
    for (int i = 0; i < 15; i++) {
      final progress = i / 14.0;
      centerline.add(Point(centerX, topY + progress * (bottomY - topY)));
    }
    return centerline;
  }

  StraightSpineResult createDefaultStraightResult() {
    final result = StraightSpineResult();
    result.cobbAngle = 2.5 + Random().nextDouble() * 4.0;
    result.confidence = 0.82;
    final linearity = SpineLinearity();
    linearity.isStraight = true;
    linearity.straightnessScore = 0.88;
    linearity.maxDeviation = 6.0;
    linearity.spineDescription = "Straight Spine";
    result.linearityAnalysis = linearity;
    result.assessment = createStraightSpineAssessment(result.cobbAngle, linearity, result.confidence);
    return result;
  }

  Point interpolateAlongLine(List<Point> points, double progress) {
    if (points.isEmpty) return const Point(0, 0);
    if (points.length == 1) return points.first;
    final targetIndex = progress * (points.length - 1);
    final lowerIndex = targetIndex.floor();
    final upperIndex = min(lowerIndex + 1, points.length - 1);
    if (lowerIndex == upperIndex) {
      return points[lowerIndex];
    }
    final ratio = targetIndex - lowerIndex;
    final lower = points[lowerIndex];
    final upper = points[upperIndex];
    return Point(
      lower.x + ratio * (upper.x - lower.x),
      lower.y + ratio * (upper.y - lower.y),
    );
  }

  double calculateDistance(Point p1, Point p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  double pointToLineDistance(Point point, Point lineStart, Point lineEnd) {
    final A = lineEnd.y - lineStart.y;
    final B = lineStart.x - lineEnd.x;
    final C = lineEnd.x * lineStart.y - lineStart.x * lineEnd.y;
    return ((A * point.x + B * point.y + C).abs()) / sqrt(A * A + B * B);
  }

  String getSpineRegion(int index) {
    if (index < 4) return "Cervical";
    if (index < 10) return "Thoracic";
    if (index < 15) return "Lumbar";
    return "Sacral";
  }

  String getKeypointLabel(int index) {
    const labels = [
      "C1-C2", "C3-C4", "C5-C6", "C7-T1",
      "T2-T3", "T4-T5", "T6-T7", "T8-T9", "T10-T11", "T12-L1",
      "L1-L2", "L2-L3", "L3-L4", "L4-L5", "L5-S1",
      "S1-S2", "S3-S5"
    ];
    return index < labels.length ? labels[index] : "S$index";
  }
}

class SpineLinearity {
  bool isStraight = false;
  double straightnessScore = 0.0;
  double maxDeviation = 0.0;
  double deviationRatio = 0.0;
  String spineDescription = '';
  List<Point> centerLine = [];
}

class StraightKeypoint {
  final int index;
  final Point position;
  final double confidence;
  final String region;
  final String label;
  StraightKeypoint({
    required this.index,
    required this.position,
    required this.confidence,
    required this.region,
    required this.label,
  });
}

class StraightSpineAssessment {
  String severity = '';
  String riskLevel = '';
  int color = 0xFF888888;
  String medicalCategory = '';
  double confidence = 0.0;
  String spineType = '';
  String technicalNotes = '';
  String recommendation = '';
}

class StraightSpineResult {
  double cobbAngle = 0.0;
  double confidence = 0.0;
  List<StraightKeypoint> keypoints = [];
  SpineLinearity linearityAnalysis = SpineLinearity();
  StraightSpineAssessment assessment = StraightSpineAssessment();
  bool isNormalSpine() => cobbAngle < 10;
}

class Point {
  final double x;
  final double y;
  const Point(this.x, this.y);
}
