import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pertukekem/features/listings/model/listing_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference<Listing> _listingsRef;
  static const String ID_PREFIX = 'BOOK-';

  ListingService() {
    _listingsRef = _firestore
        .collection('listings')
        .withConverter<Listing>(
          fromFirestore: Listing.fromFirestore,
          toFirestore: (Listing listing, _) => listing.toFirestore(),
        );
  }

  Future<String> _generateNextListingId() async {
    // Query the latest listing sorted by ID in descending order
    final querySnapshot =
        await _listingsRef
            .orderBy(FieldPath.documentId, descending: true)
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: ID_PREFIX)
            .where(FieldPath.documentId, isLessThan: '${ID_PREFIX}Z')
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) {
      // No existing listings, start with BOOK-001
      return '${ID_PREFIX}001';
    }

    // Extract the number from the latest ID and increment it
    final latestId = querySnapshot.docs.first.id;
    final currentNumber = int.parse(latestId.substring(ID_PREFIX.length));
    final nextNumber = currentNumber + 1;
    return '$ID_PREFIX${nextNumber.toString().padLeft(3, '0')}';
  }

  Stream<List<Listing>> watchAllListings({
    String? condition,
    String? category,
    String? sellerType,
    DocumentReference? sellerRef,
  }) {
    print('Building listings query with:');
    print('- sellerRef: ${sellerRef?.path}');
    print('- sellerType: $sellerType');
    print('- condition: $condition');
    print('- category: $category');

    // Create the base query
    Query<Listing> query = _listingsRef;

    // Add sellerRef filter if provided
    if (sellerRef != null) {
      query = query.where('sellerRef', isEqualTo: sellerRef);
    }

    // Add sellerType filter
    if (sellerType != null) {
      query = query.where('sellerType', isEqualTo: sellerType);
    }

    if (condition != null) {
      query = query.where('condition', isEqualTo: condition);
    }

    if (category != null) {
      query = query.where('category', arrayContains: category);
    }

    // Listen to query results
    return query.snapshots().map((snapshot) {
      final listings = snapshot.docs.map((doc) => doc.data()).toList();
      print('Found ${listings.length} listings matching the query');
      listings.forEach((listing) {
        print(
          '- ${listing.id}: ${listing.title}, ref: ${listing.sellerRef.path}',
        );
      });
      return listings;
    });
  }

  Future<void> addListing(Listing listing) async {
    // Security: Ensure the authenticated user is the seller
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }
    if (listing.sellerRef.path != 'users/${currentUser.uid}' &&
        listing.sellerRef.path != 'stores/${currentUser.uid}') {
      // This check might need adjustment based on how store IDs are managed vs user UIDs.
      // For simplicity, assuming storeId can be the same as a user UID if a user also has a store role.
      // Or, you might have a separate field in your user document indicating their storeId.
      throw Exception('Seller reference does not match authenticated user.');
    }

    // Generate the next sequential ID
    final newId = await _generateNextListingId();

    // Create the document with our custom ID and set timestamps
    final docRef = _listingsRef.doc(newId);
    final now = Timestamp.now();

    // Create listing with timestamps
    final listingWithTimestamps = listing.copyWith(
      id: newId,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(listingWithTimestamps);
  }

  Future<void> updateListing(Listing listing) async {
    if (listing.id == null) {
      throw Exception('Listing ID is required for an update.');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    final docRef = _listingsRef.doc(listing.id);
    final existingListingDoc = await docRef.get();
    if (!existingListingDoc.exists) {
      throw Exception('Listing not found.');
    }

    final existingListingData = existingListingDoc.data();
    if (existingListingData == null) {
      throw Exception('Failed to retrieve existing listing data.');
    }

    if (existingListingData.sellerRef.path != 'users/${currentUser.uid}' &&
        existingListingData.sellerRef.path != 'stores/${currentUser.uid}') {
      throw Exception('User not authorized to update this listing.');
    }

    // Update listing with new timestamp
    final updatedListing = listing.copyWith(updatedAt: Timestamp.now());

    await docRef.update(updatedListing.toFirestore());
  }

  Future<void> deleteListing(String listingId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    final docRef = _listingsRef.doc(listingId);
    final existingListingDoc = await docRef.get();
    if (!existingListingDoc.exists) {
      throw Exception('Listing not found.');
    }
    final existingListingData = existingListingDoc.data();
    if (existingListingData == null) {
      throw Exception('Failed to retrieve existing listing data.');
    }

    if (existingListingData.sellerRef.path != 'users/${currentUser.uid}' &&
        existingListingData.sellerRef.path != 'stores/${currentUser.uid}') {
      throw Exception('User not authorized to delete this listing.');
    }

    await docRef.delete();
  }

  Future<List<Listing>> fetchSellerListings(
    String sellerId,
    String sellerType,
  ) async {
    // Ensure sellerId corresponds to the document ID in either /users/{userId} or /stores/{storeId}
    final sellerDocRef = _firestore
        .collection(sellerType == 'user' ? 'users' : 'stores')
        .doc(sellerId);
    final snapshot =
        await _listingsRef
            .where('sellerRef', isEqualTo: sellerDocRef)
            .where('sellerType', isEqualTo: sellerType)
            .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
