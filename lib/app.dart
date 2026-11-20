import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/shell/main_shell.dart';

class BetFolderApp extends StatelessWidget {
  const BetFolderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BET-FOLDER',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}
