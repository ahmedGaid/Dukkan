// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'دكان';

  @override
  String get authWelcomeTitle => 'أهلاً بيك في دكان';

  @override
  String get authLoginSubtitle => 'سجّل دخولك وكمّل تسوّق من دكاكينك';

  @override
  String get authSignupTitle => 'حساب جديد';

  @override
  String get fieldName => 'الاسم';

  @override
  String get fieldEmail => 'البريد الإلكتروني';

  @override
  String get fieldPassword => 'كلمة السر';

  @override
  String get fieldPhoneOptional => 'رقم الموبايل (اختياري)';

  @override
  String get roleQuestion => 'إنت هنا عشان؟';

  @override
  String get roleCustomer => 'أطلب من الدكاكين';

  @override
  String get roleOwner => 'أدير دكاني';

  @override
  String get roleBadgeCustomer => 'زبون';

  @override
  String get roleBadgeOwner => 'صاحب دكان';

  @override
  String get actionLogin => 'تسجيل الدخول';

  @override
  String get actionSignup => 'إنشاء الحساب';

  @override
  String get actionForgot => 'نسيت كلمة السر؟';

  @override
  String get actionSendReset => 'إبعت رابط الاستعادة';

  @override
  String get actionSignupLink => 'سجّل دلوقتي';

  @override
  String get actionLoginLink => 'تسجيل الدخول';

  @override
  String get actionLogout => 'تسجيل الخروج';

  @override
  String get noAccountPrompt => 'لسه معندكش حساب؟';

  @override
  String get haveAccountPrompt => 'عندك حساب بالفعل؟';

  @override
  String get forgotTitle => 'استعادة كلمة السر';

  @override
  String get forgotSubtitle =>
      'اكتب بريدك وهنبعتلك رابط تعمل بيه كلمة سر جديدة.';

  @override
  String get resetSent => 'بعتنا رابط استعادة كلمة السر على بريدك.';

  @override
  String get validateRequired => 'الحقل ده مطلوب';

  @override
  String get validateEmail => 'اكتب بريد إلكتروني صحيح';

  @override
  String get validatePasswordShort => 'كلمة السر لازم تكون ٦ حروف على الأقل';

  @override
  String get authErrorInvalidCredentials => 'البريد أو كلمة السر مش مظبوطين';

  @override
  String get authErrorEmailInUse =>
      'البريد ده مستخدم قبل كده — جرّب تسجّل دخول';

  @override
  String get authErrorWeakPassword => 'كلمة السر ضعيفة شوية — خليها أطول';

  @override
  String get authErrorInvalidEmail => 'البريد الإلكتروني شكله مش مظبوط';

  @override
  String get authErrorUserDisabled => 'الحساب ده موقوف دلوقتي';

  @override
  String get authErrorNetwork => 'مفيش اتصال بالنت — اتأكد وجرّب تاني';

  @override
  String get authErrorUnknown => 'حصلت مشكلة — جرّب تاني';

  @override
  String homeGreeting(String name) {
    return 'أهلاً $name';
  }

  @override
  String get homeCustomerPlaceholder => 'دكاكينك هتظهر هنا قريب.';

  @override
  String get homeOwnerPlaceholder => 'لوحة دكانك هتظهر هنا قريب.';
}
