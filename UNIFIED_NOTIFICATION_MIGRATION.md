# Unified Notification System Migration Guide

## Overview

The notification system has been unified to use a single "notifications" collection for both customer and store notifications, replacing the previous separate "customer_notifications" and "notifications" collections.

## Key Changes

### 1. New Unified Model (`UnifiedNotification`)

- **Single Collection**: All notifications now go to the "notifications" collection
- **Target Field**: Added `target` field to distinguish between `customer` and `store` notifications
- **Unified Types**: Combined all notification types into a single enum
- **Backward Compatible**: Supports all existing notification types

### 2. Document Structure Example

Based on your existing notification document:

```json
{
  "createdAt": "June 16, 2025 at 2:09:52 AM UTC+3",
  "isRead": true,
  "message": "Order #QBK0NSC6 from Customer ($26.00)",
  "metadata": {
    "customerName": "Customer",
    "orderId": "qbK0nsC6TSWf7KZH6v6o",
    "orderNumber": "QBK0NSC6",
    "totalAmount": 26
  },
  "storeId": "nOZ4ox0QLYM12RUluMkNrbnLJIn1",
  "title": "New Order Received!",
  "type": "newOrder",
  "target": "store" // NEW FIELD
}
```

For customer notifications, the structure would be:

```json
{
  "createdAt": "June 16, 2025 at 2:09:52 AM UTC+3",
  "isRead": false,
  "message": "Your order #QBK0NSC6 has been confirmed. Total: $26.00",
  "metadata": {
    "orderId": "qbK0nsC6TSWf7KZH6v6o",
    "orderNumber": "QBK0NSC6",
    "totalAmount": 26,
    "storeName": "Store Name"
  },
  "customerId": "customer_user_id",
  "title": "Order Confirmed!",
  "type": "orderConfirmed",
  "target": "customer", // NEW FIELD
  "actionUrl": "/orders/qbK0nsC6TSWf7KZH6v6o"
}
```

## Migration Steps

### 1. Add Target Field to Existing Documents

For existing store notifications:

```javascript
// Firestore Console or Admin SDK
db.collection("notifications")
  .get()
  .then((snapshot) => {
    const batch = db.batch();
    snapshot.forEach((doc) => {
      batch.update(doc.ref, { target: "store" });
    });
    return batch.commit();
  });
```

### 2. Migrate Customer Notifications (if any exist)

If you have existing customer_notifications:

```javascript
// Copy customer notifications to main notifications collection
db.collection("customer_notifications")
  .get()
  .then((snapshot) => {
    const batch = db.batch();
    snapshot.forEach((doc) => {
      const data = doc.data();
      const newRef = db.collection("notifications").doc();
      batch.set(newRef, {
        ...data,
        target: "customer",
      });
    });
    return batch.commit();
  });
```

### 3. Update Security Rules

Update Firestore security rules for the unified collection:

```javascript
// Firestore Security Rules
match /notifications/{notificationId} {
  // Store notifications
  allow read, write: if resource.data.target == 'store' &&
    resource.data.storeId == getUserStoreId(request.auth.uid);

  // Customer notifications
  allow read, write: if resource.data.target == 'customer' &&
    resource.data.customerId == request.auth.uid;
}

function getUserStoreId(userId) {
  return get(/databases/$(database)/documents/users/$(userId)).data.storeId;
}
```

## Service Usage

### Creating Store Notifications

```dart
final notificationService = UnifiedNotificationService();

await notificationService.createNewOrderNotification(
  storeId: storeId,
  orderId: orderId,
  orderNumber: orderNumber,
  totalAmount: totalAmount,
  customerName: customerName,
);
```

### Creating Customer Notifications

```dart
await notificationService.createOrderConfirmationNotification(
  customerId: customerId,
  orderId: orderId,
  orderNumber: orderNumber,
  totalAmount: totalAmount,
  storeName: storeName,
);
```

### Reading Notifications

```dart
// Customer notifications
Stream<List<UnifiedNotification>> customerNotifications =
  notificationService.getCustomerNotificationsStream();

// Store notifications
Stream<List<UnifiedNotification>> storeNotifications =
  notificationService.getStoreNotifications();
```

## Benefits

1. **Single Source of Truth**: All notifications in one collection
2. **Easier Management**: Unified queries and operations
3. **Better Performance**: Reduced collection overhead
4. **Scalable**: Easy to add new notification types
5. **Consistent Structure**: Same fields and patterns for all notifications

## Testing

1. Create test notifications for both customers and stores
2. Verify filtering works correctly with the `target` field
3. Test notification streams and real-time updates
4. Validate security rules prevent cross-access

## Rollback Plan

If needed, the system can be rolled back by:

1. Copying notifications back to separate collections
2. Reverting code changes to use old services
3. Updating security rules back to original structure

The unified system is designed to be backward compatible during the transition period.
