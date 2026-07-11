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

  /// No description provided for @orderTimelineTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الطلب'**
  String get orderTimelineTitle;

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
