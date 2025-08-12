import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/goals/presentation/goals_screen.dart';
import 'main.dart';

class HasalaApp extends StatelessWidget {
  const HasalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حصّالة',
      theme: theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocale.supported,
      locale: const Locale('ar'),
      builder: (context, child) => RtlWrapper(child: child ?? const SizedBox.shrink()),
      home: const GoalsScreen(),
    );
  }
}