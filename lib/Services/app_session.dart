class AppSession {
  static String? userId;
  static String? username;
  static String role = 'user';

  static bool get isAdmin => role == 'admin';

  static void signIn({
    required String usernameValue,
    required bool isAdminValue,
    String? userIdValue,
  }) {
    userId = userIdValue;
    username = usernameValue;
    role = isAdminValue ? 'admin' : 'user';
  }

  static void clear() {
    userId = null;
    username = null;
    role = 'user';
  }
}
