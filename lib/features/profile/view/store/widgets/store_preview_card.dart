import 'dart:io';
import 'package:flutter/material.dart';

/// Real-time preview card showing store information as user fills the form
class StorePreviewCard extends StatelessWidget {
  final String storeName;
  final String? description;
  final File? logoFile;
  final File? bannerFile;
  final String? logoUrl;
  final String? bannerUrl;

  const StorePreviewCard({
    super.key,
    required this.storeName,
    this.description,
    this.logoFile,
    this.bannerFile,
    this.logoUrl,
    this.bannerUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 120,
        width: double.infinity,
        child: Stack(
          children: [
            // Banner background
            Positioned.fill(child: _buildBannerBackground(colorScheme)),

            // Content overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Logo avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.surface,
                      child: _buildLogoContent(colorScheme),
                    ),

                    const SizedBox(width: 12),

                    // Store info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            storeName.isEmpty ? 'Your Store Name' : storeName,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description != null && description!.isNotEmpty)
                            Text(
                              description!,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerBackground(ColorScheme colorScheme) {
    if (bannerFile != null) {
      return Image.file(
        bannerFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultBanner(colorScheme);
        },
      );
    }

    if (bannerUrl != null && bannerUrl!.isNotEmpty) {
      return Image.network(
        bannerUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultBanner(colorScheme);
        },
      );
    }

    return _buildDefaultBanner(colorScheme);
  }

  Widget _buildDefaultBanner(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
        ),
      ),
    );
  }

  Widget _buildLogoContent(ColorScheme colorScheme) {
    if (logoFile != null) {
      return ClipOval(
        child: Image.file(
          logoFile!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo(colorScheme);
          },
        ),
      );
    }

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          logoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo(colorScheme);
          },
        ),
      );
    }

    return _buildDefaultLogo(colorScheme);
  }

  Widget _buildDefaultLogo(ColorScheme colorScheme) {
    return Icon(Icons.store, color: colorScheme.primary, size: 24);
  }
}
