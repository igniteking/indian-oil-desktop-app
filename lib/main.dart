import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart';
import 'package:indian_oil_ai/predictions.dart';
import 'package:indian_oil_ai/modelTrain.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Track the current theme mode
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Indian Oil AI',
      themeMode: _themeMode, // Set the current theme mode
      theme: FluentThemeData(
        brightness: Brightness.light,
        // Define your light theme here
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        // Define your dark theme here
      ),
      home: MyHomePage(toggleTheme: _toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const MyHomePage({super.key, required this.toggleTheme});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int topIndex = 0;
  PaneDisplayMode displayMode = PaneDisplayMode.open;

  // Define the items outside the build method to persist across rebuilds
  List<NavigationPaneItem> items = [
    PaneItem(
      icon: const Icon(FluentIcons.home),
      title: const Text('Home'),
      body: const _NavigationBodyItem(),
    ),
    PaneItemSeparator(),
    PaneItem(
      icon: const Icon(FluentIcons.issue_tracking),
      title: const Text('Train Model'),
      body: const ModelTrain(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.disable_updates),
      title: const Text('Predictions'),
      body: const Predictions(),
    ),
    PaneItemWidgetAdapter(
      child: Builder(builder: (context) {
        return Image.asset(
          "assets/logo.png",
          width: 500,
          height: 500,
        );
      }),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Indian Oil AI'),
        leading: null,
        automaticallyImplyLeading: false,
        actions: Padding(
          padding: const EdgeInsets.all(15.0),
          child: ToggleSwitch(
            checked: FluentTheme.of(context).brightness == Brightness.dark,
            onChanged: (bool value) {
              widget.toggleTheme(); // Use the toggleTheme function from MyApp
            },
            content: const Text('Dark Mode'),
          ),
        ),
      ),
      pane: NavigationPane(
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: displayMode,
        items: items,
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: const _NavigationBodyItem(),
          ),
        ],
      ),
    );
  }
}

class _NavigationBodyItem extends StatelessWidget {
  final String? header;
  final Widget? content;

  const _NavigationBodyItem({this.header, this.content});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: header != null ? Text(header!) : null,
      content: SingleChildScrollView(
        child: content ??
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/logo.png",
                        width: 200,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color:
                          FluentTheme.of(context).brightness == Brightness.light
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to the Data Analytics applications!',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'This tool offers various functionalities to help you detect anomalies, train models, predict corrosion, and perform forecasting. Here\'s an overview of the features:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureSection('Train a New Model',
                            'Train a machine learning model on your dataset. This feature allows you to upload your data, select model parameters, and train a new model from scratch.'),
                        _buildFeatureSection('Anomaly Classification',
                            'Use the trained model to classify and detect anomalies in your data. This feature helps in identifying outliers and irregularities.'),
                        _buildFeatureSection('Corrosion Prediction',
                            'Predict corrosion based on historical data and various parameters. This helps in preventative maintenance and ensuring safety.'),
                        _buildFeatureSection('Forecasting',
                            'Perform time series forecasting to predict future values based on historical data. This feature is useful for trend analysis and planning.'),
                        const SizedBox(height: 20),
                        const Text(
                          'Use the sidebar to navigate to each of these functionalities and start utilizing the tool to its full potential.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildFeatureSection(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
