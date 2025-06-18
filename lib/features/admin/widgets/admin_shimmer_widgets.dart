import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AdminShimmerWidgets {
  /// Shimmer effect for user/customer cards
  static Widget userCardShimmer() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name placeholder
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        // Email placeholder
                        Container(width: 200, height: 14, color: Colors.white),
                      ],
                    ),
                  ),
                  // Action button placeholder
                  Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status chip placeholder
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Date placeholder
                  Container(width: 100, height: 12, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer effect for store cards
  static Widget storeCardShimmer() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Store logo placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store name placeholder
                        Container(
                          width: double.infinity,
                          height: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        // Owner name placeholder
                        Container(width: 150, height: 14, color: Colors.white),
                        const SizedBox(height: 4),
                        // Owner email placeholder
                        Container(width: 180, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                  // Action button placeholder
                  Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Rating placeholder
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Listings count placeholder
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Spacer(),
                  // Status placeholder
                  Container(
                    width: 70,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer effect for listing cards
  static Widget listingCardShimmer() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Row(
            children: [
              // Book cover placeholder
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    // Author placeholder
                    Container(width: 120, height: 14, color: Colors.white),
                    const SizedBox(height: 8),
                    // Price placeholder
                    Container(width: 80, height: 16, color: Colors.white),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Seller name placeholder
                        Container(width: 100, height: 12, color: Colors.white),
                        const Spacer(),
                        // Status placeholder
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Action button placeholder
              Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Create a list of shimmer items for loading states
  static Widget shimmerList({required Widget shimmerItem, int itemCount = 5}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: itemCount,
      itemBuilder: (context, index) => shimmerItem,
    );
  }

  /// Shimmer effect for statistics cards
  static Widget statsCardShimmer() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      elevation: 0,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12.0),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon placeholder
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              // Value placeholder
              Container(width: 40, height: 20, color: Colors.white),
              // Title placeholder
              Container(width: 60, height: 12, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer effect for statistics section
  static Widget statisticsShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: statsCardShimmer()),
          const SizedBox(width: 8),
          Expanded(child: statsCardShimmer()),
          const SizedBox(width: 8),
          Expanded(child: statsCardShimmer()),
          const SizedBox(width: 8),
          Expanded(child: statsCardShimmer()),
        ],
      ),
    );
  }
}
