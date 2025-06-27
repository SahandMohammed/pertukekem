import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final List<String> selectedCategories;
  final Function(List<String>) onCategoriesChanged;

  const CategoryChips({
    super.key,
    required this.selectedCategories,
    required this.onCategoriesChanged,
  });

  static const List<String> availableCategories = [
    'Fiction',
    'Non-Fiction',
    'Educational',
    'Children\'s Books',
    'Comics & Manga',
    'Religious',
    'Science & Technology',
    'History',
    'Biography',
    'Self-Help',
    'Cooking',
    'Travel',
    'Art & Design',
    'Business',
    'Health & Fitness',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Categories',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Select categories that best describe your store (max 5)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              availableCategories.map((category) {
                final isSelected = selectedCategories.contains(category);
                final canSelect = selectedCategories.length < 5 || isSelected;

                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected:
                      canSelect
                          ? (selected) {
                            final newCategories = List<String>.from(
                              selectedCategories,
                            );
                            if (selected) {
                              newCategories.add(category);
                            } else {
                              newCategories.remove(category);
                            }
                            onCategoriesChanged(newCategories);
                          }
                          : null,
                  backgroundColor: colorScheme.surface,
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color:
                        isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.5),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
        ),
        if (selectedCategories.length >= 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Maximum of 5 categories reached',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
