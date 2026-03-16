import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  static CollectionReference<Map<String, dynamic>> get fuelEntries =>
      _db.collection('fuel_entries');

  static CollectionReference<Map<String, dynamic>> get tripEntries =>
      _db.collection('trip_entries');

  static CollectionReference<Map<String, dynamic>> get quarterOdometers =>
      _db.collection('quarterly_odometers');

  static String usernameToEmail(String username) {
    final cleaned = username.trim().toLowerCase();
    return '$cleaned@iftatracker.local';
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await users.doc(userId).get();
    return doc.data();
  }

  static Future<void> saveFuelEntry({
    required String unitNumber,
    required String state,
    required double gallons,
    required DateTime date,
    String? fuelType,
    String? createdBy,
  }) async {
    await fuelEntries.add({
      'unitNumber': unitNumber,
      'state': state,
      'gallons': gallons,
      'fuelType': fuelType,
      'createdBy': createdBy,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveTripEntry({
    required String unitNumber,
    required String state,
    required double miles,
    required DateTime date,
    required String driver,
    double? odometerStart,
    double? odometerEnd,
  }) async {
    await tripEntries.add({
      'unitNumber': unitNumber,
      'state': state,
      'miles': miles,
      'driver': driver,
      'odometerStart': odometerStart,
      'odometerEnd': odometerEnd,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateTripEntry({
    required String documentId,
    required double odometerEnd,
    required double miles,
  }) async {
    await tripEntries.doc(documentId).update({
      'odometerEnd': odometerEnd,
      'miles': miles,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> fuelEntriesStream() {
    return fuelEntries.orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> tripEntriesStream() {
    return tripEntries.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> deleteFuelEntry(String documentId) async {
    await fuelEntries.doc(documentId).delete();
  }

  static Future<void> deleteTripEntry(String documentId) async {
    await tripEntries.doc(documentId).delete();
  }
}
