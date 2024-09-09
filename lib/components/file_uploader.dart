import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // For file operations
import 'package:path_provider/path_provider.dart'; // For directory paths

class FileUploader extends StatefulWidget {
  final String? buttonText; // Optional custom button text

  const FileUploader({Key? key, this.buttonText}) : super(key: key);

  @override
  _FileUploaderState createState() => _FileUploaderState();
}

class _FileUploaderState extends State<FileUploader> {
  String? _fileName;
  String? _filePath;

  // Callback function that gets the selected file name and path
  Future<void> pickAndSaveFile() async {
    // Pick a single file
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // Get the file path and name
      PlatformFile file = result.files.first;
      setState(() {
        _fileName = file.name;
        _filePath = file.path;
      });

      // Save the file to a directory
      await _saveFileToDirectory(file);
    }
  }

  // Save the file to the application's document directory
  Future<void> _saveFileToDirectory(PlatformFile file) async {
    try {
      Directory? directory = await getApplicationDocumentsDirectory();
      String newPath = '${directory.path}/${file.name}';

      // Copy the file to the new directory
      File newFile = File(newPath);
      File(file.path!).copy(newFile.path);

      print("File saved to: $newPath");
    } catch (e) {
      print("Error while saving the file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          _fileName != null ? 'Selected file: $_fileName' : 'No file selected',
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: pickAndSaveFile,
          child: Text(widget.buttonText ?? "Pick and Upload File"),
        ),
      ],
    );
  }
}
