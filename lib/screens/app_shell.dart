import 'package:flutter/material.dart';
import 'membres_screen.dart';
import 'cotisations_screen.dart';
import 'finances_screen.dart';
import 'menu_screen.dart';
import 'dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    MembresScreen(),
    CotisationsScreen(),
    FinancesScreen(),
    MenuScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Accueil'),
    BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Membres'),
    BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Cotisations'),
    BottomNavigationBarItem(icon: Icon(Icons.account_balance_rounded), label: 'Finances'),
    BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'Menu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFEF4444),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        elevation: 16,
        items: _navItems,
      ),
    );
  }
}
