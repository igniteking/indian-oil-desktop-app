import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Divider;
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
  List<String> dataSetDataList = [];
  bool loading = false;
  String? modelPath;
  String? model;
  String? dataPath;
  String? data;
  String? mismatchCount;

  void pickAndSaveModel() async {
    setState(() {
      modelPath = null;
      model = null;
    });

    PlatformFile? file = await FileUtils.pickFile();
    if (file != null) {
      String newFolderPath = '${Directory.current.path}/uploads';
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
      dataPath = null;
      data = null;
    });

    PlatformFile? file = await FileUtils.pickFile();
    if (file != null) {
      String newFolderPath = '${Directory.current.path}/uploads';
      Directory newFolder = Directory(newFolderPath);
      if (!newFolder.existsSync()) {
        newFolder.createSync();
      }
      String? newVar = await FileUtils.saveFileToDirectory(file, newFolderPath);
      setState(() {
        dataPath = newVar; // Save to dataPath
        data = file.name; // Update dataset name
      });
      print('Data file saved at: $dataPath');
    }
  }

  Future<String> _preparePythonScript() async {
    final pythonScript =
        await rootBundle.loadString('assets/python/prediction_internal.py');
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/prediction_internal.py');
    await file.writeAsString(pythonScript);
    return file.path;
  }

  Future<void> _runPythonScript() async {
    if (dataPath == null || modelPath == null) {
      await _showErrorDialog('Model or data path is null.');
      return;
    }

    final scriptPath = await _preparePythonScript();

    try {
      setState(() {
        dataSetDataList.clear();
        loading = true;
      });

      final result = await runExecutableArguments(
          'python', [scriptPath, dataPath!, modelPath!]);
      final scriptOutput = result.stdout.trim();
      final outputLines = scriptOutput.split('\n');

      for (String line in outputLines) {
        if (line.isNotEmpty) {
          try {
            final jsonOutput = jsonDecode(line);
            if (jsonOutput['type'] == 'data') {
              setState(() {
                dataSetDataList.add(jsonOutput['content']);
                // Ensure mismatch_count is extracted from the correct output
                mismatchCount = jsonOutput['mismatch_count']?.toString() ??
                    '0'; // Use '0' if null
                print('Mismatch count: $mismatchCount');
              });
            } else if (jsonOutput['type'] == 'error') {
              await _showErrorDialog(jsonOutput['message']);
              print("Error: " + jsonOutput['message']);
            }
          } catch (e) {
            print('Error decoding line: $e');
          }
        }
      }
    } catch (e) {
      await _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _showErrorDialog(String message) async {
    await displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: const Text('Error'),
        content: Text(message),
        action: Button(
          onPressed: close,
          child: const Icon(FluentIcons.clear),
        ),
        severity: InfoBarSeverity.error,
      );
    });
  }

  Widget _buildDataTable(String dataSetData) {
    try {
      final Map<String, dynamic> parsedData = jsonDecode(dataSetData);
      final List<String> columns = List<String>.from(parsedData['columns']);
      final List<List<dynamic>> data = List<List<dynamic>>.from(
          parsedData['data'].map((item) => List<dynamic>.from(item)));

      return Center(
        child: DataTable(
          columns:
              columns.map((column) => DataColumn(label: Text(column))).toList(),
          rows: data.map((row) {
            return DataRow(
              cells:
                  row.map((cell) => DataCell(Text(cell.toString()))).toList(),
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
    return ScaffoldPage(
      header: const PageHeader(title: Text('Predictions')),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Model', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Expander(
                    leading: const Icon(FluentIcons.robot), // Corrected part
                    header: Text(model ?? 'Select a model'),
                    content: Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width,
                          child: Button(
                            onPressed: pickAndSaveModel,
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(FluentIcons.add),
                                Text(' Add a new model'),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width,
                          child: Button(
                            onPressed: () => {
                              setState(() {
                                modelPath = 'assets/python/model.pkl';
                                model = 'model.pkl';
                              })
                            },
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(FluentIcons.chat_bot),
                                Text(' Model 0.0.1'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Dataset', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Button(
                    onPressed: pickAndSaveDataSet,
                    child: Text(data ?? 'No dataset selected'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 16),
            Button(
              onPressed: modelPath != null && dataPath != null && !loading
                  ? _runPythonScript
                  : null,
              child: loading ? const ProgressRing() : const Text('Submit'),
            ),
            const SizedBox(height: 16),
            if (dataSetDataList.isNotEmpty) ...[
              const Center(
                child: Text(
                  "Mismatches between actual vs predicted locations:",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Center(
                child: Text(
                  "Mismatches Count: $mismatchCount",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              ...dataSetDataList
                  .map((dataSetData) => _buildDataTable(dataSetData)),
            ],
          ],
        ),
      ),
    );
  }
}
