import 'package:flutter/material.dart';

import 'models/pantry_item.dart';
import 'services/pantry_service.dart';
import 'utils/day_refresh_mixin.dart';
import 'utils/expiry_utils.dart';
import 'widgets/weekly_spending_summary.dart';
import 'services/settings_service.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.onOpenPantry,
    required this.onOpenExpiryAlerts,
  });

  final VoidCallback onOpenPantry;
  final VoidCallback onOpenExpiryAlerts;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with DayRefreshMixin<HomeDashboard> {
  final service = PantryService();
  final settingsService = SettingsService();
  Stream<String?>? nameStream;
  Stream<List<PantryItem>>? pantryStream;

  @override
  void initState() {
    super.initState();
    loadPantry();
    try {
  nameStream = settingsService.watchPreferredName();
} on StateError {
  nameStream = null;
}
  }

  void loadPantry() {
    try {
      pantryStream = service.watchPantry();
    } on StateError {
      pantryStream = null;
    }
  }

  void retry() {
    setState(loadPantry);
  }

  String expiryLabel(PantryItem item, DateTime today) {
    final days = ExpiryUtils.daysUntil(
      item.expiryDate,
      today: today,
    );

    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';

    return 'Expires in $days days';
  }
Widget welcomeBanner() {
  final reduceMotion = MediaQuery.of(context).disableAnimations;

  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF123C25),
            Color(0xFF227447),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'A LITTLE LESS WASTE',
                  style: TextStyle(
                    color: Color(0xFFDDF5DF),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF305F43),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    size: 38,
                    color: Color(0xFFE5F6BD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StreamBuilder<String?>(
  stream: nameStream,
  builder: (context, snapshot) {
    final name = snapshot.hasError ? null : snapshot.data;
    final hasName = name != null && name.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasName ? 'Hi $name 👋' : 'Welcome back',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'A little care. Less food waste.',
          style: TextStyle(
            color: Color(0xFFE5F6BD),
            fontSize: 19,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  },
),
          const SizedBox(height: 12),
          const Text(
            'Know what you have, see what needs attention '
            'and make every grocery count.',
            style: TextStyle(
              color: Color(0xFFE3F1E6),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.onOpenPantry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5F6BD),
              foregroundColor: const Color(0xFF123C25),
            ),
            icon: const Icon(Icons.kitchen_outlined),
            label: const Text('Explore my pantry'),
          ),
        ],
      ),
    ),
  );
}
  Widget navigationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget expiryPreview() {
    if (pantryStream == null) {
      return const Text('Please log in to view expiry information.');
    }

    return StreamBuilder<List<PantryItem>>(
      stream: pantryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to load expiry information.'),
              TextButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          );
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final today = DateTime.now();
        final activeItems = snapshot.data!
            .where((item) => item.isActive)
            .toList();

        final soon = activeItems.where((item) {
          return ExpiryUtils.statusFor(
                item.expiryDate,
                today: today,
              ) ==
              ExpiryStatus.expiringSoon;
        }).toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

        final expiredCount = activeItems.where((item) {
          return ExpiryUtils.statusFor(
                item.expiryDate,
                today: today,
              ) ==
              ExpiryStatus.expired;
        }).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (expiredCount > 0) ...[
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.event_busy_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    '$expiredCount expired '
                    '${expiredCount == 1 ? 'entry' : 'entries'}',
                  ),
                  subtitle: const Text('Review recorded expiry dates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onOpenExpiryAlerts,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Expiring Soon',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Today and the next '
              '${ExpiryUtils.soonThresholdDays} days',
            ),
            const SizedBox(height: 12),
            if (soon.isEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    activeItems.isEmpty
                        ? 'Your pantry is empty. '
                            'Open Add to record your first grocery.'
                        : 'No groceries are approaching expiry '
                            'within this period.',
                  ),
                ),
              )
            else
              ...soon.take(3).map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${expiryLabel(item, today)}'
                      ' • ${item.currentQuantity} remaining',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: widget.onOpenExpiryAlerts,
                  ),
                );
              }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onOpenExpiryAlerts,
                child: Text(
                  soon.isEmpty
                      ? 'Open expiry alerts'
                      : 'View all expiry alerts',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Date reminders do not determine whether food is safe.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            welcomeBanner(),
const SizedBox(height: 28),
const Text(
  'Your weekly overview',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
  ),
),
const SizedBox(height: 12),
            const WeeklySpendingSummary(),
            const SizedBox(height: 24),
            navigationCard(
              icon: Icons.kitchen_outlined,
              title: 'My Pantry',
              subtitle: 'Find, organise and edit your groceries',
              onTap: widget.onOpenPantry,
            ),
            const SizedBox(height: 12),
            navigationCard(
              icon: Icons.notifications_outlined,
              title: 'Expiry Alerts',
              subtitle: 'Review dates and record use or waste',
              onTap: widget.onOpenExpiryAlerts,
            ),
            const SizedBox(height: 24),
            expiryPreview(),
          ],
        ),
      ),
    );
  }
}