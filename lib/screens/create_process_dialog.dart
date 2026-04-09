import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/process.dart';
import '../models/wallet.dart';
import '../models/worker.dart';
import '../services/api_service.dart';
import 'location_picker_screen.dart';

class CreateProcessDialog extends StatefulWidget {
  final String contractorId;
  final String accountId;

  const CreateProcessDialog({
    super.key,
    required this.contractorId,
    required this.accountId,
  });

  @override
  State<CreateProcessDialog> createState() => _CreateProcessDialogState();
}

class _CreateProcessDialogState extends State<CreateProcessDialog> {
  static const LatLng _defaultLocation = LatLng(6.927079, 79.861244);

  final _formKey = GlobalKey<FormState>();
  final _processNameController = TextEditingController();
  final _processDescriptionController = TextEditingController();

  // Job fields
  final _jobDescriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _durationController = TextEditingController();
  final _amountController = TextEditingController();

  late Future<List<Category>> _categoriesFuture;
  late Future<List<Wallet>> _walletsFuture;
  String? _selectedCategory;
  String? _selectedWalletId;
  bool _isSubmitting = false;
  LatLng _selectedLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService().getCategories(accountId: widget.accountId);
    _walletsFuture = ApiService().getWallets(accountId: widget.accountId);
  }

  Future<void> _submitProcess() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final job = Job(
        description: _jobDescriptionController.text.trim(),
        startTime: _startTimeController.text.trim(),
        duration: int.parse(_durationController.text.trim()),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        jobCategories: [_selectedCategory!],
        paymentInformation: PaymentInformation(
          amount: double.parse(_amountController.text.trim()),
          walletId: _selectedWalletId!,
        ),
      );

      final processRequest = ProcessRequest(
        name: _processNameController.text.trim(),
        description: _processDescriptionController.text.trim(),
        jobs: [job],
      );

      await ApiService().createContractorProcess(
        contractorId: widget.contractorId,
        accountId: widget.accountId,
        processRequest: processRequest,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _selectStartTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    _startTimeController.text = '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}T'
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSectionLabel('Process Information'),
                  const SizedBox(height: 12),
                  _buildProcessFields(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Job Information'),
                  const SizedBox(height: 12),
                  _buildJobFields(),
                  const SizedBox(height: 12),
                  _buildSectionLabel('Job Location'),
                  const SizedBox(height: 12),
                  _buildLocationMap(),
                  const SizedBox(height: 12),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Payment Information'),
                  const SizedBox(height: 12),
                  _buildWalletDropdown(),
                  const SizedBox(height: 12),
                  _buildAmountField(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Create Process',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildProcessFields() {
    return Column(
      children: [
        TextFormField(
          controller: _processNameController,
          decoration: const InputDecoration(
            labelText: 'Process Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Please enter process name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _processDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Process Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Please enter description' : null,
        ),
      ],
    );
  }

  Widget _buildJobFields() {
    return Column(
      children: [
        TextFormField(
          controller: _jobDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Job Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Please enter job description' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _startTimeController,
          decoration: InputDecoration(
            labelText: 'Start Time',
            hintText: 'YYYY-MM-DDTHH:MM',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectStartTime,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Please enter start time';
            final regex = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$');
            if (!regex.hasMatch(value.trim())) return 'Use format: YYYY-MM-DDTHH:MM';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _durationController,
          decoration: const InputDecoration(
            labelText: 'Duration (hours)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            if (int.tryParse(value) == null) return 'Invalid';
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );
    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Widget _buildLocationMap() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openLocationPicker,
      child: SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              IgnorePointer(
                child: FlutterMap(
                  key: ValueKey(_selectedLocation),
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.recodextech.fixflow_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 80.0,
                          height: 80.0,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Tap to pick location',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
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

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 60, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Error: ${snapshot.error}'));
        }

        final categories = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Select Category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.category),
          ),
          value: _selectedCategory,
          items: categories
              .map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)))
              .toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Please select a category' : null,
        );
      },
    );
  }

  Widget _buildWalletDropdown() {
    return FutureBuilder<List<Wallet>>(
      future: _walletsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 60, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Error loading wallets: ${snapshot.error}'));
        }

        final wallets = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Select Wallet',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.account_balance_wallet),
          ),
          value: _selectedWalletId,
          items: wallets
              .map((wallet) => DropdownMenuItem(
                    value: wallet.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(wallet.icon, color: wallet.iconColor, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${wallet.displayName} - \$${wallet.balance.toStringAsFixed(2)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedWalletId = value),
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Please select a wallet' : null,
        );
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Amount',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.attach_money),
        prefixText: ' ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Please enter amount';
        if (double.tryParse(value) == null) return 'Invalid amount';
        return null;
      },
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitProcess,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Process'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _processNameController.dispose();
    _processDescriptionController.dispose();
    _jobDescriptionController.dispose();
    _startTimeController.dispose();
    _durationController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}


