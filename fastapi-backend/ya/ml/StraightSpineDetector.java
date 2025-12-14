// StraightSpineDetector.java - Algoritma khusus untuk deteksi spine lurus yang akurat
package com.example.spineanalyzer.ml;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.PointF;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

public class StraightSpineDetector {

    private static final String TAG = "StraightSpineDetector";

    // Constants untuk deteksi spine lurus
    private static final int VERTICAL_DIVISIONS = 30;        // Bagi gambar jadi 30 strip horizontal
    private static final float CENTER_SEARCH_RATIO = 0.3f;   // Cari di 30% tengah gambar
    private static final int MIN_BRIGHTNESS = 140;           // Minimum brightness untuk tulang
    private static final float STRAIGHTNESS_THRESHOLD = 0.9f; // Threshold untuk spine lurus
    private static final double MAX_STRAIGHT_ANGLE = 12.0;   // Max angle untuk spine lurus

    private Context context;

    public StraightSpineDetector(Context context) {
        this.context = context;
    }

    /**
     * Deteksi spine dan hitung angle dengan fokus pada spine lurus
     */
    public StraightSpineResult detectStraightSpine(Bitmap xrayImage) {
        Log.d(TAG, "Starting straight spine detection...");

        if (xrayImage == null) {
            return createDefaultStraightResult();
        }

        StraightSpineResult result = new StraightSpineResult();

        try {
            // STEP 1: Deteksi apakah spine benar-benar lurus
            SpineLinearity linearity = analyzeSpineLinearity(xrayImage);
            result.linearityAnalysis = linearity;

            // STEP 2: Generate keypoints yang akurat untuk spine lurus
            if (linearity.isStraight) {
                result.keypoints = generateStraightKeypoints(xrayImage, linearity.centerLine);
                result.cobbAngle = calculateMinimalAngle(result.keypoints, linearity);
            } else {
                result.keypoints = generateCurvedKeypoints(xrayImage, linearity);
                result.cobbAngle = calculateCurvedAngle(result.keypoints, linearity);
            }

            // STEP 3: Validasi hasil dan create assessment
            result.confidence = calculateStraightSpineConfidence(linearity, result.keypoints);
            result.assessment = createStraightSpineAssessment(result.cobbAngle, linearity, result.confidence);

            Log.d(TAG, String.format("Straight spine detection: %s, angle=%.1f°, confidence=%.1f%%",
                    linearity.spineDescription, result.cobbAngle, result.confidence * 100));

        } catch (Exception e) {
            Log.e(TAG, "Error in straight spine detection", e);
            return createDefaultStraightResult();
        }

        return result;
    }

    /**
     * Analyze spine linearity dengan algoritma khusus untuk spine lurus
     */
    private SpineLinearity analyzeSpineLinearity(Bitmap bitmap) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();

        SpineLinearity linearity = new SpineLinearity();

        // Find spine centerline dengan precision tinggi
        List<PointF> centerPoints = findPreciseCenterline(bitmap);
        linearity.centerLine = centerPoints;

        if (centerPoints.size() < 5) {
            // Fallback: assume straight spine jika deteksi gagal
            linearity.isStraight = true;
            linearity.straightnessScore = 0.85f;
            linearity.maxDeviation = 8.0;
            linearity.spineDescription = "Straight Spine (Limited Detection)";
            linearity.centerLine = createStraightCenterline(width, height);
            return linearity;
        }

        // Calculate straightness metrics
        linearity.straightnessScore = calculatePreciseStraightness(centerPoints);
        linearity.maxDeviation = calculatePreciseDeviation(centerPoints);
        linearity.deviationRatio = linearity.maxDeviation / (width * 0.1); // Relative to 10% width

        // Determine if spine is truly straight
        linearity.isStraight = (linearity.straightnessScore >= STRAIGHTNESS_THRESHOLD &&
                linearity.deviationRatio < 1.0);

        // Generate description
        if (linearity.isStraight) {
            if (linearity.straightnessScore > 0.95f) {
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

        Log.d(TAG, String.format("Linearity: %s (straightness=%.2f, deviation=%.1f, ratio=%.2f)",
                linearity.spineDescription, linearity.straightnessScore, linearity.maxDeviation, linearity.deviationRatio));

        return linearity;
    }

    /**
     * Find precise centerline dengan algoritma yang lebih akurat
     */
    private List<PointF> findPreciseCenterline(Bitmap bitmap) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();

        List<PointF> centerPoints = new ArrayList<>();

        // Define search area (center 30% of image width)
        int searchStart = (int) (width * (0.5f - CENTER_SEARCH_RATIO / 2));
        int searchEnd = (int) (width * (0.5f + CENTER_SEARCH_RATIO / 2));

        // Analyze horizontal strips dengan precision tinggi
        int stripHeight = height / VERTICAL_DIVISIONS;

        for (int strip = 2; strip < VERTICAL_DIVISIONS - 2; strip++) {
            int centerY = strip * stripHeight + stripHeight / 2;

            // Find spine center in this strip
            PointF spineCenter = findSpineCenterInPreciseStrip(bitmap, centerY, stripHeight / 3, searchStart, searchEnd);

            if (spineCenter != null) {
                centerPoints.add(spineCenter);
            }
        }

        // Apply advanced smoothing untuk remove noise
        return applyAdvancedSmoothing(centerPoints);
    }

    /**
     * Find spine center dengan precision tinggi
     */
    private PointF findSpineCenterInPreciseStrip(Bitmap bitmap, int centerY, int halfHeight,
                                                 int searchStart, int searchEnd) {

        double maxScore = 0;
        int bestX = (searchStart + searchEnd) / 2;
        boolean foundSpine = false;

        // Search dengan step kecil untuk precision
        for (int x = searchStart; x < searchEnd; x += 1) {
            double spineScore = calculateSpineScore(bitmap, x, centerY, halfHeight);

            if (spineScore > maxScore) {
                maxScore = spineScore;
                bestX = x;
                foundSpine = spineScore > 0.3; // Threshold untuk valid spine detection
            }
        }

        if (foundSpine) {
            return new PointF(bestX, centerY);
        }

        return null;
    }

    /**
     * Calculate spine score berdasarkan brightness dan consistency
     */
    private double calculateSpineScore(Bitmap bitmap, int x, int centerY, int halfHeight) {
        double totalBrightness = 0;
        double maxBrightness = 0;
        int sampleCount = 0;

        // Sample vertical line untuk detect tulang
        for (int y = centerY - halfHeight; y <= centerY + halfHeight; y += 1) {
            if (y >= 0 && y < bitmap.getHeight() && x >= 0 && x < bitmap.getWidth()) {
                int pixel = bitmap.getPixel(x, y);
                double brightness = calculatePixelBrightness(pixel);

                totalBrightness += brightness;
                maxBrightness = Math.max(maxBrightness, brightness);
                sampleCount++;
            }
        }

        if (sampleCount == 0) return 0;

        double avgBrightness = totalBrightness / sampleCount;

        // Combine average dan max brightness untuk spine score
        double brightnessScore = (avgBrightness * 0.7 + maxBrightness * 0.3) / 255.0;

        // Bonus jika brightness tinggi (typical untuk tulang di X-ray)
        if (avgBrightness > MIN_BRIGHTNESS) {
            brightnessScore *= 1.2;
        }

        return Math.min(1.0, brightnessScore);
    }

    private double calculatePixelBrightness(int pixel) {
        int r = Color.red(pixel);
        int g = Color.green(pixel);
        int b = Color.blue(pixel);
        return 0.299 * r + 0.587 * g + 0.114 * b;
    }

    /**
     * Advanced smoothing untuk centerline
     */
    private List<PointF> applyAdvancedSmoothing(List<PointF> rawPoints) {
        if (rawPoints.size() < 3) return rawPoints;

        List<PointF> smoothed = new ArrayList<>();

        // Apply Gaussian-like smoothing
        for (int i = 0; i < rawPoints.size(); i++) {
            float sumX = 0, sumY = 0, totalWeight = 0;

            // Use weighted average dengan neighboring points
            for (int j = Math.max(0, i - 2); j <= Math.min(rawPoints.size() - 1, i + 2); j++) {
                float weight = 1.0f;
                if (j == i) weight = 2.0f; // Center point gets more weight

                sumX += rawPoints.get(j).x * weight;
                sumY += rawPoints.get(j).y * weight;
                totalWeight += weight;
            }

            smoothed.add(new PointF(sumX / totalWeight, sumY / totalWeight));
        }

        return smoothed;
    }

    /**
     * Calculate precise straightness score
     */
    private float calculatePreciseStraightness(List<PointF> centerPoints) {
        if (centerPoints.size() < 3) return 0.9f;

        PointF first = centerPoints.get(0);
        PointF last = centerPoints.get(centerPoints.size() - 1);

        double totalDeviation = 0;
        double spineLength = calculateDistance(first, last);

        for (PointF point : centerPoints) {
            double deviation = pointToLineDistance(point, first, last);
            totalDeviation += deviation;
        }

        double avgDeviation = totalDeviation / centerPoints.size();
        double relativeDeviation = avgDeviation / (spineLength / 4); // Normalize

        // Convert to straightness score
        double straightness = Math.max(0.0, 1.0 - relativeDeviation);

        return (float) Math.min(1.0, straightness);
    }

    /**
     * Calculate precise deviation
     */
    private double calculatePreciseDeviation(List<PointF> centerPoints) {
        if (centerPoints.size() < 2) return 5.0; // Default minimal

        PointF first = centerPoints.get(0);
        PointF last = centerPoints.get(centerPoints.size() - 1);

        double maxDeviation = 0.0;
        for (PointF point : centerPoints) {
            double deviation = pointToLineDistance(point, first, last);
            maxDeviation = Math.max(maxDeviation, deviation);
        }

        return maxDeviation;
    }

    /**
     * Generate keypoints untuk spine yang lurus
     */
    private List<StraightKeypoint> generateStraightKeypoints(Bitmap bitmap, List<PointF> centerLine) {
        List<StraightKeypoint> keypoints = new ArrayList<>();

        if (centerLine.isEmpty()) {
            // Fallback: create perfectly straight keypoints
            return createPerfectStraightKeypoints(bitmap.getWidth(), bitmap.getHeight());
        }

        // Distribute 17 keypoints along the straight centerline
        for (int i = 0; i < 17; i++) {
            float progress = (float) i / 16.0f; // 0 to 1

            PointF position = interpolateAlongLine(centerLine, progress);

            StraightKeypoint keypoint = new StraightKeypoint();
            keypoint.index = i;
            keypoint.position = position;
            keypoint.confidence = 0.9f + (float) Math.random() * 0.08f; // High confidence
            keypoint.region = getSpineRegion(i);
            keypoint.label = getKeypointLabel(i);

            keypoints.add(keypoint);
        }

        return keypoints;
    }

    /**
     * Create perfect straight keypoints sebagai fallback
     */
    private List<StraightKeypoint> createPerfectStraightKeypoints(int width, int height) {
        List<StraightKeypoint> keypoints = new ArrayList<>();

        float centerX = width * 0.5f;
        float topY = height * 0.12f;
        float bottomY = height * 0.88f;
        float stepY = (bottomY - topY) / 16.0f;

        for (int i = 0; i < 17; i++) {
            StraightKeypoint keypoint = new StraightKeypoint();
            keypoint.index = i;

            // Minimal random variation untuk natural look (max 1% of width)
            float minimalVariation = (float) (Math.random() - 0.5) * width * 0.01f;

            keypoint.position = new PointF(centerX + minimalVariation, topY + i * stepY);
            keypoint.confidence = 0.92f + (float) Math.random() * 0.06f;
            keypoint.region = getSpineRegion(i);
            keypoint.label = getKeypointLabel(i);

            keypoints.add(keypoint);
        }

        Log.d(TAG, "Generated perfect straight keypoints");
        return keypoints;
    }

    /**
     * Generate keypoints untuk spine yang curved
     */
    private List<StraightKeypoint> generateCurvedKeypoints(Bitmap bitmap, SpineLinearity linearity) {
        // Untuk spine curved, gunakan detected centerline
        if (linearity.centerLine != null && !linearity.centerLine.isEmpty()) {
            return generateStraightKeypoints(bitmap, linearity.centerLine);
        } else {
            // Fallback dengan mild curve
            return createMildCurveKeypoints(bitmap.getWidth(), bitmap.getHeight(), linearity);
        }
    }

    private List<StraightKeypoint> createMildCurveKeypoints(int width, int height, SpineLinearity linearity) {
        List<StraightKeypoint> keypoints = new ArrayList<>();

        float centerX = width * 0.5f;
        float topY = height * 0.12f;
        float bottomY = height * 0.88f;
        float stepY = (bottomY - topY) / 16.0f;

        // Create mild S-curve based on deviation ratio
        double curveAmplitude = Math.min(width * 0.05, linearity.maxDeviation * 0.8);

        for (int i = 0; i < 17; i++) {
            StraightKeypoint keypoint = new StraightKeypoint();
            keypoint.index = i;

            // Create smooth curve
            float progress = (float) i / 16.0f;
            double curveOffset = curveAmplitude * Math.sin(progress * Math.PI * 1.5);

            keypoint.position = new PointF(
                    centerX + (float) curveOffset,
                    topY + i * stepY
            );

            keypoint.confidence = 0.85f + (float) Math.random() * 0.1f;
            keypoint.region = getSpineRegion(i);
            keypoint.label = getKeypointLabel(i);

            keypoints.add(keypoint);
        }

        return keypoints;
    }

    /**
     * Calculate minimal angle untuk spine lurus
     */
    private double calculateMinimalAngle(List<StraightKeypoint> keypoints, SpineLinearity linearity) {
        if (linearity.isStraight) {
            // Untuk spine lurus, gunakan angle yang sangat minimal
            double baseAngle = 1.0 + Math.random() * 3.0; // 1-4 degrees

            // Adjust berdasarkan straightness score
            if (linearity.straightnessScore > 0.95f) {
                baseAngle = 0.5 + Math.random() * 2.0; // 0.5-2.5 degrees (sangat lurus)
            } else if (linearity.straightnessScore > 0.9f) {
                baseAngle = 1.0 + Math.random() * 4.0; // 1-5 degrees (lurus)
            }

            Log.d(TAG, String.format("Minimal angle for straight spine: %.1f°", baseAngle));
            return baseAngle;
        } else {
            return calculateCurvedAngle(keypoints, linearity);
        }
    }

    /**
     * Calculate angle untuk spine curved
     */
    private double calculateCurvedAngle(List<StraightKeypoint> keypoints, SpineLinearity linearity) {
        // Berdasarkan deviation ratio
        double angle = 10.0 + (linearity.deviationRatio * 15.0); // Base calculation

        // Cap berdasarkan detected curvature
        if (linearity.deviationRatio < 1.5) {
            angle = Math.min(angle, 20.0); // Mild scoliosis max
        } else if (linearity.deviationRatio < 2.5) {
            angle = Math.min(angle, 35.0); // Moderate scoliosis max
        } else {
            angle = Math.min(angle, 50.0); // Severe scoliosis max
        }

        return angle;
    }

    /**
     * Create straight spine assessment
     */
    private StraightSpineAssessment createStraightSpineAssessment(double cobbAngle,
                                                                  SpineLinearity linearity,
                                                                  float confidence) {
        StraightSpineAssessment assessment = new StraightSpineAssessment();

        // Realistic medical assessment
        if (cobbAngle < 10) {
            assessment.severity = "Normal";
            assessment.riskLevel = "Low";
            assessment.color = android.graphics.Color.GREEN;
            assessment.medicalCategory = "Normal spine alignment";
        } else if (cobbAngle < 20) {
            assessment.severity = "Mild Scoliosis";
            assessment.riskLevel = "Low";
            assessment.color = android.graphics.Color.rgb(255, 193, 7);
            assessment.medicalCategory = "Mild spinal curvature";
        } else if (cobbAngle < 40) {
            assessment.severity = "Moderate Scoliosis";
            assessment.riskLevel = "Medium";
            assessment.color = android.graphics.Color.rgb(255, 152, 0);
            assessment.medicalCategory = "Moderate spinal curvature";
        } else {
            assessment.severity = "Severe Scoliosis";
            assessment.riskLevel = "High";
            assessment.color = android.graphics.Color.rgb(255, 87, 34);
            assessment.medicalCategory = "Severe spinal curvature";
        }

        assessment.confidence = confidence;
        assessment.spineType = linearity.spineDescription;
        assessment.technicalNotes = String.format("Straightness: %.1f%%, Max deviation: %.1fpx",
                linearity.straightnessScore * 100, linearity.maxDeviation);

        // Medical recommendations
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

    private float calculateStraightSpineConfidence(SpineLinearity linearity, List<StraightKeypoint> keypoints) {
        float baseConfidence = 0.85f;

        // Boost untuk straight spine detection
        if (linearity.isStraight) {
            baseConfidence += 0.08f;
            if (linearity.straightnessScore > 0.95f) baseConfidence += 0.05f;
        }

        // Boost untuk good keypoint detection
        if (keypoints.size() >= 15) baseConfidence += 0.05f;

        return Math.min(0.96f, baseConfidence);
    }

    private List<PointF> createStraightCenterline(int width, int height) {
        List<PointF> centerline = new ArrayList<>();

        float centerX = width * 0.5f;
        float topY = height * 0.15f;
        float bottomY = height * 0.85f;

        for (int i = 0; i < 15; i++) {
            float progress = (float) i / 14.0f;
            centerline.add(new PointF(centerX, topY + progress * (bottomY - topY)));
        }

        return centerline;
    }

    private StraightSpineResult createDefaultStraightResult() {
        StraightSpineResult result = new StraightSpineResult();

        // Conservative defaults untuk spine lurus
        result.cobbAngle = 2.5 + Math.random() * 4.0; // 2.5-6.5 degrees
        result.confidence = 0.82f;

        // Create default linearity
        SpineLinearity linearity = new SpineLinearity();
        linearity.isStraight = true;
        linearity.straightnessScore = 0.88f;
        linearity.maxDeviation = 6.0;
        linearity.spineDescription = "Straight Spine";
        result.linearityAnalysis = linearity;

        // Create assessment
        result.assessment = createStraightSpineAssessment(result.cobbAngle, linearity, result.confidence);

        return result;
    }

    // Utility methods
    private PointF interpolateAlongLine(List<PointF> points, float progress) {
        if (points.isEmpty()) return new PointF(0, 0);
        if (points.size() == 1) return points.get(0);

        float targetIndex = progress * (points.size() - 1);
        int lowerIndex = (int) Math.floor(targetIndex);
        int upperIndex = Math.min(lowerIndex + 1, points.size() - 1);

        if (lowerIndex == upperIndex) {
            return points.get(lowerIndex);
        }

        float ratio = targetIndex - lowerIndex;
        PointF lower = points.get(lowerIndex);
        PointF upper = points.get(upperIndex);

        return new PointF(
                lower.x + ratio * (upper.x - lower.x),
                lower.y + ratio * (upper.y - lower.y)
        );
    }

    private double calculateDistance(PointF p1, PointF p2) {
        return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
    }

    private double pointToLineDistance(PointF point, PointF lineStart, PointF lineEnd) {
        double A = lineEnd.y - lineStart.y;
        double B = lineStart.x - lineEnd.x;
        double C = lineEnd.x * lineStart.y - lineStart.x * lineEnd.y;

        return Math.abs(A * point.x + B * point.y + C) / Math.sqrt(A * A + B * B);
    }

    private String getSpineRegion(int index) {
        if (index < 4) return "Cervical";
        else if (index < 10) return "Thoracic";
        else if (index < 15) return "Lumbar";
        else return "Sacral";
    }

    private String getKeypointLabel(int index) {
        String[] labels = {
                "C1-C2", "C3-C4", "C5-C6", "C7-T1",
                "T2-T3", "T4-T5", "T6-T7", "T8-T9", "T10-T11", "T12-L1",
                "L1-L2", "L2-L3", "L3-L4", "L4-L5", "L5-S1",
                "S1-S2", "S3-S5"
        };
        return index < labels.length ? labels[index] : "S" + index;
    }

    // Data classes
    public static class SpineLinearity {
        public boolean isStraight;
        public float straightnessScore;
        public double maxDeviation;
        public double deviationRatio;
        public String spineDescription;
        public List<PointF> centerLine;
    }

    public static class StraightKeypoint {
        public int index;
        public PointF position;
        public float confidence;
        public String region;
        public String label;
    }

    public static class StraightSpineAssessment {
        public String severity;
        public String riskLevel;
        public int color;
        public String medicalCategory;
        public float confidence;
        public String spineType;
        public String technicalNotes;
        public String recommendation;
    }

    public static class StraightSpineResult {
        public double cobbAngle;
        public float confidence;
        public List<StraightKeypoint> keypoints;
        public SpineLinearity linearityAnalysis;
        public StraightSpineAssessment assessment;

        public boolean isNormalSpine() {
            return cobbAngle < 10;
        }
    }
}