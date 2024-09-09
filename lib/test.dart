import 'dart:io'; // Import for File
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'components/file_uploader.dart';

class Testing extends StatefulWidget {
  const Testing({super.key});

  @override
  State<Testing> createState() => _TestingState();
}

class _TestingState extends State<Testing> {
  String _scriptOutput = "";
  String internalPointerVariable = "";
  bool loading = false;
  String? imagePath;

  Future<void> _runPythonScript(String scriptName, String input) async {
    try {
      setState(() {
        imagePath = null; // Reset image path to show CircularProgressIndicator again
        loading = true;   // Show loading indicator while running the script
      });

      // Run the Python script and get the result
      final result = await runExecutableArguments(
        'python',
        [
          './lib/helpers/$scriptName',
          input
        ], // Pass the input string to the Python script
      );

      setState(() {
        imagePath = result.stdout.trim(); // Update the image path with the new result
        loading = false; // Hide loading indicator after the script completes
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
        onPressed: () {
          setState(() {
            loading = true; // Show CircularProgressIndicator immediately after button click
          });

          _runPythonScript('data.py', internalPointerVariable).then((_) {
            setState(() {
              loading = false; // Hide CircularProgressIndicator when the process completes
            });
          });
        },
        tooltip: 'Submit',
        child: loading
            ? const ProgressRing() // Show loading indicator while waiting
            : const Text("Submit"), // Show Submit button when not loading
      ),
      body: Column(
        children: [
          const FileUploader(
            
            buttonText: "Upload a File",
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  height: 70,
                  child: Center(
                    child: InfoLabel(
                      label: 'Enter your name:',
                      child: TextBox(
                        onChanged: (value) {
                          setState(() {
                            internalPointerVariable = value;
                          });
                        },
                        placeholder: 'Name',
                        expands: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
          Center(
            child: imagePath == null
                ? const ProgressRing() // Show loading indicator when image is null
                : Image.file(
                    File(imagePath!), // Add cache-busting query parameter
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.height / 2,
                  ),
          ),
        ],
      ),
    );
  }
}
