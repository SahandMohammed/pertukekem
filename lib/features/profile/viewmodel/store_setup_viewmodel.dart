import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../dashboards/model/store_model.dart';
import '../view/store/store_setup_service.dart';

class StoreSetupViewmodel extends ChangeNotifier implements StateClearable {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreSetupService _storeService = StoreSetupService();

  bool _isLoading = false;
  StoreModel? _store;
  String? _error;
  int _currentStep = 0; // Form data
  String _storeName = '';
  String _description = '';
  List<String> _categories = [];
  Map<String, dynamic> _storeAddress = {};
  List<Map<String, String>> _contactInfo = [];
  File? _logoFile;
  File? _bannerFile;
  late Map<String, dynamic> _businessHours;
  Map<String, String> _socialMedia = {};

  StoreSetupViewmodel() {
    _businessHours = _getDefaultBusinessHours();
  }

  static Map<String, dynamic> _getDefaultBusinessHours() {
    const daysOfWeek = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final Map<String, dynamic> defaultHours = {};
    for (final day in daysOfWeek) {
      defaultHours[day] = {
        'isOpen': true,
        'openTime': '09:00',
        'closeTime': '18:00',
      };
    }
    return defaultHours;
  }

  bool get isLoading => _isLoading;
  StoreModel? get store => _store;
  String? get error => _error;
  int get currentStep => _currentStep;
  String get storeName => _storeName;
  String get description => _description;
  List<String> get categories => _categories;
  Map<String, dynamic> get storeAddress => _storeAddress;
  List<Map<String, String>> get contactInfo => _contactInfo;
  File? get logoFile => _logoFile;
  File? get bannerFile => _bannerFile;
  Map<String, dynamic> get businessHours => _businessHours;
  Map<String, String> get socialMedia => _socialMedia;
  void _safeNotifyListeners() {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      notifyListeners();
    }
  }

  void setCurrentStep(int step) {
    if (_currentStep != step) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void setStoreName(String name) {
    if (_storeName != name) {
      _storeName = name;
      _safeNotifyListeners();
    }
  }

  void setDescription(String desc) {
    if (_description != desc) {
      _description = desc;
      _safeNotifyListeners();
    }
  }

  void setCategories(List<String> cats) {
    _categories = cats;
    _safeNotifyListeners();
  }

  void setStoreAddress(Map<String, dynamic> address) {
    _storeAddress = address;
    _safeNotifyListeners();
  }

  void setContactInfo(List<Map<String, String>> contacts) {
    _contactInfo = contacts;
    _safeNotifyListeners();
  }

  void setBusinessHours(Map<String, dynamic> hours) {
    debugPrint('🕐 setBusinessHours called with: $hours');
    _businessHours = hours;
    _safeNotifyListeners();
  }

  void setSocialMedia(Map<String, String> social) {
    _socialMedia = social;
    _safeNotifyListeners();
  }

  void setLogoFile(File? file) {
    _logoFile = file;
    _safeNotifyListeners();
  }

  void setBannerFile(File? file) {
    _bannerFile = file;
    _safeNotifyListeners();
  }

  Future<void> selectLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        _logoFile = File(pickedFile.path);
        _safeNotifyListeners();
      }
    } catch (e) {
      _error = 'Failed to select logo: $e';
      _safeNotifyListeners();
    }
  }

  Future<void> selectBanner() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        _bannerFile = File(pickedFile.path);
        _safeNotifyListeners();
      }
    } catch (e) {
      _error = 'Failed to select banner: $e';
      _safeNotifyListeners();
    }
  }

  bool isStepValid(int step) {
    switch (step) {
      case 0: // Basics - Step 1
        return _storeName.isNotEmpty && _storeName.length >= 3;
      case 1: // Images - Step 2 (optional)
        return true; // Images are optional
      case 2: // Address - Step 3 (optional but should have some info)
        return true; // Address is optional
      case 3: // Business Hours & Social Media - Step 4 (optional)
        return true; // Optional fields
      default:
        return false;
    }
  }

  bool get canCreateStore {
    return isStepValid(0); // Only step 1 (basics) is required
  }

  Future<bool> checkStoreNameAvailability(String name) async {
    if (name.isEmpty || name.length < 3) return false;

    try {
      return await _storeService.isStoreNameAvailable(name);
    } catch (e) {
      debugPrint('Error checking store name availability: $e');
      return false;
    }
  } // Create a new store in Firestore

  Future<void> createStore({
    required String storeName,
    String? description,
    Map<String, dynamic>? storeAddress,
    List<Map<String, String>>? contactInfo,
    String? logoUrl,
    List<String>? categories,
    BuildContext? context,
  }) async {
    if (_auth.currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _auth.currentUser!.uid;
      final storeRef = _firestore.collection('stores').doc(userId);

      final now = DateTime.now();

      final newStore = StoreModel(
        storeId: userId, // Use the user's auth UID as the store ID
        ownerId: userId,
        storeName: storeName,
        description: description,
        storeAddress: storeAddress,
        contactInfo: contactInfo ?? [],
        createdAt: now,
        updatedAt: now,
        logoUrl: logoUrl,
        categories: categories ?? [],
      );

      await storeRef.set(newStore.toMap());

      await _firestore.collection('users').doc(userId).update({
        'storeId': userId, // Store ID is now the same as user ID
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context != null) {
        final authViewModel = Provider.of<AuthViewModel>(
          context,
          listen: false,
        );
        await authViewModel.refreshUserData();
      }

      _store = newStore;
    } catch (e) {
      _error = 'Failed to create store: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createStoreFromForm({BuildContext? context}) async {
    if (_auth.currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    if (!canCreateStore) {
      _error = 'Please complete all required fields';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _auth.currentUser!.uid;
      String? logoUrl;
      String? bannerUrl; // Upload images if selected
      if (_logoFile != null) {
        logoUrl = await _storeService.uploadImage(
          imageFile: _logoFile!,
          path: 'stores/$userId/profilePicture',
        );
      }

      if (_bannerFile != null) {
        bannerUrl = await _storeService.uploadImage(
          imageFile: _bannerFile!,
          path: 'stores/$userId/banner',
        );
      }
      final now = DateTime.now();

      debugPrint('🏪 Creating store with data:');
      debugPrint('  storeName: $_storeName');
      debugPrint('  businessHours: $_businessHours');
      debugPrint('  businessHours.isEmpty: ${_businessHours.isEmpty}');
      debugPrint('  socialMedia: $_socialMedia');
      debugPrint('  socialMedia.isEmpty: ${_socialMedia.isEmpty}');

      final newStore = StoreModel(
        storeId: userId,
        ownerId: userId,
        storeName: _storeName,
        description: _description.isEmpty ? null : _description,
        storeAddress: _storeAddress,
        contactInfo: _contactInfo,
        createdAt: now,
        updatedAt: now,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        categories: _categories,
        businessHours: _businessHours, // Always save business hours
        socialMedia:
            _socialMedia.isEmpty
                ? null
                : Map<String, dynamic>.from(_socialMedia),
      );

      await _storeService.createStoreWithUserUpdate(
        storeData: newStore.toMap(),
        userId: userId,
      );

      if (context != null) {
        final authViewModel = Provider.of<AuthViewModel>(
          context,
          listen: false,
        );
        await authViewModel.refreshUserData();
      }

      _store = newStore;
    } catch (e) {
      _error = 'Failed to create store: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStoreById(String storeId) async {
    if (storeId.isEmpty) {
      _error = 'Store ID is empty';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final storeDoc = await _firestore.collection('stores').doc(storeId).get();

      if (storeDoc.exists) {
        _store = StoreModel.fromMap(storeDoc.data()!);
      } else {
        _error = 'Store not found';
      }
    } catch (e) {
      _error = 'Failed to fetch store: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentUserStore() async {
    if (_auth.currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userDoc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();

      if (!userDoc.exists) {
        _error = 'User document not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userData = userDoc.data();
      final storeId = userData?['storeId'];

      if (storeId == null) {
        _error = 'User does not have a store';
        _isLoading = false;
        notifyListeners();
        return;
      }

      await fetchStoreById(storeId);
    } catch (e) {
      _error = 'Failed to fetch user\'s store: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStore(StoreModel updatedStore) async {
    if (_auth.currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final storeToUpdate = updatedStore.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('stores')
          .doc(updatedStore.storeId)
          .update(storeToUpdate.toMap());
      _store = storeToUpdate;
    } catch (e) {
      _error = 'Failed to update store: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing StoreSetupViewmodel state...');

    _store = null;
    _error = null;
    _isLoading = false;
    _currentStep = 0; // Clear form data
    _storeName = '';
    _description = '';
    _categories = [];
    _storeAddress = {};
    _contactInfo = [];
    _logoFile = null;
    _bannerFile = null;
    _businessHours = _getDefaultBusinessHours();
    _socialMedia = {};

    notifyListeners();

    debugPrint('✅ StoreSetupViewmodel state cleared');
  }
}
