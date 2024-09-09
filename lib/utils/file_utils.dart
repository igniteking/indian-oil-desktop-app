import 'dart:io'; // For file operations
import 'package:file_picker/file_picker.dart'; // For file picking

class FileUtils {
  // Pick a single file and return the PlatformFile object
  static Future<PlatformFile?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        return result.files.first;
      }
    } catch (e) {
      print("Error picking file: $e");
    }
    return null;
  }

  // Save the picked file to the application's document directory
  // Save the picked file to the specified directory
  static Future<String?> saveFileToDirectory(
      PlatformFile file, String folderPath) async {
    try {
      String newPath = '$folderPath/${file.name}';

      // Copy the file to the new directory
      File newFile = File(newPath);
      await File(file.path!).copy(newFile.path);

      print("File saved to: $newPath");
      return newPath;
    } catch (e) {
      print("Error while saving the file: $e");
      return null;
    }
  }
}
