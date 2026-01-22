import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/home_page.dart';
import 'services/event_service.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  await EventService.instance.init();
  runApp(
    ChangeNotifierProvider<EventService>.value(
      value: EventService.instance,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.dark,
      home: CustomTopNavigation(),
    );
  }
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    brightness: Brightness.light,
  );
  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepPurple.shade700,
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    scaffoldBackgroundColor: Colors.black,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
    ),
  );
}
