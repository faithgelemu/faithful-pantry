import 'package:flutter/material.dart';

import 'models/pantry_item.dart';
import 'services/pantry_service.dart';
import 'utils/day_refresh_mixin.dart';
import 'utils/expiry_utils.dart';
import 'widgets/weekly_spending_summary.dart';

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
  Stream<List<PantryItem>>? pantryStream;

  @override
  void initState() {
    super.initState();
    loadPantry();
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
            const Text(
              'Your pantry at a glance',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'See what needs attention and keep track of spending.',
            ),
            const SizedBox(height: 24),
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