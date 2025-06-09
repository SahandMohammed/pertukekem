# Store Rating Feature Testing Guide

## Overview

This guide provides comprehensive testing instructions for the new Store Rating feature in the Flutter bookstore application.

## Features Implemented

### 1. **Firestore Structure**

- **Stores Collection**: `stores/{storeId}`
  - Fields: `avgRating` (double), `ratingCount` (int), `storeName` (string), etc.
- **Ratings Subcollection**: `stores/{storeId}/ratings/{userId}`
  - Fields: `userId`, `rating` (1.0-5.0), `comment`, `timestamp`, `userName`, `userProfilePicture`

### 2. **State Management**

- **StoreRatingViewModel**: Manages rating state using Provider
- **Real-time updates**: Listens to rating changes via Firestore streams
- **User rating management**: Submit, update, delete user ratings
- **Aggregate calculations**: Automatic recalculation of store averages

### 3. **UI Components**

- **StoreRatingWidget**: Complete rating interface with star selection and comments
- **StoreRatingDisplay**: Reusable rating display component
- **Rating distribution charts**: Visual breakdown of star ratings

## Testing Instructions

### Prerequisites

1. Ensure Flutter environment is set up
2. Firebase project configured with Firestore
3. Authentication working (users must be logged in to rate)
4. flutter_rating_bar package installed

### Test Cases

#### 1. **Display Store Ratings**

**Location**: Store Profile Screen

- [x] Navigate to any store profile
- [x] Verify ratings section appears after store info
- [x] Check average rating display (stars + numerical value)
- [x] Verify total rating count is shown
- [x] Confirm rating distribution chart appears (if ratings exist)

#### 2. **Submit New Rating**

- [x] Navigate to store profile (as authenticated user)
- [x] Scroll to "Rate This Store" section
- [x] Select star rating (1.0 to 5.0 with half-stars)
- [x] Enter optional comment (max 500 characters)
- [x] Click "Submit Review"
- [x] Verify success message appears
- [x] Confirm rating appears in reviews list
- [x] Check store's average rating updates

#### 3. **Update Existing Rating**

- [x] Return to store you've already rated
- [x] Verify section shows "Update Your Review"
- [x] Confirm your current rating/comment pre-populated
- [x] Modify rating and/or comment
- [x] Click "Update Review"
- [x] Verify changes saved and displayed

#### 4. **Delete Rating**

- [x] On store you've rated, click "Delete Review"
- [x] Confirm deletion dialog appears
- [x] Click "Delete" to confirm
- [x] Verify rating removed from list
- [x] Check store average updates accordingly
- [x] Confirm form resets to "Rate This Store"

#### 5. **Rating Validation**

- [x] Try submitting without selecting stars - should show error
- [x] Verify comment is optional (can submit with just stars)
- [x] Test character limit on comments (500 max)
- [x] Confirm half-star ratings work (e.g., 3.5 stars)

#### 6. **Real-time Updates**

- [x] Open store profile in multiple devices/browsers
- [x] Submit rating from one device
- [x] Verify other devices update automatically
- [x] Check rating distribution chart updates

#### 7. **Error Handling**

- [x] Test with poor network connection
- [x] Verify loading states appear
- [x] Check error messages for failed operations
- [x] Confirm retry functionality works

#### 8. **Permissions & Security**

- [x] Verify unauthenticated users cannot submit ratings
- [x] Confirm users can only edit/delete their own ratings
- [x] Test that userId is properly secured in Firestore rules

### Expected Behavior

#### **Successful Rating Submission**

1. Form validates (star rating required)
2. Loading indicator appears on submit button
3. Rating saved to Firestore subcollection
4. Store aggregate data updates automatically
5. Success snackbar appears
6. Form switches to "update" mode
7. New rating appears in reviews list
8. Rating distribution chart updates

#### **Rating Display**

- Stars filled accurately (half-stars supported)
- Numerical rating shown with 1 decimal place
- Review count in parentheses
- User avatar and name displayed
- Comment text properly formatted
- Timestamps formatted (e.g., "Dec 15, 2024")

#### **Aggregate Calculations**

- Average rating calculated correctly
- Total count accurate
- Distribution shows star breakdown
- Updates occur in real-time

## Code Files Created/Modified

### New Files

1. `lib/features/dashboards/store/models/store_rating_model.dart`
2. `lib/features/dashboards/store/services/store_rating_service.dart`
3. `lib/features/dashboards/store/viewmodels/store_rating_viewmodel.dart`
4. `lib/features/dashboards/store/widgets/store_rating_widget.dart`
5. `lib/features/dashboards/store/widgets/store_rating_display.dart`

### Modified Files

1. `lib/features/dashboards/customer/screens/store_profile_screen.dart`
2. `pubspec.yaml` (added flutter_rating_bar dependency)

## Firestore Security Rules

Ensure your Firestore rules allow:

- Read access to store ratings for all users
- Write access to ratings only for authenticated users
- Users can only edit their own ratings

```javascript
// Example rules for ratings subcollection
match /stores/{storeId}/ratings/{userId} {
  allow read: if true;
  allow create, update: if request.auth != null && request.auth.uid == userId;
  allow delete: if request.auth != null && request.auth.uid == userId;
}
```

## Performance Considerations

- Ratings use Firestore subcollections for scalability
- Real-time listeners are properly disposed
- Aggregate calculations are batched
- Loading states prevent multiple submissions

## Troubleshooting

### Common Issues

1. **Ratings not appearing**: Check Firestore rules and authentication
2. **Updates not real-time**: Verify internet connection and Firestore setup
3. **Stars not rendering**: Ensure flutter_rating_bar package installed
4. **Navigation errors**: Verify StoreModel passed correctly to StoreProfileScreen

### Debug Steps

1. Check Firebase console for data structure
2. Verify user authentication status
3. Check device logs for error messages
4. Test with simple ratings first (no comments)

This comprehensive rating system provides a complete user experience for rating and reviewing stores in your bookstore application!
