import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HasalaApp()));
}

class AppLocale {
  static const supported = [
    Locale('ar'),
    Locale('en'),
  ];
}

class L10n {
  static String appTitle(BuildContext ctx) => 'حصّالة';
}

class RtlWrapper extends StatelessWidget {
  final Widget child;
  const RtlWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: child);
  }
}