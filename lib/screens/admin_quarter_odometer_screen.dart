import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminQuarterOdometerScreen extends StatefulWidget {
  const AdminQuarterOdometerScreen({super.key});

  @override
  State<AdminQuarterOdometerScreen> createState() =>
      _AdminQuarterOdometerScreenState();
}

class _AdminQuarterOdometerScreenState
    extends State<AdminQuarterOdometerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _beginController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  String _selectedQuarter = 'Q1';
  String _selectedUnit = '3';
  bool _isSaving = false;

  final List<String> _quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
  final List<String> _units = ['3', '9', '11'];

  final CollectionReference<Map<String, dynamic>> _quarterlyOdometers =
      FirebaseFirestore.instance.collection('quarterly_odometers');

  @override
  void dispose() {
    _beginController.dispose();
    _endController.dispose();
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
      title: const Text('Quarter Odometer Entry'),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _loadExistingRecord() async {
    final docId = '${_selectedQuarter}_unit_$_selectedUnit';
    final doc = await _quarterlyOdometers.doc(docId).get();

    if (!doc.exists) {
      _beginController.clear();
      _endController.clear();
      return;
    }

    final data = doc.data()!;
    _beginController.text = (data['quarterBeginningOdometer'] ?? '').toString();
    _endController.text = (data['quarterEndingOdometer'] ?? '').toString();
  }

  Future<void> _saveQuarterOdometer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? begin = int.tryParse(_beginController.text.trim());
    final int? end = int.tryParse(_endController.text.trim());

    if (begin == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid odometer numbers')),
      );
      return;
    }

    if (end < begin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quarter ending odometer cannot be less than beginning odometer',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final docId = '${_selectedQuarter}_unit_$_selectedUnit';

    await _quarterlyOdometers.doc(docId).set({
      'quarter': _selectedQuarter,
      'unitNumber': _selectedUnit,
      'quarterBeginningOdometer': begin,
      'quarterEndingOdometer': end,
      'totalQuarterMiles': end - begin,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quarter odometer saved')));

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingRecord();
    });
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
                DropdownButtonFormField<String>(
                  value: _selectedQuarter,
                  decoration: _inputDecoration('Quarter'),
                  items: _quarters
                      .map(
                        (quarter) => DropdownMenuItem<String>(
                          value: quarter,
                          child: Text(quarter),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      _selectedQuarter = value;
                    });
                    await _loadExistingRecord();
                  },
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
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      _selectedUnit = value;
                    });
                    await _loadExistingRecord();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _beginController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Quarter Beginning Odometer'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter beginning odometer';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid whole number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Quarter Ending Odometer'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter ending odometer';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid whole number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveQuarterOdometer,
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Quarter Odometer'),
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
