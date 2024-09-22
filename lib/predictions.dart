import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:indian_oil_ai/utils/file_utils.dart';
import 'package:process_run/process_run.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

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
    final pythonScript =
        await rootBundle.loadString('assets/python/prediction_internal.py');
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/data.py');
    await file.writeAsString(pythonScript);
    return file.path; // Return the path to the Python script
  }

  Future<void> _runPythonScript(
      String scriptName, String dataSetPath, String modelPath) async {
    final scriptPath = await _preparePythonScript();

    try {
      setState(() {
        imagePath = null;
        loading = true;
      });

      final result = await runExecutableArguments(
          'python', [scriptPath, dataSetPath, modelPath]);
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
                // Display mismatch count
                final mismatchCount = jsonOutput['mismatch_count'];
                print('Number of mismatches: $mismatchCount');
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
          columns: columns
              .map((e) => DataColumn(
                  label: Text(e, style: const TextStyle(fontSize: 12))))
              .toList(),
          rows: data.map((row) {
            return DataRow(
                cells: row
                    .map((cell) => DataCell(Text(cell.toString())))
                    .toList());
          }).toList(),
        ),
      );
    } catch (e) {
      print('Error parsing JSON data: $e');
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Predictions'),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Model', style: TextStyle(fontSize: 16)),
          Row(
            children: [
              Expanded(
                child: Button(
                  onPressed: pickAndSaveModel,
                  child: const Text('Choose File'),
                ),
              ),
              const SizedBox(width: 16),
              Text(model ?? 'No model selected'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Dataset', style: TextStyle(fontSize: 16)),
          Row(
            children: [
              Expanded(
                child: Button(
                  onPressed: pickAndSaveDataSet,
                  child: const Text('Choose File'),
                ),
              ),
              const SizedBox(width: 16),
              Text(dataSet ?? 'No dataset selected'),
            ],
          ),
          const SizedBox(height: 16),
          Button(
            onPressed: modelPath != null && dataSetPath != null && !loading
                ? () {
                    _runPythonScript(
                        'prediction_internal.py', dataSetPath!, modelPath!);
                  }
                : null,
            child: loading ? const ProgressRing() : const Text('Submit'),
          ),
          const SizedBox(height: 16),
          if (dataSetData != null) Expanded(child: _buildDataTable()),
          if (imagePath != null) Expanded(child: Image.file(File(imagePath!))),
        ],
      ),
    );
  }
}
