# MobileFaceNet TFLite Model

This directory must contain `mobile_face_net.tflite` for offline face
verification to work on mobile devices (Android / iOS).

## Download

**Option A – estebanuri/face_recognition (recommended — exact filename match)**

Direct raw download (verified working):
```
https://raw.githubusercontent.com/estebanuri/face_recognition/master/android/app/src/main/assets/mobile_face_net.tflite
```

Download and place the file at:
```
assets/models/mobile_face_net.tflite
```

**Option B – syaringan357 (InsightFace/ArcFace training)**

```
https://raw.githubusercontent.com/syaringan357/Android-MobileFaceNet-MTCNN-FaceAntiSpoofing/master/app/src/main/assets/MobileFaceNet.tflite
```
Rename the downloaded file to `mobile_face_net.tflite` before placing it in `assets/models/`.

**Option C – MCarlomagno/FaceRecognitionAuth (archived Flutter app)**

```
https://raw.githubusercontent.com/MCarlomagno/FaceRecognitionAuth/refs/heads/master/assets/mobilefacenet.tflite
```
Rename to `mobile_face_net.tflite` before placing in `assets/models/`.

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
