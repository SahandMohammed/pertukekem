# Admin Feature Documentation

## Overview

The admin feature provides comprehensive management capabilities for the Pertukekem online bookstore application. It allows designated administrators to monitor and control users, stores, and listings.

## Features

### 1. User Management

- **View all users**: Browse all registered users with pagination
- **Search users**: Search by name or email
- **Block/Unblock users**: Prevent or restore user access to the application
- **User details**: View user profile information, verification status, and role type

### 2. Store Management

- **View all stores**: Browse all registered stores with owner information
- **Search stores**: Search by store name
- **Block/Unblock stores**: Block store owners and automatically deactivate their listings
- **Store statistics**: View store ratings, total listings, and categories

### 3. Listing Management

- **View all listings**: Browse all book listings across the platform
- **Search listings**: Search by book title or author
- **Remove listings**: Mark listings as removed (admin action)
- **Listing details**: View seller information, pricing, and book details

### 4. Dashboard Analytics

- **Total users count**
- **Total stores count**
- **Active listings count**
- **Blocked users count**

## Access Control

- **Role-based access**: Only users with 'admin' role can access admin features
- **Automatic protection**: All admin screens are wrapped with `AdminAccessWidget`
- **Graceful fallback**: Non-admin users see access denied screen

## Architecture

### Models

- `AdminUserModel`: Simplified user model for admin views
- `AdminStoreModel`: Store model with owner information for admin management
- `AdminListingModel`: Listing model with seller details for admin oversight

### Services

- `AdminService`: Handles all Firestore operations for admin features
  - User management operations
  - Store management operations
  - Listing management operations
  - Statistics aggregation

### ViewModels

- `AdminViewModel`: Central state management for all admin operations
  - Implements `StateClearable` for proper cleanup
  - Handles pagination for large datasets
  - Manages search functionality
  - Error handling and loading states

### Views

- `AdminDashboardScreen`: Main admin interface with tabs and statistics
- `AdminUsersScreen`: User management interface
- `AdminStoresScreen`: Store management interface
- `AdminListingsScreen`: Listing management interface

### Widgets

- `AdminAccessWidget`: Role-based access control wrapper
- `AdminStatsCard`: Statistics display component
- `AdminSearchBar`: Reusable search component
- `AdminUserCard`: User information display card
- `AdminStoreCard`: Store information display card
- `AdminListingCard`: Listing information display card
- `AdminFloatingButton`: Quick admin access button for admin users

## Navigation

- Route: `/admin`
- Accessible via `AdminFloatingButton` (only visible to admin users)
- Protected by `AdminAccessWidget`

## User Roles

To make a user an admin, add 'admin' to their roles array in Firestore:

```javascript
// In Firestore users collection
{
  // ... other user fields
  "roles": ["admin"]
}
```

## Security Considerations

- **Frontend protection**: Access control is enforced in the UI
- **Backend protection**: Firestore security rules should be updated to prevent unauthorized admin operations
- **Role validation**: Always verify user roles on both client and server side

## Usage Example

### Adding Admin Access to a Screen

```dart
class SomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YourContent(),
      floatingActionButton: AdminFloatingButton(), // Shows only for admins
    );
  }
}
```

### Navigating to Admin Panel

```dart
// Only works if user has admin role
Navigator.pushNamed(context, '/admin');
```

## Error Handling

- **Network errors**: Graceful handling with user-friendly messages
- **Pagination errors**: Proper loading states and retry mechanisms
- **Search errors**: Clear error display with dismiss option
- **Action errors**: Confirmation dialogs and error feedback

## Performance Considerations

- **Pagination**: Large datasets are loaded in chunks of 20 items
- **Lazy loading**: Data is loaded only when needed
- **Search optimization**: Uses Firestore queries for server-side search
- **State management**: Efficient state updates to minimize rebuilds

## Future Enhancements

- **Bulk operations**: Select multiple items for batch actions
- **Advanced filtering**: Filter by date ranges, roles, status
- **Export functionality**: Export user/store/listing data
- **Audit logging**: Track admin actions for compliance
- **Real-time updates**: Live updates when data changes
- **Advanced analytics**: Charts and graphs for better insights
