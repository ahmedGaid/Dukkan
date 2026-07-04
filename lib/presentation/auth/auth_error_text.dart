import '../../core/errors/failures.dart';
import '../../l10n/app_localizations.dart';

/// Maps an [AuthFailureCode] to a warm, localized message. Keeps the code→copy
/// mapping in one place so every auth screen shows the same wording.
String authErrorText(AppLocalizations l10n, AuthFailureCode code) {
  return switch (code) {
    AuthFailureCode.invalidCredentials => l10n.authErrorInvalidCredentials,
    AuthFailureCode.emailInUse => l10n.authErrorEmailInUse,
    AuthFailureCode.weakPassword => l10n.authErrorWeakPassword,
    AuthFailureCode.invalidEmail => l10n.authErrorInvalidEmail,
    AuthFailureCode.userDisabled => l10n.authErrorUserDisabled,
    AuthFailureCode.network => l10n.authErrorNetwork,
    AuthFailureCode.unknown => l10n.authErrorUnknown,
  };
}
