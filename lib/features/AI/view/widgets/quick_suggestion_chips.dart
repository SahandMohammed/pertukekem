import 'package:flutter/material.dart';

class QuickSuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTapped;

  const QuickSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSuggestionTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick suggestions:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.shade50,
                    side: BorderSide(color: Colors.blue.shade200),
                    onPressed: () => onSuggestionTapped(suggestion),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
