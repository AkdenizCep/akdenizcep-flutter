import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/profile_photo_codec.dart';

class ProfilePhotoEditorPage extends StatefulWidget {
  final Uint8List imageBytes;

  const ProfilePhotoEditorPage({super.key, required this.imageBytes});

  @override
  State<ProfilePhotoEditorPage> createState() => _ProfilePhotoEditorPageState();
}

class _ProfilePhotoEditorPageState extends State<ProfilePhotoEditorPage> {
  final _cropController = CropController();
  final _processing = ValueNotifier(false);

  @override
  void dispose() {
    _processing.dispose();
    super.dispose();
  }

  Future<void> _handleCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final jpegBytes = await encodeProfilePhoto(croppedImage);
          if (mounted) context.pop(jpegBytes);
        } catch (error) {
          _processing.value = false;
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      case CropFailure(:final cause):
        _processing.value = false;
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fotoğraf kırpılamadı: $cause')));
    }
  }

  void _save() {
    if (_processing.value) return;
    _processing.value = true;
    _cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0A0D14);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        leading: ValueListenableBuilder(
          valueListenable: _processing,
          builder: (_, processing, _) => IconButton(
            tooltip: 'İptal',
            onPressed: processing ? null : () => context.pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        title: const Text('Fotoğrafı Ayarla'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _cropController,
                  onCropped: _handleCropped,
                  interactive: true,
                  fixCropRect: true,
                  withCircleUi: true,
                  baseColor: background,
                  maskColor: Colors.black.withValues(alpha: 0.68),
                  progressIndicator: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Fotoğrafı sürükleyip yakınlaştırabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ValueListenableBuilder(
                  valueListenable: _processing,
                  builder: (context, processing, _) => FilledButton.icon(
                    onPressed: processing ? null : _save,
                    icon: processing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(processing ? 'Hazırlanıyor...' : 'Kaydet'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
