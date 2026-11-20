import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../home/home_screen.dart';
import '../matches/matches_screen.dart';
import '../scanner/scanner_screen.dart';
import '../tickets/tickets_screen.dart';
import '../tracker/suivi_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    MatchesScreen(),
    ScannerScreen(),
    TicketsScreen(),
    SuiviScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.accentSoft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Matchs',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Scanner'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Tickets',
          ),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Suivi'),
        ],
      ),
    );
  }
}
