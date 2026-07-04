import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name shown as the window/task title.
  ///
  /// In ar, this message translates to:
  /// **'دكان'**
  String get appName;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بيك في دكان'**
  String get authWelcomeTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك وكمّل تسوّق من دكاكينك'**
  String get authLoginSubtitle;

  /// No description provided for @authSignupTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب جديد'**
  String get authSignupTitle;

  /// No description provided for @fieldName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get fieldName;

  /// No description provided for @fieldEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر'**
  String get fieldPassword;

  /// No description provided for @fieldPhoneOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل (اختياري)'**
  String get fieldPhoneOptional;

  /// No description provided for @roleQuestion.
  ///
  /// In ar, this message translates to:
  /// **'إنت هنا عشان؟'**
  String get roleQuestion;

  /// No description provided for @roleCustomer.
  ///
  /// In ar, this message translates to:
  /// **'أطلب من الدكاكين'**
  String get roleCustomer;

  /// No description provided for @roleOwner.
  ///
  /// In ar, this message translates to:
  /// **'أدير دكاني'**
  String get roleOwner;

  /// No description provided for @roleBadgeCustomer.
  ///
  /// In ar, this message translates to:
  /// **'زبون'**
  String get roleBadgeCustomer;

  /// No description provided for @roleBadgeOwner.
  ///
  /// In ar, this message translates to:
  /// **'صاحب دكان'**
  String get roleBadgeOwner;

  /// No description provided for @actionLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get actionLogin;

  /// No description provided for @actionSignup.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get actionSignup;

  /// No description provided for @actionForgot.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة السر؟'**
  String get actionForgot;

  /// No description provided for @actionSendReset.
  ///
  /// In ar, this message translates to:
  /// **'إبعت رابط الاستعادة'**
  String get actionSendReset;

  /// No description provided for @actionSignupLink.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دلوقتي'**
  String get actionSignupLink;

  /// No description provided for @actionLoginLink.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get actionLoginLink;

  /// No description provided for @actionLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get actionLogout;

  /// No description provided for @noAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'لسه معندكش حساب؟'**
  String get noAccountPrompt;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'عندك حساب بالفعل؟'**
  String get haveAccountPrompt;

  /// No description provided for @forgotTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة السر'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بريدك وهنبعتلك رابط تعمل بيه كلمة سر جديدة.'**
  String get forgotSubtitle;

  /// No description provided for @resetSent.
  ///
  /// In ar, this message translates to:
  /// **'بعتنا رابط استعادة كلمة السر على بريدك.'**
  String get resetSent;

  /// No description provided for @validateRequired.
  ///
  /// In ar, this message translates to:
  /// **'الحقل ده مطلوب'**
  String get validateRequired;

  /// No description provided for @validateEmail.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بريد إلكتروني صحيح'**
  String get validateEmail;

  /// No description provided for @validatePasswordShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر لازم تكون ٦ حروف على الأقل'**
  String get validatePasswordShort;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد أو كلمة السر مش مظبوطين'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In ar, this message translates to:
  /// **'البريد ده مستخدم قبل كده — جرّب تسجّل دخول'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر ضعيفة شوية — خليها أطول'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني شكله مش مظبوط'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الحساب ده موقوف دلوقتي'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالنت — اتأكد وجرّب تاني'**
  String get authErrorNetwork;

  /// No description provided for @authErrorUnknown.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة — جرّب تاني'**
  String get authErrorUnknown;

  /// AppBar greeting on the home page.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeCustomerPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'دكاكينك هتظهر هنا قريب.'**
  String get homeCustomerPlaceholder;

  /// No description provided for @homeOwnerPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'لوحة دكانك هتظهر هنا قريب.'**
  String get homeOwnerPlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
