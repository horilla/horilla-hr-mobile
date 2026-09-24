/// Recording the one reference photo the facedetection app stores per
/// employee. See facedetection_api.dart for what this does and does not
/// enable server-side -- there is no matching, only this single stored
/// image, upserted every time this screen is used again.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/toast.dart';
import '../data/facedetection_api.dart';

enum _Status { initializing, ready, denied, unavailable, reviewing }

class FaceEnrolmentScreen extends ConsumerStatefulWidget {
  const FaceEnrolmentScreen({super.key});

  @override
  ConsumerState<FaceEnrolmentScreen> createState() =>
      _FaceEnrolmentScreenState();
}

class _FaceEnrolmentScreenState extends ConsumerState<FaceEnrolmentScreen> {
  CameraController? _controller;
  _Status _status = _Status.initializing;
  Uint8List? _captured;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _status = _Status.unavailable);
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _status = _Status.ready;
      });
    } on CameraException {
      if (mounted) setState(() => _status = _Status.denied);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.unavailable);
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();
      if (mounted) {
        setState(() {
          _captured = bytes;
          _error = null;
          _status = _Status.reviewing;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not take the photo. Try again.');
      }
    }
  }

  void _retake() {
    setState(() {
      _captured = null;
      _error = null;
      _status = _Status.ready;
    });
  }

  Future<void> _confirm() async {
    final bytes = _captured;
    final session = ref.read(sessionProvider);
    if (bytes == null || session == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref
          .read(facedetectionApiProvider)
          .uploadReference(session.host, bytes);
      ref.read(toastProvider.notifier).show('Reference photo saved');
      if (mounted) context.pop(true);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(title: 'Face ID enrolment', onBack: () => context.pop()),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_status) {
      case _Status.initializing:
        return const Center(child: CircularProgressIndicator());
      case _Status.ready:
        final controller = _controller!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.x20),
              child: Text(
                'This photo is stored for HR review and is not used to '
                'verify your identity automatically.',
                textAlign: TextAlign.center,
                style: AppText.meta,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.x20,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.x20,
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.danger),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.x20),
              child: AppButton(label: 'Take photo', onPressed: _capture),
            ),
          ],
        );
      case _Status.reviewing:
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.x20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: Image.memory(_captured!, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.x20,
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.danger),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.x20),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Retake',
                      tone: AppButtonTone.quiet,
                      onPressed: _uploading ? null : _retake,
                    ),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Expanded(
                    child: AppButton(
                      label: _uploading ? 'Saving…' : 'Use this photo',
                      onPressed: _uploading ? null : _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case _Status.denied:
        return _fallback(
          'Camera access is off for Horilla HR. Turn it on in Settings to '
          'enrol a reference photo.',
        );
      case _Status.unavailable:
        return _fallback('No usable camera was found on this device.');
    }
  }

  Widget _fallback(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.screen),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.body,
        ),
      ),
    );
  }
}
