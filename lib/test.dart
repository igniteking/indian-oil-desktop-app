import 'dart:io'; // Import for File
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:indian_oil_ai/utils/file_utils.dart';
import 'package:process_run/process_run.dart';

class Testing extends StatefulWidget {
  const Testing({super.key});

  @override
  State<Testing> createState() => _TestingState();
}

class _TestingState extends State<Testing> {
  String internalPointerVariable = "";
  bool loading = false;
  String? imagePath; // To store the path of the image with timestamp
  String? filePath;
  String? fileName;

  void pickAndSaveFile() async {
    setState(() {
      filePath = null;
      fileName = null;
    });

    PlatformFile? file = await FileUtils.pickFile();
    if (file != null) {
      // Get the current working directory (where the EXE file is located)
      String workingDirectory = Directory.current.path;

      // Define the path for the new folder
      String newFolderPath = '$workingDirectory/uploads';
      Directory newFolder = Directory(newFolderPath);

      if (!newFolder.existsSync()) {
        // Create the new folder if it does not exist
        newFolder.createSync();
      }

      // Save the file to the new folder
      String? newVar = await FileUtils.saveFileToDirectory(file, newFolderPath);
      setState(() {
        filePath = newVar;
        fileName = file.name;
      });
      print('File saved at: $filePath');
    }
  }

  Future<void> _runPythonScript(String scriptName, String input) async {
    try {
      setState(() {
        imagePath = null; // Reset image path to show CircularProgressIndicator
        loading = true; // Show loading indicator while running the script
      });

      // Run the Python script and get the result
      final result = await runExecutableArguments(
        'python',
        ['./lib/helpers/$scriptName', input], // Pass the input file path
      );

      setState(() {
        imagePath = result.stdout.trim(); // Capture the new image path with timestamp
        loading = false; // Hide loading indicator
      });

      // Show completion info bar
      await displayInfoBar(context, builder: (context, close) {
        return InfoBar(
          title: const Text('Operation Completed'),
          content: const Text('The script has finished execution.'),
          action: Button(
            onPressed: close,
            child: const Icon(FluentIcons.clear),
          ),
          severity: InfoBarSeverity.info,
        );
      });

      print('Image Path: $imagePath');
    } catch (e) {
      print('Error: $e');
      setState(() {
        loading = false; // Hide loading indicator in case of error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: filePath != null
            ? () {
                setState(() {
                  loading = true; // Show CircularProgressIndicator after button click
                });

                _runPythonScript('data.py', filePath!).then((_) {
                  setState(() {
                    loading = false; // Hide CircularProgressIndicator when done
                  });
                });
              }
            : null, // Disable the button if filePath is null
        tooltip: 'Submit',
        child: loading
            ? const ProgressRing() // Show loading indicator
            : const Text("Submit"), // Show Submit button when not loading
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickAndSaveFile,
            child: Text(
              fileName != null
                  ? 'Selected file: $fileName'
                  : 'No file selected',
            ),
          ),
          const SizedBox(height: 100),
          Center(
            child: loading
                ? const ProgressRing() // Show loading indicator when processing
                : imagePath == null
                    ? const SizedBox.shrink() // Show nothing when imagePath is null
                    : Image.file(
                        File(imagePath!), // Display the new image file with timestamp
                        width: MediaQuery.of(context).size.width / 2,
                        height: MediaQuery.of(context).size.height / 2,
                      ),
          ),
        ],
      ),
    );
  }
}
