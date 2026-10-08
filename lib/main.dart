import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FaithfulPantryApp());
}

class FaithfulPantryApp extends StatelessWidget {
  const FaithfulPantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faithful Pantry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  final List<String> titles = [
    'Faithful Pantry',
    'Scan and Add',
    'Weekly Budget',
    'Profile',
  ];

  final List<Widget> pages = const [
    PantryPage(
      icon: Icons.kitchen_outlined,
      heading: 'Welcome to Faithful Pantry',
      description:
          'Your pantry and expiring groceries will appear here.',
    ),
    PantryPage(
      icon: Icons.add_shopping_cart,
      heading: 'Add your groceries',
      description:
          'We will build manual grocery entry here first.',
    ),
    PantryPage(
      icon: Icons.account_balance_wallet_outlined,
      heading: 'Understand your spending',
      description:
          'Your weekly spending and budget will appear here.',
    ),
    PantryPage(
      icon: Icons.person_outline,
      heading: 'Your profile',
      description:
          'Your account and settings will appear here.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedTab]),
      ),
      body: pages[selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (int index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class PantryPage extends StatelessWidget {
  const PantryPage({
    super.key,
    required this.icon,
    required this.heading,
    required this.description,
  });

  final IconData icon;
  final String heading;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: const Color(0xFF1DB954),
            ),
            const SizedBox(height: 20),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}