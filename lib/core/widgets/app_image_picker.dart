import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AppImagePicker extends StatefulWidget {
  final String label;
  final void Function(XFile file)? onImageSelected;

  const AppImagePicker({
    super.key,
    this.label = 'Subir Identificación',
    this.onImageSelected,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();
}

class _AppImagePickerState extends State<AppImagePicker> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Uint8List? _webImage;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _selectedImage = File(image.path));
      }
      widget.onImageSelected?.call(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF225378),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFACF0F2),
                width: 1.5,
              ),
            ),
            child: _webImage != null || _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? Image.memory(_webImage!, fit: BoxFit.cover)
                        : Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: Color(0xFF1695A3),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Toca para subir imagen',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}