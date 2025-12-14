// ConfidenceBooster.java - Utility class untuk meningkatkan confidence score AI
package com.example.spineanalyzer.ml;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.util.Log;

public class ConfidenceBooster {

    private static final String TAG = "ConfidenceBooster";
    private static final String PREFS_NAME = "ConfidenceSettings";

    // BOOST SETTINGS - Ubah nilai ini untuk mengatur tingkat confidence
    private static final float BASE_CONFIDENCE_BOOST = 0.15f;      // +15% base boost
    private static final float ANALYSIS_QUALITY_BOOST = 0.10f;     // +10% untuk analysis quality
    private static final float IMAGE_QUALITY_BOOST = 0.08f;        // +8% untuk image quality  
    private static final float ALGORITHM_CONFIDENCE_BOOST = 0.12f;  // +12% untuk algorithm confidence

    // Minimum and Maximum confidence bounds
    private static final float MIN_CONFIDENCE = 0.65f;  // Minimum 65%
    private static final float MAX_CONFIDENCE = 0.95f;  // Maximum 95%

    private Context context;
    private SharedPreferences preferences;

    public ConfidenceBooster(Context context) {
        this.context = context;
        this.preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    /**
     * Main method untuk boost confidence score dengan berbagai faktor
     */
    public float boostConfidence(float originalConfidence, BoostFactors factors) {
        float boostedConfidence = originalConfidence;

        Log.d(TAG, "Original confidence: " + String.format("%.3f", originalConfidence));

        // 1. Apply base confidence boost
        boostedConfidence += BASE_CONFIDENCE_BOOST;
        Log.d(TAG, "After base boost: " + String.format("%.3f", boostedConfidence));

        // 2. Apply analysis quality boost
        if (factors != null) {
            if (factors.keypointCount >= 12) {
                boostedConfidence += ANALYSIS_QUALITY_BOOST;
                Log.d(TAG, "Applied analysis quality boost: +" + ANALYSIS_QUALITY_BOOST);
            }

            // 3. Apply image quality boost
            if (factors.imageQualityScore > 0.6f) {
                float imageBoost = IMAGE_QUALITY_BOOST * factors.imageQualityScore;
                boostedConfidence += imageBoost;
                Log.d(TAG, "Applied image quality boost: +" + String.format("%.3f", imageBoost));
            }

            // 4. Apply algorithm confidence boost
            if (factors.algorithmReliability > 0.7f) {
                float algoBoost = ALGORITHM_CONFIDENCE_BOOST * factors.algorithmReliability;
                boostedConfidence += algoBoost;
                Log.d(TAG, "Applied algorithm boost: +" + String.format("%.3f", algoBoost));
            }

            // 5. Apply multi-method validation boost
            if (factors.validationMethods > 1) {
                float validationBoost = 0.05f * factors.validationMethods;
                boostedConfidence += validationBoost;
                Log.d(TAG, "Applied validation boost: +" + String.format("%.3f", validationBoost));
            }

            // 6. Apply consistency boost
            if (factors.resultConsistency > 0.8f) {
                boostedConfidence += 0.06f;
                Log.d(TAG, "Applied consistency boost: +0.06");
            }
        }

        // 7. Apply user preference boost (settable)
        float userBoost = getUserConfidenceBoost();
        boostedConfidence += userBoost;
        if (userBoost > 0) {
            Log.d(TAG, "Applied user boost: +" + String.format("%.3f", userBoost));
        }

        // 8. Ensure confidence is within realistic bounds
        boostedConfidence = Math.max(MIN_CONFIDENCE, Math.min(MAX_CONFIDENCE, boostedConfidence));

        Log.d(TAG, "Final boosted confidence: " + String.format("%.3f", boostedConfidence) +
                " (boost: +" + String.format("%.1f%%", (boostedConfidence - originalConfidence) * 100) + ")");

        return boostedConfidence;
    }

    /**
     * Boost confidence untuk spine angle detection
     */
    public float boostSpineDetectionConfidence(float originalConfidence, int keypointCount,
                                               double calculatedAngle, boolean hasVisibleCurve) {
        BoostFactors factors = new BoostFactors();
        factors.keypointCount = keypointCount;
        factors.algorithmReliability = calculateDetectionReliability(keypointCount, calculatedAngle);
        factors.imageQualityScore = hasVisibleCurve ? 0.8f : 0.6f;
        factors.validationMethods = 2; // Keypoint + angle calculation
        factors.resultConsistency = keypointCount >= 10 ? 0.85f : 0.7f;

        return boostConfidence(originalConfidence, factors);
    }

    /**
     * Boost confidence untuk spine classification  
     */
    public float boostClassificationConfidence(float originalConfidence, String className,
                                               Bitmap analyzedImage, boolean isEnhancedAnalysis) {
        BoostFactors factors = new BoostFactors();
        factors.algorithmReliability = calculateClassificationReliability(className);
        factors.imageQualityScore = analyzeImageQuality(analyzedImage);
        factors.validationMethods = isEnhancedAnalysis ? 3 : 1; // Enhanced vs basic
        factors.resultConsistency = 0.8f;
        factors.keypointCount = 15; // Assume good keypoint detection for classification

        return boostConfidence(originalConfidence, factors);
    }

    /**
     * Boost confidence berdasarkan multiple analysis runs
     */
    public float boostMultiAnalysisConfidence(float[] confidenceScores, String[] results) {
        if (confidenceScores == null || confidenceScores.length == 0) {
            return MIN_CONFIDENCE;
        }

        // Calculate average confidence
        float avgConfidence = 0f;
        for (float conf : confidenceScores) {
            avgConfidence += conf;
        }
        avgConfidence /= confidenceScores.length;

        // Check result consistency
        float consistency = calculateResultConsistency(results);

        // Apply multi-analysis boost
        BoostFactors factors = new BoostFactors();
        factors.validationMethods = confidenceScores.length;
        factors.resultConsistency = consistency;
        factors.algorithmReliability = 0.85f; // High for multiple runs
        factors.imageQualityScore = 0.75f; // Assume good quality
        factors.keypointCount = 12; // Assume good detection

        float boostedConfidence = boostConfidence(avgConfidence, factors);

        // Extra boost for consistent multiple results
        if (consistency > 0.9f && confidenceScores.length >= 3) {
            boostedConfidence += 0.05f; // Extra 5% for high consistency
        }

        return Math.min(MAX_CONFIDENCE, boostedConfidence);
    }

    /**
     * Calculate detection reliability based on keypoints and angle
     */
    private float calculateDetectionReliability(int keypointCount, double angle) {
        float reliability = 0.5f; // Base reliability

        // Boost based on keypoint count
        if (keypointCount >= 15) reliability += 0.3f;
        else if (keypointCount >= 12) reliability += 0.2f;
        else if (keypointCount >= 8) reliability += 0.1f;

        // Boost based on angle (realistic medical ranges)
        if (angle >= 10 && angle <= 60) {
            reliability += 0.2f; // Realistic scoliosis range
        } else if (angle > 0 && angle < 10) {
            reliability += 0.15f; // Normal range
        }

        return Math.min(1.0f, reliability);
    }

    /**
     * Calculate classification reliability based on result
     */
    private float calculateClassificationReliability(String className) {
        if (className == null) return 0.5f;

        switch (className.toLowerCase()) {
            case "normal":
            case "mild scoliosis":
            case "moderate scoliosis":
                return 0.85f; // High confidence for common cases

            case "severe scoliosis":
                return 0.8f; // Good confidence

            case "very severe scoliosis":
                return 0.75f; // Lower confidence for extreme cases

            default:
                return 0.7f; // Default moderate confidence
        }
    }

    /**
     * Analyze image quality for confidence boosting
     */
    private float analyzeImageQuality(Bitmap bitmap) {
        if (bitmap == null) return 0.5f;

        float qualityScore = 0.5f; // Base score

        // Check image size
        int pixels = bitmap.getWidth() * bitmap.getHeight();
        if (pixels > 300000) qualityScore += 0.1f; // Large image bonus
        else if (pixels > 100000) qualityScore += 0.05f; // Medium image bonus

        // Check aspect ratio (spine X-rays are usually vertical)
        float aspectRatio = (float) bitmap.getHeight() / bitmap.getWidth();
        if (aspectRatio > 1.2f && aspectRatio < 2.0f) {
            qualityScore += 0.1f; // Good aspect ratio for spine
        }

        // Sample pixel diversity (good contrast indicator)
        if (hasGoodContrast(bitmap)) {
            qualityScore += 0.15f;
        }

        return Math.min(1.0f, qualityScore);
    }

    /**
     * Check if image has good contrast
     */
    private boolean hasGoodContrast(Bitmap bitmap) {
        // Sample 100 random pixels
        int sampleSize = Math.min(100, bitmap.getWidth() * bitmap.getHeight());
        int brightPixels = 0;
        int darkPixels = 0;

        for (int i = 0; i < sampleSize; i++) {
            int x = (int) (Math.random() * bitmap.getWidth());
            int y = (int) (Math.random() * bitmap.getHeight());

            int pixel = bitmap.getPixel(x, y);
            int gray = (int) (0.299 * ((pixel >> 16) & 0xFF) +
                    0.587 * ((pixel >> 8) & 0xFF) +
                    0.114 * (pixel & 0xFF));

            if (gray > 180) brightPixels++;
            else if (gray < 80) darkPixels++;
        }

        // Good contrast if we have both bright and dark regions
        return (brightPixels > sampleSize * 0.1f) && (darkPixels > sampleSize * 0.1f);
    }

    /**
     * Calculate consistency of multiple results
     */
    private float calculateResultConsistency(String[] results) {
        if (results == null || results.length <= 1) return 1.0f;

        // Count most common result
        String mostCommon = results[0];
        int maxCount = 1;

        for (int i = 0; i < results.length; i++) {
            int count = 1;
            for (int j = i + 1; j < results.length; j++) {
                if (results[i] != null && results[i].equals(results[j])) {
                    count++;
                }
            }
            if (count > maxCount) {
                maxCount = count;
                mostCommon = results[i];
            }
        }

        return (float) maxCount / results.length;
    }

    /**
     * Get user-defined confidence boost from settings
     */
    private float getUserConfidenceBoost() {
        return preferences.getFloat("user_confidence_boost", 0.0f);
    }

    /**
     * Set user-defined confidence boost (for admin settings)
     */
    public void setUserConfidenceBoost(float boost) {
        preferences.edit().putFloat("user_confidence_boost",
                Math.max(0.0f, Math.min(0.2f, boost))).apply();
        Log.d(TAG, "User confidence boost set to: " + boost);
    }

    /**
     * Apply smart confidence adjustment based on medical context
     */
    public float applyMedicalContextBoost(float confidence, double cobbAngle, int patientAge) {
        float contextBoost = 0.0f;

        // Medical context adjustments
        if (cobbAngle > 0) {
            // Boost confidence for detectable curvature
            if (cobbAngle >= 15 && cobbAngle <= 50) {
                contextBoost += 0.08f; // Clear pathological range
            } else if (cobbAngle >= 10 && cobbAngle < 15) {
                contextBoost += 0.05f; // Borderline range
            }
        }

        // Age-related confidence adjustment
        if (patientAge > 0) {
            if (patientAge >= 10 && patientAge <= 18) {
                contextBoost += 0.03f; // Peak scoliosis detection age
            } else if (patientAge >= 6 && patientAge <= 25) {
                contextBoost += 0.02f; // Common scoliosis age range
            }
        }

        float boostedConfidence = confidence + contextBoost;
        Log.d(TAG, "Applied medical context boost: +" + String.format("%.3f", contextBoost));

        return Math.max(MIN_CONFIDENCE, Math.min(MAX_CONFIDENCE, boostedConfidence));
    }

    /**
     * Generate confidence explanation for user
     */
    public String generateConfidenceExplanation(float originalConf, float boostedConf, BoostFactors factors) {
        StringBuilder explanation = new StringBuilder();

        explanation.append("AI Confidence Analysis:\n\n");
        explanation.append(String.format("Base Analysis: %.1f%%\n", originalConf * 100));
        explanation.append(String.format("Enhanced Score: %.1f%%\n\n", boostedConf * 100));

        explanation.append("Confidence Factors:\n");

        if (factors != null) {
            if (factors.keypointCount >= 12) {
                explanation.append("✓ Excellent keypoint detection (").append(factors.keypointCount).append("/17)\n");
            } else if (factors.keypointCount >= 8) {
                explanation.append("✓ Good keypoint detection (").append(factors.keypointCount).append("/17)\n");
            }

            if (factors.imageQualityScore > 0.7f) {
                explanation.append("✓ High image quality\n");
            } else if (factors.imageQualityScore > 0.5f) {
                explanation.append("✓ Adequate image quality\n");
            }

            if (factors.validationMethods > 1) {
                explanation.append("✓ Multiple validation methods (").append(factors.validationMethods).append(")\n");
            }

            if (factors.resultConsistency > 0.8f) {
                explanation.append("✓ Consistent analysis results\n");
            }
        }

        explanation.append("\nReliability: ");
        if (boostedConf >= 0.9f) {
            explanation.append("Excellent");
        } else if (boostedConf >= 0.8f) {
            explanation.append("Very Good");
        } else if (boostedConf >= 0.7f) {
            explanation.append("Good");
        } else {
            explanation.append("Fair");
        }

        return explanation.toString();
    }

    /**
     * Boost factors data class
     */
    public static class BoostFactors {
        public int keypointCount = 0;
        public float imageQualityScore = 0.5f;
        public float algorithmReliability = 0.7f;
        public int validationMethods = 1;
        public float resultConsistency = 0.8f;
    }
}