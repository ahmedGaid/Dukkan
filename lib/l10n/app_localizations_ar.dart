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
  String get roleCourier => 'مندوب التوصيل';

  @override
  String get roleBadgeCustomer => 'زبون';

  @override
  String get roleBadgeOwner => 'صاحب دكان';

  @override
  String get roleBadgeCourier => 'مندوب التوصيل';

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
  String get favoriteActionErrorBody => 'معرفناش نحفظها — جرّب تاني.';

  @override
  String get favoritesSectionShops => 'الدكاكين';

  @override
  String get favoritesSectionProducts => 'المنتجات';

  @override
  String get favoritesErrorBody => 'معرفناش نجيب مفضلاتك دلوقتي — جرّب تاني.';

  @override
  String get ordersEmptyTitle => 'لسه مفيش طلبات';

  @override
  String get ordersEmptyBody =>
      'أول ما تطلب من دكان، هتلاقي طلبك هنا وتتابعه خطوة بخطوة.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsPreferences => 'التفضيلات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLangArabic => 'العربية';

  @override
  String get settingsLangEnglish => 'English';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'غامق';

  @override
  String get settingsThemeSystem => 'تلقائي';

  @override
  String get settingsAbout => 'عن التطبيق';

  @override
  String get settingsVersion => 'الإصدار';

  @override
  String get settingsLogoutConfirmTitle => 'تسجّل خروج؟';

  @override
  String get settingsLogoutConfirmBody => 'هتحتاج تسجّل دخولك تاني عشان تكمّل.';

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
  String get orderRateTitle => 'قيّم الدكان';

  @override
  String get orderRateBody => 'طلبك اتوصّلك، إيه رأيك في الدكان؟';

  @override
  String get orderRatedTitle => 'تقييمك';

  @override
  String get orderRateErrorBody => 'معرفناش نسجل تقييمك دلوقتي — جرّب تاني.';

  @override
  String get navCatalog => 'الكتالوج';

  @override
  String get navOrderDesk => 'الطلبات';

  @override
  String get orderDeskTitle => 'الطلبات';

  @override
  String get orderDeskEmptyTitle => 'لسه مفيش طلبات';

  @override
  String get orderDeskEmptyBody => 'طلبات عملائك الجديدة هتظهر هنا.';

  @override
  String get orderDeskErrorBody => 'مش قادرين نجيب طلباتك دلوقتي — جرّب تاني.';

  @override
  String get orderDeskTodayLabel => 'النهاردة';

  @override
  String get actionAcceptOrder => 'قبول';

  @override
  String get actionRejectOrder => 'رفض';

  @override
  String get actionStartPreparing => 'ابدأ التجهيز';

  @override
  String get actionStartDelivery => 'ابعته للتوصيل';

  @override
  String get actionMarkDelivered => 'وصل الطلب';

  @override
  String get orderRejectConfirmTitle => 'ترفض الطلب؟';

  @override
  String get orderRejectConfirmBody => 'العميل هيوصله إشعار إن الطلب اترفض.';

  @override
  String get orderActionErrorBody => 'معرفناش نحدّث الطلب دلوقتي — جرّب تاني.';

  @override
  String get orderCustomerSection => 'العميل';

  @override
  String get orderPaymentMethod => 'طريقة الدفع';

  @override
  String get orderSubtotalLabel => 'المجموع الفرعي';

  @override
  String get orderDeliveryFeeLabel => 'رسوم التوصيل';

  @override
  String get orderDriverSection => 'المندوب';

  @override
  String get orderAssignDriverButton => 'تعيين مندوب';

  @override
  String get orderAssignDriverSheetTitle => 'تعيين مندوب';

  @override
  String get orderAssignDriverEmptyTitle => 'مفيش مندوبين متاحين';

  @override
  String get orderAssignDriverEmptyBody =>
      'لا يوجد مندوبون متاحون الآن — يمكنك التوصيل بنفسك';

  @override
  String get orderAssignDriverConfirmTitle => 'تعيين المندوب ده؟';

  @override
  String get orderAssignDriverConfirmBody =>
      'الطلب هينتقل للمندوب ده بعد التعيين.';

  @override
  String get orderAssignDriverErrorOffline =>
      'المندوب ده بقى أوفلاين دلوقتي — جرّب واحد تاني.';

  @override
  String get orderAssignDriverErrorCapacity =>
      'المندوب ده وصل لأقصى عدد طلبات — جرّب واحد تاني.';

  @override
  String get orderAssignDriverErrorArea =>
      'المندوب ده مش بيغطي المنطقة دي — جرّب واحد تاني.';

  @override
  String get orderAssignDriverErrorTaken => 'الطلب ده اتعيّنله مندوب بالفعل.';

  @override
  String get orderAssignDriverErrorGeneric =>
      'معرفناش نعيّن المندوب ده — جرّب تاني.';

  @override
  String get orderAssignedAtLabel => 'اتعيّن';

  @override
  String get orderTimelineTitle => 'سجل الطلب';

  @override
  String get notifyNewOrderTitle => 'طلب جديد!';

  @override
  String get notifyNewOrderBody => 'وصلك طلب جديد، افتح دكانك وشوفه.';

  @override
  String get notifyOrderStatusTitle => 'تحديث على طلبك';

  @override
  String notifyOrderStatusBody(Object status) {
    return 'طلبك بقى $status.';
  }

  @override
  String get notifyDriverAssignedTitle => 'طلب جديد لتوصيله';

  @override
  String notifyDriverAssignedBody(Object area, Object shop) {
    return '$shop عندهم طلب لك في $area.';
  }

  @override
  String get notifyOrderDeliveredTitle => 'تسليم الطلب';

  @override
  String get notifyOrderDeliveredBody => 'المندوب سلّم الطلب.';

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
  String get catalogEmptyTitle => 'لسه مفيش منتجات';

  @override
  String get catalogEmptyBody => 'ضيف أول منتج، وهيظهر هنا على طول.';

  @override
  String get catalogErrorBody => 'مش قادرين نجيب كتالوجك دلوقتي — جرّب تاني.';

  @override
  String get actionAddProduct => 'أضف منتج';

  @override
  String get addProductTitle => 'أضف منتج';

  @override
  String get editProductTitle => 'تعديل المنتج';

  @override
  String get fieldProductName => 'اسم المنتج (إنجليزي)';

  @override
  String get fieldProductNameAr => 'اسم المنتج (عربي)';

  @override
  String get fieldProductCategory => 'القسم';

  @override
  String get fieldProductSubcategory => 'القسم الفرعي';

  @override
  String get categoryRequired => 'اختر القسم';

  @override
  String get subcategoryRequired => 'اختر القسم الفرعي';

  @override
  String get taxonomyErrorBody => 'مش قادرين نجيب الأقسام دلوقتي — جرّب تاني.';

  @override
  String get fieldProductPrice => 'السعر (جنيه)';

  @override
  String get fieldProductStock => 'المخزون';

  @override
  String get fieldProductPromoLabel => 'خليه عرض';

  @override
  String get productImageLabel => 'صورة المنتج';

  @override
  String get actionSave => 'احفظ';

  @override
  String get productFormErrorBody => 'مش قادرين نحفظ المنتج — جرّب تاني.';

  @override
  String get productImageErrorBody => 'مش قادرين نرفع الصورة — جرّب تاني.';

  @override
  String get validatePriceInvalid => 'اكتب سعر صحيح';

  @override
  String get productDeleteConfirmTitle => 'تحذف المنتج ده؟';

  @override
  String get productDeleteConfirmBody => 'هيتشال من دكانك على طول.';

  @override
  String get actionDelete => 'احذف';

  @override
  String get productDeleteErrorBody => 'مش قادرين نحذف المنتج — جرّب تاني.';

  @override
  String get actionCreate => 'إنشاء';

  @override
  String get catalogCollectionsEntry => 'المجموعات';

  @override
  String get collectionsEmptyTitle => 'لا توجد مجموعات بعد';

  @override
  String get collectionsEmptyAction => 'أنشئ مجموعة';

  @override
  String get collectionsErrorBody =>
      'مش قادرين نجيب مجموعاتك دلوقتي — جرّب تاني.';

  @override
  String get collectionsCreateTitle => 'مجموعة جديدة';

  @override
  String get collectionsRenameTitle => 'تعديل المجموعة';

  @override
  String get fieldCollectionNameAr => 'الاسم بالعربي';

  @override
  String get fieldCollectionNameEn => 'الاسم بالإنجليزي';

  @override
  String get collectionNameArHint => 'مثلاً: عروض';

  @override
  String get collectionNameEnHint => 'مثلاً: Offers';

  @override
  String get collectionsDeleteConfirmTitle => 'حذف المجموعة؟';

  @override
  String get collectionsDeleteConfirmBody => 'حذف المجموعة لا يحذف المنتجات';

  @override
  String get collectionsActionErrorBody => 'حصلت مشكلة — جرّب تاني.';

  @override
  String get productCollections => 'المجموعات (اختياري)';

  @override
  String get fieldArea => 'المنطقة';

  @override
  String get areaRequired => 'اختر منطقتك';

  @override
  String get areasErrorBody => 'مش قادرين نجيب المناطق دلوقتي — جرّب تاني.';

  @override
  String get navDeliveries => 'التوصيلات';

  @override
  String get courierOnlineLabel => 'أونلاين';

  @override
  String get courierOfflineLabel => 'أوفلاين';

  @override
  String get courierSuspendedBannerBody => 'حسابك قيد المراجعة — تواصل مع دكان';

  @override
  String get courierActiveTabLabel => 'الحالية';

  @override
  String get courierHistoryTabLabel => 'السجل';

  @override
  String get courierActiveEmptyTitle => 'لسه مفيش توصيلات دلوقتي';

  @override
  String get courierHistoryEmptyTitle => 'لسه مفيش توصيلات سابقة';

  @override
  String get courierActionPickedUp => 'استلمت الطلب';

  @override
  String get courierActionDelivered => 'تم التوصيل';

  @override
  String get courierActionDeliveredConfirmTitle => 'تأكيد إن الطلب اتوصّل؟';

  @override
  String get courierActionDeliveredConfirmBody => 'مش هتقدر ترجّعها بعد كده.';

  @override
  String get financeTitle => 'المالية';

  @override
  String get financeLedgerNote =>
      'أرقام دفترية — التحصيل يتم يدويًا مع المتاجر';

  @override
  String get financeTotalOrders => 'إجمالي الطلبات';

  @override
  String get financeDeliveredOrders => 'الطلبات المُسلّمة';

  @override
  String get financeCancelledOrders => 'الطلبات الملغاة';

  @override
  String get financeTotalCommission => 'إجمالي العمولات';

  @override
  String get financeDeliveryRevenue => 'إيراد التوصيل';

  @override
  String get financeTotalPlatformRevenue => 'إجمالي إيراد المنصة';

  @override
  String get financeErrorBody =>
      'مقدرناش نجيب أرقام المالية دلوقتي — جرّب تاني';

  @override
  String get consoleTitle => 'لوحة التحكم';

  @override
  String get consoleNavDashboard => 'الرئيسية';

  @override
  String get consoleNavAudit => 'سجل العمليات';

  @override
  String get consoleDashboardSubtitle => 'نظرة عامة على المنصة هتظهر هنا قريب.';

  @override
  String get consoleComingSoon => 'القسم ده جاي قريب.';

  @override
  String get settingsConsoleRow => 'لوحة التحكم';

  @override
  String get roleFounder => 'المؤسس';

  @override
  String get roleAdmin => 'مشرف عام';

  @override
  String get roleModerator => 'مشرف';

  @override
  String get roleSupport => 'دعم';

  @override
  String get auditFilterAction => 'العملية';

  @override
  String get auditFilterType => 'النوع';

  @override
  String get auditFilterTargetId => 'معرّف العنصر';

  @override
  String get auditFilterAll => 'الكل';

  @override
  String get auditFilterDateRange => 'الفترة';

  @override
  String get auditFilterClear => 'مسح الفلاتر';

  @override
  String get auditReported => 'مُبلَّغ';

  @override
  String get auditLoadMore => 'حمّل المزيد';

  @override
  String get auditEmptyTitle => 'لسه مفيش عمليات';

  @override
  String get auditEmptyBody => 'أي عملية بتحصل في المنصة هتظهر هنا.';

  @override
  String get auditErrorBody => 'مقدرناش نجيب السجل دلوقتي — جرّب تاني';

  @override
  String get auditDetailTarget => 'العنصر';

  @override
  String get auditDetailActor => 'نفّذها';

  @override
  String get auditDetailWhen => 'التوقيت';

  @override
  String get auditDetailReason => 'السبب';

  @override
  String get auditDetailIp => 'عنوان الـ IP';

  @override
  String get auditDetailChanges => 'التغييرات';

  @override
  String get auditDetailField => 'الحقل';

  @override
  String get auditDetailBefore => 'قبل';

  @override
  String get auditDetailAfter => 'بعد';

  @override
  String get auditDetailNoChanges => 'مفيش تغييرات متسجّلة.';

  @override
  String get auditTimeJustNow => 'دلوقتي';

  @override
  String auditTimeMinutesAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'من $countString د';
  }

  @override
  String auditTimeHoursAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'من $countString س';
  }

  @override
  String auditTimeDaysAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'من $countString ي';
  }
}
