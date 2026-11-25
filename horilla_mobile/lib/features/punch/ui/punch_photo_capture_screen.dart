import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_top_bar.dart';

/// A confirmed, front-camera attendance image. The server still performs the
/// identity match; ML Kit only prevents an empty or multi-face upload.
class PunchPhotoCaptureResult {
  const PunchPhotoCaptureResult({required this.jpegBytes, required this.capturedAt});

  final Uint8List jpegBytes;
  final DateTime capturedAt;
}

class PunchPhotoCaptureScreen extends StatefulWidget {
  const PunchPhotoCaptureScreen({super.key});

  @override
  State<PunchPhotoCaptureScreen> createState() => _PunchPhotoCaptureScreenState();
}

class _PunchPhotoCaptureScreenState extends State<PunchPhotoCaptureScreen> {
  CameraController? _camera;
  FaceDetector? _detector;
  XFile? _photo;
  String? _error;
  bool _initializing = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    setState(() { _initializing = true; _error = null; });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No usable camera was found on this device.');
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      await _camera?.dispose();
      _camera = controller;
      _detector ??= FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
      if (mounted) setState(() => _initializing = false);
    } on CameraException catch (error) {
      if (mounted) setState(() { _initializing = false; _error = error.code == 'CameraAccessDenied' ? 'Camera permission was denied. Allow camera access and retry.' : 'Camera could not be started. Retry.'; });
    } catch (error) {
      if (mounted) setState(() { _initializing = false; _error = error.toString().replaceFirst('Bad state: ', ''); });
    }
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    final detector = _detector;
    if (camera == null || !camera.value.isInitialized || detector == null || _checking) return;
    setState(() { _checking = true; _error = null; });
    try {
      final photo = await camera.takePicture();
      final faces = await detector.processImage(InputImage.fromFilePath(photo.path));
      if (faces.length != 1) {
        throw StateError(faces.isEmpty ? 'No face was found. Center one face and retake the photo.' : 'More than one face was found. Keep only the employee in frame and retake the photo.');
      }
      if (mounted) setState(() { _photo = photo; _checking = false; });
    } catch (error) {
      if (mounted) setState(() { _checking = false; _error = error.toString().replaceFirst('Bad state: ', ''); });
    }
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;
    Navigator.of(context).pop(PunchPhotoCaptureResult(jpegBytes: bytes, capturedAt: DateTime.now().toUtc()));
  }

  @override
  void dispose() {
    _detector?.close();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(children: [
        AppTopBar(title: 'Confirm your face', onDark: true, onBack: () => Navigator.of(context).pop()),
        Expanded(child: Padding(padding: const EdgeInsets.all(AppSpace.x20), child: Column(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(AppRadii.card), child: photo == null
              ? (_initializing ? const Center(child: CircularProgressIndicator(color: AppColors.surface)) : (_camera == null ? const SizedBox.shrink() : CameraPreview(_camera!)))
              : Image.file(File(photo.path), width: double.infinity, fit: BoxFit.cover))),
          const SizedBox(height: AppSpace.x16),
          Text(_error ?? (photo == null ? 'Take a clear photo of one face. Nothing is sent until you choose Submit.' : 'Review the photo before submitting it.'), textAlign: TextAlign.center, style: AppText.body.copyWith(color: _error == null ? AppColors.onDark2 : AppColors.warning)),
          const SizedBox(height: AppSpace.x16),
          Row(children: [
            Expanded(child: AppButton(label: photo == null ? (_checking ? 'Checking…' : 'Take Photo') : 'Retake', tone: AppButtonTone.onDark, onPressed: _checking ? null : (photo == null ? _takePhoto : () { setState(() => _photo = null); _startCamera(); }))),
            if (photo != null) ...[const SizedBox(width: AppSpace.x12), Expanded(child: AppButton(label: 'Submit', onPressed: _submit))],
          ]),
        ]))),
      ]),
    );
  }
}
