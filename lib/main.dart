import 'package:fluent_ui/fluent_ui.dart';

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
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Indian Oil',
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
      title: const Text('Track orders'),
      infoBadge: const InfoBadge(source: Text('8')),
      body: const _NavigationBodyItem(
        header: 'Badging',
        content: Text(
          'Badging is a non-intrusive and intuitive way to display '
          'notifications or bring focus to an area within an app - '
          'whether that be for notifications, indicating new content, '
          'or showing an alert. An InfoBadge is a small piece of UI '
          'that can be added into an app and customized to display a '
          'number, icon, or a simple dot.',
        ),
      ),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.disable_updates),
      title: const Text('Disabled Item'),
      body: const _NavigationBodyItem(),
      enabled: false,
    ),
    PaneItemExpander(
      icon: const Icon(FluentIcons.account_management),
      title: const Text('Account'),
      body: const _NavigationBodyItem(
        header: 'PaneItemExpander',
        content: Text(
          'Some apps may have a more complex hierarchical structure '
          'that requires more than just a flat list of navigation '
          'items. You may want to use top-level navigation items to '
          'display categories of pages, with children items displaying '
          'specific pages. It is also useful if you have hub-style '
          'pages that only link to other pages. For these kinds of '
          'cases, you should create a hierarchical NavigationView.',
        ),
      ),
      items: [
        PaneItemHeader(header: const Text('Apps')),
        PaneItem(
          icon: const Icon(FluentIcons.mail),
          title: const Text('Mail'),
          body: const _NavigationBodyItem(),
        ),
        PaneItem(
          icon: const Icon(FluentIcons.calendar),
          title: const Text('Calendar'),
          body: const _NavigationBodyItem(),
        ),
      ],
    ),
    PaneItemWidgetAdapter(
      child: Builder(builder: (context) {
        if (NavigationView.of(context).displayMode == PaneDisplayMode.compact) {
          return const FlutterLogo();
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200.0),
          child: const Row(children: [
            FlutterLogo(),
            SizedBox(width: 6.0),
            Text('This is a custom widget'),
          ]),
        );
      }),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Indian Oil'),
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
      content: content ?? const Center(child: Text('Default content')),
    );
  }
}
