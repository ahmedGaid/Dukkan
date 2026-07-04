import '../../l10n/app_localizations.dart';

/// Form validators for the auth screens, localized. Firebase is the real
/// authority on email/password validity — these only catch obvious mistakes
/// before a round-trip.
class AuthValidators {
  const AuthValidators(this._l10n);

  final AppLocalizations _l10n;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? required(String? value) {
    return (value == null || value.trim().isEmpty)
        ? _l10n.validateRequired
        : null;
  }

  String? email(String? value) {
    if (value == null || value.trim().isEmpty) return _l10n.validateRequired;
    return _emailPattern.hasMatch(value.trim()) ? null : _l10n.validateEmail;
  }

  String? password(String? value) {
    if (value == null || value.isEmpty) return _l10n.validateRequired;
    return value.length < 6 ? _l10n.validatePasswordShort : null;
  }
}
