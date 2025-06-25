# Condition Filter Implementation

## Overview

Extended the search functionality to include book condition filtering (New/Used), allowing users to refine their search results based on the book's condition.

## Features Added

### 1. Condition Filter Interface

- Added a dedicated condition filter row below the category filter
- Three filter options: **All**, **New**, **Used**
- Compact design using smaller filter chips
- Uses secondary color scheme to distinguish from category filters
- Persistent across searches and category selections

### 2. Enhanced Search Logic

- **Backend Support**: Modified `CustomerHomeService.searchListings()` to accept a `condition` parameter
- **Firestore Integration**: Filters results based on the `condition` field in book documents
- **Case-Insensitive**: Supports case-insensitive condition matching
- **Combined Filtering**: Works alongside text search and category filters

### 3. User Experience Improvements

- **Persistent State**: Condition filter persists when switching between searches and categories
- **Smart Interactions**: Condition filter applies immediately to current search results
- **Visual Feedback**: Selected condition is clearly highlighted
- **Contextual Messages**: Empty state messages adapt to show selected condition

## Technical Implementation

### Backend Changes

#### CustomerHomeService (`customer_home_service.dart`)

```dart
Future<List<Listing>> searchListings(String query, {int limit = 20, String? condition}) async {
  // ... existing code ...

  // Get condition field
  final bookCondition = (data['condition'] as String? ?? '').toLowerCase();

  // Check condition filter if specified
  final bool conditionMatches = condition == null ||
      bookCondition == condition.toLowerCase();

  if (queryMatches && conditionMatches) {
    // Add to results
  }
}
```

#### CustomerHomeViewModel (`customer_home_viewmodel.dart`)

```dart
Future<void> searchListings(String query, {String? condition}) async {
  // ... existing code ...
  _searchResults = await _homeService.searchListings(_searchQuery, condition: condition);
}
```

### Frontend Changes

#### Search Tab (`search_tab.dart`)

1. **Added State Variables**:

   - `String? _selectedCondition` - Tracks selected condition filter

2. **Added UI Components**:

   - `_buildConditionFilter()` - Renders the condition filter row
   - `_buildConditionChip()` - Individual condition filter chips
   - `_onConditionSelected()` - Handles condition selection

3. **Updated Search Logic**:
   - Pass condition parameter to all search calls
   - Maintain condition state across different search types
   - Update empty state messages to reflect condition filter

## Data Structure Support

The implementation leverages the existing Firestore document structure:

```json
{
  "condition": "new", // or "used"
  "title": "Brain on Fire",
  "author": "Susannah Cahalan",
  "category": ["Science", "Non-Fiction", "Biography"]
  // other fields
}
```

## Usage Examples

### Filter by Condition Only

1. Select "New" → Shows all new books
2. Select "Used" → Shows all used books
3. Select "All" → Shows all books regardless of condition

### Combined Filtering

1. Type "Science" + Select "New" → Shows only new Science books
2. Select "Fiction" category + Select "Used" → Shows only used Fiction books
3. Search "Brain" + Select "New" → Shows new books matching "Brain"

### Persistent Filtering

1. Select "New" condition
2. Search for different terms → Condition filter remains active
3. Browse different categories → Condition filter remains active
4. Clear search → Condition filter remains for category browsing

## Benefits

- **Refined Search**: Users can find exactly what they're looking for (new vs used books)
- **Better UX**: Visual filters are more intuitive than complex search syntax
- **Persistent State**: Condition preference is maintained across interactions
- **Flexible Filtering**: Works with all existing search methods
- **Performance**: Leverages existing efficient search implementation
- **Clear Visual Design**: Secondary color scheme distinguishes condition from category filters

## UI Design

- **Compact Layout**: Condition filters use smaller, more compact chips
- **Secondary Styling**: Uses `secondaryContainer` and `secondary` colors
- **Clear Hierarchy**: Positioned below categories but above search results
- **Responsive**: Works on different screen sizes
- **Accessible**: Maintains keyboard navigation and screen reader support

## Future Enhancements

- Add condition-specific sorting (newest first for new books, price for used)
- Include condition in search suggestions
- Add condition statistics (e.g., "120 new books found")
- Support for additional conditions (like "refurbished", "damaged", etc.)
- Condition-based pricing displays and comparisons
