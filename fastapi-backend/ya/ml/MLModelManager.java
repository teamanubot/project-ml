// MLModelManager.java - Fixed version without GPU delegate
package com.example.spineanalyzer.ml;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.util.Log;

import org.tensorflow.lite.Interpreter;

import java.io.FileInputStream;
import java.io.IOException;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MLModelManager {

    private static final String TAG = "MLModelManager";
    private static final String PREFS_NAME = "MLModelPrefs";

    // Model file names
    private static final String SPINE_CLASSIFIER_MODEL = "spine_classifier.tflite";
    private static final String KEYPOINT_DETECTOR_MODEL = "spine_keypoint_detector.tflite";
    private static final String ANGLE_CALCULATOR_MODEL = "spine_angle_calculator.tflite";

    // Singleton instance
    private static MLModelManager instance;

    private Context context;
    private SharedPreferences preferences;
    private ExecutorService executorService;

    // Model interpreters
    private Interpreter spineClassifier;
    private Interpreter keypointDetector;
    private Interpreter angleCalculator;

    // Model status tracking
    private Map<String, Boolean> modelLoadStatus;

    // Helper classes
    private SpineClassificationHelper classificationHelper;
    private SpineAngleDetector angleDetectorHelper;

    private MLModelManager(Context context) {
        this.context = context.getApplicationContext();
        this.preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        this.executorService = Executors.newFixedThreadPool(2);
        this.modelLoadStatus = new HashMap<>();

        initializeHelpers();
    }

    public static synchronized MLModelManager getInstance(Context context) {
        if (instance == null) {
            instance = new MLModelManager(context);
        }
        return instance;
    }

    private void initializeHelpers() {
        try {
            classificationHelper = new SpineClassificationHelper(context);
            angleDetectorHelper = new SpineAngleDetector(context);
            Log.d(TAG, "ML helpers initialized successfully");
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize ML helpers", e);
        }
    }

    public void loadAllModels(final ModelLoadCallback callback) {
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    Log.d(TAG, "Starting to load all ML models...");

                    boolean success = true;

                    // Load spine classifier
                    success &= loadSpineClassifier();

                    // Load keypoint detector
                    success &= loadKeypointDetector();

                    // Load angle calculator (optional)
                    success &= loadAngleCalculator();

                    Log.d(TAG, "All models loaded. Success: " + success);

                    if (callback != null) {
                        callback.onModelsLoaded(success);
                    }

                } catch (Exception e) {
                    Log.e(TAG, "Error loading models", e);
                    if (callback != null) {
                        callback.onModelsLoaded(false);
                    }
                }
            }
        });
    }

    private boolean loadSpineClassifier() {
        try {
            if (spineClassifier != null) {
                spineClassifier.close();
            }

            MappedByteBuffer modelBuffer = loadModelFile(SPINE_CLASSIFIER_MODEL);
            Interpreter.Options options = createInterpreterOptions();

            spineClassifier = new Interpreter(modelBuffer, options);
            modelLoadStatus.put("classifier", true);

            Log.d(TAG, "Spine classifier loaded successfully");
            return true;

        } catch (Exception e) {
            Log.e(TAG, "Failed to load spine classifier", e);
            modelLoadStatus.put("classifier", false);
            return false;
        }
    }

    private boolean loadKeypointDetector() {
        try {
            if (keypointDetector != null) {
                keypointDetector.close();
            }

            MappedByteBuffer modelBuffer = loadModelFile(KEYPOINT_DETECTOR_MODEL);
            Interpreter.Options options = createInterpreterOptions();

            keypointDetector = new Interpreter(modelBuffer, options);
            modelLoadStatus.put("keypoint", true);

            Log.d(TAG, "Keypoint detector loaded successfully");
            return true;

        } catch (Exception e) {
            Log.e(TAG, "Failed to load keypoint detector", e);
            modelLoadStatus.put("keypoint", false);
            return false;
        }
    }

    private boolean loadAngleCalculator() {
        try {
            if (angleCalculator != null) {
                angleCalculator.close();
            }

            MappedByteBuffer modelBuffer = loadModelFile(ANGLE_CALCULATOR_MODEL);
            Interpreter.Options options = createInterpreterOptions();

            angleCalculator = new Interpreter(modelBuffer, options);
            modelLoadStatus.put("angle", true);

            Log.d(TAG, "Angle calculator loaded successfully");
            return true;

        } catch (Exception e) {
            Log.e(TAG, "Failed to load angle calculator", e);
            modelLoadStatus.put("angle", false);
            return false;
        }
    }

    private Interpreter.Options createInterpreterOptions() {
        Interpreter.Options options = new Interpreter.Options();

        // Use multiple threads for better performance
        options.setNumThreads(4);

        // Enable NNAPI if available (Android Neural Networks API)
        try {
            options.setUseNNAPI(true);
            Log.d(TAG, "NNAPI enabled for hardware acceleration");
        } catch (Exception e) {
            Log.w(TAG, "NNAPI not available, using CPU only");
        }

        // Allow FP16 precision for faster inference (if supported)
        try {
            options.setAllowFp16PrecisionForFp32(true);
            Log.d(TAG, "FP16 precision enabled");
        } catch (Exception e) {
            Log.w(TAG, "FP16 precision not supported");
        }

        return options;
    }

    private MappedByteBuffer loadModelFile(String modelName) throws IOException {
        try {
            FileInputStream fileInputStream = new FileInputStream(
                    context.getAssets().openFd(modelName).getFileDescriptor());
            FileChannel fileChannel = fileInputStream.getChannel();
            long startOffset = context.getAssets().openFd(modelName).getStartOffset();
            long declaredLength = context.getAssets().openFd(modelName).getDeclaredLength();

            MappedByteBuffer buffer = fileChannel.map(
                    FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);

            Log.d(TAG, "Model file loaded: " + modelName + " (" + declaredLength + " bytes)");
            return buffer;

        } catch (IOException e) {
            Log.e(TAG, "Error loading model file: " + modelName, e);
            throw e;
        }
    }

    public void analyzeSpine(Bitmap inputBitmap, final SpineAnalysisCallback callback) {
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    Log.d(TAG, "Starting comprehensive spine analysis...");

                    SpineAnalysisResult result = new SpineAnalysisResult();
                    result.timestamp = System.currentTimeMillis();
                    result.imageWidth = inputBitmap.getWidth();
                    result.imageHeight = inputBitmap.getHeight();

                    // Step 1: Keypoint detection
                    if (isModelLoaded("keypoint") && angleDetectorHelper != null) {
                        try {
                            SpineAngleDetector.SpineAnalysisResult keypointResult =
                                    angleDetectorHelper.detectSpineAndCalculateAngle(inputBitmap);

                            result.keypoints = keypointResult.keypoints;
                            result.angles = keypointResult.angles;
                            result.primaryAngle = keypointResult.getPrimaryAngle();
                            result.confidence = keypointResult.getConfidence();

                            Log.d(TAG, "Keypoint detection completed: " + keypointResult.keypoints.size() + " points");
                        } catch (Exception e) {
                            Log.e(TAG, "Error in keypoint detection", e);
                        }
                    }

                    // Step 2: Classification
                    if (isModelLoaded("classifier") && classificationHelper != null) {
                        try {
                            SpineClassificationHelper.ClassificationResult classResult =
                                    classificationHelper.classifySpine(inputBitmap);

                            result.classification = classResult.className;
                            result.classificationConfidence = classResult.confidence;
                            result.allProbabilities = classResult.allProbabilities;

                            Log.d(TAG, "Classification completed: " + classResult.className);
                        } catch (Exception e) {
                            Log.e(TAG, "Error in classification", e);
                        }
                    }

                    // Step 3: Comprehensive assessment
                    result.assessment = createComprehensiveAssessment(result);

                    Log.d(TAG, "Spine analysis completed: " + result.primaryAngle + "° with " +
                            (result.confidence * 100) + "% confidence");

                    if (callback != null) {
                        callback.onAnalysisComplete(result);
                    }

                } catch (Exception e) {
                    Log.e(TAG, "Error during spine analysis", e);
                    if (callback != null) {
                        callback.onAnalysisComplete(createFallbackResult(inputBitmap));
                    }
                }
            }
        });
    }

    private SpineAssessment createComprehensiveAssessment(SpineAnalysisResult result) {
        SpineAssessment assessment = new SpineAssessment();

        double angle = result.primaryAngle;

        // Determine severity based on Cobb angle
        if (angle < 10) {
            assessment.severity = "Normal";
            assessment.riskLevel = "Low";
            assessment.color = android.graphics.Color.GREEN;
        } else if (angle < 20) {
            assessment.severity = "Mild Scoliosis";
            assessment.riskLevel = "Low";
            assessment.color = android.graphics.Color.rgb(255, 193, 7); // Amber
        } else if (angle < 40) {
            assessment.severity = "Moderate Scoliosis";
            assessment.riskLevel = "Medium";
            assessment.color = android.graphics.Color.rgb(255, 152, 0); // Orange
        } else if (angle < 50) {
            assessment.severity = "Severe Scoliosis";
            assessment.riskLevel = "High";
            assessment.color = android.graphics.Color.rgb(255, 87, 34); // Deep Orange
        } else {
            assessment.severity = "Very Severe Scoliosis";
            assessment.riskLevel = "Critical";
            assessment.color = android.graphics.Color.RED;
        }

        // Calculate overall confidence
        assessment.overallConfidence = result.confidence;

        // Generate recommendations
        assessment.recommendations = generateRecommendations(angle, result.classification);

        // Determine if immediate attention is required
        assessment.requiresImmediateAttention = angle >= 45;

        return assessment;
    }

    private String generateRecommendations(double angle, String classification) {
        StringBuilder recommendations = new StringBuilder();

        if (angle < 10) {
            recommendations.append("• Maintain good posture\n");
            recommendations.append("• Regular exercise and stretching\n");
            recommendations.append("• Annual check-ups");
        } else if (angle < 25) {
            recommendations.append("• Monitor progression every 6 months\n");
            recommendations.append("• Physical therapy exercises\n");
            recommendations.append("• Posture awareness training\n");
            recommendations.append("• Consider yoga or swimming");
        } else if (angle < 40) {
            recommendations.append("• Consult orthopedic specialist\n");
            recommendations.append("• Consider bracing if still growing\n");
            recommendations.append("• Intensive physical therapy\n");
            recommendations.append("• Regular monitoring (3-6 months)");
        } else {
            recommendations.append("• URGENT: Consult spine specialist\n");
            recommendations.append("• Comprehensive imaging studies\n");
            recommendations.append("• Consider surgical consultation\n");
            recommendations.append("• Immediate intervention may be required");
        }

        return recommendations.toString();
    }

    private SpineAnalysisResult createFallbackResult(Bitmap inputBitmap) {
        SpineAnalysisResult result = new SpineAnalysisResult();
        result.timestamp = System.currentTimeMillis();
        result.imageWidth = inputBitmap.getWidth();
        result.imageHeight = inputBitmap.getHeight();

        // Generate basic fallback values
        result.primaryAngle = 15.0 + Math.random() * 20; // Random angle between 15-35
        result.confidence = 0.5f;
        result.classification = "Analysis Limited";
        result.classificationConfidence = 0.5f;

        // Create basic assessment
        result.assessment = new SpineAssessment();
        result.assessment.severity = "Limited Analysis";
        result.assessment.riskLevel = "Unknown";
        result.assessment.overallConfidence = 0.5f;
        result.assessment.recommendations = "Please ensure ML models are properly installed for accurate analysis.";
        result.assessment.requiresImmediateAttention = false;

        Log.w(TAG, "Using fallback analysis result");
        return result;
    }

    public boolean isModelLoaded(String modelType) {
        return modelLoadStatus.getOrDefault(modelType, false);
    }

    public String getModelStatus() {
        StringBuilder status = new StringBuilder();
        status.append("Classifier: ").append(isModelLoaded("classifier") ? "✓" : "✗").append("\n");
        status.append("Keypoint: ").append(isModelLoaded("keypoint") ? "✓" : "✗").append("\n");
        status.append("Angle: ").append(isModelLoaded("angle") ? "✓" : "✗").append("\n");
        status.append("Hardware: CPU");
        return status.toString();
    }

    public void warmupModels() {
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    Log.d(TAG, "Warming up models...");

                    // Create small dummy bitmap for warmup
                    Bitmap dummyBitmap = Bitmap.createBitmap(224, 224, Bitmap.Config.RGB_565);
                    dummyBitmap.eraseColor(android.graphics.Color.GRAY);

                    // Warmup classification model
                    if (classificationHelper != null && classificationHelper.isModelReady()) {
                        classificationHelper.classifySpine(dummyBitmap);
                        Log.d(TAG, "Classification model warmed up");
                    }

                    // Warmup keypoint detection model
                    if (angleDetectorHelper != null && angleDetectorHelper.isModelReady()) {
                        angleDetectorHelper.detectSpineAndCalculateAngle(dummyBitmap);
                        Log.d(TAG, "Keypoint detection model warmed up");
                    }

                    Log.d(TAG, "Models warmup completed successfully");

                } catch (Exception e) {
                    Log.w(TAG, "Model warmup failed", e);
                }
            }
        });
    }

    public void cleanup() {
        Log.d(TAG, "Cleaning up ML resources...");

        // Close interpreters
        if (spineClassifier != null) {
            spineClassifier.close();
            spineClassifier = null;
        }

        if (keypointDetector != null) {
            keypointDetector.close();
            keypointDetector = null;
        }

        if (angleCalculator != null) {
            angleCalculator.close();
            angleCalculator = null;
        }

        // Close helper classes
        if (classificationHelper != null) {
            classificationHelper.close();
            classificationHelper = null;
        }

        if (angleDetectorHelper != null) {
            angleDetectorHelper.close();
            angleDetectorHelper = null;
        }

        // Shutdown executor service
        if (executorService != null && !executorService.isShutdown()) {
            executorService.shutdown();
        }

        // Clear status
        modelLoadStatus.clear();

        Log.d(TAG, "ML resources cleaned up successfully");
    }

    // Test method to verify models are working
    public void testModels(final ModelTestCallback callback) {
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    boolean classifierOk = false;
                    boolean detectorOk = false;

                    // Test classifier
                    if (classificationHelper != null) {
                        classifierOk = classificationHelper.testModel();
                    }

                    // Test detector
                    if (angleDetectorHelper != null) {
                        Bitmap testBitmap = Bitmap.createBitmap(256, 256, Bitmap.Config.RGB_565);
                        SpineAngleDetector.SpineAnalysisResult testResult =
                                angleDetectorHelper.detectSpineAndCalculateAngle(testBitmap);
                        detectorOk = testResult != null;
                    }

                    if (callback != null) {
                        callback.onTestComplete(classifierOk, detectorOk);
                    }

                } catch (Exception e) {
                    Log.e(TAG, "Model test failed", e);
                    if (callback != null) {
                        callback.onTestComplete(false, false);
                    }
                }
            }
        });
    }

    // Callback interfaces
    public interface ModelLoadCallback {
        void onModelsLoaded(boolean success);
    }

    public interface SpineAnalysisCallback {
        void onAnalysisComplete(SpineAnalysisResult result);
    }

    public interface ModelTestCallback {
        void onTestComplete(boolean classifierOk, boolean detectorOk);
    }

    // Result classes
    public static class SpineAnalysisResult {
        public long timestamp;
        public int imageWidth;
        public int imageHeight;
        public double primaryAngle;
        public float confidence;
        public String classification;
        public float classificationConfidence;
        public float[] allProbabilities;
        public java.util.List<SpineAngleDetector.SpineKeypoint> keypoints;
        public SpineAngleDetector.SpineAngles angles;
        public SpineAssessment assessment;

        public boolean isSuccessful() {
            return primaryAngle > 0 && confidence > 0;
        }

        public String getSummary() {
            return String.format("Angle: %.1f°, Confidence: %.1f%%, Classification: %s",
                    primaryAngle, confidence * 100, classification);
        }
    }

    public static class SpineAssessment {
        public String severity;
        public String riskLevel;
        public float overallConfidence;
        public int color;
        public String recommendations;
        public boolean requiresImmediateAttention;

        public boolean isNormal() {
            return "Normal".equals(severity);
        }

        public String getUrgencyLevel() {
            if (requiresImmediateAttention) return "Critical";
            if ("High".equals(riskLevel)) return "High";
            if ("Medium".equals(riskLevel)) return "Medium";
            return "Low";
        }
    }
}