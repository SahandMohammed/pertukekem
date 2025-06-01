import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/library_viewmodel.dart';
import '../models/library_model.dart';
import 'book_details_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load library data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<LibraryViewModel>();
      viewModel.refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryViewModel>(
      builder:
          (context, libraryViewModel, child) => Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: const Text(
                'My Library',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue.shade600,
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: Colors.blue.shade600,
                      tabs: const [
                        Tab(text: 'All Books'),
                        Tab(text: 'E-Books'),
                        Tab(text: 'Physical'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: Consumer<LibraryViewModel>(
              builder: (context, viewModel, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllBooksTab(viewModel),
                    _buildEbooksTab(viewModel),
                    _buildPhysicalBooksTab(viewModel),
                  ],
                );
              },
            ),
          ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search your library...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (query) {
            context.read<LibraryViewModel>().setSearchQuery(query);
          },
        ),
      ),
    );
  }

  Widget _buildAllBooksTab(LibraryViewModel viewModel) {
    if (viewModel.isLoadingLibrary) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return _buildErrorState(viewModel.errorMessage!, viewModel);
    }

    if (viewModel.allBooks.isEmpty) {
      return _buildEmptyLibraryState();
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.allBooks.length,
        itemBuilder: (context, index) {
          final book = viewModel.allBooks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBookCard(book, showProgress: book.isEbook),
          );
        },
      ),
    );
  }

  Widget _buildEbooksTab(LibraryViewModel viewModel) {
    if (viewModel.isLoadingLibrary) {
      return const Center(child: CircularProgressIndicator());
    }

    final ebooks = viewModel.ebooks;
    if (ebooks.isEmpty) {
      return _buildEmptyEbooksState();
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ebooks.length,
        itemBuilder: (context, index) {
          final book = ebooks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBookCard(book, showProgress: true),
          );
        },
      ),
    );
  }

  Widget _buildPhysicalBooksTab(LibraryViewModel viewModel) {
    if (viewModel.isLoadingLibrary) {
      return const Center(child: CircularProgressIndicator());
    }

    final physicalBooks = viewModel.physicalBooks;
    if (physicalBooks.isEmpty) {
      return _buildEmptyPhysicalBooksState();
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: physicalBooks.length,
        itemBuilder: (context, index) {
          final book = physicalBooks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBookCard(book),
          );
        },
      ),
    );
  }

  Widget _buildBookCard(LibraryBook book, {bool showProgress = false}) {
    return GestureDetector(
      onTap: () {
        _showBookDetails(book);
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book Cover
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 100,
                  height: 140, // Fixed height for consistent card size
                  child:
                      book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 140,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildBookPlaceholder();
                            },
                          )
                          : _buildBookPlaceholder(),
                ),
              ),
              // Book Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showProgress && book.totalPages != null) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: book.readingProgress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(book.readingProgress * 100).toInt()}% Complete',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  book.isEbook
                                      ? Icons.tablet_mac
                                      : Icons.menu_book,
                                  size: 12,
                                  color:
                                      book.isEbook
                                          ? Colors.blue
                                          : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  book.isEbook ? 'E-Book' : 'Physical',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        book.isEbook
                                            ? Colors.blue
                                            : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookPlaceholder() {
    return Container(
      width: 100,
      height: 140,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.book, size: 40, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildEmptyLibraryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Your Library is Empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your personal library by purchasing books from our store.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to store
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.store),
              label: const Text('Browse Books'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEbooksState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tablet_mac, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No E-Books Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Purchase e-books to start your digital library.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhysicalBooksState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Physical Books Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Purchase physical books to add them to your collection.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, LibraryViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => viewModel.refreshAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookDetails(LibraryBook book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
    );
  }
}
