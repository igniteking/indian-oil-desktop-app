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
  List<String> dataSetDataList =
      []; // List to store multiple JSON strings for tables
  List<String> imagePaths = []; // List to store multiple image paths
  bool loading = false;
  String? filePath;
  String? fileName;

  void pickAndSaveFile() async {
    setState(() {
      filePath = null;
      fileName = null;
    });

    PlatformFile? file = await FileUtils.pickFile();
    if (file != null) {
      String workingDirectory = Directory.current.path;
      String newFolderPath = '$workingDirectory/uploads';
      Directory newFolder = Directory(newFolderPath);

      if (!newFolder.existsSync()) {
        newFolder.createSync();
      }

      String? newVar = await FileUtils.saveFileToDirectory(file, newFolderPath);
      setState(() {
        filePath = newVar;
        fileName = file.name;
      });
      print('File saved at: $filePath');
    }
  }

  Future<String> _preparePythonScript() async {
    final pythonScript =
        await rootBundle.loadString('assets/python/train_internal.py');
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/train_internal.py');
    await file.writeAsString(pythonScript);
    return file.path; // Return the path to the Python script
  }

  Future<void> _runPythonScript(String scriptName, String input) async {
    final scriptPath = await _preparePythonScript();

    try {
      setState(() {
        imagePaths.clear(); // Clear the image paths
        dataSetDataList.clear();
        loading = true;
      });

      final result =
          await runExecutableArguments('python', [scriptPath, input]);
      final scriptOutput = result.stdout.trim();
      final outputLines = scriptOutput.split('\n');

      for (String line in outputLines) {
        if (line.isNotEmpty) {
          try {
            final jsonOutput = jsonDecode(line);
            if (jsonOutput is Map<String, dynamic> &&
                jsonOutput.containsKey('type')) {
              if (jsonOutput['type'] == 'image') {
                setState(() {
                  imagePaths.addAll([
                    jsonOutput['pdp_image_path'],
                    jsonOutput['fi_image_path'],
                    jsonOutput['box_plot_path'],
                    jsonOutput['stationing_plot_path'],
                    jsonOutput['heatmap_plot_path']
                  ]); // Store all image paths
                });
              }

              if (jsonOutput['type'] == 'data') {
                setState(() {
                  dataSetDataList.add(jsonOutput['content']);
                });
              }

              if (jsonOutput['type'] == 'error') {
                await displayInfoBar(context, builder: (context, close) {
                  print(jsonOutput['message']);

                  return InfoBar(
                    title: const Text('Error'),
                    content: Text(jsonOutput['message']),
                    action: Button(
                      onPressed: close,
                      child: const Icon(FluentIcons.clear),
                    ),
                    severity: InfoBarSeverity.error,
                  );
                });
              }
            } else {
              print('Invalid JSON format: Missing "type" key');
            }
          } catch (e) {
            print('Error decoding line: $line');
            print('Error: $e');
          }
        }
      }
    } catch (e) {
      await displayInfoBar(context, builder: (context, close) {
        print(e);
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
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildDataTable(String dataSetData) {
    try {
      final Map<String, dynamic> parsedData = jsonDecode(dataSetData);
      final List<String> columns = List<String>.from(parsedData['columns']);
      final List<List<dynamic>> data = List<List<dynamic>>.from(
          parsedData['data'].map((item) => List<dynamic>.from(item)));

      return DataTable(
        columns:
            columns.map((column) => DataColumn(label: Text(column))).toList(),
        rows: data.map((row) {
          return DataRow(
            cells: row.map((cell) => DataCell(Text(cell.toString()))).toList(),
          );
        }).toList(),
      );
    } catch (e) {
      print('Error parsing dataSetData: $e');
      return const SizedBox.shrink(); // Fallback in case of parsing error
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Train Model')),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Set', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Button(
                      onPressed: pickAndSaveFile,
                      child: Text(fileName ?? 'No Data Set selected'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Button(
                onPressed: filePath != null
                    ? () {
                        _runPythonScript('train_internal.py', filePath!);
                      }
                    : null,
                child: loading ? const ProgressRing() : const Text('Submit'),
              ),
              const SizedBox(height: 16),
              if (loading)
                const Center(child: null)
              else if (imagePaths.isEmpty && dataSetDataList.isEmpty)
                const Center(child: Text('No data or images to display'))
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column for the images on the left
                    Expanded(
                      flex: 1, // 50% width for images
                      child: Column(
                        children: [
                          if (imagePaths.isNotEmpty)
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: imagePaths.map((path) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.file(
                                    File(path),
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    height:
                                        MediaQuery.of(context).size.height / 3,
                                    fit: BoxFit
                                        .contain, // Ensures image fits well
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        width: 16), // Spacer between images and table

                    // Column for the tables on the right
                    Expanded(
                      flex: 1, // 50% width for tables
                      child: Column(
                        children: [
                          for (var dataSetData in dataSetDataList)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildDataTable(dataSetData),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
