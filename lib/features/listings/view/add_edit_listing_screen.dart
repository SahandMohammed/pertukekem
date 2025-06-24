import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:pertukekem/features/listings/model/listing_model.dart';
import 'package:pertukekem/features/listings/viewmodel/manage_listings_viewmodel.dart';

class AddEditListingScreen extends StatefulWidget {
  final Listing? listing;

  const AddEditListingScreen({super.key, this.listing});

  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TabController _tabController;
  final int _totalSteps = 4;
  int _currentStep = 0;

  // Book type selection
  String _selectedBookType = 'physical'; // 'physical' or 'ebook'
  File? _ebookFile;
  bool _isEbookUploading = false;

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _isbnController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoriesController;
  late TextEditingController _publisherController;
  late TextEditingController _pageCountController;

  // Dropdown values
  String _selectedCondition = 'new';
  String? _selectedLanguage;
  String? _selectedFormat;
  DateTime? _selectedYear;

  // Options
  final List<String> _conditionOptions = ['new', 'used'];
  final List<String> _languageOptions = ['English', 'Kurdish', 'Arabic'];
  final List<String> _formatOptions = [
    'Hardcover',
    'Paperback',
    'eBook',
    'Digital',
    'Audio Book',
  ];

  // Image handling
  File? _imageFile;
  String? _networkImageUrl;
  bool _isImageUploading = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize form controllers
    _titleController = TextEditingController(text: widget.listing?.title);
    _authorController = TextEditingController(text: widget.listing?.author);
    _isbnController = TextEditingController(text: widget.listing?.isbn);
    _priceController = TextEditingController(
      text: widget.listing?.price.toString(),
    );
    _networkImageUrl = widget.listing?.coverUrl;
    _descriptionController = TextEditingController(
      text: widget.listing?.description,
    );
    _categoriesController = TextEditingController(
      text: widget.listing?.category.join(', '),
    );
    _publisherController = TextEditingController(
      text: widget.listing?.publisher,
    );
    _pageCountController = TextEditingController(
      text: widget.listing?.pageCount?.toString(),
    ); // Initialize dropdown values
    _selectedCondition = widget.listing?.condition ?? 'new';
    _selectedLanguage = widget.listing?.language;
    _selectedFormat = widget.listing?.format;
    _selectedBookType = widget.listing?.bookType ?? 'physical';
    _selectedYear =
        widget.listing?.year != null ? DateTime(widget.listing!.year!) : null;

    // Initialize tab controller for multi-step form
    _tabController = TabController(length: _totalSteps, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentStep = _tabController.index;
      });
    });

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoriesController.dispose();
    _publisherController.dispose();
    _pageCountController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _networkImageUrl = null;
        });

        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: ${e.toString()}');
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('User not authenticated for image upload');
      return null;
    }

    setState(() {
      _isImageUploading = true;
    });

    try {
      if (!await imageFile.exists()) {
        _showErrorSnackBar('Selected image file not found');
        return null;
      }

      String fileName =
          'listings_covers/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child(fileName);

      firebase_storage.SettableMetadata metadata =
          firebase_storage.SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': currentUser.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          );

      firebase_storage.UploadTask uploadTask = ref.putFile(imageFile, metadata);

      uploadTask.snapshotEvents.listen((
        firebase_storage.TaskSnapshot snapshot,
      ) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      firebase_storage.TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      print('Upload successful. Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      String errorMessage = 'Error uploading image: ${e.toString()}';
      print(errorMessage);
      _showErrorSnackBar(errorMessage);
      return null;
    } finally {
      setState(() {
        _isImageUploading = false;
      });
    }
  }

  Future<void> _pickEbookFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'mobi', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        // Check file size (limit to 50MB)
        int fileSizeInBytes = await file.length();
        double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 50) {
          _showErrorSnackBar(
            'File size too large. Please select a file smaller than 50MB.',
          );
          return;
        }

        setState(() {
          _ebookFile = file;
        });

        _showSuccessSnackBar(
          'eBook file selected successfully! (${fileSizeInMB.toStringAsFixed(2)} MB)',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting eBook file: ${e.toString()}');
    }
  }

  Future<String?> _uploadEbookFile(File ebookFile) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('User not authenticated for file upload');
      return null;
    }

    setState(() {
      _isEbookUploading = true;
    });

    try {
      if (!await ebookFile.exists()) {
        _showErrorSnackBar('Selected eBook file not found');
        return null;
      }

      // Get file extension to determine content type
      String fileName = ebookFile.path.split('/').last;
      String extension = fileName.split('.').last.toLowerCase();

      String contentType;
      switch (extension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'epub':
          contentType = 'application/epub+zip';
          break;
        case 'mobi':
          contentType = 'application/x-mobipocket-ebook';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      String storagePath =
          'ebooks/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child(storagePath);

      firebase_storage.SettableMetadata metadata =
          firebase_storage.SettableMetadata(
            contentType: contentType,
            customMetadata: {
              'uploadedBy': currentUser.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
              'fileType': 'ebook',
              'originalFileName': fileName,
            },
          );

      firebase_storage.UploadTask uploadTask = ref.putFile(ebookFile, metadata);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((
        firebase_storage.TaskSnapshot snapshot,
      ) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('eBook Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      firebase_storage.TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      print('eBook upload successful. Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      String errorMessage = 'Error uploading eBook: ${e.toString()}';
      print(errorMessage);
      _showErrorSnackBar(errorMessage);
      return null;
    } finally {
      setState(() {
        _isEbookUploading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Additional validation for eBook files
      if (_selectedBookType == 'ebook' &&
          _ebookFile == null &&
          (widget.listing?.ebookUrl == null ||
              widget.listing!.ebookUrl!.isEmpty)) {
        _showErrorSnackBar('Please select an eBook file for eBook listings');
        return;
      }

      setState(() => _isLoading = true);

      final viewModel = Provider.of<ManageListingsViewModel>(
        context,
        listen: false,
      );
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        try {
          String? imageUrl = _networkImageUrl;
          String? ebookFileUrl = widget.listing?.ebookUrl;

          if (_imageFile != null) {
            imageUrl = await _uploadImage(_imageFile!);
            if (imageUrl == null) {
              throw Exception('Failed to upload image');
            }
          }

          // Upload eBook file if this is an eBook listing and a new file is selected
          if (_selectedBookType == 'ebook' && _ebookFile != null) {
            ebookFileUrl = await _uploadEbookFile(_ebookFile!);
            if (ebookFileUrl == null) {
              throw Exception('Failed to upload eBook file');
            }
          }

          final price = double.tryParse(_priceController.text) ?? 0;
          final categories =
              _categoriesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
          final pageCount =
              _pageCountController.text.isNotEmpty
                  ? int.tryParse(_pageCountController.text)
                  : null;

          // Determine seller type and reference
          final storeDoc =
              await FirebaseFirestore.instance
                  .collection('stores')
                  .doc(currentUser.uid)
                  .get();

          // Use the appropriate collection based on seller type
          final String sellerType = storeDoc.exists ? 'store' : 'user';
          final DocumentReference sellerRef = FirebaseFirestore.instance
              .collection(sellerType == 'store' ? 'stores' : 'users')
              .doc(currentUser.uid); // Create the listing object
          final listing = Listing(
            id: widget.listing?.id,
            sellerRef: sellerRef,
            sellerType: sellerType,
            title: _titleController.text,
            author: _authorController.text,
            isbn: _isbnController.text,
            condition: _selectedCondition,
            price: price,
            category: categories,
            coverUrl: imageUrl!,
            description:
                _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : null,
            publisher:
                _publisherController.text.isNotEmpty
                    ? _publisherController.text
                    : null,
            language: _selectedLanguage,
            pageCount: pageCount,
            year: _selectedYear?.year,
            format: _selectedFormat,
            bookType: _selectedBookType,
            ebookUrl: ebookFileUrl,
            // Keep existing createdAt for updates, let service handle timestamps
            createdAt: widget.listing?.createdAt,
            updatedAt: widget.listing?.updatedAt,
          );
          if (widget.listing != null) {
            await viewModel.updateListing(listing);
            if (mounted) {
              _showSuccessSnackBar('Listing updated successfully!');
              // Return success result to trigger refresh
              Navigator.of(context).pop('updated');
            }
          } else {
            await viewModel.addListing(listing);
            if (mounted) {
              _showSuccessSnackBar('Listing added successfully!');
              // Return success result to trigger refresh
              Navigator.of(context).pop('added');
            }
          }
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar('Error: ${e.toString()}');
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    } else {
      _showErrorSnackBar('Please fill in all required fields correctly');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
          duration: const Duration(
            seconds: 4,
          ), // Longer duration for multiple errors
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  void _nextStep() {
    // Get all validation errors for current step
    final errors = _getValidationErrors(_currentStep);

    if (errors.isNotEmpty) {
      // Show all errors in a single snackbar
      final errorMessage =
          errors.length == 1
              ? errors.first
              : errors.map((e) => '• $e').join('\n');

      _showErrorSnackBar(errorMessage);
      return;
    }

    // If validation passes, proceed to next step
    if (_currentStep < _totalSteps - 1) {
      _tabController.animateTo(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _tabController.animateTo(_currentStep - 1);
    }
  }

  // Validation methods for each step
  bool _isStepValid(int stepIndex) {
    switch (stepIndex) {
      case 0:
        // Book type step - always valid since we have default selection
        return true;
      case 1:
        // Book cover step
        bool hasImage =
            _imageFile != null ||
            (_networkImageUrl != null && _networkImageUrl!.isNotEmpty);
        bool hasEbookFile =
            _selectedBookType != 'ebook' ||
            _ebookFile != null ||
            (widget.listing?.ebookUrl != null &&
                widget.listing!.ebookUrl!.isNotEmpty);
        return hasImage && hasEbookFile;
      case 2:
        // Book details step
        return _titleController.text.trim().isNotEmpty &&
            _authorController.text.trim().isNotEmpty &&
            _isbnController.text.trim().isNotEmpty &&
            _selectedLanguage != null &&
            _selectedLanguage!.isNotEmpty &&
            _selectedFormat != null &&
            _selectedFormat!.isNotEmpty &&
            (_pageCountController.text.trim().isEmpty ||
                (int.tryParse(_pageCountController.text.trim()) != null &&
                    int.parse(_pageCountController.text.trim()) > 0));
      case 3:
        // Pricing & category step
        bool hasValidPrice =
            _priceController.text.trim().isNotEmpty &&
            double.tryParse(_priceController.text.trim()) != null &&
            double.parse(_priceController.text.trim()) > 0;
        bool hasValidCategories =
            _categoriesController.text.trim().isNotEmpty &&
            _categoriesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .isNotEmpty;
        return hasValidPrice && hasValidCategories;
      default:
        return false;
    }
  }

  // Get all validation errors for a specific step
  List<String> _getValidationErrors(int stepIndex) {
    List<String> errors = [];

    switch (stepIndex) {
      case 1:
        // Book cover step
        if (_imageFile == null &&
            (_networkImageUrl == null || _networkImageUrl!.isEmpty)) {
          errors.add('Please add a book cover image');
        }
        if (_selectedBookType == 'ebook' &&
            _ebookFile == null &&
            (widget.listing?.ebookUrl == null ||
                widget.listing!.ebookUrl!.isNotEmpty)) {
          errors.add('Please select an eBook file for eBook listings');
        }
        break;
      case 2:
        // Book details step
        if (_titleController.text.trim().isEmpty) {
          errors.add('Book title is required');
        }
        if (_authorController.text.trim().isEmpty) {
          errors.add('Author name is required');
        }
        if (_isbnController.text.trim().isEmpty) {
          errors.add('ISBN number is required');
        }
        if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
          errors.add('Language selection is required');
        }
        if (_selectedFormat == null || _selectedFormat!.isEmpty) {
          errors.add('Format selection is required');
        }
        if (_pageCountController.text.trim().isNotEmpty) {
          final pageCount = int.tryParse(_pageCountController.text.trim());
          if (pageCount == null || pageCount <= 0) {
            errors.add('Page count must be a valid number greater than 0');
          }
        }
        break;
      case 3:
        // Pricing & Category step
        if (_priceController.text.trim().isEmpty) {
          errors.add('Price is required');
        } else {
          final price = double.tryParse(_priceController.text.trim());
          if (price == null || price <= 0) {
            errors.add('Price must be a valid number greater than 0');
          }
        }

        if (_categoriesController.text.trim().isEmpty) {
          errors.add('At least one category is required');
        } else {
          final categories =
              _categoriesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
          if (categories.isEmpty) {
            errors.add('Please enter at least one valid category');
          }
        }
        break;
    }

    return errors;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.listing != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Listing' : 'Add New Listing',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Listing',
              onPressed: () => _showDeleteConfirmationDialog(),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Stack(
                  children: [
                    // Progress line background
                    Positioned(
                      top: 15, // Half the height of the circle (32/2 - 1)
                      left: 16, // Start from first circle center
                      right: 16, // End at last circle center
                      child: Container(height: 2, color: Colors.grey.shade300),
                    ),
                    // Active progress line
                    if (_currentStep > 0)
                      Positioned(
                        top: 15,
                        left: 16,
                        width:
                            (MediaQuery.of(context).size.width - 80) *
                            (_currentStep /
                                (_totalSteps -
                                    1)), // 80 = 24*2 padding + 16*2 for circle centers
                        child: Container(
                          height: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    // Step nodes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List<Widget>.generate(_totalSteps, (index) {
                        bool isActive = index == _currentStep;
                        bool isPast = index < _currentStep;
                        bool isValid = _isStepValid(index);

                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isActive
                                    ? theme.colorScheme.primary
                                    : isPast && isValid
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade200,
                            border: Border.all(
                              color:
                                  isActive
                                      ? theme.colorScheme.primary
                                      : isPast && isValid
                                      ? theme.colorScheme.primary
                                      : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child:
                                isPast && isValid
                                    ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                    : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color:
                                            isActive
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Step title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      _getStepTitle(_currentStep),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Step ${_currentStep + 1}/$_totalSteps',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBookTypeStep(),
                    _buildBookCoverStep(),
                    _buildBookDetailsStep(),
                    _buildPricingAndCategoryStep(),
                  ],
                ),
              ),

              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        if (_currentStep < _totalSteps - 1) {
                          _nextStep();
                        } else {
                          _submitForm();
                        }
                      },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        _currentStep == _totalSteps - 1 ? 'Submit' : 'Next',
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Listing?'),
            content: const Text(
              'Are you sure you want to delete this listing? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  setState(() => _isLoading = true);
                  try {
                    if (widget.listing?.id != null) {
                      final viewModel = Provider.of<ManageListingsViewModel>(
                        context,
                        listen: false,
                      );
                      await viewModel.deleteListing(widget.listing!.id!);
                      _showSuccessSnackBar('Listing deleted successfully!');
                      Navigator.of(context).pop('deleted');
                    }
                  } catch (e) {
                    _showErrorSnackBar(
                      'Error deleting listing: ${e.toString()}',
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Book Type';
      case 1:
        return 'Book Cover';
      case 2:
        return 'Book Details';
      case 3:
        return 'Pricing & Category';
      default:
        return '';
    }
  }

  Widget _buildBookTypeStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Book Type',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select whether you are adding a physical book or an eBook.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // Physical Book Option
            GestureDetector(
              onTap: () => setState(() => _selectedBookType = 'physical'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      _selectedBookType == 'physical'
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _selectedBookType == 'physical'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _selectedBookType == 'physical'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.menu_book,
                        color:
                            _selectedBookType == 'physical'
                                ? Colors.white
                                : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Physical Book',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedBookType == 'physical'
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A traditional printed book that will be shipped to the buyer',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _selectedBookType == 'physical'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          _selectedBookType == 'physical'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // eBook Option
            GestureDetector(
              onTap: () => setState(() => _selectedBookType = 'ebook'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      _selectedBookType == 'ebook'
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _selectedBookType == 'ebook'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _selectedBookType == 'ebook'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.book_online,
                        color:
                            _selectedBookType == 'ebook'
                                ? Colors.white
                                : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'eBook',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedBookType == 'ebook'
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A digital book file (PDF, EPUB, etc.) for instant download',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _selectedBookType == 'ebook'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          _selectedBookType == 'ebook'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Information container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedBookType == 'physical') ...[
                    _buildInfoItem(
                      'Physical books require shipping arrangements',
                    ),
                    _buildInfoItem(
                      'Book condition should be accurately described',
                    ),
                    _buildInfoItem('Include clear photos of the actual book'),
                  ] else ...[
                    _buildInfoItem(
                      'eBooks are delivered instantly after purchase',
                    ),
                    _buildInfoItem('Accepted formats: PDF, EPUB, MOBI'),
                    _buildInfoItem('File size limit: 50MB maximum'),
                    _buildInfoItem(
                      'Ensure you have rights to sell the digital content',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue.shade700)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCoverStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedBookType == 'ebook' ? 'Book Cover & File' : 'Book Cover',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedBookType == 'ebook'
                  ? 'Upload a cover image and the eBook file for your listing.'
                  : 'Upload a high-quality image of your book cover to attract potential buyers.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // Book Cover Section
            Text(
              'Book Cover Image',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: () => _showImageSourceDialog(),
                child: Container(
                  width: 220,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child:
                      _isImageUploading
                          ? const Center(child: CircularProgressIndicator())
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildCoverImageWidget(),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImageSourceButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 16),
                _buildImageSourceButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ), // eBook File Upload Section (only for eBooks)
            if (_selectedBookType == 'ebook') ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              Text(
                'eBook File',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickEbookFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        _ebookFile != null ||
                                (widget.listing?.ebookUrl != null &&
                                    widget.listing!.ebookUrl!.isNotEmpty)
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _ebookFile != null ||
                                  (widget.listing?.ebookUrl != null &&
                                      widget.listing!.ebookUrl!.isNotEmpty)
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child:
                      _isEbookUploading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                            children: [
                              Icon(
                                _ebookFile != null ||
                                        (widget.listing?.ebookUrl != null &&
                                            widget
                                                .listing!
                                                .ebookUrl!
                                                .isNotEmpty)
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                size: 48,
                                color:
                                    _ebookFile != null ||
                                            (widget.listing?.ebookUrl != null &&
                                                widget
                                                    .listing!
                                                    .ebookUrl!
                                                    .isNotEmpty)
                                        ? Colors.green.shade600
                                        : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _ebookFile != null
                                    ? 'New eBook file selected: ${_ebookFile!.path.split('/').last}'
                                    : (widget.listing?.ebookUrl != null &&
                                        widget.listing!.ebookUrl!.isNotEmpty)
                                    ? 'eBook file already uploaded (tap to replace)'
                                    : 'Tap to select eBook file',
                                style: TextStyle(
                                  color:
                                      _ebookFile != null ||
                                              (widget.listing?.ebookUrl !=
                                                      null &&
                                                  widget
                                                      .listing!
                                                      .ebookUrl!
                                                      .isNotEmpty)
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_ebookFile != null) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed:
                                      () => setState(() => _ebookFile = null),
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Remove'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'eBook File Requirements',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildEbookGuidelineItem(
                      'Accepted formats: PDF, EPUB, MOBI',
                    ),
                    _buildEbookGuidelineItem('Maximum file size: 50MB'),
                    _buildEbookGuidelineItem(
                      'Ensure you have rights to sell this content',
                    ),
                    _buildEbookGuidelineItem(
                      'File will be securely stored and delivered',
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Image Guidelines',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildImageGuidelineItem(
                    'Use a well-lit, clear image of the book cover',
                  ),
                  _buildImageGuidelineItem(
                    'Ensure the book title and author are visible',
                  ),
                  _buildImageGuidelineItem(
                    _selectedBookType == 'ebook'
                        ? 'For eBooks, use the official cover image'
                        : 'Show the actual condition of the book',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEbookGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.orange.shade700)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue.shade700)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageWidget() {
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (_networkImageUrl != null && _networkImageUrl!.isNotEmpty) {
      return Image.network(
        _networkImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(),
      );
    } else {
      return _buildPlaceholderCover();
    }
  }

  Widget _buildPlaceholderCover() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tap to add cover',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showImageSourceDialog(),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Image Source',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageSourceOption(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      _buildImageSourceOption(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = true,
    String? helperText,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        helperText: helperText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator:
          validator ??
          (isRequired
              ? (value) =>
                  value == null || value.isEmpty
                      ? 'This field is required'
                      : null
              : null),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      icon: const Icon(Icons.arrow_drop_down),
      isExpanded: true,
    );
  }

  // Book Details step
  Widget _buildBookDetailsStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book Details',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide accurate information about your book.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            _buildInputField(
              controller: _titleController,
              label: 'Book Title',
              hint: 'Enter the full title of the book',
              icon: Icons.title,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter a title'
                          : null,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _authorController,
              label: 'Author',
              hint: "Enter the author's name",
              icon: Icons.person_outline,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter an author'
                          : null,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _publisherController,
              label: 'Publisher (Optional)',
              hint: "Enter the publisher's name",
              icon: Icons.business,
              isRequired: false,
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Language',
              icon: Icons.language,
              value: _selectedLanguage ?? _languageOptions[0],
              items:
                  _languageOptions
                      .map(
                        (language) => DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        ),
                      )
                      .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedLanguage = newValue);
                }
              },
            ),
            const SizedBox(height: 16),

            // Year input using date picker
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final DateTime? picked = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Select Publication Year'),
                      content: SizedBox(
                        width: 300,
                        height: 300,
                        child: YearPicker(
                          firstDate: DateTime(1900),
                          lastDate: now,
                          selectedDate: _selectedYear ?? now,
                          onChanged: (DateTime dateTime) {
                            setState(() => _selectedYear = dateTime);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                );

                if (picked != null) {
                  setState(() => _selectedYear = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Publication Year',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                child: Text(
                  _selectedYear != null
                      ? _selectedYear!.year.toString()
                      : 'Select Year',
                  style:
                      _selectedYear == null
                          ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          )
                          : Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Format',
              icon: Icons.format_size,
              value: _selectedFormat ?? _formatOptions[0],
              items:
                  _formatOptions
                      .map(
                        (format) => DropdownMenuItem<String>(
                          value: format,
                          child: Text(format),
                        ),
                      )
                      .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedFormat = newValue);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _isbnController,
              label: 'ISBN',
              hint: 'Enter the ISBN number',
              icon: Icons.qr_code,
              keyboardType: TextInputType.number,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter an ISBN'
                          : null,
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Condition',
              icon: Icons.auto_awesome,
              value: _selectedCondition,
              items:
                  _conditionOptions
                      .map(
                        (condition) => DropdownMenuItem<String>(
                          value: condition,
                          child: Text(
                            condition[0].toUpperCase() + condition.substring(1),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedCondition = newValue);
                }
              },
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _pageCountController,
              label: 'Page Count',
              hint: 'Enter the number of pages',
              icon: Icons.description_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final pageCount = int.tryParse(value);
                  if (pageCount == null) {
                    return 'Please enter a valid number';
                  }
                  if (pageCount <= 0) {
                    return 'Page count must be greater than 0';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint:
                  'Describe the book, its condition, and any other relevant details',
              icon: Icons.description_outlined,
              maxLines: 5,
              isRequired: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingAndCategoryStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing & Category',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your price and categorize your book.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _priceController,
              label: 'Price',
              hint: 'Enter the selling price',
              icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: r'$ ',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _categoriesController,
              label: 'Categories',
              hint: 'e.g. Fiction, Novel, Drama (comma-separated)',
              icon: Icons.category,
              helperText: 'Enter one or more categories separated by commas',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter at least one category';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Popular Categories',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                        'Fiction',
                        'Non-Fiction',
                        'Science',
                        'History',
                        'Biography',
                        'Self-Help',
                        'Literature',
                        'Reference',
                        'Textbook',
                      ]
                      .map<Widget>((category) => _buildCategoryChip(category))
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return ActionChip(
      label: Text(category),
      backgroundColor: Colors.grey.shade200,
      onPressed: () {
        final currentText = _categoriesController.text;
        final currentCategories =
            currentText.isEmpty
                ? <String>[]
                : currentText.split(',').map((e) => e.trim()).toList();

        if (currentCategories.contains(category)) {
          // Remove category if already selected
          currentCategories.remove(category);
        } else {
          // Add category if not selected
          currentCategories.add(category);
        }

        _categoriesController.text = currentCategories.join(', ');
      },
    );
  }
}
