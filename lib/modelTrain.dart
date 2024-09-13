import 'dart:io'; // Import for File
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:indian_oil_ai/utils/file_utils.dart';
import 'package:process_run/process_run.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert'; // Import to handle JSON

class ModelTrain extends StatefulWidget {
  const ModelTrain({super.key});

  @override
  State<ModelTrain> createState() => _ModelTrainState();
}

class _ModelTrainState extends State<ModelTrain> {
  String? dataSetData; // JSON string for the table data
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

  Future<String> _preparePythonScript() async {
    // Load the script from the assets
    final pythonScript = await rootBundle.loadString('assets/python/data.py');

    // Get the directory where to store the file
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/data.py');

    // Write the script to the file
    await file.writeAsString(pythonScript);

    return file.path; // Return the path to the Python script
  }

  Future<void> _runPythonScript(String scriptName, String input) async {
    final scriptPath = await _preparePythonScript();

    try {
      setState(() {
        imagePath = null;
        loading = true;
      });

      // Check and delete old heatmap image
      final heatmapFile = File('$imagePath');
      if (heatmapFile.existsSync()) {
        heatmapFile.deleteSync();
        print('Deleted previous heatmap at: $imagePath');
      }

      // Execute the Python script, passing in the input Excel file
      final result = await runExecutableArguments('python', [scriptPath, input]);
      final scriptOutput = result.stdout.trim();

      // Split the output into individual JSON strings (each line should be a valid JSON object)
      final outputLines = scriptOutput.split('\n');

      // Process each line of output
      for (String line in outputLines) {
        if (line.isNotEmpty) {
          try {
            final jsonOutput = jsonDecode(line); // Decode each JSON line

            // Handle different types of output
            if (jsonOutput['type'] == 'data') {
              setState(() {
                dataSetData = jsonOutput['content']; // Display or process the data
                loading = false;
              });
            } else if (jsonOutput['type'] == 'image') {
              setState(() {
                imagePath = jsonOutput['content']; // Show the path of the heatmap image
                loading = false;
              });

              // Notify success
              await displayInfoBar(context, builder: (context, close) {
                return InfoBar(
                  title: const Text('Operation Completed'),
                  content: Text('Image saved at: $imagePath'),
                  action: Button(
                    onPressed: close,
                    child: const Icon(FluentIcons.clear),
                  ),
                  severity: InfoBarSeverity.success,
                );
              });
            } else if (jsonOutput['type'] == 'error') {
              await displayInfoBar(context, builder: (context, close) {
                return InfoBar(
                  title: const Text('Error'),
                  content: Text(jsonOutput['message']), // Show error message
                  action: Button(
                    onPressed: close,
                    child: const Icon(FluentIcons.clear),
                  ),
                  severity: InfoBarSeverity.error,
                );
              });
            }
          } catch (e) {
            print('Error decoding line: $e');
          }
        }
      }
    } catch (e) {
      // Handle errors
      await displayInfoBar(context, builder: (context, close) {
        return InfoBar(
          title: const Text('Error'),
          content: Text('Error: $e'),
          action: Button(
            onPressed: close,
            child: const Icon(FluentIcons.clear),
          ),
          severity: InfoBarSeverity.error,
        );
      });

      print('Error: $e');
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildDataTable() {
    if (dataSetData == null) return const SizedBox.shrink();

    try {
      final Map<String, dynamic> parsedData = jsonDecode(dataSetData!);
      final List<String> columns = List<String>.from(parsedData['columns']);
      final List<List<dynamic>> data = List<List<dynamic>>.from(
          parsedData['data'].map((item) => List<dynamic>.from(item)));

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns.map((column) => DataColumn(label: Text(column))).toList(),
          rows: data.map((row) {
            return DataRow(
              cells: row.map((cell) => DataCell(Text(cell.toString()))).toList(),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      print('Error parsing dataSetData: $e');
      return const SizedBox.shrink(); // Fallback in case of parsing error
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndSaveFile,
              child: Text(
                fileName != null
                    ? 'Selected file: $fileName'
                    : 'No file selected',
              ),
            ),
            Center(
              child: loading
                  ? const ProgressRing() // Show loading indicator when processing
                  : imagePath == null && dataSetData == null
                      ? const SizedBox.shrink() // Show nothing when both imagePath and dataSetData are null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (dataSetData != null) // Check if dataSetData is not null
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildDataTable(), // Display the data table
                              ),
                            if (imagePath != null) // Check if imagePath is not null
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(
                                  File(imagePath!), // Display the new image file
                                  width: MediaQuery.of(context).size.width / 2,
                                  height: MediaQuery.of(context).size.height / 2,
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
