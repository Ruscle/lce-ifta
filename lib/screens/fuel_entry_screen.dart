import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../services/firestore_service.dart';

class FuelEntryScreen extends StatefulWidget {
  const FuelEntryScreen({super.key});

  @override
  State<FuelEntryScreen> createState() => _FuelEntryScreenState();
}

class _FuelEntryScreenState extends State<FuelEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _gallonsController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  String _selectedUnit = '3';
  String _selectedFuelType = 'Bulk';
  bool _isSaving = false;

  final List<String> _units = ['3', '9', '11'];
  final List<String> _fuelTypes = ['Bulk', 'Non-Bulk'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _gallonsController.dispose();
    _stateController.dispose();
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
      title: const Text('Fuel Entry'),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _saveFuelEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final gallons = double.tryParse(_gallonsController.text.trim());
    if (gallons == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid gallons amount')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirestoreService.saveFuelEntry(
        unitNumber: _selectedUnit,
        state: _stateController.text.trim().toUpperCase(),
        gallons: gallons,
        date: DateTime.now(),
        fuelType: _selectedFuelType,
        createdBy: AppSession.username,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fuel entry saved')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save fuel entry: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  decoration: _inputDecoration('Fuel Type'),
                  items: _fuelTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedFuelType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gallonsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Gallons'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter gallons';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stateController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  decoration: _inputDecoration('State Abbreviation'),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveFuelEntry,
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Fuel Entry'),
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
