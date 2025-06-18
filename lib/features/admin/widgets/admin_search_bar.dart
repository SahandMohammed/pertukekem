import 'package:flutter/material.dart';

class AdminSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const AdminSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            widget.controller.text.isNotEmpty
                ? IconButton(
                  onPressed: () {
                    widget.controller.clear();
                    widget.onClear();
                    setState(() {}); // Trigger rebuild to hide clear button
                  },
                  icon: const Icon(Icons.clear),
                )
                : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: (value) {
        widget.onSearch(value);
        setState(() {}); // Trigger rebuild to show/hide clear button
      },
    );
  }
}
