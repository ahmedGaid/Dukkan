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

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCategories => 'الأقسام';

  @override
  String get navFavorites => 'المفضلة';

  @override
  String get navOrders => 'طلباتي';

  @override
  String get navMore => 'المزيد';

  @override
  String get homeSearchHint => 'دوّر على منتج أو دكان';

  @override
  String get sectionOffers => 'عروض';

  @override
  String get sectionCategories => 'الأقسام';

  @override
  String get sectionNearbyShops => 'دكاكين قريبة منك';

  @override
  String get categoryAll => 'الكل';

  @override
  String get shopOpen => 'متاح';

  @override
  String get shopClosed => 'مقفول';

  @override
  String get shopsEmptyTitle => 'مافيش دكاكين قريبة لسه';

  @override
  String get shopsEmptyBody =>
      'بنضيف دكاكين جديدة كل يوم — تعالى بصّ تاني قريب.';

  @override
  String get categoryEmptyTitle => 'مافيش دكاكين في القسم ده';

  @override
  String get categoryEmptyBody => 'جرّب قسم تاني أو شوف كل الدكاكين.';

  @override
  String get errorTitle => 'حصلت مشكلة';

  @override
  String get errorBody => 'مش قادرين نجيب الدكاكين دلوقتي — جرّب تاني.';

  @override
  String get actionRetry => 'جرّب تاني';

  @override
  String get favoritesEmptyTitle => 'لسه مفيش مفضلة';

  @override
  String get favoritesEmptyBody =>
      'دوس على القلب في أي دكان أو منتج بتحبه، وهيتحفظ هنا.';

  @override
  String get ordersEmptyTitle => 'لسه مفيش طلبات';

  @override
  String get ordersEmptyBody =>
      'أول ما تطلب من دكان، هتلاقي طلبك هنا وتتابعه خطوة بخطوة.';

  @override
  String get moreTitle => 'المزيد';

  @override
  String get moreComingSoonTitle => 'الإعدادات قريب';

  @override
  String get moreComingSoonBody => 'حسابك وإعداداتك هتكون هنا قريب.';

  @override
  String get categoriesComingSoonTitle => 'تصفّح الأقسام قريب';

  @override
  String get categoriesComingSoonBody =>
      'هتقدر تتصفّح كل قسم لوحده هنا قريب. دلوقتي الأقسام في الصفحة الرئيسية.';

  @override
  String get promoBadge => 'عرض';

  @override
  String get productStockIn => 'متوفر';

  @override
  String get productStockLow => 'آخر كمية';

  @override
  String get productStockOut => 'خلص من المخزن';

  @override
  String get actionAdd => 'أضف';

  @override
  String get actionAddToCart => 'أضف للسلة';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionClear => 'امسح';

  @override
  String get actionClearAndAdd => 'امسح وضيف';

  @override
  String get actionCheckout => 'إتمام الطلب';

  @override
  String get actionPlaceOrder => 'أكّد الطلب';

  @override
  String get actionBackHome => 'رجوع للرئيسية';

  @override
  String get qtyLabel => 'الكمية';

  @override
  String get qtyIncrease => 'زوّد واحد';

  @override
  String get qtyDecrease => 'قلّل واحد';

  @override
  String get cartItemAdded => 'اتضاف للسلة';

  @override
  String get cartTitle => 'السلة';

  @override
  String get cartTotal => 'الإجمالي';

  @override
  String get cartClearAll => 'امسح السلة';

  @override
  String get cartClearConfirmTitle => 'تمسح السلة؟';

  @override
  String get cartClearConfirmBody => 'هيتشال كل اللي في السلة.';

  @override
  String get cartEmptyTitle => 'السلة فاضية';

  @override
  String get cartEmptyBody => 'ضيف منتجات من أي دكان عشان تشوفها هنا.';

  @override
  String get cartEmptyAction => 'تصفّح الدكاكين';

  @override
  String get cartSwitchShopTitle => 'تبدأ سلة جديدة؟';

  @override
  String get cartSwitchShopBody =>
      'السلة فيها منتجات من دكان تاني. لو ضفت المنتج ده، هنمسح السلة الأول.';

  @override
  String get checkoutTitle => 'إتمام الطلب';

  @override
  String get checkoutAddressSection => 'عنوان التوصيل';

  @override
  String get checkoutSummary => 'ملخص الطلب';

  @override
  String get checkoutErrorBody => 'معرفناش نأكد طلبك دلوقتي — جرّب تاني.';

  @override
  String get fieldAddressLine => 'العنوان';

  @override
  String get fieldCity => 'المدينة';

  @override
  String get fieldNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get codLabel => 'الدفع عند الاستلام';

  @override
  String get orderPlacedTitle => 'الطلب اتأكد!';

  @override
  String get orderPlacedBody => 'الدكان هيبدأ يجهّز طلبك على طول.';

  @override
  String get ordersErrorBody => 'مش قادرين نجيب طلباتك دلوقتي — جرّب تاني.';

  @override
  String get orderDetailTitle => 'تفاصيل الطلب';

  @override
  String get orderStatusPending => 'بانتظار التأكيد';

  @override
  String get orderStatusAccepted => 'مقبول';

  @override
  String get orderStatusPreparing => 'بيتجهّز';

  @override
  String get orderStatusOutForDelivery => 'في الطريق إليك';

  @override
  String get orderStatusDelivered => 'اتوصّل';

  @override
  String get orderStatusCancelled => 'ملغي';

  @override
  String get orderStatusRejected => 'مرفوض';

  @override
  String get actionCancelOrder => 'إلغاء الطلب';

  @override
  String get orderCancelConfirmTitle => 'تلغي الطلب؟';

  @override
  String get orderCancelConfirmBody => 'مش هتقدر ترجّعه بعد كده.';

  @override
  String get orderCancelErrorBody => 'معرفناش نلغي طلبك دلوقتي — جرّب تاني.';

  @override
  String get shopProductsEmptyTitle => 'الدكان لسه بيرتّب رفوفه';

  @override
  String get shopProductsEmptyBody =>
      'المنتجات هتظهر هنا أول ما الدكان يضيفها.';

  @override
  String get productsCategoryEmptyTitle => 'مافيش منتجات في القسم ده';

  @override
  String get productsCategoryEmptyBody => 'جرّب قسم تاني أو شوف كل المنتجات.';

  @override
  String get shopErrorBody => 'مش قادرين نفتح الدكان دلوقتي — جرّب تاني.';

  @override
  String get productNotFoundTitle => 'المنتج مش موجود';

  @override
  String get productNotFoundBody =>
      'يمكن يكون اتشال من الدكان. ارجع وبصّ على باقي المنتجات.';

  @override
  String get searchPromptTitle => 'دوّر على اللي محتاجه';

  @override
  String get searchPromptBody => 'اكتب اسم منتج أو دكان، وهنلاقيهولك على طول.';

  @override
  String get searchNoResultsTitle => 'مفيش نتايج';

  @override
  String get searchNoResultsBody => 'جرّب كلمة تانية أو اسم أقصر.';

  @override
  String get searchClear => 'امسح';

  @override
  String get searchErrorBody => 'مش قادرين نكمّل البحث دلوقتي — جرّب تاني.';

  @override
  String get shopOnboardingTitle => 'جهّز دكانك';

  @override
  String get shopOnboardingSubtitle => 'الزباين هيشوفوا دكانك أول ما تخلّص.';

  @override
  String get fieldShopName => 'اسم الدكان (إنجليزي)';

  @override
  String get fieldShopNameAr => 'اسم الدكان (عربي)';

  @override
  String get fieldShopAddress => 'عنوان الدكان';

  @override
  String get shopOnboardingLogoLabel => 'لوجو الدكان';

  @override
  String get shopOnboardingLogoHint => 'دوس عشان تضيف صورة';

  @override
  String get shopOnboardingOpenLabel => 'متاح لاستقبال الطلبات';

  @override
  String get actionCreateShop => 'أنشئ الدكان';

  @override
  String get shopOnboardingErrorBody => 'مش قادرين ننشئ الدكان — جرّب تاني.';

  @override
  String get shopOnboardingLogoErrorBody =>
      'مش قادرين نرفع الصورة — جرّب تاني.';

  @override
  String get promo1Title => 'أهلاً بيك في دكان';

  @override
  String get promo1Body => 'دكاكين حيّك، في جيبك.';

  @override
  String get promo2Title => 'توصيل من دكانك';

  @override
  String get promo2Body => 'اطلب اللي محتاجه، وهو ييجي لحد باب البيت.';

  @override
  String get promo3Title => 'أسعار حيّك';

  @override
  String get promo3Body => 'نفس أسعار الدكان اللي تحت بيتك، بالظبط.';
}
