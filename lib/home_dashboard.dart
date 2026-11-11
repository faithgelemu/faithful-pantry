import 'package:flutter/material.dart';

import 'models/pantry_item.dart';
import 'services/pantry_service.dart';
import 'utils/day_refresh_mixin.dart';
import 'utils/expiry_utils.dart';
import 'widgets/weekly_spending_summary.dart';
import 'services/settings_service.dart';
import 'widgets/grocery_category_icon.dart';
import 'widgets/grocery_quantity_dialog.dart';

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
  bool isUpdatingGrocery = false;

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
  Future<void> markGrocery(PantryItem item, String action) async {
  if (isUpdatingGrocery) return;

  setState(() {
    isUpdatingGrocery = true;
  });

  try {
    final quantity = await showDialog<int>(
      context: context,
      builder: (_) => GroceryQuantityDialog(
        item: item,
        action: action,
      ),
    );

    if (quantity == null || !mounted) return;

    await service.resolveQuantity(
      itemId: item.id,
      quantity: quantity,
      action: action,
      actionId: service.newActionId(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$quantity of ${item.name} marked as $action.',
        ),
      ),
    );
  } on StateError catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  } on ArgumentError catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.message?.toString() ?? 'Check the quantity.',
        ),
      ),
    );
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to confirm the update. Check the pantry '
          'quantity before trying again.',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isUpdatingGrocery = false;
      });
    }
  }
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
  bool isAlert = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final background = isDark
    ? colorScheme.surfaceContainerHighest
    : isAlert
        ? const Color(0xFFFFF3E7)
        : const Color(0xFFEDF6E8);

final accent = isDark
    ? isAlert
        ? const Color(0xFFFFC18F)
        : colorScheme.primary
    : isAlert
        ? const Color(0xFF88451D)
        : const Color(0xFF176B3A);

  return Card(
    margin: EdgeInsets.zero,
    color: background,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
      color: isDark
      ? colorScheme.outlineVariant
      : isAlert
          ? const Color(0xFFEEDBC9)
          : const Color(0xFFD3E6CC),
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: accent,
              size: 22,
            ),
          ],
        ),
      ),
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
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroceryCategoryIcon(
                category: item.category,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expiryLabel(item, today),
                      style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFFFC18F)
                      : const Color(0xFF88451D),
                      fontWeight: FontWeight.w700,
        ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.currentQuantity} remaining',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: isUpdatingGrocery
                    ? null
                    : () => markGrocery(item, 'used'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Use it'),
              ),
              OutlinedButton.icon(
                onPressed: isUpdatingGrocery
                    ? null
                    : () => markGrocery(item, 'wasted'),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Wasted'),
              ),
            ],
          ),
        ],
      ),
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
              isAlert: true,
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