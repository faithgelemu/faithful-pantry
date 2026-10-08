import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final searchController = TextEditingController();

  Stream<QuerySnapshot<Map<String, dynamic>>>? pantryStream;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      pantryStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pantry')
          .snapshots();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  DateTime? readDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  int daysUntil(DateTime date) {
    final today = DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    final expiryUtc = DateTime.utc(date.year, date.month, date.day);

    return expiryUtc.difference(todayUtc).inDays;
  }

  String expiryLabel(DateTime? date) {
    if (date == null) return 'Expiry date unavailable';

    final days = daysUntil(date);

    if (days < 0) return 'Expired ${dateLabel(date)}';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';

    return 'Expires in $days days • ${dateLabel(date)}';
  }

  Color expiryColor(BuildContext context, DateTime? date) {
    if (date == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    final days = daysUntil(date);

    if (days < 0) return Theme.of(context).colorScheme.error;
    if (days <= 3) return Colors.orange.shade800;

    return Colors.green.shade800;
  }

  @override
  Widget build(BuildContext context) {
    if (pantryStream == null) {
      return const Center(
        child: Text('Please log in to view your pantry.'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: pantryStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load your pantry. '
                'Check your connection and access rules.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs
            .where((document) => document.data()['status'] == 'active')
            .toList();

        items.sort((a, b) {
          final first = readDate(a.data()['expiryDate']);
          final second = readDate(b.data()['expiryDate']);

          if (first == null && second == null) return 0;
          if (first == null) return 1;
          if (second == null) return -1;

          return first.compareTo(second);
        });

        final query = searchQuery.trim().toLowerCase();

        final matchingItems = items.where((document) {
          final value = document.data()['name'];
          final name = value is String ? value : 'Unnamed item';

          return name.toLowerCase().contains(query);
        }).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Pantry',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${items.length} grocery entries '
                        '• Soonest expiry first',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Search your pantry',
                          hintText: 'Enter an item name',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Your pantry is empty.\n'
                              'Open the Scan tab to add a grocery.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : matchingItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No groceries match your search.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 12, 24, 24),
                              itemCount: matchingItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final data = matchingItems[index].data();

                                final name = data['name'] is String
                                    ? data['name'] as String
                                    : 'Unnamed item';

                                final quantity = data['quantity'] is num
                                    ? (data['quantity'] as num).toInt()
                                    : 0;

                                final totalPence =
                                    data['totalPricePence'] is num
                                        ? (data['totalPricePence'] as num)
                                            .toInt()
                                        : null;

                                final expiry = readDate(data['expiryDate']);

                                return Card(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Color(0xFF1DB954),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text('Quantity: $quantity'),
                                              if (totalPence != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Purchase total: '
                                                  '£${(totalPence / 100).toStringAsFixed(2)}',
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Text(
                                                expiryLabel(expiry),
                                                style: TextStyle(
                                                  color: expiryColor(
                                                    context,
                                                    expiry,
                                                  ),
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}