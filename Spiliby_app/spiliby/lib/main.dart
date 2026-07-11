import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/app_store.dart';
import 'pages/onboarding_page.dart';
import 'theme/app_theme.dart';
import 'widgets/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appStore = AppStore();
  await appStore.init();
  runApp(
    ChangeNotifierProvider.value(
      value: appStore,
      child: const SpilibyApp(),
    ),
  );
}

class SpilibyApp extends StatelessWidget {
  const SpilibyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return MaterialApp(
      title: 'Spiliby',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(store.isDark),
      home: !store.ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (store.profile == null ? const OnboardingPage() : const MainShell()),
    );
  }
}

