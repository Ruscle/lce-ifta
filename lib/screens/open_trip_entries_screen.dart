import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../services/firestore_service.dart';

class OpenTripEntriesScreen extends StatelessWidget {
  const OpenTripEntriesScreen({super.key});

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
      title: const Text('Open Trip Entries'),
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

  Future<void> _finishTripEntry(
    BuildContext context,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final endController = TextEditingController();
    final start = ((data['odometerStart'] ?? 0) as num).toDouble();

    await showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveEndOdometer() async {
              final end = double.tryParse(endController.text.trim());

              if (end == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid ending odometer'),
                  ),
                );
                return;
              }

              if (end < start) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ending odometer cannot be less than starting odometer',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                await FirestoreService.updateTripEntry(
                  documentId: documentId,
                  odometerEnd: end,
                  miles: end - start,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip entry updated')),
                  );
                }
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not update trip: $e')),
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text('Finish Trip Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Starting odometer: ${start.toStringAsFixed(1)}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: endController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ending Odometer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveEndOdometer,
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = AppSession.username ?? '';

    return Scaffold(
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trip_entries')
            .where('driver', isEqualTo: username)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading trip entries'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            return data['odometerEnd'] == null;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No open trip entries found'));
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
              final start = ((data['odometerStart'] ?? 0) as num).toDouble();
              final date = _formatDate(data['date']);

              return Card(
                child: ListTile(
                  title: Text('Unit $unitNumber • $state'),
                  subtitle: Text('$date • Start: ${start.toStringAsFixed(1)}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _finishTripEntry(context, doc.id, data);
                    },
                    child: const Text('Finish'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
