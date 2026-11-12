class Validators {
  Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(v.trim()) ? null : 'Enter a valid email address';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Password is required' : null;

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    final digits = v.replaceAll(RegExp(r'[\s\-+]'), '');
    if (!RegExp(r'^\d{8,15}$').hasMatch(digits))
      return 'Enter a valid phone number';
    return null;
  }

  static String? Function(String?) match(String Function() other, String msg) =>
      (v) => v == other() ? null : msg;
}
