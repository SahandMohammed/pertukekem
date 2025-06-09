import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';
import '../../checkout/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize cart when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartService>().initializeCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart'), elevation: 0),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cart = cartService.cart;
          if (cart == null || cart.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(context, item, cartService);
                  },
                ),
              ),
              _buildBottomSummary(context, cart, cartService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some books to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartService cartService,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.listing.coverUrl,
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.book, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Book details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.listing.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${item.listing.author}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Condition: ${item.listing.condition}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(item.listing.price),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          // Quantity controls
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      cartService.updateQuantity(
                                        item.id,
                                        item.quantity - 1,
                                      );
                                    } else {
                                      cartService.removeFromCart(item.id);
                                    }
                                  },
                                  icon: Icon(
                                    item.quantity > 1
                                        ? Icons.remove
                                        : Icons.delete,
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  onPressed: () {
                                    cartService.updateQuantity(
                                      item.id,
                                      item.quantity + 1,
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 20),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary(
    BuildContext context,
    Cart cart,
    CartService cartService,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${cart.totalItems} items)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  currencyFormat.format(cart.totalAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to checkout/payment
                  _proceedToCheckout(context, cart);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToCheckout(BuildContext context, Cart cart) {
    // Navigate to checkout screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutScreen(cart: cart)),
    );
  }
}
