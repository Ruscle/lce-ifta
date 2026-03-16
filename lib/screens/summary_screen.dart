import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../services/export_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _selectedQuarter = 'All';
  String _selectedUnit = 'All';
  String _selectedState = 'All';

  final List<String> _quarters = const ['All', 'Q1', 'Q2', 'Q3', 'Q4'];

  final List<String> _units = const ['All', '3', '9', '11'];

  final List<String> _states = const [
    'All',
    'AR',
    'TX',
    'OK',
    'MO',
    'TN',
    'MS',
    'LA',
  ];

  bool get _isAdmin => AppSession.isAdmin;

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          'assets/images/logo.png',
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.local_shipping);
          },
        ),
      ),
      title: const Text('Summary'),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsListCard({
    required String title,
    required Map<String, double> totals,
    required String suffix,
  }) {
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('No data')
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text('${entry.value.toStringAsFixed(1)} $suffix'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _quarterFromDate(DateTime? date) {
    if (date == null) return '';
    if (date.month >= 1 && date.month <= 3) return 'Q1';
    if (date.month >= 4 && date.month <= 6) return 'Q2';
    if (date.month >= 7 && date.month <= 9) return 'Q3';
    return 'Q4';
  }

  bool _matchesQuarterFromDate(DateTime? date) {
    if (_selectedQuarter == 'All') return true;
    return _quarterFromDate(date) == _selectedQuarter;
  }

  bool _matchesQuarterFromValue(String? quarter) {
    if (_selectedQuarter == 'All') return true;
    return (quarter ?? '') == _selectedQuarter;
  }

  bool _matchesUnit(String? unitNumber) {
    if (_selectedUnit == 'All') return true;
    return (unitNumber ?? '') == _selectedUnit;
  }

  bool _matchesState(String? state) {
    if (_selectedState == 'All') return true;
    return (state ?? '').toUpperCase() == _selectedState;
  }

  Future<void> _exportData() async {
    try {
      await ExportService.exportQuarterReport(
        selectedQuarter: _selectedQuarter,
        selectedUnit: _selectedUnit,
        selectedState: _selectedState,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export Excel file: $e')),
      );
    }
  }

  void _quickIftaReport(double arkansasMiles, double outOfStateMiles) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'IFTA report: Arkansas ${arkansasMiles.toStringAsFixed(1)} miles, out-of-state ${outOfStateMiles.toStringAsFixed(1)} miles.',
        ),
      ),
    );
  }

  void _signOut() {
    AppSession.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Map<String, dynamic> _buildDashboardData({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> fuelDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> tripDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> odometerDocs,
  }) {
    final now = DateTime.now();

    final filteredFuelDocs = fuelDocs.where((doc) {
      final data = doc.data();
      final date = _readDate(data['date']);
      final unitNumber = (data['unitNumber'] ?? '').toString();
      final state = (data['state'] ?? '').toString().toUpperCase();

      return _matchesQuarterFromDate(date) &&
          _matchesUnit(unitNumber) &&
          _matchesState(state);
    }).toList();

    final filteredTripDocs = tripDocs.where((doc) {
      final data = doc.data();
      final date = _readDate(data['date']);
      final unitNumber = (data['unitNumber'] ?? '').toString();
      final state = (data['state'] ?? '').toString().toUpperCase();

      return _matchesQuarterFromDate(date) &&
          _matchesUnit(unitNumber) &&
          _matchesState(state);
    }).toList();

    final filteredOdometerDocs = odometerDocs.where((doc) {
      final data = doc.data();
      final quarter = (data['quarter'] ?? '').toString();
      final unitNumber = (data['unitNumber'] ?? data['unit'] ?? '').toString();

      return _matchesQuarterFromValue(quarter) && _matchesUnit(unitNumber);
    }).toList();

    double totalGallons = 0;
    for (final doc in filteredFuelDocs) {
      final gallons = ((doc.data()['gallons'] ?? 0) as num).toDouble();
      totalGallons += gallons;
    }

    double totalOutOfStateMiles = 0;
    for (final doc in filteredTripDocs) {
      final miles = ((doc.data()['miles'] ?? 0) as num).toDouble();
      totalOutOfStateMiles += miles;
    }

    double totalQuarterMiles = 0;
    for (final doc in filteredOdometerDocs) {
      final data = doc.data();
      final begin =
          ((data['quarterBeginningOdometer'] ?? data['begin'] ?? 0) as num)
              .toDouble();
      final end = ((data['quarterEndingOdometer'] ?? data['end'] ?? 0) as num)
          .toDouble();
      totalQuarterMiles += (end - begin);
    }

    final todayTripDocs = tripDocs.where((doc) {
      final date = _readDate(doc.data()['date']);
      if (date == null) return false;
      final sameDay =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      if (!sameDay) return false;

      final unitNumber = (doc.data()['unitNumber'] ?? '').toString();
      final state = (doc.data()['state'] ?? '').toString().toUpperCase();

      return _matchesUnit(unitNumber) && _matchesState(state);
    }).toList();

    double todayMiles = 0;
    for (final doc in todayTripDocs) {
      todayMiles += ((doc.data()['miles'] ?? 0) as num).toDouble();
    }

    final arkansasMilesRaw = totalQuarterMiles - totalOutOfStateMiles;
    final arkansasMiles = arkansasMilesRaw < 0 ? 0.0 : arkansasMilesRaw;

    final Map<String, double> milesByState = {};
    for (final doc in filteredTripDocs) {
      final state = (doc.data()['state'] ?? '').toString().toUpperCase();
      final miles = ((doc.data()['miles'] ?? 0) as num).toDouble();
      milesByState[state] = (milesByState[state] ?? 0) + miles;
    }

    if (_selectedState == 'All' || _selectedState == 'AR') {
      milesByState['AR'] = (milesByState['AR'] ?? 0) + arkansasMiles;
    }

    final Map<String, double> fuelByState = {};
    for (final doc in filteredFuelDocs) {
      final state = (doc.data()['state'] ?? '').toString().toUpperCase();
      final gallons = ((doc.data()['gallons'] ?? 0) as num).toDouble();
      fuelByState[state] = (fuelByState[state] ?? 0) + gallons;
    }

    final Map<String, double> tripsByDriver = {};
    for (final doc in filteredTripDocs) {
      final data = doc.data();
      final driver = (data['driver'] ?? data['createdBy'] ?? 'Unknown')
          .toString();
      final miles = ((data['miles'] ?? 0) as num).toDouble();
      tripsByDriver[driver] = (tripsByDriver[driver] ?? 0) + miles;
    }

    return {
      'totalGallons': totalGallons,
      'totalOutOfStateMiles': totalOutOfStateMiles,
      'totalQuarterMiles': totalQuarterMiles,
      'arkansasMiles': arkansasMiles,
      'todayMiles': todayMiles,
      'fuelEntryCount': filteredFuelDocs.length,
      'tripEntryCount': filteredTripDocs.length,
      'milesByState': milesByState,
      'fuelByState': fuelByState,
      'tripsByDriver': tripsByDriver,
    };
  }

  Widget _buildDashboard(Map<String, dynamic> dashboard) {
    final totalGallons = (dashboard['totalGallons'] as double?) ?? 0;
    final totalOutOfStateMiles =
        (dashboard['totalOutOfStateMiles'] as double?) ?? 0;
    final totalQuarterMiles = (dashboard['totalQuarterMiles'] as double?) ?? 0;
    final arkansasMiles = (dashboard['arkansasMiles'] as double?) ?? 0;
    final todayMiles = (dashboard['todayMiles'] as double?) ?? 0;
    final fuelEntryCount = (dashboard['fuelEntryCount'] as int?) ?? 0;
    final tripEntryCount = (dashboard['tripEntryCount'] as int?) ?? 0;
    final milesByState =
        (dashboard['milesByState'] as Map<String, double>?) ?? {};
    final fuelByState =
        (dashboard['fuelByState'] as Map<String, double>?) ?? {};
    final tripsByDriver =
        (dashboard['tripsByDriver'] as Map<String, double>?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Fleet Dashboard',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          AppSession.username == null
              ? 'Filter the collected data by quarter, unit number, and state.'
              : 'Signed in as ${AppSession.username} • Filter the collected data by quarter, unit number, and state.',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Quarter',
          value: _selectedQuarter,
          items: _quarters,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedQuarter = value;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Unit Number',
          value: _selectedUnit,
          items: _units,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedUnit = value;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'State',
          value: _selectedState,
          items: _states,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedState = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildSummaryCard(
          title: 'Total Miles Today',
          value: todayMiles.toStringAsFixed(1),
          icon: Icons.today,
        ),
        _buildSummaryCard(
          title: 'Total Quarter Miles',
          value: totalQuarterMiles.toStringAsFixed(1),
          icon: Icons.speed,
        ),
        _buildSummaryCard(
          title: 'Out-of-State Miles',
          value: totalOutOfStateMiles.toStringAsFixed(1),
          icon: Icons.route,
        ),
        _buildSummaryCard(
          title: 'Arkansas Miles',
          value: arkansasMiles.toStringAsFixed(1),
          icon: Icons.map,
        ),
        _buildSummaryCard(
          title: 'Fuel Purchases (Gallons)',
          value: totalGallons.toStringAsFixed(1),
          icon: Icons.local_gas_station,
        ),
        _buildSummaryCard(
          title: 'Trip Entries',
          value: tripEntryCount.toString(),
          icon: Icons.alt_route,
        ),
        _buildSummaryCard(
          title: 'Fuel Entries',
          value: fuelEntryCount.toString(),
          icon: Icons.receipt_long,
        ),
        const SizedBox(height: 16),
        _buildTotalsListCard(
          title: 'Miles by State',
          totals: milesByState,
          suffix: 'miles',
        ),
        _buildTotalsListCard(
          title: 'Fuel Purchases by State',
          totals: fuelByState,
          suffix: 'gal',
        ),
        _buildTotalsListCard(
          title: 'Trips by Driver',
          totals: tripsByDriver,
          suffix: 'miles',
        ),
        const SizedBox(height: 16),
        if (_isAdmin) ...[
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/user-management');
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage Users'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/admin-entries');
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Manage Entries'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/admin-quarter-odometer');
              },
              icon: const Icon(Icons.pin),
              label: const Text('Quarter Odometer Entry'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                _quickIftaReport(arkansasMiles, totalOutOfStateMiles);
              },
              icon: const Icon(Icons.assessment),
              label: const Text('Quick IFTA Report'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _exportData,
              icon: const Icon(Icons.table_view),
              label: const Text('Export Data to Excel'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fuelStream = FirebaseFirestore.instance
        .collection('fuel_entries')
        .snapshots();

    final tripStream = FirebaseFirestore.instance
        .collection('trip_entries')
        .snapshots();

    final odometerStream = FirebaseFirestore.instance
        .collection('quarterly_odometers')
        .snapshots();

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: fuelStream,
          builder: (context, fuelSnapshot) {
            if (fuelSnapshot.hasError) {
              return const Center(child: Text('Error loading fuel entries.'));
            }

            if (!fuelSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: tripStream,
              builder: (context, tripSnapshot) {
                if (tripSnapshot.hasError) {
                  return const Center(
                    child: Text('Error loading trip entries.'),
                  );
                }

                if (!tripSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: odometerStream,
                  builder: (context, odometerSnapshot) {
                    if (odometerSnapshot.hasError) {
                      return const Center(
                        child: Text('Error loading quarter odometers.'),
                      );
                    }

                    if (!odometerSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final dashboard = _buildDashboardData(
                      fuelDocs: fuelSnapshot.data!.docs,
                      tripDocs: tripSnapshot.data!.docs,
                      odometerDocs: odometerSnapshot.data!.docs,
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildDashboard(dashboard),
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/fuel-entry',
                                            );
                                          },
                                          child: const Text('Add Fuel Entry'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/trip-entry',
                                            );
                                          },
                                          child: const Text(
                                            'Add Out-of-State Trip',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/open-trip-entries',
                                      );
                                    },
                                    child: const Text(
                                      'Finish Open Trip Entries',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
