
ML Model Files Required:

1. spine_classifier.tflite
   - CNN model for spine condition classification
   - Input: 224x224x3 RGB image
   - Output: 5 classes (Normal, Mild, Moderate, Severe, Very Severe)

2. spine_keypoint_detector.tflite  
   - Keypoint detection model for spine landmarks
   - Input: 256x256x3 RGB image
   - Output: 17 keypoints with confidence scores

3. spine_angle_calculator.tflite (Optional)
   - Enhanced angle calculation model
   - Input: Keypoint coordinates
   - Output: Precise angle measurements

Please place your trained .tflite model files in this directory.
