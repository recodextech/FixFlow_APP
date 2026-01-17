import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/worker_provider.dart';
import '../providers/contractor_provider.dart';
import '../services/preferences_service.dart';
import 'create_worker_screen.dart';
import 'create_contractor_screen.dart';
import 'worker_profile_screen.dart';
import 'contractor_profile_screen.dart';
import 'selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().fetchWorkers();
      context.read<ContractorProvider>().fetchContractors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesService();
    final workerProfile = prefs.getWorkerId();
    final contractorProfile = prefs.getContractorId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FixFlow - Worker & Contractor Manager'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Switch Profile'),
                onTap: () async {
                  await prefs.clearAll();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Info Section
          if (workerProfile != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Worker Profile',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          prefs.getWorkerName() ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkerProfileScreen(workerId: workerProfile),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View'),
                  ),
                ],
              ),
            ),
          if (contractorProfile != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.business, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contractor Profile',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          prefs.getContractorName() ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ContractorProfileScreen(contractorId: contractorProfile),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildWorkersTab(),
                _buildContractorsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Workers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Contractors',
          ),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedIndex == 0
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkerScreen(),
                  ),
                )
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateContractorScreen(),
                  ),
                ),
        tooltip: _selectedIndex == 0 ? 'Add Worker' : 'Add Contractor',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWorkersTab() {
    return Consumer<WorkerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.workers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.workers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchWorkers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.workers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No workers yet'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWorkerScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Worker'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: provider.workers.length,
          itemBuilder: (context, index) {
            final worker = provider.workers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(worker.workerName[0].toUpperCase()),
                ),
                title: Text(worker.workerName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.email),
                    Text(worker.phoneNumber),
                    if (worker.workerCategories.isNotEmpty)
                      Text(
                        'Categories: ${worker.workerCategories.join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContractorsTab() {
    return Consumer<ContractorProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.contractors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.contractors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchContractors(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.contractors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No contractors yet'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateContractorScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Contractor'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: provider.contractors.length,
          itemBuilder: (context, index) {
            final contractor = provider.contractors[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(contractor.contractorName[0].toUpperCase()),
                ),
                title: Text(contractor.contractorName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contractor.email),
                    Text(contractor.phoneNumber),
                    Text(
                      'Type: ${contractor.contractorType}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
