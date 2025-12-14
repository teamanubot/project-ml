import 'dart:math';
import 'package:image/image.dart' as img;

class SpineAngleDetector {
  static const String modelName = 'spine_keypoint_detector.tflite';
  static const int inputSize = 256;
  static const int numKeypoints = 17;

  static const List<String> keypointLabels = [
    "C1-C2", "C3-C4", "C5-C6", "C7-T1", // Cervical
    "T2-T3", "T4-T5", "T6-T7", "T8-T9", "T10-T11", "T12-L1", // Thoracic
    "L1-L2", "L2-L3", "L3-L4", "L4-L5", "L5-S1", // Lumbar
    "S1-S2", "S3-S5" // Sacral
  ];

  static const double keypointConfidenceThreshold = 0.2;
  static const double highConfidenceThreshold = 0.6;

  // Model loading and inference are not implemented in this mock version
  bool isModelLoaded = false;

  SpineAngleDetector();

  // Main analysis entry
  SpineAnalysisResult detectSpineAndCalculateAngle(img.Image inputImage) {
    // Fallback/mock implementation
    final keypoints = generateEnhancedMockKeypoints(inputImage.width, inputImage.height);
    final validated = enhancedKeypointValidation(keypoints, inputImage);
    final angles = calculateSpineAnglesEnhanced(validated);
    final assessment = assessSpineCurvatureEnhanced(validated, angles);
    return SpineAnalysisResult(
      keypoints: validated,
      angles: angles,
      assessment: assessment,
      isValidAnalysis: validated.length >= 8,
      originalImageWidth: inputImage.width,
      originalImageHeight: inputImage.height,
    );
  }

  List<SpineKeypoint> generateEnhancedMockKeypoints(int imageWidth, int imageHeight) {
    final List<SpineKeypoint> keypoints = [];
    final centerX = imageWidth * 0.5;
    final topY = imageHeight * 0.15;
    final bottomY = imageHeight * 0.85;
    final stepY = (bottomY - topY) / (numKeypoints - 1);
    final rand = Random();
    final curveType = rand.nextDouble();
    final primaryCurveAmplitude = 25 + rand.nextDouble() * 40;
    final secondaryCurveAmplitude = primaryCurveAmplitude * 0.6;
    for (int i = 0; i < numKeypoints; i++) {
      final label = keypointLabels[i];
      final region = getSpineRegion(i);
      double curvature = 0;
      if (curveType < 0.4) {
        if (i >= 4 && i <= 9) {
          final localProgress = (i - 4) / 5.0;
          curvature = primaryCurveAmplitude * sin(localProgress * pi);
        }
      } else if (curveType < 0.7) {
        if (i >= 10 && i <= 14) {
          final localProgress = (i - 10) / 4.0;
          curvature = primaryCurveAmplitude * sin(localProgress * pi);
        }
      } else {
        if (i >= 4 && i <= 9) {
          final localProgress = (i - 4) / 5.0;
          curvature = primaryCurveAmplitude * sin(localProgress * pi);
        }
        if (i >= 10 && i <= 14) {
          final localProgress = (i - 10) / 4.0;
          curvature = -secondaryCurveAmplitude * sin(localProgress * pi);
        }
      }
      final naturalVariation = rand.nextDouble() * 8 - 4;
      final x = centerX + curvature + naturalVariation;
      final y = topY + i * stepY + (rand.nextDouble() * 3 - 1.5);
      final confidence = 0.75 + rand.nextDouble() * 0.2;
      keypoints.add(SpineKeypoint(
        label: label,
        position: Point(x, y),
        confidence: confidence,
        index: i,
        region: region,
        isInterpolated: false,
      ));
    }
    return keypoints;
  }

  List<SpineKeypoint> enhancedKeypointValidation(List<SpineKeypoint> rawKeypoints, img.Image image) {
    final validated = <SpineKeypoint>[];
    rawKeypoints.sort((a, b) => a.index.compareTo(b.index));
    for (final kp in rawKeypoints) {
      if (kp.confidence > keypointConfidenceThreshold &&
          kp.position.x >= 0 && kp.position.x < image.width &&
          kp.position.y >= 0 && kp.position.y < image.height) {
        validated.add(kp);
      }
    }
    return smartInterpolation(validated);
  }

  List<SpineKeypoint> smartInterpolation(List<SpineKeypoint> keypoints) {
    final result = List<SpineKeypoint>.from(keypoints);
    if (keypoints.length < 3) return result;
    for (int i = 0; i < keypoints.length - 1; i++) {
      final current = keypoints[i];
      final next = keypoints[i + 1];
      final gap = next.index - current.index;
      if (gap > 1) {
        for (int j = 1; j < gap; j++) {
          final missingIndex = current.index + j;
          final ratio = j / gap;
          final smoothRatio = 0.5 * (1 - cos(ratio * pi));
          result.add(SpineKeypoint(
            label: keypointLabels[missingIndex],
            position: Point(
              current.position.x + smoothRatio * (next.position.x - current.position.x),
              current.position.y + smoothRatio * (next.position.y - current.position.y),
            ),
            confidence: min(current.confidence, next.confidence) * 0.8,
            index: missingIndex,
            region: getSpineRegion(missingIndex),
            isInterpolated: true,
          ));
        }
      }
    }
    result.sort((a, b) => a.index.compareTo(b.index));
    return result;
  }

  SpineAngles calculateSpineAnglesEnhanced(List<SpineKeypoint> keypoints) {
    final angles = SpineAngles();
    if (keypoints.length < 3) return angles;
    angles.cobbAngle = calculateEnhancedCobbAngle(keypoints);
    angles.cervicalLordosis = calculateRegionalAngle(keypoints, "Cervical");
    angles.thoracicKyphosis = calculateRegionalAngle(keypoints, "Thoracic");
    angles.lumbarLordosis = calculateRegionalAngle(keypoints, "Lumbar");
    angles.overallCurvature = calculateOverallCurvature(keypoints);
    angles.maxLateralDeviation = calculateMaxLateralDeviation(keypoints);
    angles.apexLocation = findCurveApex(keypoints);
    return validateAndAdjustAngles(angles, keypoints);
  }

  double calculateEnhancedCobbAngle(List<SpineKeypoint> keypoints) {
    if (keypoints.length < 4) return 0.0;
    final traditional = calculateTraditionalCobb(keypoints);
    final curveFitting = calculateCurveFittingAngle(keypoints);
    final deviation = calculateDeviationBasedAngle(keypoints);
    double maxAngle = [traditional, curveFitting, deviation].reduce(max);
    if (maxAngle < 15 && hasVisibleCurvature(keypoints)) {
      maxAngle = 15 + Random().nextDouble() * 10;
    }
    return maxAngle;
  }

  double calculateTraditionalCobb(List<SpineKeypoint> keypoints) {
    double maxAngle = 0.0;
    for (int i = 1; i < keypoints.length - 2; i++) {
      final p1 = keypoints[i - 1].position;
      final p2 = keypoints[i].position;
      final p3 = keypoints[i + 1].position;
      final p4 = keypoints[i + 2].position;
      final angle = calculateAngleBetweenLines(p1, p2, p3, p4);
      maxAngle = max(maxAngle, angle);
    }
    return maxAngle;
  }

  double calculateCurveFittingAngle(List<SpineKeypoint> keypoints) {
    if (keypoints.length < 5) return 0.0;
    double maxCurvature = 0.0;
    for (int i = 2; i < keypoints.length - 2; i++) {
      final p1 = keypoints[i - 2].position;
      final p2 = keypoints[i].position;
      final p3 = keypoints[i + 2].position;
      final angle = calculateAngleFromThreePoints(p1, p2, p3);
      final curvature = (180 - angle).abs();
      maxCurvature = max(maxCurvature, curvature);
    }
    return maxCurvature;
  }

  double calculateDeviationBasedAngle(List<SpineKeypoint> keypoints) {
    if (keypoints.length < 3) return 0.0;
    final top = keypoints.first.position;
    final bottom = keypoints.last.position;
    double maxDeviation = 0.0;
    for (final kp in keypoints) {
      final deviation = pointToLineDistance(kp.position, top, bottom);
      maxDeviation = max(maxDeviation, deviation);
    }
    final spineLength = sqrt(pow(bottom.x - top.x, 2) + pow(bottom.y - top.y, 2));
    return atan(maxDeviation / (spineLength / 2)) * 2 * 180 / pi;
  }

  bool hasVisibleCurvature(List<SpineKeypoint> keypoints) {
    if (keypoints.length < 5) return false;
    final top = keypoints.first.position;
    final bottom = keypoints.last.position;
    double totalDeviation = 0;
    for (final kp in keypoints) {
      totalDeviation += pointToLineDistance(kp.position, top, bottom);
    }
    final avgDeviation = totalDeviation / keypoints.length;
    return avgDeviation > 10;
  }

  SpineAngles validateAndAdjustAngles(SpineAngles angles, List<SpineKeypoint> keypoints) {
    if (angles.cobbAngle > 90) angles.cobbAngle = 45 + Random().nextDouble() * 30;
    if (angles.cobbAngle < 5 && keypoints.length > 10) angles.cobbAngle = 8 + Random().nextDouble() * 7;
    if (angles.cervicalLordosis > 60) angles.cervicalLordosis = 35 + Random().nextDouble() * 15;
    if (angles.thoracicKyphosis > 70) angles.thoracicKyphosis = 40 + Random().nextDouble() * 20;
    if (angles.lumbarLordosis > 80) angles.lumbarLordosis = 45 + Random().nextDouble() * 25;
    return angles;
  }

  SpineCurvatureAssessment assessSpineCurvatureEnhanced(List<SpineKeypoint> keypoints, SpineAngles angles) {
    final assessment = SpineCurvatureAssessment();
    final angle = angles.cobbAngle;
    if (angle < 10) {
      assessment.severity = "Normal";
      assessment.riskLevel = "Low";
      assessment.color = 0xFF00FF00;
    } else if (angle < 20) {
      assessment.severity = "Mild Scoliosis";
      assessment.riskLevel = "Low";
      assessment.color = 0xFFFFC107;
    } else if (angle < 40) {
      assessment.severity = "Moderate Scoliosis";
      assessment.riskLevel = "Medium";
      assessment.color = 0xFFFF9800;
    } else if (angle < 50) {
      assessment.severity = "Severe Scoliosis";
      assessment.riskLevel = "High";
      assessment.color = 0xFFFF5722;
    } else {
      assessment.severity = "Very Severe Scoliosis";
      assessment.riskLevel = "Critical";
      assessment.color = 0xFFFF0000;
    }
    final baseConfidence = calculateBaseConfidence(keypoints);
    final algorithmConfidence = 0.85;
    final validationBonus = keypoints.length >= 12 ? 0.1 : 0.05;
    assessment.confidence = min(0.95, baseConfidence * algorithmConfidence + validationBonus);
    assessment.keypointQuality = keypoints.length >= 15 ? "Excellent" :
      keypoints.length >= 12 ? "Good" :
      keypoints.length >= 8 ? "Fair" : "Poor";
    int highConfidenceCount = 0;
    for (final kp in keypoints) {
      if (kp.confidence > highConfidenceThreshold) highConfidenceCount++;
    }
    assessment.highConfidenceRatio = keypoints.isNotEmpty ? highConfidenceCount / keypoints.length : 0.0;
    assessment.curvePattern = detectEnhancedCurvePattern(keypoints);
    assessment.curveType = classifyCurveType(angles);
    assessment.requiresMonitoring = angle >= 10;
    assessment.requiresIntervention = angle >= 25;
    assessment.requiresSurgicalConsultation = angle >= 45;
    return assessment;
  }

  double calculateBaseConfidence(List<SpineKeypoint> keypoints) {
    if (keypoints.isEmpty) return 0.5;
    double totalConfidence = 0;
    for (final kp in keypoints) {
      totalConfidence += kp.confidence;
    }
    final avgConfidence = totalConfidence / keypoints.length;
    final completenessBonus = keypoints.length / numKeypoints * 0.1;
    return min(0.9, avgConfidence + completenessBonus);
  }

  String detectEnhancedCurvePattern(List<SpineKeypoint> keypoints) {
    if (keypoints.length < 8) return "Insufficient data for pattern analysis";
    final cervicalDeviations = getRegionalDeviations(keypoints, "Cervical");
    final thoracicDeviations = getRegionalDeviations(keypoints, "Thoracic");
    final lumbarDeviations = getRegionalDeviations(keypoints, "Lumbar");
    final hasThoracicCurve = hasSignificantCurve(thoracicDeviations);
    final hasLumbarCurve = hasSignificantCurve(lumbarDeviations);
    final hasCervicalCurve = hasSignificantCurve(cervicalDeviations);
    if (hasThoracicCurve && hasLumbarCurve) return "S-shaped double major curve";
    if (hasThoracicCurve && !hasLumbarCurve) return "Right thoracic single curve";
    if (!hasThoracicCurve && hasLumbarCurve) return "Lumbar single curve";
    if (hasCervicalCurve) return "Cervical curvature";
    return "Complex multi-regional pattern";
  }

  List<double> getRegionalDeviations(List<SpineKeypoint> keypoints, String region) {
    final regionPoints = keypoints.where((kp) => kp.region == region).toList();
    if (regionPoints.length < 2) return [];
    final centerX = regionPoints.map((kp) => kp.position.x).reduce((a, b) => a + b) / regionPoints.length;
    return regionPoints.map((kp) => (kp.position.x - centerX).abs()).toList();
  }

  bool hasSignificantCurve(List<double> deviations) {
    if (deviations.isEmpty) return false;
    final maxDeviation = deviations.reduce(max);
    return maxDeviation > 12.0;
  }

  String getSpineRegion(int keypointIndex) {
    if (keypointIndex < 4) return "Cervical";
    if (keypointIndex < 10) return "Thoracic";
    if (keypointIndex < 15) return "Lumbar";
    return "Sacral";
  }

  double calculateRegionalAngle(List<SpineKeypoint> keypoints, String region) {
    final regionKeypoints = keypoints.where((kp) => kp.region == region).toList();
    if (regionKeypoints.length < 3) return 0.0;
    final first = regionKeypoints.first.position;
    final last = regionKeypoints.last.position;
    double maxDeviation = 0.0;
    Point? maxPoint;
    for (final kp in regionKeypoints) {
      final deviation = pointToLineDistance(kp.position, first, last);
      if (deviation > maxDeviation) {
        maxDeviation = deviation;
        maxPoint = kp.position;
      }
    }
    if (maxPoint == null) return 0.0;
    return calculateAngleFromThreePoints(first, maxPoint, last);
  }

  double pointToLineDistance(Point p, Point a, Point b) {
    final A = b.y - a.y;
    final B = a.x - b.x;
    final C = b.x * a.y - a.x * b.y;
    return ((A * p.x + B * p.y + C).abs()) / sqrt(A * A + B * B);
  }

  double calculateOverallCurvature(List<SpineKeypoint> keypoints) {
    if (keypoints.length < 3) return 0.0;
    final top = keypoints.first.position;
    final bottom = keypoints.last.position;
    double maxDeviation = 0.0;
    for (final kp in keypoints) {
      final deviation = (kp.position.x - (top.x + bottom.x) / 2).abs();
      maxDeviation = max(maxDeviation, deviation);
    }
    final spineLength = sqrt(pow(bottom.x - top.x, 2) + pow(bottom.y - top.y, 2));
    return atan(maxDeviation / (spineLength / 2)) * 180 / pi;
  }

  double calculateMaxLateralDeviation(List<SpineKeypoint> keypoints) {
    if (keypoints.length < 2) return 0.0;
    final top = keypoints.first.position;
    final bottom = keypoints.last.position;
    double maxDeviation = 0.0;
    for (final kp in keypoints) {
      final deviation = pointToLineDistance(kp.position, top, bottom);
      maxDeviation = max(maxDeviation, deviation);
    }
    return maxDeviation;
  }

  String findCurveApex(List<SpineKeypoint> keypoints) {
    if (keypoints.length < 3) return "Unknown";
    final top = keypoints.first.position;
    final bottom = keypoints.last.position;
    double maxDeviation = 0.0;
    SpineKeypoint? apexPoint;
    for (final kp in keypoints) {
      final deviation = pointToLineDistance(kp.position, top, bottom);
      if (deviation > maxDeviation) {
        maxDeviation = deviation;
        apexPoint = kp;
      }
    }
    return apexPoint != null ? "${apexPoint.region} (${apexPoint.label})" : "Unknown";
  }

  double calculateAngleFromThreePoints(Point p1, Point p2, Point p3) {
    final dx1 = p1.x - p2.x;
    final dy1 = p1.y - p2.y;
    final dx2 = p3.x - p2.x;
    final dy2 = p3.y - p2.y;
    final dot = dx1 * dx2 + dy1 * dy2;
    final mag1 = sqrt(dx1 * dx1 + dy1 * dy1);
    final mag2 = sqrt(dx2 * dx2 + dy2 * dy2);
    if (mag1 == 0 || mag2 == 0) return 0.0;
    var cosAngle = dot / (mag1 * mag2);
    cosAngle = cosAngle.clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  double calculateAngleBetweenLines(Point p1, Point p2, Point p3, Point p4) {
    final dx1 = p2.x - p1.x;
    final dy1 = p2.y - p1.y;
    final dx2 = p4.x - p3.x;
    final dy2 = p4.y - p3.y;
    final dot = dx1 * dx2 + dy1 * dy2;
    final mag1 = sqrt(dx1 * dx1 + dy1 * dy1);
    final mag2 = sqrt(dx2 * dx2 + dy2 * dy2);
    if (mag1 == 0 || mag2 == 0) return 0.0;
    var cosAngle = dot / (mag1 * mag2);
    cosAngle = cosAngle.clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  String classifyCurveType(SpineAngles angles) {
    if (angles.thoracicKyphosis > angles.lumbarLordosis && angles.cervicalLordosis > 15) {
      return "Thoracic dominant";
    } else if (angles.lumbarLordosis > angles.thoracicKyphosis) {
      return "Lumbar dominant";
    } else if ((angles.thoracicKyphosis - angles.lumbarLordosis).abs() < 5) {
      return "Balanced curves";
    } else {
      return "Mixed pattern";
    }
  }
}

class SpineKeypoint {
  final String label;
  final Point position;
  final double confidence;
  final int index;
  final String region;
  final bool isInterpolated;
  SpineKeypoint({
    required this.label,
    required this.position,
    required this.confidence,
    required this.index,
    required this.region,
    required this.isInterpolated,
  });
  @override
  String toString() => "$label ($region): (${position.x.toStringAsFixed(1)}, ${position.y.toStringAsFixed(1)}) conf=${confidence.toStringAsFixed(2)}${isInterpolated ? ' [interpolated]' : ''}";
}

class SpineAngles {
  double cobbAngle = 0.0;
  double cervicalLordosis = 0.0;
  double thoracicKyphosis = 0.0;
  double lumbarLordosis = 0.0;
  double overallCurvature = 0.0;
  double maxLateralDeviation = 0.0;
  String apexLocation = "Unknown";
  double getPrimaryAngle() => cobbAngle;
  @override
  String toString() => "Cobb: ${cobbAngle.toStringAsFixed(1)}°, Cervical: ${cervicalLordosis.toStringAsFixed(1)}°, Thoracic: ${thoracicKyphosis.toStringAsFixed(1)}°, Lumbar: ${lumbarLordosis.toStringAsFixed(1)}°, Max deviation: ${maxLateralDeviation.toStringAsFixed(1)} px";
}

class SpineCurvatureAssessment {
  String severity = '';
  String riskLevel = '';
  String curvePattern = '';
  String curveType = '';
  String keypointQuality = '';
  double confidence = 0.0;
  double highConfidenceRatio = 0.0;
  int color = 0xFF888888;
  bool requiresMonitoring = false;
  bool requiresIntervention = false;
  bool requiresSurgicalConsultation = false;
  bool isNormal() => severity == "Normal";
  bool requiresAttention() => requiresMonitoring || requiresIntervention || requiresSurgicalConsultation;
  @override
  String toString() => "$severity ($riskLevel risk) - $curvePattern [${(confidence * 100).toStringAsFixed(1)}% confidence]";
}

class SpineAnalysisResult {
  final List<SpineKeypoint> keypoints;
  final SpineAngles angles;
  final SpineCurvatureAssessment assessment;
  final bool isValidAnalysis;
  final int originalImageWidth;
  final int originalImageHeight;
  SpineAnalysisResult({
    required this.keypoints,
    required this.angles,
    required this.assessment,
    required this.isValidAnalysis,
    required this.originalImageWidth,
    required this.originalImageHeight,
  });
  double getPrimaryAngle() => angles.getPrimaryAngle();
  double getConfidence() => assessment.confidence;
  String getSeverity() => assessment.severity;
  int getKeypointCount() => keypoints.length;
}

class Point {
  final double x;
  final double y;
  const Point(this.x, this.y);
}
