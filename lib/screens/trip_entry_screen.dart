import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../services/firestore_service.dart';

class TripEntryScreen extends StatefulWidget {
  const TripEntryScreen({super.key});

  @override
  State<TripEntryScreen> createState() => _TripEntryScreenState();
}

class _TripEntryScreenState extends State<TripEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _odometerStartController =
      TextEditingController();
  final TextEditingController _odometerEndController = TextEditingController();

  String _selectedUnit = '3';
  bool _isSaving = false;

  final List<String> _units = ['3', '9', '11'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';

    _odometerStartController.addListener(_refreshMiles);
    _odometerEndController.addListener(_refreshMiles);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _stateController.dispose();
    _odometerStartController.dispose();
    _odometerEndController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leadingWidth: 96,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Image.asset(
              'assets/images/logo.png',
              height: 28,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.local_shipping);
              },
            ),
          ),
        ],
      ),
      title: const Text('Out-of-State Trip Entry'),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  double? get _startValue =>
      double.tryParse(_odometerStartController.text.trim());

  double? get _endValue => double.tryParse(_odometerEndController.text.trim());

  double get _calculatedMiles {
    final start = _startValue;
    final end = _endValue;

    if (start == null || end == null || end < start) {
      return 0;
    }

    return end - start;
  }

  void _refreshMiles() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveTripEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final start = _startValue;
    final end = _endValue;

    if (start == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter odometer start')));
      return;
    }

    final state = _stateController.text.trim().toUpperCase();
    if (state == 'AR') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This screen is only for out-of-state trips'),
        ),
      );
      return;
    }

    if (end != null && end < start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Odometer end cannot be less than odometer start'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirestoreService.saveTripEntry(
        unitNumber: _selectedUnit,
        state: state,
        miles: end == null ? 0 : (end - start),
        date: DateTime.now(),
        driver: AppSession.username ?? 'Unknown',
        odometerStart: start,
        odometerEnd: end,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            end == null
                ? 'Trip start saved. You can update ending odometer later.'
                : 'Trip entry saved',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save trip entry: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculatedMiles = _calculatedMiles;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: _inputDecoration('Date'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: _inputDecoration('Unit Number'),
                  items: _units
                      .map(
                        (unit) => DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedUnit = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stateController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  decoration: _inputDecoration('Out-of-State Abbreviation'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter state abbreviation';
                    }
                    if (value.trim().length != 2) {
                      return 'Enter 2 letters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _odometerStartController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Odometer Start'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter odometer start';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _odometerEndController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    'Odometer End (optional for now)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calculate),
                    title: const Text('Total Miles'),
                    subtitle: Text(calculatedMiles.toStringAsFixed(1)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTripEntry,
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Trip Entry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
