import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_project/clock/provider/clock_provider.dart';
import 'package:test_project/router/app_router.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ClockProvider()),
    ],
    child: MainApp(savedThemeMode: savedThemeMode),
  ));
}

class MainApp extends StatelessWidget {
  MainApp({super.key, this.savedThemeMode});
  final AdaptiveThemeMode? savedThemeMode;

  final _appRouter = AppRouter();
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: ThemeData.light(
          useMaterial3: true,
        ),
        dark: ThemeData.dark(useMaterial3: true),
        initial: savedThemeMode ?? AdaptiveThemeMode.dark,
        builder: (theme, darkTheme) => MaterialApp.router(
              title: 'Adaptive Theme Demo',
              theme: theme,
              darkTheme: darkTheme,
              routerConfig: _appRouter.config(),
            ));
  }
}
