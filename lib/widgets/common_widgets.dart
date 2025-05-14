import 'package:flutter/material.dart';

import '../models/models.dart' as models;
import 'app_icons.dart';

/// CircleIconButton - A circular button with an icon
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      color: backgroundColor ?? theme.colorScheme.surface,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              icon,
              size: size * 0.5,
              color: iconColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// CountBadge - A small badge showing a count (for cart items, notifications, etc.)
class CountBadge extends StatelessWidget {
  final int count;
/*************  ✨ Codeium Command ⭐  *************/
/// Submits a new diary event based on the current form input.
///
/// Validates the form fields and constructs a `DiaryEvent` object with the
/// selected event type, title, and time. Depending on the event type, it also
/// includes nutritional data such as calories, protein, carbs, fat, or water
/// intake. The event is then added to the `DiaryProvider` and the dialog is
/// closed.

/******  457f9a7f-68fd-4fce-b83c-23c6a23c67e3  *******/  final Color? backgroundColor;
  final Color? textColor;

  const CountBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: TextStyle(
            color: textColor ?? theme.colorScheme.onPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// SectionTitle - A title with an optional trailing widget
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// SeeAllButton - A button to view all items
class SeeAllButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SeeAllButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 32),
        textStyle: theme.textTheme.bodySmall,
      ),
      child: Row(
        children: [
          const Text('See All'),
          const SizedBox(width: 4),
          Icon(AppIcons.arrowRight, size: 16),
        ],
      ),
    );
  }
}

/// MetricCard - A small card showing a health metric
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LabelChip - A small chip for labels or tags
class LabelChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const LabelChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// OutlinedItemCard - A card with an image placeholder, title, subtitle, and optional badges
class OutlinedItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> badges;
  final VoidCallback onTap;

  const OutlinedItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Image placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          badges.map((tag) => LabelChip(label: tag)).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  // Update type to explicitly mention the model version
  final models.CartItem item;
  final Function(int, int) onUpdateQuantity;
  final Function(int) onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            // Quantity controls
            Row(
              children: [
                CircleIconButton(
                  icon: AppIcons.minus,
                  onPressed: () => onUpdateQuantity(item.id, -1),
                  size: 32,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    item.quantity.toString(),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                CircleIconButton(
                  icon: AppIcons.plus,
                  onPressed: () => onUpdateQuantity(item.id, 1),
                  size: 32,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(AppIcons.delete, color: theme.colorScheme.error),
                  onPressed: () => onRemove(item.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  // Update type to explicitly mention the model version
  final models.MenuItem item;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleFavorite;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.onAddToCart,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          item.isFavorite
                              ? AppIcons.favorite
                              : AppIcons.favoriteBorder,
                          color:
                              item.isFavorite
                                  ? Colors.red
                                  : theme.colorScheme.onSurface,
                          size: 20,
                        ),
                        onPressed: onToggleFavorite,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.calories,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Image and add to cart
            Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onAddToCart,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 32),
                    textStyle: theme.textTheme.bodySmall,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Import these models to make the file self-contained
class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String calories;
  final String? imageUrl;
  final String category;
  final bool isFavorite;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
    this.imageUrl,
    required this.category,
    this.isFavorite = false,
  });

  MenuItem copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? calories,
    String? imageUrl,
    String? category,
    bool? isFavorite,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      calories: calories ?? this.calories,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class CartItem {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final String restaurant;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.restaurant,
  });

  CartItem copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    String? restaurant,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      restaurant: restaurant ?? this.restaurant,
    );
  }

  double get totalPrice => price * quantity;
}
