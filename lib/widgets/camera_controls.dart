import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback? onCapture;
  final Function(XFile)? onImageSelected;

  const CameraControls({
    Key? key,
    this.onCapture,
    this.onImageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          buildGalleryButton(context, isIOS),

          // Capture button
          buildCaptureButton(isIOS),

          // Placeholder for symmetry
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget buildGalleryButton(BuildContext context, bool isIOS) {
    return GestureDetector(
      onTap: () => pickImageFromGallery(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isIOS ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isIOS ? CupertinoIcons.photo : Icons.photo_library,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget buildCaptureButton(bool isIOS) {
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isIOS ? CupertinoColors.systemRed : Colors.redAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Future<void> pickImageFromGallery(BuildContext context) async {
    if (onImageSelected == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image != null && onImageSelected != null) {
        onImageSelected!(image);
      }
    } catch (e) {
      if (context.mounted) {
        // Show error message
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to pick image: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to pick image: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}