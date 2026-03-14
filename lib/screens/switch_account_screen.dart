import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contractor_provider.dart';
import '../providers/worker_provider.dart';
import '../services/preferences_service.dart';
import '../widgets/home_navigation_button.dart';
import 'selection_screen.dart';

enum _LoginType { worker, contractor }

class SwitchAccountScreen extends StatefulWidget {
  const SwitchAccountScreen({super.key});

  @override
  State<SwitchAccountScreen> createState() => _SwitchAccountScreenState();
}

class _SwitchAccountScreenState extends State<SwitchAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountIdController = TextEditingController();
  final _profileIdController = TextEditingController();

  _LoginType _loginType = _LoginType.worker;
  bool _isSubmitting = false;

  void _goToSelectionScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SelectionScreen()),
    );
  }

  Future<void> _quickSwitchToWorker() async {
    final preferences = PreferencesService();
    final workerId = preferences.getWorkerId();

    if (workerId == null || workerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved worker profile found')),
      );
      return;
    }

    await preferences.activateWorkerProfile();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  Future<void> _quickSwitchToContractor() async {
    final preferences = PreferencesService();
    final contractorId = preferences.getContractorId();

    if (contractorId == null || contractorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved contractor profile found')),
      );
      return;
    }

    await preferences.activateContractorProfile();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  Future<void> _loginExistingProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final accountId = _accountIdController.text.trim();
    final profileId = _profileIdController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final preferences = PreferencesService();

      if (_loginType == _LoginType.worker) {
        final worker = await context.read<WorkerProvider>().getWorker(
              profileId,
              accountId: accountId,
            );

        if (worker == null) {
          throw Exception('Worker not found for the provided account and ID');
        }

        final workerAccountId = worker.accountId?.isNotEmpty == true
            ? worker.accountId!
            : accountId;

        await preferences.setWorkerId(worker.id);
        await preferences.setWorkerName(worker.workerName);
        await preferences.setWorkerAccountId(workerAccountId);
        await preferences.activateWorkerProfile();
      } else {
        final contractor =
            await context.read<ContractorProvider>().getContractor(
                  profileId,
                  accountId: accountId,
                );

        if (contractor == null) {
          throw Exception(
              'Contractor not found for the provided account and ID');
        }

        final contractorAccountId = contractor.accountId?.isNotEmpty == true
            ? contractor.accountId!
            : accountId;

        await preferences.setContractorId(contractor.id);
        await preferences.setContractorName(contractor.contractorName);
        await preferences.setContractorAccountId(contractorAccountId);
        await preferences.activateContractorProfile();
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged in successfully')),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = PreferencesService();
    final savedWorkerId = preferences.getWorkerId();
    final savedContractorId = preferences.getContractorId();
    final hasSavedWorker = savedWorkerId != null && savedWorkerId.isNotEmpty;
    final hasSavedContractor =
        savedContractorId != null && savedContractorId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Account'),
        actions: [
          const HomeNavigationButton(),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Account',
            onPressed: _goToSelectionScreen,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasSavedWorker || hasSavedContractor) ...[
                          const Text(
                            'Quick Switch',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use last logged-in profile without entering IDs again.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          if (hasSavedWorker)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _quickSwitchToWorker,
                                icon: const Icon(Icons.people),
                                label: Text(
                                  'Switch to Worker: '
                                  '${preferences.getWorkerName() ?? savedWorkerId}',
                                ),
                              ),
                            ),
                          if (hasSavedContractor) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _quickSwitchToContractor,
                                icon: const Icon(Icons.business),
                                label: Text(
                                  'Switch to Contractor: '
                                  '${preferences.getContractorName() ?? savedContractorId}',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'Login Existing Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose profile type and enter Account ID plus profile ID.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<_LoginType>(
                          segments: const [
                            ButtonSegment<_LoginType>(
                              value: _LoginType.worker,
                              label: Text('Worker'),
                              icon: Icon(Icons.people),
                            ),
                            ButtonSegment<_LoginType>(
                              value: _LoginType.contractor,
                              label: Text('Contractor'),
                              icon: Icon(Icons.business),
                            ),
                          ],
                          selected: {_loginType},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _loginType = selection.first;
                              _profileIdController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _accountIdController,
                          decoration: const InputDecoration(
                            labelText: 'Account ID',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter account ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _profileIdController,
                          decoration: InputDecoration(
                            labelText: _loginType == _LoginType.worker
                                ? 'Worker ID'
                                : 'Contractor ID',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _loginType == _LoginType.worker
                                  ? 'Please enter worker ID'
                                  : 'Please enter contractor ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed:
                              _isSubmitting ? null : _loginExistingProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _loginType == _LoginType.worker
                                      ? 'Login as Worker'
                                      : 'Login as Contractor',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _accountIdController.dispose();
    _profileIdController.dispose();
    super.dispose();
  }
}
