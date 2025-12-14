# Spine Analysis TensorFlow Lite Models

## Generated Models

### 1. spine_classifier.tflite
- **Purpose**: Classifies spine condition severity
- **Input**: RGB image (224x224x3)
- **Output**: 5-class probabilities
  - Class 0: Normal
  - Class 1: Mild Scoliosis
  - Class 2: Moderate Scoliosis
  - Class 3: Severe Scoliosis
  - Class 4: Very Severe Scoliosis

### 2. spine_keypoint_detector.tflite
- **Purpose**: Detects 17 spine keypoints
- **Input**: RGB image (256x256x3)
- **Output**: 
  - Keypoint coordinates (34 values: x1,y1,x2,y2,...,x17,y17)
  - Confidence scores (17 values)

### 3. spine_angle_calculator.tflite
- **Purpose**: Calculates spine angles from keypoints
- **Input**: Keypoint coordinates (34 values)
- **Output**: 
  - Cobb angle
  - Cervical angle
  - Thoracic angle
  - Lumbar angle

## Usage Notes

These are basic models for testing and development. For production use:
1. Train with real medical datasets
2. Validate with medical professionals
3. Ensure compliance with medical device regulations

## Model Performance

These models are generated for testing purposes and may not provide
medically accurate results. Always consult medical professionals for
actual spine analysis.
