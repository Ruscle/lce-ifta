import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminAuthService {
  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(app: Firebase.app(), region: 'us-central1');

  static Future<void> _ensureAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No signed-in Firebase user found');
    }

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser == null) {
      throw Exception('Firebase user disappeared after reload');
    }

    await refreshedUser.getIdToken(true);
  }

  static Future<void> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    await _ensureAuthenticated();

    final callable = _functions.httpsCallable(
      'createManagedUser',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    await callable.call({
      'username': username.trim().toLowerCase(),
      'password': password,
      'role': role,
    });
  }

  static Future<void> resetUserPassword({
    required String uid,
    required String newPassword,
  }) async {
    await _ensureAuthenticated();

    final callable = _functions.httpsCallable(
      'resetManagedUserPassword',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    await callable.call({'uid': uid, 'newPassword': newPassword});
  }

  static Future<void> deleteUser({required String uid}) async {
    await _ensureAuthenticated();

    final callable = _functions.httpsCallable(
      'deleteManagedUser',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    await callable.call({'uid': uid});
  }
}
