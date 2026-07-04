// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Dukkan';

  @override
  String get authWelcomeTitle => 'Welcome to Dukkan';

  @override
  String get authLoginSubtitle => 'Log in and keep shopping from your shops';

  @override
  String get authSignupTitle => 'New account';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPhoneOptional => 'Phone (optional)';

  @override
  String get roleQuestion => 'You\'re here to…';

  @override
  String get roleCustomer => 'Order from shops';

  @override
  String get roleOwner => 'Run my shop';

  @override
  String get roleBadgeCustomer => 'Customer';

  @override
  String get roleBadgeOwner => 'Shop owner';

  @override
  String get actionLogin => 'Log in';

  @override
  String get actionSignup => 'Create account';

  @override
  String get actionForgot => 'Forgot password?';

  @override
  String get actionSendReset => 'Send reset link';

  @override
  String get actionSignupLink => 'Sign up';

  @override
  String get actionLoginLink => 'Log in';

  @override
  String get actionLogout => 'Log out';

  @override
  String get noAccountPrompt => 'No account yet?';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get forgotTitle => 'Reset password';

  @override
  String get forgotSubtitle =>
      'Enter your email and we\'ll send you a link to set a new password.';

  @override
  String get resetSent => 'We sent a password reset link to your email.';

  @override
  String get validateRequired => 'This field is required';

  @override
  String get validateEmail => 'Enter a valid email';

  @override
  String get validatePasswordShort => 'Password must be at least 6 characters';

  @override
  String get authErrorInvalidCredentials => 'Wrong email or password';

  @override
  String get authErrorEmailInUse =>
      'This email is already registered — try logging in';

  @override
  String get authErrorWeakPassword => 'Password is a bit weak — make it longer';

  @override
  String get authErrorInvalidEmail => 'That email doesn\'t look right';

  @override
  String get authErrorUserDisabled => 'This account is currently disabled';

  @override
  String get authErrorNetwork => 'No internet connection — check and try again';

  @override
  String get authErrorUnknown => 'Something went wrong — try again';

  @override
  String homeGreeting(String name) {
    return 'Hi $name';
  }

  @override
  String get homeCustomerPlaceholder => 'Your shops will appear here soon.';

  @override
  String get homeOwnerPlaceholder =>
      'Your shop dashboard will appear here soon.';
}
