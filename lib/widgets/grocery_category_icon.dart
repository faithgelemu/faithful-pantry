
import 'package:flutter/material.dart';

class GroceryCategoryIcon extends StatelessWidget {
  const GroceryCategoryIcon({
    super.key,
    required this.category,
  });

  final String category;

  IconData get icon {
    final value = category.toLowerCase();

    if (value.contains('dairy') || value.contains('egg')) {
      return Icons.egg_alt_outlined;
    }
    if (value.contains('fruit') || value.contains('veg')) {
      return Icons.eco_outlined;
    }
    if (value.contains('meat') || value.contains('fish')) {
      return Icons.set_meal_outlined;
    }
    if (value.contains('bread') || value.contains('bakery')) {
      return Icons.bakery_dining_outlined;
    }
    if (value.contains('frozen')) {
      return Icons.ac_unit;
    }
    if (value.contains('cupboard')) {
      return Icons.kitchen_outlined;
    }
    if (value.contains('drink')) {
      return Icons.local_drink_outlined;
    }

    return Icons.shopping_basket_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: category,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 28,
          color: colorScheme.primary,
          semanticLabel: category,
        ),
      ),
    );
  }
}
