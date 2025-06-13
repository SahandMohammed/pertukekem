import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/features/cart/model/cart_item_model.dart';
import 'lib/features/listings/model/listing_model.dart';

void main() {
  testCartItemListingId();
}

void testCartItemListingId() {
  print('🧪 Testing Cart Item Listing ID Fix');

  // Create a sample listing with correct ID
  final listing = Listing(
    id: 'BOOK-001', // This is our custom sequential ID
    sellerRef: FirebaseFirestore.instance
        .collection('stores')
        .doc('test-seller'),
    sellerType: 'store',
    title: 'Test Book',
    author: 'Test Author',
    condition: 'new',
    price: 29.99,
    category: ['Fiction'],
    isbn: '1234567890',
    coverUrl: 'https://example.com/cover.jpg',
    bookType: 'physical',
  );

  print('✅ Created listing with ID: ${listing.id}');

  // Create a cart item
  final cartItem = CartItem(
    id: 'cart-item-123', // This is the cart item's auto-generated ID
    userId: 'test-user',
    listing: listing,
    quantity: 1,
    addedAt: Timestamp.now(),
  );

  print('✅ Created cart item with cart ID: ${cartItem.id}');
  print('✅ Cart item listing ID: ${cartItem.listing.id}');

  // Simulate storing to Firestore (convert to map)
  final cartItemMap = cartItem.toMap();
  print('✅ Converted to map for storage');

  // Simulate loading from Firestore (convert from map)
  final loadedCartItem = CartItem.fromMap(cartItemMap, 'cart-item-123');

  print('✅ Loaded cart item from map');
  print('📋 Original listing ID: ${listing.id}');
  print('📋 Loaded cart item listing ID: ${loadedCartItem.listing.id}');

  // Verify the fix
  if (loadedCartItem.listing.id == 'BOOK-001') {
    print('🎉 SUCCESS: Listing ID is correctly preserved as BOOK-001');
    print(
      '🎯 Order creation will now use correct listingRef: /listings/BOOK-001',
    );
  } else {
    print('❌ FAILURE: Listing ID was not preserved correctly');
    print('❌ Got: ${loadedCartItem.listing.id}');
    print('❌ Expected: BOOK-001');
  }
}
