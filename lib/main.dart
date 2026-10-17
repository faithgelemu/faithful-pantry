import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'add_grocery_screen.dart';
import 'auth_screen.dart';
import 'budget_screen.dart';
import 'firebase_options.dart';
import 'home_dashboard.dart';
import 'pantry_screen.dart';
import 'profile_screen.dart';

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Unable to check your login. '
                    'Please restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final user = snapshot.data;

          if (user != null) {
            return HomeScreen(key: ValueKey(user.uid));
          }

          return const AuthScreen();
        },
      ),
    );
  }
}

enum HomeDetail {
  pantry,
  alerts,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.testPages,
  });

  final List<Widget>? testPages;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  HomeDetail? homeDetail;

  LocalHistoryEntry? detailHistory;

  static const titles = [
    'Faithful Pantry',
    'Add groceries',
    'Weekly Budget',
    'Profile',
  ];

  void openHomeDetail(HomeDetail detail) {
    if (homeDetail != null) return;

    final route = ModalRoute.of(context);
    if (route == null) return;

    final entry = LocalHistoryEntry(
      onRemove: () {
        detailHistory = null;

        if (!mounted || detailHistory == null && homeDetail == null) {
  return;
}
        setState(() {
          homeDetail = null;
        });
      },
    );

    detailHistory = entry;
    route.addLocalHistoryEntry(entry);

    setState(() {
      homeDetail = detail;
    });
  }

  void closeHomeDetail() {
    detailHistory?.remove();
  }

  void selectTab(int index) {
    // Leaving a detail view returns Home to its dashboard.
    closeHomeDetail();

    setState(() {
      selectedTab = index;
    });
  }

  String get currentTitle {
    if (selectedTab == 0 && homeDetail != null) {
      return homeDetail == HomeDetail.pantry
          ? 'My Pantry'
          : 'Expiry Alerts';
    }

    return titles[selectedTab];
  }

  Widget get currentPage {
    final testPages = widget.testPages;

    if (testPages != null) {
      return testPages[selectedTab];
    }

    switch (selectedTab) {
      case 1:
        return const AddGroceryScreen();
      case 2:
        return const BudgetScreen();
      case 3:
        return const ProfileScreen();
      default:
        switch (homeDetail) {
          case HomeDetail.pantry:
            return const PantryScreen(
              key: ValueKey('inventory'),
              view: PantryView.inventory,
            );
          case HomeDetail.alerts:
            return const PantryScreen(
              key: ValueKey('alerts'),
              view: PantryView.alerts,
            );
          case null:
            return HomeDashboard(
              onOpenPantry: () => openHomeDetail(HomeDetail.pantry),
              onOpenExpiryAlerts: () =>
                  openHomeDetail(HomeDetail.alerts),
            );
        }
    }
  }

    Future<void> logOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      closeHomeDetail();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    detailHistory = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentTitle),
        automaticallyImplyLeading: false,
        leading: homeDetail == null
            ? null
            : BackButton(
                onPressed: closeHomeDetail,
              ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: logOut,
          ),
        ],
      ),
      body: currentPage,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart_outlined),
            selectedIcon: Icon(Icons.add_shopping_cart),
            label: 'Add',
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