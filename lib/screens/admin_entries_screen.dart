import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class AdminEntriesScreen extends StatefulWidget {
  const AdminEntriesScreen({super.key});

  @override
  State<AdminEntriesScreen> createState() => _AdminEntriesScreenState();
}

class _AdminEntriesScreenState extends State<AdminEntriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      title: const Text('Manage Entries'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Fuel Entries'),
          Tab(text: 'Trip Entries'),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$month/$day/$year';
    }
    return '';
  }

  Future<void> _confirmDeleteFuelEntry(String documentId) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Fuel Entry'),
              content: const Text('Delete this fuel entry?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await FirestoreService.deleteFuelEntry(documentId);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fuel entry deleted')));
  }

  Future<void> _confirmDeleteTripEntry(String documentId) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Trip Entry'),
              content: const Text('Delete this out-of-state trip entry?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await FirestoreService.deleteTripEntry(documentId);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip entry deleted')));
  }

  Widget _buildFuelEntriesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.fuelEntriesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading fuel entries'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No fuel entries found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final unitNumber = (data['unitNumber'] ?? '').toString();
            final state = (data['state'] ?? '').toString();
            final gallons = ((data['gallons'] ?? 0) as num).toDouble();
            final fuelType = (data['fuelType'] ?? '').toString();
            final date = _formatDate(data['date']);

            return Card(
              child: ListTile(
                title: Text(
                  'Unit $unitNumber • $state • ${gallons.toStringAsFixed(1)} gal',
                ),
                subtitle: Text(fuelType.isEmpty ? date : '$date • $fuelType'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _confirmDeleteFuelEntry(doc.id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTripEntriesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.tripEntriesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading trip entries'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No trip entries found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final unitNumber = (data['unitNumber'] ?? '').toString();
            final state = (data['state'] ?? '').toString();
            final miles = ((data['miles'] ?? 0) as num).toDouble();
            final driver = (data['driver'] ?? '').toString();
            final date = _formatDate(data['date']);

            return Card(
              child: ListTile(
                title: Text(
                  'Unit $unitNumber • $state • ${miles.toStringAsFixed(1)} miles',
                ),
                subtitle: Text(driver.isEmpty ? date : '$date • $driver'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _confirmDeleteTripEntry(doc.id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFuelEntriesTab(), _buildTripEntriesTab()],
      ),
    );
  }
}
