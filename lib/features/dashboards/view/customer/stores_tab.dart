import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/customer_home_viewmodel.dart';
import '../../widgets/home_widgets.dart';

class StoresTab extends StatefulWidget {
  const StoresTab({super.key});

  @override
  State<StoresTab> createState() => _StoresTabState();
}

class _StoresTabState extends State<StoresTab> {
  @override
  void initState() {
    super.initState();
    // Load all stores when the tab is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<CustomerHomeViewModel>();
      if (viewModel.allStores.isEmpty && !viewModel.isLoadingAllStores) {
        viewModel.loadAllStores();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerHomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('All Stores'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => viewModel.loadAllStores(),
              ),
            ],
          ),
          body:
              viewModel.isLoadingAllStores
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.allStores.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                    onRefresh: () => viewModel.loadAllStores(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: viewModel.allStores.length,
                      itemBuilder: (context, index) {
                        final store = viewModel.allStores[index];
                        return StoreCard(store: store);
                      },
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Stores Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'No bookstores are currently registered',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
