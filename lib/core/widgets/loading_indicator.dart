import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? message;
  final bool showMessage;

  const LoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.message,
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget loader = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? theme.primaryColor,
        strokeWidth: 2.0,
      ),
    );

    if (showMessage && message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loader;
  }
}

class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({super.key, this.message, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: LoadingIndicator(
              message: message ?? 'Loading...',
              showMessage: true,
              size: 32.0,
            ),
          ),
        ),
      ),
    );
  }
}
