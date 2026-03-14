import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../widgets/home_navigation_button.dart';
import 'worker_profile_screen.dart';
import 'contractor_profile_screen.dart';
import 'switch_account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openWorkerProfile(String workerId) async {
    final preferences = PreferencesService();
    await preferences.activateWorkerProfile();

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerProfileScreen(workerId: workerId),
      ),
    );
  }

  Future<void> _openContractorProfile(String contractorId) async {
    final preferences = PreferencesService();
    await preferences.activateContractorProfile();

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContractorProfileScreen(contractorId: contractorId),
      ),
    );
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
        actions: const [HomeNavigationButton()],
      ),
      body: SingleChildScrollView(
        child: Column(
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
                      onPressed: () => _openWorkerProfile(workerProfile),
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
                      onPressed: () =>
                          _openContractorProfile(contractorProfile),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('View'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SwitchAccountScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Switch Account / Create New'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
