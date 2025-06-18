# Customer Order Status Notification System

## Overview
This implementation adds customer notifications when store owners update order statuses. When a store changes an order status (e.g., from "pending" to "confirmed"), the customer receives a notification in their notification center.

## Implementation Details

### 1. Enhanced Order Service (`order_service.dart`)
- **Added CustomerNotificationService**: Imported and instantiated the customer notification service alongside the existing store notification service.
- **Modified updateOrderStatus method**: Added customer notification creation after successful order status updates.
- **Created _createCustomerNotificationForOrderUpdate method**: Handles different notification types based on order status:
  - `confirmed` → Order Confirmation notification
  - `shipped` → Order Shipped notification  
  - `delivered` → Order Delivered notification
  - `cancelled` → Order Cancellation notification
  - `rejected` → Order Rejection notification
  - Other statuses → Generic system update notification

### 2. Enhanced Customer Notification Service (`customer_notification_service.dart`)
- **Added createOrderCancellationNotification**: Creates specific notifications for cancelled orders
- **Added createOrderRejectionNotification**: Creates specific notifications for rejected orders
- Both methods support optional reason parameters for better user experience

### 3. Notification Flow
1. Store owner updates order status via `store_manage_orders_screen.dart`
2. `StoreOrderViewModel.updateOrderStatus()` calls `OrderService.updateOrderStatus()`
3. Order status is updated in Firestore
4. Store notification is created (existing functionality)
5. **NEW**: Customer notification is created based on the new status
6. Customer sees notification in their dashboard with unread badge
7. Customer can view detailed notifications in `customer_notification_list_screen.dart`

### 4. Notification Types Created
- **Order Confirmed**: When status changes to `confirmed`
- **Order Shipped**: When status changes to `shipped` (includes tracking number if available)
- **Order Delivered**: When status changes to `delivered`
- **Order Cancelled**: When status changes to `cancelled`
- **Order Rejected**: When status changes to `rejected`

### 5. UI Integration
- **Customer Dashboard**: Shows notification badge with unread count
- **Notification List Screen**: Displays all notifications with filtering options
- **Notification Detail Screen**: Shows full notification details
- **Real-time Updates**: Uses Firestore streams for live notification updates

## Database Structure
Notifications are stored in the `customer_notifications` collection with the following structure:
```
customer_notifications/{notificationId}
├── customerId: string (user ID)
├── title: string
├── message: string  
├── type: string (orderConfirmed, orderShipped, etc.)
├── isRead: boolean
├── createdAt: Timestamp
├── metadata: object (orderId, orderNumber, storeName, etc.)
├── imageUrl?: string
└── actionUrl?: string
```

## Error Handling
- Notification creation failures don't prevent order status updates
- All errors are logged for debugging
- Graceful fallbacks for missing store/user data

## Testing
To test the implementation:
1. Create an order as a customer
2. Log in as store owner
3. Update the order status in the store management screen
4. Log back in as the customer
5. Check the notification badge and notification list

The system ensures customers stay informed about their order progress automatically whenever stores update order statuses.
