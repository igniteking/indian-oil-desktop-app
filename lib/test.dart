import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';

class Testing extends StatefulWidget {
  const Testing({super.key});

  @override
  State<Testing> createState() => _TestingState();
}

class _TestingState extends State<Testing> {
  String _scriptOutput = "";
  String internalPointerVariable = "";

  Future<void> _runPythonScript(String scriptName, String input) async {
    try {
      final result = await runExecutableArguments(
        'python',
        [
          './lib/helpers/$scriptName',
          input
        ], // Pass the input string to the Python script
      );
      setState(() {
        _scriptOutput = result.stdout; // Update state with script output
      });
      print(result.stdout);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _runPythonScript('data.py', internalPointerVariable),
        tooltip: 'Increment',
        child: const Text("Submit"),
      ),
      body: Column(
        children: [
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
                            internalPointerVariable =
                                value; // Update the state with the new value
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
          Text(
            _scriptOutput, // Display the script output
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
