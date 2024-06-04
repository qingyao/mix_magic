import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {

  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _cropImage() async {
    if (_imageFile == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: _imageFile!.path,
      aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      compressFormat: ImageCompressFormat.png,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path);
      });

      _compressAndSaveImage(_imageFile!);
    }
  }

  Future<void> _compressAndSaveImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image originalImage = img.decodeImage(bytes)!;

    img.Image resizedImage =
        img.copyResize(originalImage, width: 300, height: 300);
    final compressedBytes = img.encodePng(resizedImage);

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/compressed_image.png';
    final file = File(imagePath);
    await file.writeAsBytes(compressedBytes);

    print('Image saved at $imagePath');
  }

  @override
  Widget build(BuildContext context) {
    return  Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _imageFile != null
                    ? Expanded(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!)))
                    : const SizedBox(height: 100,),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Pick Image'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _cropImage,
                  child: Text('Crop & Compress Image'),
                ),
              ],
            ),
          );
}
}