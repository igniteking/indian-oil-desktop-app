import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';

class Testing extends StatefulWidget {
  const Testing({super.key});

  @override
  State<Testing> createState() => _TestingState();
}

class _TestingState extends State<Testing> {
  String _scriptOutput = "";
  Future<void> _runPythonScript(String scriptName) async {
    try {
      final result = await runExecutableArguments(
        'python',
        ['./lib/helpers/hello.py'], // Make sure the path is correct
      );
      setState(() {
        _scriptOutput = result.stdout; // Update state with script output
      });
      print('Script output: ${result.stdout}');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Center(
          child: ElevatedButton(
            onPressed: () => _runPythonScript('hello.py'),
            child: const Text('Run Python Script'),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _scriptOutput, // Display the script output
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
