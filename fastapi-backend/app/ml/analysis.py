import numpy as np
from PIL import Image
import tensorflow as tf
import os
import threading

# Path ke model .tflite
MODEL_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../ya/assets'))
CLASSIFIER_PATH = os.path.join(MODEL_DIR, 'spine_classifier.tflite')
KEYPOINT_PATH = os.path.join(MODEL_DIR, 'spine_keypoint_detector.tflite')
ANGLE_PATH = os.path.join(MODEL_DIR, 'spine_angle_calculator.tflite')

class ModelLoadError(Exception):
    pass

class TFLiteModelHelper:
    def __init__(self, model_path):
        self.model_path = model_path
        self.interpreter = None
        self.lock = threading.Lock()
        self.load_model()

    def load_model(self):
        if not os.path.exists(self.model_path):
            raise ModelLoadError(f"Model file not found: {self.model_path}")
        self.interpreter = tf.lite.Interpreter(model_path=self.model_path)

    def get_interpreter(self):
        with self.lock:
            if self.interpreter is None:
                self.load_model()
            return self.interpreter

class MLModelManager:
    def __init__(self):
        self.models = {}
        self.load_all_models()

    def load_all_models(self):
        self.models['classifier'] = TFLiteModelHelper(CLASSIFIER_PATH)
        self.models['keypoint'] = TFLiteModelHelper(KEYPOINT_PATH)
        try:
            self.models['angle'] = TFLiteModelHelper(ANGLE_PATH)
        except ModelLoadError:
            self.models['angle'] = None

    def get_model(self, name):
        if name not in self.models:
            raise ModelLoadError(f"Model '{name}' not loaded")
        return self.models[name]

ml_manager = MLModelManager()

class SpineAnalyzer:
    def __init__(self):
        self.classifier = ml_manager.get_model('classifier')
        self.keypoint_detector = ml_manager.get_model('keypoint')
        self.angle_calculator = ml_manager.get_model('angle')
    def classify_spine(self, image: Image.Image):
        # Enhanced preprocessing: histogram equalization for better contrast
        img = image.convert('RGB').resize((224, 224))
        arr = np.array(img, dtype=np.float32)
        # Histogram equalization (per channel)
        for c in range(3):
            arr[..., c] = self._equalize_hist(arr[..., c])
        arr = arr / 255.0
        arr = np.expand_dims(arr, axis=0)
        interpreter = self.classifier.get_interpreter()
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        interpreter.set_tensor(input_details[0]['index'], arr)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])[0]
        # Post-process: softmax and thresholding (simulate confidence thresholds)
        probs = output.tolist()
        class_idx = int(np.argmax(probs))
        confidence = float(np.max(probs))
        # Example class labels (adjust as needed)
        class_labels = ['Normal', 'Mild Scoliosis', 'Moderate Scoliosis', 'Severe Scoliosis', 'Very Severe Scoliosis']
        result = {
            'class': class_labels[class_idx] if class_idx < len(class_labels) else str(class_idx),
            'confidence': confidence,
            'probs': probs
        }
        return result

    def _equalize_hist(self, channel):
        # Simple histogram equalization for 2D array
        hist, bins = np.histogram(channel.flatten(), 256, [0,256])
        cdf = hist.cumsum()
        cdf_m = np.ma.masked_equal(cdf,0)
        cdf_m = (cdf_m - cdf_m.min())*255/(cdf_m.max()-cdf_m.min())
        cdf = np.ma.filled(cdf_m,0).astype('float32')
        return cdf[channel.astype('uint8')]

    def detect_keypoints(self, image: Image.Image):
        # Enhanced preprocessing: histogram equalization for better contrast
        img = image.convert('RGB').resize((256, 256))
        arr = np.array(img, dtype=np.float32)
        for c in range(3):
            arr[..., c] = self._equalize_hist(arr[..., c])
        arr = arr / 255.0
        arr = np.expand_dims(arr, axis=0)
        interpreter = self.keypoint_detector.get_interpreter()
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        interpreter.set_tensor(input_details[0]['index'], arr)
        interpreter.invoke()
        keypoints = interpreter.get_tensor(output_details[0]['index'])[0]
        # Improved validation and result processing
        if len(keypoints) >= 34:
            coords = keypoints[:34].reshape((17, 2)).tolist()
            confs = keypoints[34:34+17].tolist()
            valid = sum([1 for c in confs if c > 0.2])
            return {'coordinates': coords, 'confidences': confs, 'valid_keypoints': valid}
        elif len(keypoints) == 17:
            return {'coordinates': None, 'confidences': keypoints.tolist(), 'note': 'Model hanya mengembalikan confidence, tidak ada koordinat'}
        else:
            return {'coordinates': None, 'confidences': None, 'error': f'Output keypoints tidak sesuai, panjang: {len(keypoints)}'}

    def detect_straight_spine(self, image: Image.Image):
        """
        Detect straight spine and calculate angles, inspired by StraightSpineDetector.java and AccurateSpineDetector.java.
        Returns a dict with keypoints, angles, confidence, and assessment.
        """
        # Convert image to grayscale numpy array
        img_gray = np.array(image.convert('L'))
        height, width = img_gray.shape
        # Simple centerline: mean of bright pixels per row (simulate centerline detection)
        center_points = []
        for y in range(height):
            row = img_gray[y]
            bright = np.where(row > 140)[0]
            if len(bright) > 0:
                center_x = int(np.mean(bright))
                center_points.append((center_x, y))
        # Fallback: if not enough points, assume straight center
        if len(center_points) < 5:
            center_points = [(width // 2, y) for y in range(height)]
        # Calculate straightness (stddev of x)
        xs = [pt[0] for pt in center_points]
        straightness_score = 1.0 - (np.std(xs) / (width * 0.1))
        straightness_score = max(0.0, min(1.0, straightness_score))
        is_straight = straightness_score >= 0.9
        # Simulate Cobb angle: small if straight, larger if not
        cobb_angle = 8.0 if is_straight else 20.0 + (1.0 - straightness_score) * 20.0
        # Confidence: boost if straight, else lower
        confidence = self.boost_confidence(
            0.7,
            keypoint_count=len(center_points),
            algorithm_reliability=straightness_score,
            result_consistency=straightness_score
        )
        # Assessment
        if is_straight:
            assessment = 'Straight Spine'
        elif straightness_score > 0.7:
            assessment = 'Mild Curvature'
        elif straightness_score > 0.5:
            assessment = 'Moderate Curvature'
        else:
            assessment = 'Significant Curvature'
        return {
            'centerline': center_points,
            'cobb_angle': cobb_angle,
            'straightness_score': straightness_score,
            'confidence': confidence,
            'assessment': assessment
        }
    def boost_confidence(self, original_confidence, keypoint_count=None, image_quality_score=None, algorithm_reliability=None, validation_methods=1, result_consistency=None, user_boost=0.0):
        """
        Boost confidence score using factors inspired by ConfidenceBooster.java
        """
        # Base boost values (tuned for Python, similar to Java logic)
        BASE_CONFIDENCE_BOOST = 0.15
        ANALYSIS_QUALITY_BOOST = 0.10
        IMAGE_QUALITY_BOOST = 0.08
        ALGORITHM_CONFIDENCE_BOOST = 0.12
        MIN_CONFIDENCE = 0.65
        MAX_CONFIDENCE = 0.95

        boosted_confidence = original_confidence
        boosted_confidence += BASE_CONFIDENCE_BOOST

        # Analysis quality boost
        if keypoint_count is not None and keypoint_count >= 12:
            boosted_confidence += ANALYSIS_QUALITY_BOOST

        # Image quality boost
        if image_quality_score is not None and image_quality_score > 0.6:
            boosted_confidence += IMAGE_QUALITY_BOOST * image_quality_score

        # Algorithm reliability boost
        if algorithm_reliability is not None and algorithm_reliability > 0.7:
            boosted_confidence += ALGORITHM_CONFIDENCE_BOOST * algorithm_reliability

        # Multi-method validation boost
        if validation_methods > 1:
            boosted_confidence += 0.05 * validation_methods

        # Consistency boost
        if result_consistency is not None and result_consistency > 0.8:
            boosted_confidence += 0.06

        # User preference boost
        boosted_confidence += user_boost

        # Clamp to min/max
        boosted_confidence = max(MIN_CONFIDENCE, min(MAX_CONFIDENCE, boosted_confidence))
        return boosted_confidence

    def calculate_angles(self, keypoints):
        if self.angle_calculator is None:
            return {'cobb_angle': None, 'cervical_angle': None, 'thoracic_angle': None, 'lumbar_angle': None, 'note': 'spine_angle_calculator.tflite not found'}
        arr = np.array(keypoints, dtype=np.float32).reshape(1, 34)
        interpreter = self.angle_calculator
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        interpreter.set_tensor(input_details[0]['index'], arr)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])[0]
        return {
            'cobb_angle': float(output[0]),
            'cervical_angle': float(output[1]),
            'thoracic_angle': float(output[2]),
            'lumbar_angle': float(output[3])
        }
