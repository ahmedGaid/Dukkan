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

  /// No description provided for @roleCourier.
  ///
  /// In ar, this message translates to:
  /// **'مندوب التوصيل'**
  String get roleCourier;

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

  /// No description provided for @roleBadgeCourier.
  ///
  /// In ar, this message translates to:
  /// **'مندوب التوصيل'**
  String get roleBadgeCourier;

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

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navCategories.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get navCategories;

  /// No description provided for @navFavorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get navFavorites;

  /// No description provided for @navOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get navOrders;

  /// No description provided for @navMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get navMore;

  /// No description provided for @homeSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على منتج أو دكان'**
  String get homeSearchHint;

  /// No description provided for @sectionOffers.
  ///
  /// In ar, this message translates to:
  /// **'عروض'**
  String get sectionOffers;

  /// No description provided for @sectionCategories.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get sectionCategories;

  /// No description provided for @sectionNearbyShops.
  ///
  /// In ar, this message translates to:
  /// **'دكاكين قريبة منك'**
  String get sectionNearbyShops;

  /// No description provided for @categoryAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get categoryAll;

  /// No description provided for @shopOpen.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get shopOpen;

  /// No description provided for @shopClosed.
  ///
  /// In ar, this message translates to:
  /// **'مقفول'**
  String get shopClosed;

  /// No description provided for @shopsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مافيش دكاكين قريبة لسه'**
  String get shopsEmptyTitle;

  /// No description provided for @shopsEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'بنضيف دكاكين جديدة كل يوم — تعالى بصّ تاني قريب.'**
  String get shopsEmptyBody;

  /// No description provided for @categoryEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مافيش دكاكين في القسم ده'**
  String get categoryEmptyTitle;

  /// No description provided for @categoryEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'جرّب قسم تاني أو شوف كل الدكاكين.'**
  String get categoryEmptyBody;

  /// No description provided for @errorTitle.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة'**
  String get errorTitle;

  /// No description provided for @errorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب الدكاكين دلوقتي — جرّب تاني.'**
  String get errorBody;

  /// No description provided for @actionRetry.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تاني'**
  String get actionRetry;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش مفضلة'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'دوس على القلب في أي دكان أو منتج بتحبه، وهيتحفظ هنا.'**
  String get favoritesEmptyBody;

  /// No description provided for @favoriteActionErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحفظها — جرّب تاني.'**
  String get favoriteActionErrorBody;

  /// No description provided for @favoritesSectionShops.
  ///
  /// In ar, this message translates to:
  /// **'الدكاكين'**
  String get favoritesSectionShops;

  /// No description provided for @favoritesSectionProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get favoritesSectionProducts;

  /// No description provided for @favoritesErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجيب مفضلاتك دلوقتي — جرّب تاني.'**
  String get favoritesErrorBody;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش طلبات'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'أول ما تطلب من دكان، هتلاقي طلبك هنا وتتابعه خطوة بخطوة.'**
  String get ordersEmptyBody;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @settingsPreferences.
  ///
  /// In ar, this message translates to:
  /// **'التفضيلات'**
  String get settingsPreferences;

  /// No description provided for @settingsLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguage;

  /// No description provided for @settingsLangArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get settingsLangArabic;

  /// No description provided for @settingsLangEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get settingsLangEnglish;

  /// No description provided for @settingsAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ar, this message translates to:
  /// **'غامق'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get settingsThemeSystem;

  /// No description provided for @settingsAbout.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get settingsVersion;

  /// No description provided for @settingsLogoutConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجّل خروج؟'**
  String get settingsLogoutConfirmTitle;

  /// No description provided for @settingsLogoutConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هتحتاج تسجّل دخولك تاني عشان تكمّل.'**
  String get settingsLogoutConfirmBody;

  /// No description provided for @categoriesComingSoonTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصفّح الأقسام قريب'**
  String get categoriesComingSoonTitle;

  /// No description provided for @categoriesComingSoonBody.
  ///
  /// In ar, this message translates to:
  /// **'هتقدر تتصفّح كل قسم لوحده هنا قريب. دلوقتي الأقسام في الصفحة الرئيسية.'**
  String get categoriesComingSoonBody;

  /// No description provided for @promoBadge.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get promoBadge;

  /// No description provided for @productStockIn.
  ///
  /// In ar, this message translates to:
  /// **'متوفر'**
  String get productStockIn;

  /// No description provided for @productStockLow.
  ///
  /// In ar, this message translates to:
  /// **'آخر كمية'**
  String get productStockLow;

  /// No description provided for @productStockOut.
  ///
  /// In ar, this message translates to:
  /// **'خلص من المخزن'**
  String get productStockOut;

  /// No description provided for @actionAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف'**
  String get actionAdd;

  /// No description provided for @actionAddToCart.
  ///
  /// In ar, this message translates to:
  /// **'أضف للسلة'**
  String get actionAddToCart;

  /// No description provided for @actionCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get actionConfirm;

  /// No description provided for @actionEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get actionEnable;

  /// No description provided for @actionDisable.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التفعيل'**
  String get actionDisable;

  /// No description provided for @actionClear.
  ///
  /// In ar, this message translates to:
  /// **'امسح'**
  String get actionClear;

  /// No description provided for @actionClearAndAdd.
  ///
  /// In ar, this message translates to:
  /// **'امسح وضيف'**
  String get actionClearAndAdd;

  /// No description provided for @actionCheckout.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get actionCheckout;

  /// No description provided for @actionPlaceOrder.
  ///
  /// In ar, this message translates to:
  /// **'أكّد الطلب'**
  String get actionPlaceOrder;

  /// No description provided for @actionBackHome.
  ///
  /// In ar, this message translates to:
  /// **'رجوع للرئيسية'**
  String get actionBackHome;

  /// No description provided for @qtyLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get qtyLabel;

  /// No description provided for @qtyIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زوّد واحد'**
  String get qtyIncrease;

  /// No description provided for @qtyDecrease.
  ///
  /// In ar, this message translates to:
  /// **'قلّل واحد'**
  String get qtyDecrease;

  /// No description provided for @cartItemAdded.
  ///
  /// In ar, this message translates to:
  /// **'اتضاف للسلة'**
  String get cartItemAdded;

  /// No description provided for @cartTitle.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get cartTitle;

  /// No description provided for @cartTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get cartTotal;

  /// No description provided for @cartClearAll.
  ///
  /// In ar, this message translates to:
  /// **'امسح السلة'**
  String get cartClearAll;

  /// No description provided for @cartClearConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمسح السلة؟'**
  String get cartClearConfirmTitle;

  /// No description provided for @cartClearConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هيتشال كل اللي في السلة.'**
  String get cartClearConfirmBody;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'السلة فاضية'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'ضيف منتجات من أي دكان عشان تشوفها هنا.'**
  String get cartEmptyBody;

  /// No description provided for @cartEmptyAction.
  ///
  /// In ar, this message translates to:
  /// **'تصفّح الدكاكين'**
  String get cartEmptyAction;

  /// No description provided for @cartSwitchShopTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبدأ سلة جديدة؟'**
  String get cartSwitchShopTitle;

  /// No description provided for @cartSwitchShopBody.
  ///
  /// In ar, this message translates to:
  /// **'السلة فيها منتجات من دكان تاني. لو ضفت المنتج ده، هنمسح السلة الأول.'**
  String get cartSwitchShopBody;

  /// No description provided for @checkoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get checkoutTitle;

  /// No description provided for @checkoutAddressSection.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التوصيل'**
  String get checkoutAddressSection;

  /// No description provided for @checkoutSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الطلب'**
  String get checkoutSummary;

  /// No description provided for @checkoutErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نأكد طلبك دلوقتي — جرّب تاني.'**
  String get checkoutErrorBody;

  /// No description provided for @fieldAddressLine.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get fieldAddressLine;

  /// No description provided for @fieldCity.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get fieldCity;

  /// No description provided for @fieldNotesOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get fieldNotesOptional;

  /// No description provided for @codLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدفع عند الاستلام'**
  String get codLabel;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلب اتأكد!'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedBody.
  ///
  /// In ar, this message translates to:
  /// **'الدكان هيبدأ يجهّز طلبك على طول.'**
  String get orderPlacedBody;

  /// No description provided for @ordersErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب طلباتك دلوقتي — جرّب تاني.'**
  String get ordersErrorBody;

  /// No description provided for @orderDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get orderDetailTitle;

  /// No description provided for @orderStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار التأكيد'**
  String get orderStatusPending;

  /// No description provided for @orderStatusAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get orderStatusAccepted;

  /// No description provided for @orderStatusPreparing.
  ///
  /// In ar, this message translates to:
  /// **'بيتجهّز'**
  String get orderStatusPreparing;

  /// No description provided for @orderStatusOutForDelivery.
  ///
  /// In ar, this message translates to:
  /// **'في الطريق إليك'**
  String get orderStatusOutForDelivery;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In ar, this message translates to:
  /// **'اتوصّل'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get orderStatusRejected;

  /// No description provided for @actionCancelOrder.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get actionCancelOrder;

  /// No description provided for @orderCancelConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تلغي الطلب؟'**
  String get orderCancelConfirmTitle;

  /// No description provided for @orderCancelConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'مش هتقدر ترجّعه بعد كده.'**
  String get orderCancelConfirmBody;

  /// No description provided for @orderCancelErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نلغي طلبك دلوقتي — جرّب تاني.'**
  String get orderCancelErrorBody;

  /// No description provided for @orderRateTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيّم الدكان'**
  String get orderRateTitle;

  /// No description provided for @orderRateBody.
  ///
  /// In ar, this message translates to:
  /// **'طلبك اتوصّلك، إيه رأيك في الدكان؟'**
  String get orderRateBody;

  /// No description provided for @orderRatedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقييمك'**
  String get orderRatedTitle;

  /// No description provided for @orderRateErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نسجل تقييمك دلوقتي — جرّب تاني.'**
  String get orderRateErrorBody;

  /// No description provided for @navCatalog.
  ///
  /// In ar, this message translates to:
  /// **'الكتالوج'**
  String get navCatalog;

  /// No description provided for @navOrderDesk.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get navOrderDesk;

  /// No description provided for @orderDeskTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get orderDeskTitle;

  /// No description provided for @orderDeskEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش طلبات'**
  String get orderDeskEmptyTitle;

  /// No description provided for @orderDeskEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'طلبات عملائك الجديدة هتظهر هنا.'**
  String get orderDeskEmptyBody;

  /// No description provided for @orderDeskErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب طلباتك دلوقتي — جرّب تاني.'**
  String get orderDeskErrorBody;

  /// No description provided for @orderDeskTodayLabel.
  ///
  /// In ar, this message translates to:
  /// **'النهاردة'**
  String get orderDeskTodayLabel;

  /// No description provided for @actionAcceptOrder.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get actionAcceptOrder;

  /// No description provided for @actionRejectOrder.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get actionRejectOrder;

  /// No description provided for @actionStartPreparing.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التجهيز'**
  String get actionStartPreparing;

  /// No description provided for @actionStartDelivery.
  ///
  /// In ar, this message translates to:
  /// **'ابعته للتوصيل'**
  String get actionStartDelivery;

  /// No description provided for @actionMarkDelivered.
  ///
  /// In ar, this message translates to:
  /// **'وصل الطلب'**
  String get actionMarkDelivered;

  /// No description provided for @orderRejectConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'ترفض الطلب؟'**
  String get orderRejectConfirmTitle;

  /// No description provided for @orderRejectConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'العميل هيوصله إشعار إن الطلب اترفض.'**
  String get orderRejectConfirmBody;

  /// No description provided for @orderActionErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحدّث الطلب دلوقتي — جرّب تاني.'**
  String get orderActionErrorBody;

  /// No description provided for @orderCustomerSection.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get orderCustomerSection;

  /// No description provided for @orderPaymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get orderPaymentMethod;

  /// No description provided for @orderSubtotalLabel.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الفرعي'**
  String get orderSubtotalLabel;

  /// No description provided for @orderDeliveryFeeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل'**
  String get orderDeliveryFeeLabel;

  /// No description provided for @orderDriverSection.
  ///
  /// In ar, this message translates to:
  /// **'المندوب'**
  String get orderDriverSection;

  /// No description provided for @orderAssignDriverButton.
  ///
  /// In ar, this message translates to:
  /// **'تعيين مندوب'**
  String get orderAssignDriverButton;

  /// No description provided for @orderAssignDriverSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين مندوب'**
  String get orderAssignDriverSheetTitle;

  /// No description provided for @orderAssignDriverEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مندوبين متاحين'**
  String get orderAssignDriverEmptyTitle;

  /// No description provided for @orderAssignDriverEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مندوبون متاحون الآن — يمكنك التوصيل بنفسك'**
  String get orderAssignDriverEmptyBody;

  /// No description provided for @orderAssignDriverConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين المندوب ده؟'**
  String get orderAssignDriverConfirmTitle;

  /// No description provided for @orderAssignDriverConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'الطلب هينتقل للمندوب ده بعد التعيين.'**
  String get orderAssignDriverConfirmBody;

  /// No description provided for @orderAssignDriverErrorOffline.
  ///
  /// In ar, this message translates to:
  /// **'المندوب ده بقى أوفلاين دلوقتي — جرّب واحد تاني.'**
  String get orderAssignDriverErrorOffline;

  /// No description provided for @orderAssignDriverErrorCapacity.
  ///
  /// In ar, this message translates to:
  /// **'المندوب ده وصل لأقصى عدد طلبات — جرّب واحد تاني.'**
  String get orderAssignDriverErrorCapacity;

  /// No description provided for @orderAssignDriverErrorArea.
  ///
  /// In ar, this message translates to:
  /// **'المندوب ده مش بيغطي المنطقة دي — جرّب واحد تاني.'**
  String get orderAssignDriverErrorArea;

  /// No description provided for @orderAssignDriverErrorTaken.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ده اتعيّنله مندوب بالفعل.'**
  String get orderAssignDriverErrorTaken;

  /// No description provided for @orderAssignDriverErrorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نعيّن المندوب ده — جرّب تاني.'**
  String get orderAssignDriverErrorGeneric;

  /// No description provided for @orderAssignedAtLabel.
  ///
  /// In ar, this message translates to:
  /// **'اتعيّن'**
  String get orderAssignedAtLabel;

  /// No description provided for @orderTimelineTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الطلب'**
  String get orderTimelineTitle;

  /// No description provided for @orderForcedChip.
  ///
  /// In ar, this message translates to:
  /// **'تصحيح إداري'**
  String get orderForcedChip;

  /// No description provided for @orderNotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات الداخلية'**
  String get orderNotesTitle;

  /// No description provided for @orderNotesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش ملاحظات.'**
  String get orderNotesEmpty;

  /// No description provided for @orderNotesAddHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظة للفريق…'**
  String get orderNotesAddHint;

  /// No description provided for @orderForceStatusAction.
  ///
  /// In ar, this message translates to:
  /// **'فرض الحالة'**
  String get orderForceStatusAction;

  /// No description provided for @orderForceStatusWarning.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة دي بتتخطى مسار الطلب العادي — استخدمها بس لتصحيح غلطة.'**
  String get orderForceStatusWarning;

  /// No description provided for @orderForceStatusLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالة الجديدة'**
  String get orderForceStatusLabel;

  /// No description provided for @orderStaffReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'السبب (مطلوب)'**
  String get orderStaffReasonLabel;

  /// No description provided for @orderReassignDriverAction.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المندوب'**
  String get orderReassignDriverAction;

  /// No description provided for @orderUnassignDriverAction.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التعيين'**
  String get orderUnassignDriverAction;

  /// No description provided for @orderRefundNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة استرداد (اختياري)'**
  String get orderRefundNoteLabel;

  /// No description provided for @orderRefundNoteHelper.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة دفتر بس — مفيش تحويل فلوس.'**
  String get orderRefundNoteHelper;

  /// No description provided for @staffOrderActionErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء ده مكملش — جرّب تاني.'**
  String get staffOrderActionErrorBody;

  /// No description provided for @notifyNewOrderTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد!'**
  String get notifyNewOrderTitle;

  /// No description provided for @notifyNewOrderBody.
  ///
  /// In ar, this message translates to:
  /// **'وصلك طلب جديد، افتح دكانك وشوفه.'**
  String get notifyNewOrderBody;

  /// No description provided for @notifyOrderStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث على طلبك'**
  String get notifyOrderStatusTitle;

  /// No description provided for @notifyOrderStatusBody.
  ///
  /// In ar, this message translates to:
  /// **'طلبك بقى {status}.'**
  String notifyOrderStatusBody(Object status);

  /// No description provided for @notifyDriverAssignedTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد لتوصيله'**
  String get notifyDriverAssignedTitle;

  /// No description provided for @notifyDriverAssignedBody.
  ///
  /// In ar, this message translates to:
  /// **'{shop} عندهم طلب لك في {area}.'**
  String notifyDriverAssignedBody(Object area, Object shop);

  /// No description provided for @notifyOrderDeliveredTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسليم الطلب'**
  String get notifyOrderDeliveredTitle;

  /// No description provided for @notifyOrderDeliveredBody.
  ///
  /// In ar, this message translates to:
  /// **'المندوب سلّم الطلب.'**
  String get notifyOrderDeliveredBody;

  /// No description provided for @shopProductsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدكان لسه بيرتّب رفوفه'**
  String get shopProductsEmptyTitle;

  /// No description provided for @shopProductsEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات هتظهر هنا أول ما الدكان يضيفها.'**
  String get shopProductsEmptyBody;

  /// No description provided for @productsCategoryEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مافيش منتجات في القسم ده'**
  String get productsCategoryEmptyTitle;

  /// No description provided for @productsCategoryEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'جرّب قسم تاني أو شوف كل المنتجات.'**
  String get productsCategoryEmptyBody;

  /// No description provided for @shopErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نفتح الدكان دلوقتي — جرّب تاني.'**
  String get shopErrorBody;

  /// No description provided for @productNotFoundTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنتج مش موجود'**
  String get productNotFoundTitle;

  /// No description provided for @productNotFoundBody.
  ///
  /// In ar, this message translates to:
  /// **'يمكن يكون اتشال من الدكان. ارجع وبصّ على باقي المنتجات.'**
  String get productNotFoundBody;

  /// No description provided for @searchPromptTitle.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على اللي محتاجه'**
  String get searchPromptTitle;

  /// No description provided for @searchPromptBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم منتج أو دكان، وهنلاقيهولك على طول.'**
  String get searchPromptBody;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتايج'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة تانية أو اسم أقصر.'**
  String get searchNoResultsBody;

  /// No description provided for @searchClear.
  ///
  /// In ar, this message translates to:
  /// **'امسح'**
  String get searchClear;

  /// No description provided for @searchErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نكمّل البحث دلوقتي — جرّب تاني.'**
  String get searchErrorBody;

  /// No description provided for @shopOnboardingTitle.
  ///
  /// In ar, this message translates to:
  /// **'جهّز دكانك'**
  String get shopOnboardingTitle;

  /// No description provided for @shopOnboardingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الزباين هيشوفوا دكانك أول ما تخلّص.'**
  String get shopOnboardingSubtitle;

  /// No description provided for @fieldShopName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الدكان (إنجليزي)'**
  String get fieldShopName;

  /// No description provided for @fieldShopNameAr.
  ///
  /// In ar, this message translates to:
  /// **'اسم الدكان (عربي)'**
  String get fieldShopNameAr;

  /// No description provided for @fieldShopAddress.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الدكان'**
  String get fieldShopAddress;

  /// No description provided for @shopOnboardingLogoLabel.
  ///
  /// In ar, this message translates to:
  /// **'لوجو الدكان'**
  String get shopOnboardingLogoLabel;

  /// No description provided for @shopOnboardingLogoHint.
  ///
  /// In ar, this message translates to:
  /// **'دوس عشان تضيف صورة'**
  String get shopOnboardingLogoHint;

  /// No description provided for @shopOnboardingOpenLabel.
  ///
  /// In ar, this message translates to:
  /// **'متاح لاستقبال الطلبات'**
  String get shopOnboardingOpenLabel;

  /// No description provided for @actionCreateShop.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ الدكان'**
  String get actionCreateShop;

  /// No description provided for @shopOnboardingErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين ننشئ الدكان — جرّب تاني.'**
  String get shopOnboardingErrorBody;

  /// No description provided for @shopOnboardingLogoErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نرفع الصورة — جرّب تاني.'**
  String get shopOnboardingLogoErrorBody;

  /// No description provided for @catalogEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش منتجات'**
  String get catalogEmptyTitle;

  /// No description provided for @catalogEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'ضيف أول منتج، وهيظهر هنا على طول.'**
  String get catalogEmptyBody;

  /// No description provided for @catalogErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب كتالوجك دلوقتي — جرّب تاني.'**
  String get catalogErrorBody;

  /// No description provided for @actionAddProduct.
  ///
  /// In ar, this message translates to:
  /// **'أضف منتج'**
  String get actionAddProduct;

  /// No description provided for @addProductTitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف منتج'**
  String get addProductTitle;

  /// No description provided for @editProductTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنتج'**
  String get editProductTitle;

  /// No description provided for @fieldProductName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج (إنجليزي)'**
  String get fieldProductName;

  /// No description provided for @fieldProductNameAr.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج (عربي)'**
  String get fieldProductNameAr;

  /// No description provided for @fieldProductCategory.
  ///
  /// In ar, this message translates to:
  /// **'القسم'**
  String get fieldProductCategory;

  /// No description provided for @fieldProductSubcategory.
  ///
  /// In ar, this message translates to:
  /// **'القسم الفرعي'**
  String get fieldProductSubcategory;

  /// No description provided for @categoryRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر القسم'**
  String get categoryRequired;

  /// No description provided for @subcategoryRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر القسم الفرعي'**
  String get subcategoryRequired;

  /// No description provided for @taxonomyErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب الأقسام دلوقتي — جرّب تاني.'**
  String get taxonomyErrorBody;

  /// No description provided for @fieldProductPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر (جنيه)'**
  String get fieldProductPrice;

  /// No description provided for @fieldProductStock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get fieldProductStock;

  /// No description provided for @fieldProductPromoLabel.
  ///
  /// In ar, this message translates to:
  /// **'خليه عرض'**
  String get fieldProductPromoLabel;

  /// No description provided for @productImageLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة المنتج'**
  String get productImageLabel;

  /// No description provided for @actionSave.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get actionSave;

  /// No description provided for @productFormErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نحفظ المنتج — جرّب تاني.'**
  String get productFormErrorBody;

  /// No description provided for @productImageErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نرفع الصورة — جرّب تاني.'**
  String get productImageErrorBody;

  /// No description provided for @validatePriceInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سعر صحيح'**
  String get validatePriceInvalid;

  /// No description provided for @productDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحذف المنتج ده؟'**
  String get productDeleteConfirmTitle;

  /// No description provided for @productDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هيتشال من دكانك على طول.'**
  String get productDeleteConfirmBody;

  /// No description provided for @actionDelete.
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get actionDelete;

  /// No description provided for @productDeleteErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نحذف المنتج — جرّب تاني.'**
  String get productDeleteErrorBody;

  /// No description provided for @actionCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get actionCreate;

  /// No description provided for @catalogCollectionsEntry.
  ///
  /// In ar, this message translates to:
  /// **'المجموعات'**
  String get catalogCollectionsEntry;

  /// No description provided for @collectionsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجموعات بعد'**
  String get collectionsEmptyTitle;

  /// No description provided for @collectionsEmptyAction.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ مجموعة'**
  String get collectionsEmptyAction;

  /// No description provided for @collectionsErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب مجموعاتك دلوقتي — جرّب تاني.'**
  String get collectionsErrorBody;

  /// No description provided for @collectionsCreateTitle.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة جديدة'**
  String get collectionsCreateTitle;

  /// No description provided for @collectionsRenameTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المجموعة'**
  String get collectionsRenameTitle;

  /// No description provided for @fieldCollectionNameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالعربي'**
  String get fieldCollectionNameAr;

  /// No description provided for @fieldCollectionNameEn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالإنجليزي'**
  String get fieldCollectionNameEn;

  /// No description provided for @collectionNameArHint.
  ///
  /// In ar, this message translates to:
  /// **'مثلاً: عروض'**
  String get collectionNameArHint;

  /// No description provided for @collectionNameEnHint.
  ///
  /// In ar, this message translates to:
  /// **'مثلاً: Offers'**
  String get collectionNameEnHint;

  /// No description provided for @collectionsDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف المجموعة؟'**
  String get collectionsDeleteConfirmTitle;

  /// No description provided for @collectionsDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'حذف المجموعة لا يحذف المنتجات'**
  String get collectionsDeleteConfirmBody;

  /// No description provided for @collectionsActionErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة — جرّب تاني.'**
  String get collectionsActionErrorBody;

  /// No description provided for @productCollections.
  ///
  /// In ar, this message translates to:
  /// **'المجموعات (اختياري)'**
  String get productCollections;

  /// No description provided for @fieldArea.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get fieldArea;

  /// No description provided for @areaRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر منطقتك'**
  String get areaRequired;

  /// No description provided for @areasErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب المناطق دلوقتي — جرّب تاني.'**
  String get areasErrorBody;

  /// No description provided for @navDeliveries.
  ///
  /// In ar, this message translates to:
  /// **'التوصيلات'**
  String get navDeliveries;

  /// No description provided for @courierOnlineLabel.
  ///
  /// In ar, this message translates to:
  /// **'أونلاين'**
  String get courierOnlineLabel;

  /// No description provided for @courierOfflineLabel.
  ///
  /// In ar, this message translates to:
  /// **'أوفلاين'**
  String get courierOfflineLabel;

  /// No description provided for @courierSuspendedBannerBody.
  ///
  /// In ar, this message translates to:
  /// **'حسابك قيد المراجعة — تواصل مع دكان'**
  String get courierSuspendedBannerBody;

  /// No description provided for @courierActiveTabLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get courierActiveTabLabel;

  /// No description provided for @courierHistoryTabLabel.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get courierHistoryTabLabel;

  /// No description provided for @courierActiveEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش توصيلات دلوقتي'**
  String get courierActiveEmptyTitle;

  /// No description provided for @courierHistoryEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش توصيلات سابقة'**
  String get courierHistoryEmptyTitle;

  /// No description provided for @courierActionPickedUp.
  ///
  /// In ar, this message translates to:
  /// **'استلمت الطلب'**
  String get courierActionPickedUp;

  /// No description provided for @courierActionDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التوصيل'**
  String get courierActionDelivered;

  /// No description provided for @courierActionDeliveredConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إن الطلب اتوصّل؟'**
  String get courierActionDeliveredConfirmTitle;

  /// No description provided for @courierActionDeliveredConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'مش هتقدر ترجّعها بعد كده.'**
  String get courierActionDeliveredConfirmBody;

  /// No description provided for @financeTitle.
  ///
  /// In ar, this message translates to:
  /// **'المالية'**
  String get financeTitle;

  /// No description provided for @financeLedgerNote.
  ///
  /// In ar, this message translates to:
  /// **'أرقام دفترية — التحصيل يتم يدويًا مع المتاجر'**
  String get financeLedgerNote;

  /// No description provided for @financeTotalOrders.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الطلبات'**
  String get financeTotalOrders;

  /// No description provided for @financeDeliveredOrders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المُسلّمة'**
  String get financeDeliveredOrders;

  /// No description provided for @financeCancelledOrders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات الملغاة'**
  String get financeCancelledOrders;

  /// No description provided for @financeTotalCommission.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي العمولات'**
  String get financeTotalCommission;

  /// No description provided for @financeDeliveryRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إيراد التوصيل'**
  String get financeDeliveryRevenue;

  /// No description provided for @financeTotalPlatformRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي إيراد المنصة'**
  String get financeTotalPlatformRevenue;

  /// No description provided for @financeErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نجيب أرقام المالية دلوقتي — جرّب تاني'**
  String get financeErrorBody;

  /// No description provided for @consoleTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get consoleTitle;

  /// No description provided for @consoleNavDashboard.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get consoleNavDashboard;

  /// No description provided for @consoleNavAudit.
  ///
  /// In ar, this message translates to:
  /// **'سجل العمليات'**
  String get consoleNavAudit;

  /// No description provided for @consoleNavUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمين'**
  String get consoleNavUsers;

  /// No description provided for @consoleDashboardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة على المنصة هتظهر هنا قريب.'**
  String get consoleDashboardSubtitle;

  /// No description provided for @consoleComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'القسم ده جاي قريب.'**
  String get consoleComingSoon;

  /// No description provided for @settingsConsoleRow.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get settingsConsoleRow;

  /// No description provided for @roleFounder.
  ///
  /// In ar, this message translates to:
  /// **'المؤسس'**
  String get roleFounder;

  /// No description provided for @roleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مشرف عام'**
  String get roleAdmin;

  /// No description provided for @roleModerator.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get roleModerator;

  /// No description provided for @roleSupport.
  ///
  /// In ar, this message translates to:
  /// **'دعم'**
  String get roleSupport;

  /// No description provided for @auditFilterAction.
  ///
  /// In ar, this message translates to:
  /// **'العملية'**
  String get auditFilterAction;

  /// No description provided for @auditFilterType.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get auditFilterType;

  /// No description provided for @auditFilterTargetId.
  ///
  /// In ar, this message translates to:
  /// **'معرّف العنصر'**
  String get auditFilterTargetId;

  /// No description provided for @auditFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get auditFilterAll;

  /// No description provided for @auditFilterDateRange.
  ///
  /// In ar, this message translates to:
  /// **'الفترة'**
  String get auditFilterDateRange;

  /// No description provided for @auditFilterClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح الفلاتر'**
  String get auditFilterClear;

  /// No description provided for @auditReported.
  ///
  /// In ar, this message translates to:
  /// **'مُبلَّغ'**
  String get auditReported;

  /// No description provided for @auditLoadMore.
  ///
  /// In ar, this message translates to:
  /// **'حمّل المزيد'**
  String get auditLoadMore;

  /// No description provided for @auditEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش عمليات'**
  String get auditEmptyTitle;

  /// No description provided for @auditEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'أي عملية بتحصل في المنصة هتظهر هنا.'**
  String get auditEmptyBody;

  /// No description provided for @auditErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نجيب السجل دلوقتي — جرّب تاني'**
  String get auditErrorBody;

  /// No description provided for @auditDetailTarget.
  ///
  /// In ar, this message translates to:
  /// **'العنصر'**
  String get auditDetailTarget;

  /// No description provided for @auditDetailActor.
  ///
  /// In ar, this message translates to:
  /// **'نفّذها'**
  String get auditDetailActor;

  /// No description provided for @auditDetailWhen.
  ///
  /// In ar, this message translates to:
  /// **'التوقيت'**
  String get auditDetailWhen;

  /// No description provided for @auditDetailReason.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get auditDetailReason;

  /// No description provided for @auditDetailIp.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الـ IP'**
  String get auditDetailIp;

  /// No description provided for @auditDetailChanges.
  ///
  /// In ar, this message translates to:
  /// **'التغييرات'**
  String get auditDetailChanges;

  /// No description provided for @auditDetailField.
  ///
  /// In ar, this message translates to:
  /// **'الحقل'**
  String get auditDetailField;

  /// No description provided for @auditDetailBefore.
  ///
  /// In ar, this message translates to:
  /// **'قبل'**
  String get auditDetailBefore;

  /// No description provided for @auditDetailAfter.
  ///
  /// In ar, this message translates to:
  /// **'بعد'**
  String get auditDetailAfter;

  /// No description provided for @auditDetailNoChanges.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تغييرات متسجّلة.'**
  String get auditDetailNoChanges;

  /// No description provided for @auditTimeJustNow.
  ///
  /// In ar, this message translates to:
  /// **'دلوقتي'**
  String get auditTimeJustNow;

  /// No description provided for @auditTimeMinutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'من {count} د'**
  String auditTimeMinutesAgo(int count);

  /// No description provided for @auditTimeHoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'من {count} س'**
  String auditTimeHoursAgo(int count);

  /// No description provided for @auditTimeDaysAgo.
  ///
  /// In ar, this message translates to:
  /// **'من {count} ي'**
  String auditTimeDaysAgo(int count);

  /// No description provided for @dashboardOrdersToday.
  ///
  /// In ar, this message translates to:
  /// **'طلبات النهارده'**
  String get dashboardOrdersToday;

  /// No description provided for @dashboardRevenueToday.
  ///
  /// In ar, this message translates to:
  /// **'إيراد النهارده'**
  String get dashboardRevenueToday;

  /// No description provided for @dashboardCommissionToday.
  ///
  /// In ar, this message translates to:
  /// **'عمولة النهارده'**
  String get dashboardCommissionToday;

  /// No description provided for @dashboardOrdersWaiting.
  ///
  /// In ar, this message translates to:
  /// **'طلبات مستنية'**
  String get dashboardOrdersWaiting;

  /// No description provided for @dashboardTotalUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمين'**
  String get dashboardTotalUsers;

  /// No description provided for @dashboardTotalShops.
  ///
  /// In ar, this message translates to:
  /// **'الدكاكين'**
  String get dashboardTotalShops;

  /// No description provided for @dashboardTotalProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get dashboardTotalProducts;

  /// No description provided for @dashboardDriversOnline.
  ///
  /// In ar, this message translates to:
  /// **'مناديب أونلاين'**
  String get dashboardDriversOnline;

  /// No description provided for @dashboardPendingShops.
  ///
  /// In ar, this message translates to:
  /// **'دكاكين مستنية موافقة'**
  String get dashboardPendingShops;

  /// No description provided for @dashboardFailedNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات فشلت (٧ أيام)'**
  String get dashboardFailedNotifications;

  /// No description provided for @dashboardChartTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات آخر ٧ أيام'**
  String get dashboardChartTitle;

  /// No description provided for @dashboardActivityTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر العمليات'**
  String get dashboardActivityTitle;

  /// No description provided for @dashboardViewAll.
  ///
  /// In ar, this message translates to:
  /// **'شوف الكل'**
  String get dashboardViewAll;

  /// No description provided for @dashboardActivityEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش عمليات جديدة.'**
  String get dashboardActivityEmpty;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardQuickAudit.
  ///
  /// In ar, this message translates to:
  /// **'افتح سجل العمليات'**
  String get dashboardQuickAudit;

  /// No description provided for @dashboardExternalTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدوات خارجية'**
  String get dashboardExternalTitle;

  /// No description provided for @dashboardCrashlyticsTitle.
  ///
  /// In ar, this message translates to:
  /// **'Crashlytics'**
  String get dashboardCrashlyticsTitle;

  /// No description provided for @dashboardCrashlyticsNote.
  ///
  /// In ar, this message translates to:
  /// **'تقارير الأعطال بتتفتح في Firebase Console.'**
  String get dashboardCrashlyticsNote;

  /// No description provided for @dashboardErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نجيب أرقام اللوحة دلوقتي — جرّب تاني'**
  String get dashboardErrorBody;

  /// No description provided for @usersErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نجيب قائمة المستخدمين دلوقتي — جرّب تاني'**
  String get usersErrorBody;

  /// No description provided for @usersEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مستخدمين'**
  String get usersEmptyTitle;

  /// No description provided for @usersEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'جرّب بحث أو فلتر تاني.'**
  String get usersEmptyBody;

  /// No description provided for @usersSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get usersSearchLabel;

  /// No description provided for @usersSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'إيميل أو رقم بالظبط، أو اسم في الصفحة دي'**
  String get usersSearchHint;

  /// No description provided for @usersFilterRole.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get usersFilterRole;

  /// No description provided for @usersFilterStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get usersFilterStatus;

  /// No description provided for @usersRoleCustomer.
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get usersRoleCustomer;

  /// No description provided for @usersRoleOwner.
  ///
  /// In ar, this message translates to:
  /// **'صاحب دكان'**
  String get usersRoleOwner;

  /// No description provided for @usersRoleCourier.
  ///
  /// In ar, this message translates to:
  /// **'مندوب'**
  String get usersRoleCourier;

  /// No description provided for @usersStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get usersStatusActive;

  /// No description provided for @usersStatusSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get usersStatusSuspended;

  /// No description provided for @usersStatusBanned.
  ///
  /// In ar, this message translates to:
  /// **'محظور'**
  String get usersStatusBanned;

  /// No description provided for @usersDeletedLabel.
  ///
  /// In ar, this message translates to:
  /// **'متمسح'**
  String get usersDeletedLabel;

  /// No description provided for @usersSelectedCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} متحدد'**
  String usersSelectedCount(int count);

  /// No description provided for @usersBulkSuspend.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get usersBulkSuspend;

  /// No description provided for @usersBulkUnsuspend.
  ///
  /// In ar, this message translates to:
  /// **'رجّعه نشط'**
  String get usersBulkUnsuspend;

  /// No description provided for @usersBulkConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'إجراء جماعي'**
  String get usersBulkConfirmTitle;

  /// No description provided for @usersBulkConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'{action} للمستخدمين المحددين؟'**
  String usersBulkConfirmBody(Object action);

  /// No description provided for @usersBulkSummary.
  ///
  /// In ar, this message translates to:
  /// **'{done}/{total} تم'**
  String usersBulkSummary(int done, int total);

  /// No description provided for @userDetailMissingSeed.
  ///
  /// In ar, this message translates to:
  /// **'افتح الصفحة دي من قائمة المستخدمين — مفيش حاجة تتعرض هنا لسه.'**
  String get userDetailMissingSeed;

  /// No description provided for @userDetailBackToList.
  ///
  /// In ar, this message translates to:
  /// **'رجوع للمستخدمين'**
  String get userDetailBackToList;

  /// No description provided for @userDetailActionOk.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get userDetailActionOk;

  /// No description provided for @userDetailActionFailed.
  ///
  /// In ar, this message translates to:
  /// **'الحاجة دي متنفذتش — جرّب تاني'**
  String get userDetailActionFailed;

  /// No description provided for @userDetailProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get userDetailProfileTitle;

  /// No description provided for @userDetailEmail.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل'**
  String get userDetailEmail;

  /// No description provided for @userDetailPhone.
  ///
  /// In ar, this message translates to:
  /// **'الموبايل'**
  String get userDetailPhone;

  /// No description provided for @userDetailMemberSince.
  ///
  /// In ar, this message translates to:
  /// **'عضو من'**
  String get userDetailMemberSince;

  /// No description provided for @userDetailUnknown.
  ///
  /// In ar, this message translates to:
  /// **'مش معروف'**
  String get userDetailUnknown;

  /// No description provided for @userDetailActionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات'**
  String get userDetailActionsTitle;

  /// No description provided for @userDetailBan.
  ///
  /// In ar, this message translates to:
  /// **'حظر'**
  String get userDetailBan;

  /// No description provided for @userDetailConfirmSuspend.
  ///
  /// In ar, this message translates to:
  /// **'توقف الحساب ده مؤقتًا؟ مش هيقدر يسجل دخول لحد ما ترجّعه.'**
  String get userDetailConfirmSuspend;

  /// No description provided for @userDetailConfirmBan.
  ///
  /// In ar, this message translates to:
  /// **'تحظر الحساب ده؟ ده أشد من الإيقاف المؤقت.'**
  String get userDetailConfirmBan;

  /// No description provided for @userDetailConfirmPasswordReset.
  ///
  /// In ar, this message translates to:
  /// **'تبعت إيميل استرجاع كلمة السر للحساب ده؟'**
  String get userDetailConfirmPasswordReset;

  /// No description provided for @userDetailSendPasswordReset.
  ///
  /// In ar, this message translates to:
  /// **'ابعت استرجاع كلمة السر'**
  String get userDetailSendPasswordReset;

  /// No description provided for @userDetailChangeEmail.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الإيميل'**
  String get userDetailChangeEmail;

  /// No description provided for @userDetailSetPersonaRole.
  ///
  /// In ar, this message translates to:
  /// **'غيّر نوع الحساب'**
  String get userDetailSetPersonaRole;

  /// No description provided for @userDetailConfirmSoftDelete.
  ///
  /// In ar, this message translates to:
  /// **'تعطّل الحساب ده؟ ده قابل للاسترجاع تاني.'**
  String get userDetailConfirmSoftDelete;

  /// No description provided for @userDetailSoftDelete.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل'**
  String get userDetailSoftDelete;

  /// No description provided for @userDetailRestore.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع'**
  String get userDetailRestore;

  /// No description provided for @userDetailAuthTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدخول'**
  String get userDetailAuthTitle;

  /// No description provided for @userDetailEmailVerified.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل متأكد'**
  String get userDetailEmailVerified;

  /// No description provided for @userDetailAuthDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الدخول متعطل'**
  String get userDetailAuthDisabled;

  /// No description provided for @userDetailYes.
  ///
  /// In ar, this message translates to:
  /// **'أيوه'**
  String get userDetailYes;

  /// No description provided for @userDetailNo.
  ///
  /// In ar, this message translates to:
  /// **'لأ'**
  String get userDetailNo;

  /// No description provided for @userDetailLastLogin.
  ///
  /// In ar, this message translates to:
  /// **'آخر دخول'**
  String get userDetailLastLogin;

  /// No description provided for @userDetailStaffTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفريق الإداري'**
  String get userDetailStaffTitle;

  /// No description provided for @userDetailNotStaff.
  ///
  /// In ar, this message translates to:
  /// **'مش من فريق العمل.'**
  String get userDetailNotStaff;

  /// No description provided for @userDetailStaffRole.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة الإدارية'**
  String get userDetailStaffRole;

  /// No description provided for @userDetailStaffPermissions.
  ///
  /// In ar, this message translates to:
  /// **'الصلاحيات'**
  String get userDetailStaffPermissions;

  /// No description provided for @userDetailMakeStaff.
  ///
  /// In ar, this message translates to:
  /// **'ضمّه للفريق'**
  String get userDetailMakeStaff;

  /// No description provided for @userDetailEditStaff.
  ///
  /// In ar, this message translates to:
  /// **'تعديل صلاحياته'**
  String get userDetailEditStaff;

  /// No description provided for @userDetailRemoveStaff.
  ///
  /// In ar, this message translates to:
  /// **'شيله من الفريق'**
  String get userDetailRemoveStaff;

  /// No description provided for @userDetailExtraPermissionsHint.
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات إضافية، فوق صلاحيات الدرجة نفسها:'**
  String get userDetailExtraPermissionsHint;

  /// No description provided for @userDetailShopsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدكان'**
  String get userDetailShopsTitle;

  /// No description provided for @userDetailNoShop.
  ///
  /// In ar, this message translates to:
  /// **'مفيش دكان ليه.'**
  String get userDetailNoShop;

  /// No description provided for @userDetailOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get userDetailOrdersTitle;

  /// No description provided for @userDetailNoOrders.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش طلبات.'**
  String get userDetailNoOrders;

  /// No description provided for @userDetailAuditTitle.
  ///
  /// In ar, this message translates to:
  /// **'النشاط'**
  String get userDetailAuditTitle;

  /// No description provided for @catalogPendingBannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحت المراجعة'**
  String get catalogPendingBannerTitle;

  /// No description provided for @catalogPendingBannerBody.
  ///
  /// In ar, this message translates to:
  /// **'دكانك لسه مش ظاهر للعملاء — الفريق بيراجعه دلوقتي.'**
  String get catalogPendingBannerBody;

  /// No description provided for @consoleNavShops.
  ///
  /// In ar, this message translates to:
  /// **'الدكاكين'**
  String get consoleNavShops;

  /// No description provided for @shopsBoardSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'دور بالاسم'**
  String get shopsBoardSearchLabel;

  /// No description provided for @shopsBoardCreateAction.
  ///
  /// In ar, this message translates to:
  /// **'دكان جديد'**
  String get shopsBoardCreateAction;

  /// No description provided for @shopsBoardErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجيب قائمة الدكاكين — جرب تاني.'**
  String get shopsBoardErrorBody;

  /// No description provided for @shopsBoardEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش دكاكين مطابقة'**
  String get shopsBoardEmptyTitle;

  /// No description provided for @shopsBoardEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'جرب فلتر تاني أو دور بكلمة مختلفة.'**
  String get shopsBoardEmptyBody;

  /// No description provided for @shopsBoardOwnerLabel.
  ///
  /// In ar, this message translates to:
  /// **'المالك: {ownerUid}'**
  String shopsBoardOwnerLabel(Object ownerUid);

  /// No description provided for @shopsFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get shopsFilterAll;

  /// No description provided for @shopsStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'تحت المراجعة'**
  String get shopsStatusPending;

  /// No description provided for @shopsStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get shopsStatusActive;

  /// No description provided for @shopsStatusSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get shopsStatusSuspended;

  /// No description provided for @shopsStatusDeleted.
  ///
  /// In ar, this message translates to:
  /// **'محذوف'**
  String get shopsStatusDeleted;

  /// No description provided for @shopsFeaturedBadge.
  ///
  /// In ar, this message translates to:
  /// **'مميّز'**
  String get shopsFeaturedBadge;

  /// No description provided for @shopsVerifiedBadge.
  ///
  /// In ar, this message translates to:
  /// **'مُوثّق'**
  String get shopsVerifiedBadge;

  /// No description provided for @shopDetailMissingSeed.
  ///
  /// In ar, this message translates to:
  /// **'افتح الصفحة دي من قائمة الدكاكين — لسه مفيش حاجة تتعرض.'**
  String get shopDetailMissingSeed;

  /// No description provided for @shopDetailStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get shopDetailStatusTitle;

  /// No description provided for @shopDetailApprove.
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get shopDetailApprove;

  /// No description provided for @shopDetailConfirmApprove.
  ///
  /// In ar, this message translates to:
  /// **'توافق على الدكان ده؟ هيبقى ظاهر للعملاء.'**
  String get shopDetailConfirmApprove;

  /// No description provided for @shopDetailReject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get shopDetailReject;

  /// No description provided for @shopDetailRejectReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'السبب (بيتسجل في سجل النشاط)'**
  String get shopDetailRejectReasonLabel;

  /// No description provided for @shopDetailSuspend.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get shopDetailSuspend;

  /// No description provided for @shopDetailConfirmSuspend.
  ///
  /// In ar, this message translates to:
  /// **'توقف الدكان ده؟ هيختفي من عند العملاء فورًا.'**
  String get shopDetailConfirmSuspend;

  /// No description provided for @shopDetailUnsuspend.
  ///
  /// In ar, this message translates to:
  /// **'رجّعه تاني'**
  String get shopDetailUnsuspend;

  /// No description provided for @shopDetailFieldsTitle.
  ///
  /// In ar, this message translates to:
  /// **'البيانات'**
  String get shopDetailFieldsTitle;

  /// No description provided for @shopDetailHoursNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة مواعيد العمل (اختياري)'**
  String get shopDetailHoursNoteLabel;

  /// No description provided for @shopDetailTransferTitle.
  ///
  /// In ar, this message translates to:
  /// **'نقل الملكية'**
  String get shopDetailTransferTitle;

  /// No description provided for @shopDetailTransferHint.
  ///
  /// In ar, this message translates to:
  /// **'بينقل الدكان لمالك تاني. لازم يكون عنده حساب مالك أصلاً.'**
  String get shopDetailTransferHint;

  /// No description provided for @shopDetailNewOwnerUidLabel.
  ///
  /// In ar, this message translates to:
  /// **'معرّف المستخدم للمالك الجديد'**
  String get shopDetailNewOwnerUidLabel;

  /// No description provided for @shopDetailTransferAction.
  ///
  /// In ar, this message translates to:
  /// **'نقل'**
  String get shopDetailTransferAction;

  /// No description provided for @shopDetailConfirmTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تنقل الدكان ده للمستخدم {newOwnerUid}؟ الخطوة دي مش هترجع من هنا.'**
  String shopDetailConfirmTransfer(Object newOwnerUid);

  /// No description provided for @shopTransferOldOwnerHint.
  ///
  /// In ar, this message translates to:
  /// **'المالك القديم لسه دوره مالك من غير دكان — عدّل حسابه من إدارة المستخدمين لو محتاج.'**
  String get shopTransferOldOwnerHint;

  /// No description provided for @shopDetailDangerTitle.
  ///
  /// In ar, this message translates to:
  /// **'منطقة خطر'**
  String get shopDetailDangerTitle;

  /// No description provided for @shopDetailConfirmSoftDelete.
  ///
  /// In ar, this message translates to:
  /// **'تشيل الدكان ده؟ ممكن ترجّعه تاني بعدين.'**
  String get shopDetailConfirmSoftDelete;

  /// No description provided for @shopDetailShortcutsTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختصارات'**
  String get shopDetailShortcutsTitle;

  /// No description provided for @shopCreateOwnerTitle.
  ///
  /// In ar, this message translates to:
  /// **'المالك'**
  String get shopCreateOwnerTitle;

  /// No description provided for @shopCreateOwnerEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'إيميل المالك'**
  String get shopCreateOwnerEmailLabel;

  /// No description provided for @shopCreateOwnerNotFound.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مستخدم بالإيميل ده.'**
  String get shopCreateOwnerNotFound;

  /// No description provided for @shopCreateOwnerNotOwnerRole.
  ///
  /// In ar, this message translates to:
  /// **'الحساب ده مش حساب مالك.'**
  String get shopCreateOwnerNotOwnerRole;

  /// No description provided for @shopCreateOwnerRequired.
  ///
  /// In ar, this message translates to:
  /// **'دور على المالك الأول.'**
  String get shopCreateOwnerRequired;

  /// No description provided for @consoleNavProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get consoleNavProducts;

  /// No description provided for @productsBoardSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'دور بالاسم'**
  String get productsBoardSearchLabel;

  /// No description provided for @productsBoardErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نجيب قايمة المنتجات دلوقتي — جرّب تاني.'**
  String get productsBoardErrorBody;

  /// No description provided for @productsBoardEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش منتجات مطابقة'**
  String get productsBoardEmptyTitle;

  /// No description provided for @productsBoardEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'جرّب فلتر أو بحث تاني.'**
  String get productsBoardEmptyBody;

  /// No description provided for @productsBoardActionFailed.
  ///
  /// In ar, this message translates to:
  /// **'الحركة دي معملتش — جرّب تاني.'**
  String get productsBoardActionFailed;

  /// No description provided for @productsBoardFilterShop.
  ///
  /// In ar, this message translates to:
  /// **'الدكان'**
  String get productsBoardFilterShop;

  /// No description provided for @productsBoardDeletedOnly.
  ///
  /// In ar, this message translates to:
  /// **'متشال'**
  String get productsBoardDeletedOnly;

  /// No description provided for @productsBoardDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get productsBoardDuplicate;

  /// No description provided for @productsBoardSoftDelete.
  ///
  /// In ar, this message translates to:
  /// **'شيل'**
  String get productsBoardSoftDelete;

  /// No description provided for @productsBoardRestore.
  ///
  /// In ar, this message translates to:
  /// **'رجّع'**
  String get productsBoardRestore;

  /// No description provided for @productsBoardHardDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي'**
  String get productsBoardHardDelete;

  /// No description provided for @productsBoardConfirmSoftDelete.
  ///
  /// In ar, this message translates to:
  /// **'تشيل المنتج ده؟ ممكن ترجّعه تاني بعدين.'**
  String get productsBoardConfirmSoftDelete;

  /// No description provided for @productsBoardHardDeleteWarning.
  ///
  /// In ar, this message translates to:
  /// **'الحركة دي هتمسح \"{name}\" نهائي — مش هترجع تاني. اكتب اسم المنتج علشان تأكد.'**
  String productsBoardHardDeleteWarning(Object name);

  /// No description provided for @productsBoardTypeNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج'**
  String get productsBoardTypeNameLabel;

  /// No description provided for @productsBoardSelectedCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} متحدد'**
  String productsBoardSelectedCount(Object count);

  /// No description provided for @productsBoardBulkAction.
  ///
  /// In ar, this message translates to:
  /// **'حركة جماعية'**
  String get productsBoardBulkAction;

  /// No description provided for @productsBoardBulkPrice.
  ///
  /// In ar, this message translates to:
  /// **'تغيير السعر'**
  String get productsBoardBulkPrice;

  /// No description provided for @productsBoardBulkStock.
  ///
  /// In ar, this message translates to:
  /// **'تحديد حالة المخزون'**
  String get productsBoardBulkStock;

  /// No description provided for @productsBoardBulkPromo.
  ///
  /// In ar, this message translates to:
  /// **'علامة العرض'**
  String get productsBoardBulkPromo;

  /// No description provided for @productsBoardBulkCategory.
  ///
  /// In ar, this message translates to:
  /// **'نقل القسم'**
  String get productsBoardBulkCategory;

  /// No description provided for @productsBoardBulkPricePercent.
  ///
  /// In ar, this message translates to:
  /// **'نسبة مئوية'**
  String get productsBoardBulkPricePercent;

  /// No description provided for @productsBoardBulkPriceFixed.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ ثابت'**
  String get productsBoardBulkPriceFixed;

  /// No description provided for @productsBoardBulkPriceIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زيادة'**
  String get productsBoardBulkPriceIncrease;

  /// No description provided for @productsBoardBulkPriceDecrease.
  ///
  /// In ar, this message translates to:
  /// **'تخفيض'**
  String get productsBoardBulkPriceDecrease;

  /// No description provided for @productsBoardBulkPricePercentLabel.
  ///
  /// In ar, this message translates to:
  /// **'النسبة'**
  String get productsBoardBulkPricePercentLabel;

  /// No description provided for @productsBoardBulkPriceFixedLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ (جنيه)'**
  String get productsBoardBulkPriceFixedLabel;

  /// No description provided for @consoleNavTaxonomy.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get consoleNavTaxonomy;

  /// No description provided for @consoleNavGeo.
  ///
  /// In ar, this message translates to:
  /// **'مناطق التوصيل'**
  String get consoleNavGeo;

  /// No description provided for @fieldCategoryNameAr.
  ///
  /// In ar, this message translates to:
  /// **'اسم القسم (عربي)'**
  String get fieldCategoryNameAr;

  /// No description provided for @fieldCategoryNameEn.
  ///
  /// In ar, this message translates to:
  /// **'اسم القسم (إنجليزي)'**
  String get fieldCategoryNameEn;

  /// No description provided for @fieldAreaNameAr.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنطقة (عربي)'**
  String get fieldAreaNameAr;

  /// No description provided for @fieldAreaNameEn.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنطقة (إنجليزي)'**
  String get fieldAreaNameEn;

  /// No description provided for @fieldGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get fieldGovernorate;

  /// No description provided for @fieldDeliveryFeeOverrideOptional.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رسوم التوصيل (اختياري)'**
  String get fieldDeliveryFeeOverrideOptional;

  /// No description provided for @validateAmountInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ صحيح'**
  String get validateAmountInvalid;

  /// No description provided for @taxonomyBoardHint.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام اللي بتظهر للعملاء وأصحاب الدكاكين. لو متردد، إخفاء أحسن من مسح.'**
  String get taxonomyBoardHint;

  /// No description provided for @taxonomyBoardAddAction.
  ///
  /// In ar, this message translates to:
  /// **'قسم جديد'**
  String get taxonomyBoardAddAction;

  /// No description provided for @taxonomyBoardErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجيب الأقسام دلوقتي — جرّب تاني.'**
  String get taxonomyBoardErrorBody;

  /// No description provided for @taxonomyBoardEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش أقسام'**
  String get taxonomyBoardEmptyTitle;

  /// No description provided for @taxonomyBoardActionFailed.
  ///
  /// In ar, this message translates to:
  /// **'الحركة دي معملتش — جرّب تاني.'**
  String get taxonomyBoardActionFailed;

  /// No description provided for @taxonomyBoardHide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get taxonomyBoardHide;

  /// No description provided for @taxonomyBoardShow.
  ///
  /// In ar, this message translates to:
  /// **'إظهار'**
  String get taxonomyBoardShow;

  /// No description provided for @taxonomyBoardEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل القسم'**
  String get taxonomyBoardEditTitle;

  /// No description provided for @taxonomyBoardIconLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأيقونة'**
  String get taxonomyBoardIconLabel;

  /// No description provided for @taxonomyBoardDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمسح القسم؟'**
  String get taxonomyBoardDeleteConfirmTitle;

  /// No description provided for @taxonomyBoardDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'الحركة دي مش هترجع.'**
  String get taxonomyBoardDeleteConfirmBody;

  /// No description provided for @taxonomyBoardDeleteConfirmBodyWithProducts.
  ///
  /// In ar, this message translates to:
  /// **'{count} منتج لسه بيستخدم القسم ده — هيفضلوا ظاهرين، بس الحركة دي مش هترجع. تمسح برضو؟'**
  String taxonomyBoardDeleteConfirmBodyWithProducts(Object count);

  /// No description provided for @geoBoardHint.
  ///
  /// In ar, this message translates to:
  /// **'مناطق التوصيل اللي بتظهر في الشيك أوت. لو متردد، إيقاف أحسن من مسح.'**
  String get geoBoardHint;

  /// No description provided for @geoBoardAddAction.
  ///
  /// In ar, this message translates to:
  /// **'منطقة جديدة'**
  String get geoBoardAddAction;

  /// No description provided for @geoBoardErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجيب المناطق دلوقتي — جرّب تاني.'**
  String get geoBoardErrorBody;

  /// No description provided for @geoBoardEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش مناطق'**
  String get geoBoardEmptyTitle;

  /// No description provided for @geoBoardActionFailed.
  ///
  /// In ar, this message translates to:
  /// **'الحركة دي معملتش — جرّب تاني.'**
  String get geoBoardActionFailed;

  /// No description provided for @geoBoardEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنطقة'**
  String get geoBoardEditTitle;

  /// No description provided for @geoBoardFeeOverrideBadge.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرسوم: {fee}'**
  String geoBoardFeeOverrideBadge(Object fee);

  /// No description provided for @geoBoardDeactivateInsteadTitle.
  ///
  /// In ar, this message translates to:
  /// **'توقف المنطقة بدل ما تتمسح؟'**
  String get geoBoardDeactivateInsteadTitle;

  /// No description provided for @geoBoardDeactivateInsteadBody.
  ///
  /// In ar, this message translates to:
  /// **'{count} طلب بيستخدم المنطقة دي — مينفعش تتمسح، بس ممكن توقفها فتختفي من الشيك أوت.'**
  String geoBoardDeactivateInsteadBody(Object count);

  /// No description provided for @geoBoardDeactivateAction.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get geoBoardDeactivateAction;

  /// No description provided for @geoBoardDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمسح المنطقة؟'**
  String get geoBoardDeleteConfirmTitle;

  /// No description provided for @geoBoardDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'الحركة دي مش هترجع.'**
  String get geoBoardDeleteConfirmBody;

  /// No description provided for @consoleNavOrders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get consoleNavOrders;

  /// No description provided for @dashboardQuickOrdersWaiting.
  ///
  /// In ar, this message translates to:
  /// **'طلبات مستنية'**
  String get dashboardQuickOrdersWaiting;

  /// No description provided for @ordersBoardSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب أو رقم الموبايل بالظبط'**
  String get ordersBoardSearchLabel;

  /// No description provided for @ordersBoardErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجيب قائمة الطلبات دلوقتي — جرّب تاني.'**
  String get ordersBoardErrorBody;

  /// No description provided for @ordersBoardEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طلبات مطابقة'**
  String get ordersBoardEmptyTitle;

  /// No description provided for @ordersBoardEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'جرّب فلتر أو بحث تاني.'**
  String get ordersBoardEmptyBody;

  /// No description provided for @ordersBoardShopLabel.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get ordersBoardShopLabel;

  /// No description provided for @ordersBoardAreaLabel.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get ordersBoardAreaLabel;

  /// No description provided for @ordersBoardDateRangeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الفترة الزمنية'**
  String get ordersBoardDateRangeLabel;

  /// No description provided for @ordersBoardNoDriver.
  ///
  /// In ar, this message translates to:
  /// **'بدون مندوب'**
  String get ordersBoardNoDriver;

  /// No description provided for @consoleNavDrivers.
  ///
  /// In ar, this message translates to:
  /// **'المناديب'**
  String get consoleNavDrivers;

  /// No description provided for @driversBoardErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجيب قايمة المناديب دلوقتي — جرّب تاني.'**
  String get driversBoardErrorBody;

  /// No description provided for @driversBoardEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مناديب مطابقين'**
  String get driversBoardEmptyTitle;

  /// No description provided for @driversBoardEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'جرّب فلتر تاني.'**
  String get driversBoardEmptyBody;

  /// No description provided for @driversFilterPendingActivation.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار التفعيل'**
  String get driversFilterPendingActivation;

  /// No description provided for @driversFilterActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get driversFilterActive;

  /// No description provided for @driversFilterSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get driversFilterSuspended;

  /// No description provided for @driversFilterOnline.
  ///
  /// In ar, this message translates to:
  /// **'متصل الآن'**
  String get driversFilterOnline;

  /// No description provided for @driverDetailMissingSeed.
  ///
  /// In ar, this message translates to:
  /// **'افتح صفحة المندوب من القايمة.'**
  String get driverDetailMissingSeed;

  /// No description provided for @driverDetailStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get driverDetailStatusTitle;

  /// No description provided for @driverDetailActiveSwitch.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get driverDetailActiveSwitch;

  /// No description provided for @driverDetailVerifiedSwitch.
  ///
  /// In ar, this message translates to:
  /// **'موثّق'**
  String get driverDetailVerifiedSwitch;

  /// No description provided for @driverDetailVerifiedBadge.
  ///
  /// In ar, this message translates to:
  /// **'موثّق'**
  String get driverDetailVerifiedBadge;

  /// No description provided for @driverDetailSuspendTitle.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف المندوب'**
  String get driverDetailSuspendTitle;

  /// No description provided for @driverDetailSuspendReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإيقاف'**
  String get driverDetailSuspendReasonLabel;

  /// No description provided for @driverDetailFieldsTitle.
  ///
  /// In ar, this message translates to:
  /// **'البيانات'**
  String get driverDetailFieldsTitle;

  /// No description provided for @fieldDriverName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get fieldDriverName;

  /// No description provided for @fieldDriverPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get fieldDriverPhone;

  /// No description provided for @driverDetailAreasLabel.
  ///
  /// In ar, this message translates to:
  /// **'مناطق التوصيل'**
  String get driverDetailAreasLabel;

  /// No description provided for @driverDetailMaxActiveOrdersLabel.
  ///
  /// In ar, this message translates to:
  /// **'أقصى عدد طلبات في نفس الوقت'**
  String get driverDetailMaxActiveOrdersLabel;

  /// No description provided for @driverDetailVehicleTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع المركبة'**
  String get driverDetailVehicleTypeLabel;

  /// No description provided for @driverDetailVehiclePlateLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم اللوحة'**
  String get driverDetailVehiclePlateLabel;

  /// No description provided for @driverDetailIdDocLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة إثبات الشخصية'**
  String get driverDetailIdDocLabel;

  /// No description provided for @driverDetailIdDocUploadError.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نرفع الصورة — جرّب تاني.'**
  String get driverDetailIdDocUploadError;

  /// No description provided for @driverDetailPerformanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأداء'**
  String get driverDetailPerformanceTitle;

  /// No description provided for @driverDetailActiveLoad.
  ///
  /// In ar, this message translates to:
  /// **'الحمل الحالي'**
  String get driverDetailActiveLoad;

  /// No description provided for @driverDetailDeliveredThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'التوصيلات الشهر ده'**
  String get driverDetailDeliveredThisMonth;

  /// No description provided for @driverDetailDeliveredTotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي التوصيلات'**
  String get driverDetailDeliveredTotal;

  /// No description provided for @driverDetailAssignedOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات الحالية'**
  String get driverDetailAssignedOrdersTitle;

  /// No description provided for @driverDetailNoAssignedOrders.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طلبات معاه دلوقتي.'**
  String get driverDetailNoAssignedOrders;

  /// No description provided for @consoleNavSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get consoleNavSettings;

  /// No description provided for @consoleNavNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get consoleNavNotifications;

  /// No description provided for @settingsSaveOk.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get settingsSaveOk;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة في الحفظ — جرّب تاني'**
  String get settingsSaveFailed;

  /// No description provided for @settingsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب الإعدادات دلوقتي — جرّب تاني'**
  String get settingsLoadError;

  /// No description provided for @settingsLastEdited.
  ///
  /// In ar, this message translates to:
  /// **'آخر تعديل {when}'**
  String settingsLastEdited(Object when);

  /// No description provided for @settingsFooterNote.
  ///
  /// In ar, this message translates to:
  /// **'التغييرات بتتطبق على الطلبات الجديدة وأول ما التطبيق يتفتح تاني'**
  String get settingsFooterNote;

  /// No description provided for @settingsRatesTitle.
  ///
  /// In ar, this message translates to:
  /// **'العمولة والتوصيل'**
  String get settingsRatesTitle;

  /// No description provided for @settingsCommissionLabel.
  ///
  /// In ar, this message translates to:
  /// **'العمولة (%)'**
  String get settingsCommissionLabel;

  /// No description provided for @settingsVatLabel.
  ///
  /// In ar, this message translates to:
  /// **'الضريبة (%)'**
  String get settingsVatLabel;

  /// No description provided for @settingsDeliveryFeeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل (جنيه)'**
  String get settingsDeliveryFeeLabel;

  /// No description provided for @settingsDriverShareLabel.
  ///
  /// In ar, this message translates to:
  /// **'نصيب السائق (جنيه)'**
  String get settingsDriverShareLabel;

  /// No description provided for @settingsMinOrderLabel.
  ///
  /// In ar, this message translates to:
  /// **'أقل قيمة للطلب (جنيه)'**
  String get settingsMinOrderLabel;

  /// No description provided for @settingsDriverShareTooHigh.
  ///
  /// In ar, this message translates to:
  /// **'نصيب السائق مينفعش يبقى أكتر من رسوم التوصيل'**
  String get settingsDriverShareTooHigh;

  /// No description provided for @settingsContactTitle.
  ///
  /// In ar, this message translates to:
  /// **'التواصل'**
  String get settingsContactTitle;

  /// No description provided for @settingsSupportPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'تليفون الدعم'**
  String get settingsSupportPhoneLabel;

  /// No description provided for @settingsSupportWhatsAppLabel.
  ///
  /// In ar, this message translates to:
  /// **'واتساب الدعم'**
  String get settingsSupportWhatsAppLabel;

  /// No description provided for @settingsBusinessHoursLabel.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد العمل'**
  String get settingsBusinessHoursLabel;

  /// No description provided for @settingsAppGatesTitle.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get settingsAppGatesTitle;

  /// No description provided for @settingsMaintenanceSwitch.
  ///
  /// In ar, this message translates to:
  /// **'وضع الصيانة'**
  String get settingsMaintenanceSwitch;

  /// No description provided for @settingsMaintenanceSwitchHint.
  ///
  /// In ar, this message translates to:
  /// **'بيوقف التطبيق لأي حد غير فريق العمل'**
  String get settingsMaintenanceSwitchHint;

  /// No description provided for @settingsMinBuildLabel.
  ///
  /// In ar, this message translates to:
  /// **'أقل نسخة مدعومة'**
  String get settingsMinBuildLabel;

  /// No description provided for @settingsAppGatesConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'متأكد؟'**
  String get settingsAppGatesConfirmTitle;

  /// No description provided for @settingsMaintenanceConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل وضع الصيانة هيوقف التطبيق دلوقتي لكل عميل وسائق. فريق العمل بس هيقدر يدخل.'**
  String get settingsMaintenanceConfirmBody;

  /// No description provided for @settingsMinBuildConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'أي حد بنسخة أقدم هيتطلب منه يحدّث التطبيق الأول عشان يقدر يستخدمه.'**
  String get settingsMinBuildConfirmBody;

  /// No description provided for @settingsFlagsTitle.
  ///
  /// In ar, this message translates to:
  /// **'خصائص تجريبية'**
  String get settingsFlagsTitle;

  /// No description provided for @settingsFlagsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش خصائص'**
  String get settingsFlagsEmpty;

  /// No description provided for @settingsAddFlagLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم خاصية جديدة'**
  String get settingsAddFlagLabel;

  /// No description provided for @maintenanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'نرجع لكم حالًا'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In ar, this message translates to:
  /// **'دكان بياخد نفسه شوية. جرّب تاني بعد كام دقيقة.'**
  String get maintenanceBody;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In ar, this message translates to:
  /// **'محتاجين تحدّث التطبيق'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In ar, this message translates to:
  /// **'حدّث تطبيق دكان من متجر Google Play عشان تكمل تستخدمه.'**
  String get updateRequiredBody;

  /// No description provided for @notificationsTabSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get notificationsTabSend;

  /// No description provided for @notificationsTabHistory.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get notificationsTabHistory;

  /// No description provided for @notificationsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نفتح مركز الإشعارات دلوقتي — جرب تاني.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'الإرسال فشل — جرب تاني.'**
  String get notificationsSendFailed;

  /// No description provided for @notificationsSendOk.
  ///
  /// In ar, this message translates to:
  /// **'اتبعت'**
  String get notificationsSendOk;

  /// No description provided for @notificationsAudienceLabel.
  ///
  /// In ar, this message translates to:
  /// **'الفئة المستهدفة'**
  String get notificationsAudienceLabel;

  /// No description provided for @notificationsAudienceCustomers.
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get notificationsAudienceCustomers;

  /// No description provided for @notificationsAudienceOwners.
  ///
  /// In ar, this message translates to:
  /// **'أصحاب الدكاكين'**
  String get notificationsAudienceOwners;

  /// No description provided for @notificationsAudienceCouriers.
  ///
  /// In ar, this message translates to:
  /// **'المناديب'**
  String get notificationsAudienceCouriers;

  /// No description provided for @notificationsAudienceAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get notificationsAudienceAll;

  /// No description provided for @notificationsAudienceSpecificUser.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم محدد'**
  String get notificationsAudienceSpecificUser;

  /// No description provided for @notificationsTargetSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'دور بالإيميل أو الرقم بالظبط'**
  String get notificationsTargetSearchLabel;

  /// No description provided for @notificationsTargetSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'زي user@email.com أو ٠١٠…'**
  String get notificationsTargetSearchHint;

  /// No description provided for @notificationsTargetNotFound.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مستخدم بالإيميل/الرقم ده.'**
  String get notificationsTargetNotFound;

  /// No description provided for @notificationsTemplatesLabel.
  ///
  /// In ar, this message translates to:
  /// **'القوالب'**
  String get notificationsTemplatesLabel;

  /// No description provided for @notificationsTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get notificationsTitleLabel;

  /// No description provided for @notificationsBodyLabel.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get notificationsBodyLabel;

  /// No description provided for @notificationsSaveTemplateAction.
  ///
  /// In ar, this message translates to:
  /// **'احفظ كقالب'**
  String get notificationsSaveTemplateAction;

  /// No description provided for @notificationsTemplateNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم القالب'**
  String get notificationsTemplateNameLabel;

  /// No description provided for @notificationsTemplateRename.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الاسم'**
  String get notificationsTemplateRename;

  /// No description provided for @notificationsTemplateDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get notificationsTemplateDelete;

  /// No description provided for @notificationsPreviewLabel.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get notificationsPreviewLabel;

  /// No description provided for @notificationsSendAction.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get notificationsSendAction;

  /// No description provided for @notificationsConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبعت الإشعار ده؟'**
  String get notificationsConfirmTitle;

  /// No description provided for @notificationsConfirmDirectBody.
  ///
  /// In ar, this message translates to:
  /// **'هيتبعت لـ {name} دلوقتي.'**
  String notificationsConfirmDirectBody(Object name);

  /// No description provided for @notificationsConfirmBroadcastBody.
  ///
  /// In ar, this message translates to:
  /// **'هيتبعت لكل اللي في \"{audience}\" دلوقتي. مش هنقدر نقولك عددهم كام — الإشعار العام معندوش معاينة لعدد المستقبلين.'**
  String notificationsConfirmBroadcastBody(Object audience);

  /// No description provided for @notificationsHistoryEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'معدش اتبعت حاجة'**
  String get notificationsHistoryEmptyTitle;

  /// No description provided for @notificationsHistoryEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات العامة والمباشرة هتظهر هنا.'**
  String get notificationsHistoryEmptyBody;

  /// No description provided for @notificationsResendAction.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال'**
  String get notificationsResendAction;

  /// No description provided for @notificationsStatusSent.
  ///
  /// In ar, this message translates to:
  /// **'اتبعت'**
  String get notificationsStatusSent;

  /// No description provided for @notificationsStatusFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل'**
  String get notificationsStatusFailed;

  /// No description provided for @notificationsStatusSkipped.
  ///
  /// In ar, this message translates to:
  /// **'اتجاهل'**
  String get notificationsStatusSkipped;

  /// No description provided for @notificationsStatsSent.
  ///
  /// In ar, this message translates to:
  /// **'{count} اتبعتوا'**
  String notificationsStatsSent(Object count);

  /// No description provided for @notificationsStatsFailed.
  ///
  /// In ar, this message translates to:
  /// **'{count} فشلوا'**
  String notificationsStatsFailed(Object count);

  /// No description provided for @consoleNavMedia.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة الصور'**
  String get consoleNavMedia;

  /// No description provided for @mediaTabBrowse.
  ///
  /// In ar, this message translates to:
  /// **'تصفح'**
  String get mediaTabBrowse;

  /// No description provided for @mediaTabUnused.
  ///
  /// In ar, this message translates to:
  /// **'غير مستخدم'**
  String get mediaTabUnused;

  /// No description provided for @mediaTabBroken.
  ///
  /// In ar, this message translates to:
  /// **'روابط معطلة'**
  String get mediaTabBroken;

  /// No description provided for @mediaLoadError.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نفتح مكتبة الصور دلوقتي — جرب تاني.'**
  String get mediaLoadError;

  /// No description provided for @mediaFolderAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get mediaFolderAll;

  /// No description provided for @mediaFolderShopLogos.
  ///
  /// In ar, this message translates to:
  /// **'شعارات الدكاكين'**
  String get mediaFolderShopLogos;

  /// No description provided for @mediaFolderProductImages.
  ///
  /// In ar, this message translates to:
  /// **'صور المنتجات'**
  String get mediaFolderProductImages;

  /// No description provided for @mediaFolderDriverDocs.
  ///
  /// In ar, this message translates to:
  /// **'مستندات المناديب'**
  String get mediaFolderDriverDocs;

  /// No description provided for @mediaFolderBanners.
  ///
  /// In ar, this message translates to:
  /// **'بانرات'**
  String get mediaFolderBanners;

  /// No description provided for @mediaStatsCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get mediaStatsCountLabel;

  /// No description provided for @mediaStatsSizeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحجم الكلي'**
  String get mediaStatsSizeLabel;

  /// No description provided for @mediaEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش صور هنا'**
  String get mediaEmptyTitle;

  /// No description provided for @mediaEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'الصور المرفوعة للقسم ده هتظهر هنا.'**
  String get mediaEmptyBody;

  /// No description provided for @mediaUploadAction.
  ///
  /// In ar, this message translates to:
  /// **'رفع صورة'**
  String get mediaUploadAction;

  /// No description provided for @mediaUploadErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'الرفع فشل — جرب تاني.'**
  String get mediaUploadErrorBody;

  /// No description provided for @mediaDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'متأكد؟'**
  String get mediaDeleteConfirmTitle;

  /// No description provided for @mediaDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هيتحذف {count} صورة نهائيًا — الصور لا تخضع للاسترجاع.'**
  String mediaDeleteConfirmBody(Object count);

  /// No description provided for @mediaDeleteAction.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get mediaDeleteAction;

  /// No description provided for @mediaSelectedCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} متحدد'**
  String mediaSelectedCount(Object count);

  /// No description provided for @mediaFindersScanningBody.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فحص الصور والروابط المرتبطة…'**
  String get mediaFindersScanningBody;

  /// No description provided for @mediaFindersErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نفحص الصور دلوقتي — جرب تاني.'**
  String get mediaFindersErrorBody;

  /// No description provided for @mediaUnusedEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش صور غير مستخدمة'**
  String get mediaUnusedEmptyTitle;

  /// No description provided for @mediaUnusedEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'كل الصور في المكتبة مرتبطة بحاجة.'**
  String get mediaUnusedEmptyBody;

  /// No description provided for @mediaUnusedSelectAllAction.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل'**
  String get mediaUnusedSelectAllAction;

  /// No description provided for @mediaBrokenEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'كل الروابط شغالة'**
  String get mediaBrokenEmptyTitle;

  /// No description provided for @mediaBrokenEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'مفيش رابط صورة معطل دلوقتي.'**
  String get mediaBrokenEmptyBody;

  /// No description provided for @mediaDocTypeShop.
  ///
  /// In ar, this message translates to:
  /// **'دكان'**
  String get mediaDocTypeShop;

  /// No description provided for @mediaDocTypeProduct.
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get mediaDocTypeProduct;

  /// No description provided for @mediaDocTypeDriver.
  ///
  /// In ar, this message translates to:
  /// **'مندوب'**
  String get mediaDocTypeDriver;

  /// No description provided for @mediaDocTypeBanner.
  ///
  /// In ar, this message translates to:
  /// **'بانر'**
  String get mediaDocTypeBanner;

  /// No description provided for @mediaBrokenFixAction.
  ///
  /// In ar, this message translates to:
  /// **'روح لمصدرها'**
  String get mediaBrokenFixAction;

  /// No description provided for @userDetailImpersonate.
  ///
  /// In ar, this message translates to:
  /// **'الدخول كهذا المستخدم'**
  String get userDetailImpersonate;

  /// No description provided for @impersonateConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هتدخل بحساب المستخدم ده وتشوف التطبيق زيه بالظبط — العملية دي مسجّلة في سجل التدقيق.'**
  String get impersonateConfirmBody;

  /// No description provided for @impersonateFailedBody.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين ندخل بحساب المستخدم دلوقتي — جرب تاني.'**
  String get impersonateFailedBody;

  /// No description provided for @impersonationBannerLabel.
  ///
  /// In ar, this message translates to:
  /// **'وضع الانتحال: {name} — جلسة مسجّلة'**
  String impersonationBannerLabel(Object name);

  /// No description provided for @impersonationExitAction.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get impersonationExitAction;

  /// No description provided for @consoleNavDevtools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات المطوّر'**
  String get consoleNavDevtools;

  /// No description provided for @devtoolsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نفتح أدوات المطوّر دلوقتي — جرب تاني.'**
  String get devtoolsLoadError;

  /// No description provided for @devtoolsActionFailed.
  ///
  /// In ar, this message translates to:
  /// **'العملية فشلت — جرب تاني.'**
  String get devtoolsActionFailed;

  /// No description provided for @devtoolsEnvironmentTitle.
  ///
  /// In ar, this message translates to:
  /// **'البيئة'**
  String get devtoolsEnvironmentTitle;

  /// No description provided for @devtoolsEnvVersion.
  ///
  /// In ar, this message translates to:
  /// **'إصدار التطبيق'**
  String get devtoolsEnvVersion;

  /// No description provided for @devtoolsEnvProjectId.
  ///
  /// In ar, this message translates to:
  /// **'مشروع Firebase'**
  String get devtoolsEnvProjectId;

  /// No description provided for @devtoolsEnvWorkerUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط الـ Worker'**
  String get devtoolsEnvWorkerUrl;

  /// No description provided for @devtoolsEnvWorkerConfigured.
  ///
  /// In ar, this message translates to:
  /// **'الـ Worker مُفعّل'**
  String get devtoolsEnvWorkerConfigured;

  /// No description provided for @devtoolsEnvFlavor.
  ///
  /// In ar, this message translates to:
  /// **'نوع البناء'**
  String get devtoolsEnvFlavor;

  /// No description provided for @devtoolsHealthTitle.
  ///
  /// In ar, this message translates to:
  /// **'فحوصات الصحة'**
  String get devtoolsHealthTitle;

  /// No description provided for @devtoolsHealthRunAll.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الكل'**
  String get devtoolsHealthRunAll;

  /// No description provided for @devtoolsHealthEmpty.
  ///
  /// In ar, this message translates to:
  /// **'اضغط «تشغيل الكل» لبدء الفحص.'**
  String get devtoolsHealthEmpty;

  /// No description provided for @devtoolsHealthWorkerPing.
  ///
  /// In ar, this message translates to:
  /// **'استجابة الـ Worker'**
  String get devtoolsHealthWorkerPing;

  /// No description provided for @devtoolsHealthFirestoreRead.
  ///
  /// In ar, this message translates to:
  /// **'قراءة من Firestore'**
  String get devtoolsHealthFirestoreRead;

  /// No description provided for @devtoolsHealthConfigSanity.
  ///
  /// In ar, this message translates to:
  /// **'سلامة إعدادات المنصة'**
  String get devtoolsHealthConfigSanity;

  /// No description provided for @devtoolsHealthTaxonomy.
  ///
  /// In ar, this message translates to:
  /// **'التصنيفات موجودة'**
  String get devtoolsHealthTaxonomy;

  /// No description provided for @devtoolsHealthAreas.
  ///
  /// In ar, this message translates to:
  /// **'المناطق موجودة'**
  String get devtoolsHealthAreas;

  /// No description provided for @devtoolsHealthActiveDriver.
  ///
  /// In ar, this message translates to:
  /// **'يوجد مندوب متصل'**
  String get devtoolsHealthActiveDriver;

  /// No description provided for @devtoolsSeedTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعبئة البيانات التجريبية'**
  String get devtoolsSeedTitle;

  /// No description provided for @devtoolsSeedWarning.
  ///
  /// In ar, this message translates to:
  /// **'عملية مدمّرة — هتستبدل بيانات الحسابات التجريبية وتسجّل خروجك في الآخر.'**
  String get devtoolsSeedWarning;

  /// No description provided for @devtoolsSeedRbac.
  ///
  /// In ar, this message translates to:
  /// **'الأدوار والصلاحيات'**
  String get devtoolsSeedRbac;

  /// No description provided for @devtoolsSeedCatalog.
  ///
  /// In ar, this message translates to:
  /// **'الدكاكين والمنتجات'**
  String get devtoolsSeedCatalog;

  /// No description provided for @devtoolsSeedCustomers.
  ///
  /// In ar, this message translates to:
  /// **'حسابات العملاء'**
  String get devtoolsSeedCustomers;

  /// No description provided for @devtoolsSeedAction.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التعبئة'**
  String get devtoolsSeedAction;

  /// No description provided for @devtoolsSeedConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'متأكد؟'**
  String get devtoolsSeedConfirmTitle;

  /// No description provided for @devtoolsSeedConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتب SEED عشان تأكد إنك عايز تعيد تعبئة البيانات التجريبية.'**
  String get devtoolsSeedConfirmBody;

  /// No description provided for @devtoolsSeedConfirmField.
  ///
  /// In ar, this message translates to:
  /// **'اكتب SEED'**
  String get devtoolsSeedConfirmField;

  /// No description provided for @devtoolsFakeTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات وهمية'**
  String get devtoolsFakeTitle;

  /// No description provided for @devtoolsFakeCustomersLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد العملاء الوهميين'**
  String get devtoolsFakeCustomersLabel;

  /// No description provided for @devtoolsFakeGenerate.
  ///
  /// In ar, this message translates to:
  /// **'توليد'**
  String get devtoolsFakeGenerate;

  /// No description provided for @devtoolsFakeCustomersResult.
  ///
  /// In ar, this message translates to:
  /// **'اتولّد {count} عميل وهمي.'**
  String devtoolsFakeCustomersResult(Object count);

  /// No description provided for @devtoolsFakeNoShops.
  ///
  /// In ar, this message translates to:
  /// **'مفيش دكاكين عشان تتولّد طلبات وهمية.'**
  String get devtoolsFakeNoShops;

  /// No description provided for @devtoolsFakeShopLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدكان'**
  String get devtoolsFakeShopLabel;

  /// No description provided for @devtoolsFakeOrdersLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد الطلبات الوهمية'**
  String get devtoolsFakeOrdersLabel;

  /// No description provided for @devtoolsFakeOrdersResult.
  ///
  /// In ar, this message translates to:
  /// **'اتولّد {count} طلب وهمي.'**
  String devtoolsFakeOrdersResult(Object count);

  /// No description provided for @devtoolsFakeCleanupAction.
  ///
  /// In ar, this message translates to:
  /// **'حذف كل البيانات الوهمية'**
  String get devtoolsFakeCleanupAction;

  /// No description provided for @devtoolsFakeCleanupResult.
  ///
  /// In ar, this message translates to:
  /// **'اتحذف {count} عنصر وهمي.'**
  String devtoolsFakeCleanupResult(Object count);

  /// No description provided for @devtoolsCachesTitle.
  ///
  /// In ar, this message translates to:
  /// **'التخزين المؤقت المحلي'**
  String get devtoolsCachesTitle;

  /// No description provided for @devtoolsCachesCleared.
  ///
  /// In ar, this message translates to:
  /// **'اتنضّف التخزين المؤقت.'**
  String get devtoolsCachesCleared;

  /// No description provided for @devtoolsCachesAction.
  ///
  /// In ar, this message translates to:
  /// **'تنظيف'**
  String get devtoolsCachesAction;

  /// No description provided for @devtoolsNotifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'إشعار تجريبي'**
  String get devtoolsNotifyTitle;

  /// No description provided for @devtoolsNotifySent.
  ///
  /// In ar, this message translates to:
  /// **'اتبعت الإشعار.'**
  String get devtoolsNotifySent;

  /// No description provided for @devtoolsNotifyAction.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get devtoolsNotifyAction;

  /// No description provided for @devtoolsMigrationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الترحيلات'**
  String get devtoolsMigrationsTitle;

  /// No description provided for @devtoolsMigrationRun.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get devtoolsMigrationRun;

  /// No description provided for @devtoolsMigrationRerun.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تشغيل'**
  String get devtoolsMigrationRerun;
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
