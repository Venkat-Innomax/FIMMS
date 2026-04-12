import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() {
  runApp(const ProviderScope(child: FimmsApp()));
}

class FimmsApp extends ConsumerWidget {
  const FimmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: FimmsTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
