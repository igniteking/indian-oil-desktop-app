import 'dart:io'; // Import for File
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:indian_oil_ai/utils/file_utils.dart';
import 'package:process_run/process_run.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert'; // Import to handle JSON

class Predictions extends StatefulWidget {
  const Predictions({super.key});

  @override
  State<Predictions> createState() => _PredictionsState();
}

class _PredictionsState extends State<Predictions> {
  String? dataSetData; // JSON string for the table data
  bool loading = false;
  String? imagePath; // To store the path of the image with timestamp
  String? modelPath;
  String? model;
  String? dataSetPath;
  String? dataSet;

  void pickAndSaveModel() async {
    setState(() {
      modelPath = null;
      model = null;
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
        modelPath = newVar;
        model = file.name;
      });
      print('Model file saved at: $modelPath');
    }
  }

  void pickAndSaveDataSet() async {
    setState(() {
      dataSetPath = null;
      dataSet = null;
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
        dataSetPath = newVar;
        dataSet = file.name;
      });
      print('Dataset file saved at: $dataSetPath');
    }
  }

  Future<String> _preparePythonScript() async {
    final pythonScript = await rootBundle.loadString('assets/python/data.py');
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/data.py');
    await file.writeAsString(pythonScript);
    return file.path; // Return the path to the Python script
  }

  Future<void> _runPythonScript(String scriptName, String dataSetPath, String modelPath) async {
    final scriptPath = await _preparePythonScript();

    try {
      setState(() {
        imagePath = null;
        loading = true;
      });

      final result = await runExecutableArguments('python', [scriptPath, dataSetPath, modelPath]);
      final scriptOutput = result.stdout.trim();
      final outputLines = scriptOutput.split('\n');

      for (String line in outputLines) {
        if (line.isNotEmpty) {
          try {
            final jsonOutput = jsonDecode(line);

            if (jsonOutput['type'] == 'data') {
              setState(() {
                dataSetData = jsonOutput['content'];
                loading = false;
              });
            } else if (jsonOutput['type'] == 'image') {
              setState(() {
                imagePath = jsonOutput['content'];
                loading = false;
              });

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
                  content: Text(jsonOutput['message']),
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
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: (dataSetPath != null && modelPath != null)
            ? () {
                setState(() {
                  loading = true;
                });

                _runPythonScript('data.py', dataSetPath!, modelPath!).then((_) {
                  setState(() {
                    loading = false;
                  });
                });
              }
            : null, // Disable the button if dataSetPath or modelPath is null
        tooltip: 'Submit',
        child: loading
            ? const ProgressRing()
            : const Text("Submit"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: pickAndSaveDataSet,
                  child: Text(
                    dataSet != null
                        ? 'Selected dataset: $dataSet'
                        : 'Select a Dataset file',
                  ),
                ),
                ElevatedButton(
                  onPressed: pickAndSaveModel,
                  child: Text(
                    model != null
                        ? 'Selected model: $model'
                        : 'Select a Model.PKL file',
                  ),
                ),
              ],
            ),
            Center(
              child: loading
                  ? const ProgressRing()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (dataSetData != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildDataTable(),
                          ),
                        if (imagePath != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.file(
                              File(imagePath!),
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
