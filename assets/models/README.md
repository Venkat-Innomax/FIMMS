# MobileFaceNet TFLite Model

This directory must contain `mobile_face_net.tflite` for offline face
verification to work on mobile devices (Android / iOS).

## Download

**Option A – Sirius Face (recommended, open-source)**

```
https://github.com/Shiming-Liang/FaceVerification/blob/master/models/mobile_face_net.tflite
```

Download and place the file at:

```
assets/models/mobile_face_net.tflite
```

**Option B – TensorFlow Hub**

Search for "MobileFaceNet" on https://tfhub.dev and download a
128-dimensional embedding model in TFLite format.

## Model Spec

| Property | Value |
|---|---|
| Input | 112 × 112 RGB image (normalised –1 → +1) |
| Output | 128-d float32 embedding vector |
| Similarity metric | Cosine similarity (threshold ≥ 0.75 = match) |
| Runtime | tflite_flutter ^0.10.4 |

## Web

`tflite_flutter` has **no web support**. On Flutter Web the selfie gate
shows a hard-block message instead of running the model. The profile tab
likewise shows a "mobile app only" notice.
