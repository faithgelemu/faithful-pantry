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
import 'services/push_notification_service.dart';
import 'widgets/push_registration_refresh.dart';

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
        useMaterial3: true,
        fontFamily: 'NunitoSans',
        scaffoldBackgroundColor: const Color(0xFFF8FAF5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF176B3A),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDDF5DF),
          onPrimaryContainer: const Color(0xFF123C25),
          surface: Colors.white,
          onSurface: const Color(0xFF20382B),
          onSurfaceVariant: const Color(0xFF536458),
          surfaceContainerHighest: const Color(0xFFEDF5E9),
          outline: const Color(0xFF738574),
          outlineVariant: const Color(0xFFDCE7D8),
        ),
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'NunitoSans',
              bodyColor: const Color(0xFF20382B),
              displayColor: const Color(0xFF123C25),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAF5),
          foregroundColor: Color(0xFF123C25),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF123C25),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFFDCE7D8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF738574),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF176B3A),
              width: 2,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 50),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 14,
            ),
            textStyle: const TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            textStyle: const TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Color(0xFFDDF5DF),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20382B),
            ),
          ),
        ),
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
          return PushRegistrationRefresh(
          key: ValueKey(user.uid),
          userId: user.uid,
          child: HomeScreen(key: ValueKey(user.uid)),
          );
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
    this.dashboardBuilder,
    this.detailBuilder,
  });

  final List<Widget>? testPages;

  final Widget Function(
    VoidCallback onOpenPantry,
    VoidCallback onOpenAlerts,
  )? dashboardBuilder;

  final Widget Function(HomeDetail detail)? detailBuilder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  HomeDetail? homeDetail;
  LocalHistoryEntry? detailHistory;

  bool isLoggingOut = false;

  static const titles = [
    'Faithful Pantry',
    'Add groceries',
    'Weekly Budget',
    'Profile',
  ];

  void openHomeDetail(HomeDetail detail) {
    if (homeDetail != null || isLoggingOut) return;

    final route = ModalRoute.of(context);
    if (route == null) return;

    final entry = LocalHistoryEntry(
      onRemove: () {
        detailHistory = null;

        if (!mounted || homeDetail == null) return;

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
    if (isLoggingOut) return;

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
    // Use the real Home navigation with optional test content.
    if (selectedTab == 0) {
      final detail = homeDetail;

      if (detail != null) {
        final builder = widget.detailBuilder;

        if (builder != null) {
          return builder(detail);
        }

        return PantryScreen(
          key: ValueKey(detail),
          view: detail == HomeDetail.pantry
              ? PantryView.inventory
              : PantryView.alerts,
        );
      }

      final dashboardBuilder = widget.dashboardBuilder;

      if (dashboardBuilder != null) {
        return dashboardBuilder(
          () => openHomeDetail(HomeDetail.pantry),
          () => openHomeDetail(HomeDetail.alerts),
        );
      }

      final testPages = widget.testPages;

      if (testPages != null) {
        return testPages[0];
      }

      return HomeDashboard(
        onOpenPantry: () => openHomeDetail(HomeDetail.pantry),
        onOpenExpiryAlerts: () => openHomeDetail(HomeDetail.alerts),
      );
    }

    final testPages = widget.testPages;

    if (testPages != null) {
      return testPages[selectedTab];
    }

    switch (selectedTab) {
      case 1:
        return const AddGroceryScreen();
      case 2:
        return const BudgetScreen();
      default:
        return const ProfileScreen();
    }
  }

  Future<void> logOut() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    var notificationCleanupFinished = false;

    try {
      await PushNotificationService().prepareForLogout();
      notificationCleanupFinished = true;

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      closeHomeDetail();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notificationCleanupFinished
                ? 'Unable to log out. Please try again.'
                : 'Unable to finish notification cleanup. '
                    'You are still signed in. '
                    'Check your connection and try logging out again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
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
                onPressed: isLoggingOut ? null : closeHomeDetail,
              ),
        actions: [
          if (isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout),
              onPressed: logOut,
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: isLoggingOut,
        child: currentPage,
      ),
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