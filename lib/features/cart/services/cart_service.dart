import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../model/cart_item_model.dart';
import '../../listings/model/listing_model.dart';

class CartService extends ChangeNotifier implements StateClearable {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Cart? _cart;
  bool _isLoading = false;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  int get itemCount => _cart?.totalItems ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> initializeCart() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _loadCart();
    } catch (e) {
      debugPrint('Error initializing cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCart() async {
    if (_currentUserId == null) return;

    try {
      final cartSnapshot =
          await _firestore
              .collection('carts')
              .doc(_currentUserId)
              .collection('items')
              .orderBy('addedAt', descending: true)
              .get();

      final items =
          cartSnapshot.docs
              .map((doc) => CartItem.fromMap(doc.data(), doc.id))
              .toList();

      _cart = Cart(
        userId: _currentUserId!,
        items: items,
        updatedAt: Timestamp.now(),
      );
    } catch (e) {
      debugPrint('Error loading cart: $e');
      _cart = Cart(
        userId: _currentUserId!,
        items: [],
        updatedAt: Timestamp.now(),
      );
    }
  }

  Future<bool> addToCart(Listing listing, {int quantity = 1}) async {
    if (_currentUserId == null) return false;
    if (listing.bookType != 'physical') return false; // Only physical books

    try {
      final existingItemIndex =
          _cart?.items.indexWhere((item) => item.listing.id == listing.id) ??
          -1;

      if (existingItemIndex != -1) {
        await _updateItemQuantity(
          _cart!.items[existingItemIndex].id,
          _cart!.items[existingItemIndex].quantity + quantity,
        );
      } else {
        final cartItem = CartItem(
          id: '', // Will be set by Firestore
          userId: _currentUserId!,
          listing: listing,
          quantity: quantity,
          addedAt: Timestamp.now(),
        );

        final docRef = await _firestore
            .collection('carts')
            .doc(_currentUserId)
            .collection('items')
            .add(cartItem.toMap());

        final newItem = cartItem.copyWith(id: docRef.id);
        final updatedItems = List<CartItem>.from(_cart?.items ?? []);
        updatedItems.add(newItem);

        _cart =
            _cart?.copyWith(items: updatedItems, updatedAt: Timestamp.now()) ??
            Cart(
              userId: _currentUserId!,
              items: [newItem],
              updatedAt: Timestamp.now(),
            );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      return false;
    }
  }

  Future<bool> _updateItemQuantity(String itemId, int quantity) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore
          .collection('carts')
          .doc(_currentUserId)
          .collection('items')
          .doc(itemId)
          .update({'quantity': quantity});

      if (_cart != null) {
        final updatedItems =
            _cart!.items.map((item) {
              if (item.id == itemId) {
                return item.copyWith(quantity: quantity);
              }
              return item;
            }).toList();

        _cart = _cart!.copyWith(
          items: updatedItems,
          updatedAt: Timestamp.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating item quantity: $e');
      return false;
    }
  }

  Future<bool> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      return removeFromCart(itemId);
    }
    return _updateItemQuantity(itemId, quantity);
  }

  Future<bool> removeFromCart(String itemId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore
          .collection('carts')
          .doc(_currentUserId)
          .collection('items')
          .doc(itemId)
          .delete();

      if (_cart != null) {
        final updatedItems =
            _cart!.items.where((item) => item.id != itemId).toList();

        _cart = _cart!.copyWith(
          items: updatedItems,
          updatedAt: Timestamp.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      return false;
    }
  }

  Future<bool> clearCart() async {
    if (_currentUserId == null) return false;

    try {
      final batch = _firestore.batch();
      final cartItems =
          await _firestore
              .collection('carts')
              .doc(_currentUserId)
              .collection('items')
              .get();

      for (final doc in cartItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _cart = Cart(
        userId: _currentUserId!,
        items: [],
        updatedAt: Timestamp.now(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      return false;
    }
  }

  bool isInCart(String listingId) {
    return _cart?.items.any((item) => item.listing.id == listingId) ?? false;
  }

  int getItemQuantity(String listingId) {
    if (_cart == null || _cart!.items.isEmpty) return 0;

    try {
      final item = _cart!.items.firstWhere(
        (item) => item.listing.id == listingId,
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  @override
  void dispose() {
    _cart = null;
    super.dispose();
  }

  @override
  Future<void> clearState() async {
    _cart = null;
    _isLoading = false;

    notifyListeners();

    debugPrint('✅ CartService state cleared');
  }
}
