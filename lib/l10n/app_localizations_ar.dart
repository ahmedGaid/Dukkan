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
  String get actionConfirm => 'تأكيد';

  @override
  String get actionEnable => 'تفعيل';

  @override
  String get actionDisable => 'إلغاء التفعيل';

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
  String get orderForcedChip => 'تصحيح إداري';

  @override
  String get orderNotesTitle => 'الملاحظات الداخلية';

  @override
  String get orderNotesEmpty => 'لسه مفيش ملاحظات.';

  @override
  String get orderNotesAddHint => 'اكتب ملاحظة للفريق…';

  @override
  String get orderForceStatusAction => 'فرض الحالة';

  @override
  String get orderForceStatusWarning =>
      'الخطوة دي بتتخطى مسار الطلب العادي — استخدمها بس لتصحيح غلطة.';

  @override
  String get orderForceStatusLabel => 'الحالة الجديدة';

  @override
  String get orderStaffReasonLabel => 'السبب (مطلوب)';

  @override
  String get orderReassignDriverAction => 'تغيير المندوب';

  @override
  String get orderUnassignDriverAction => 'إلغاء التعيين';

  @override
  String get orderRefundNoteLabel => 'ملاحظة استرداد (اختياري)';

  @override
  String get orderRefundNoteHelper => 'ملاحظة دفتر بس — مفيش تحويل فلوس.';

  @override
  String get staffOrderActionErrorBody => 'الإجراء ده مكملش — جرّب تاني.';

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
  String get consoleNavUsers => 'المستخدمين';

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

  @override
  String get dashboardOrdersToday => 'طلبات النهارده';

  @override
  String get dashboardRevenueToday => 'إيراد النهارده';

  @override
  String get dashboardCommissionToday => 'عمولة النهارده';

  @override
  String get dashboardOrdersWaiting => 'طلبات مستنية';

  @override
  String get dashboardTotalUsers => 'المستخدمين';

  @override
  String get dashboardTotalShops => 'الدكاكين';

  @override
  String get dashboardTotalProducts => 'المنتجات';

  @override
  String get dashboardDriversOnline => 'مناديب أونلاين';

  @override
  String get dashboardPendingShops => 'دكاكين مستنية موافقة';

  @override
  String get dashboardFailedNotifications => 'إشعارات فشلت (٧ أيام)';

  @override
  String get dashboardChartTitle => 'طلبات آخر ٧ أيام';

  @override
  String get dashboardActivityTitle => 'آخر العمليات';

  @override
  String get dashboardViewAll => 'شوف الكل';

  @override
  String get dashboardActivityEmpty => 'لسه مفيش عمليات جديدة.';

  @override
  String get dashboardQuickActionsTitle => 'إجراءات سريعة';

  @override
  String get dashboardQuickAudit => 'افتح سجل العمليات';

  @override
  String get dashboardExternalTitle => 'أدوات خارجية';

  @override
  String get dashboardCrashlyticsTitle => 'Crashlytics';

  @override
  String get dashboardCrashlyticsNote =>
      'تقارير الأعطال بتتفتح في Firebase Console.';

  @override
  String get dashboardErrorBody =>
      'مقدرناش نجيب أرقام اللوحة دلوقتي — جرّب تاني';

  @override
  String get usersErrorBody =>
      'مقدرناش نجيب قائمة المستخدمين دلوقتي — جرّب تاني';

  @override
  String get usersEmptyTitle => 'مفيش مستخدمين';

  @override
  String get usersEmptyBody => 'جرّب بحث أو فلتر تاني.';

  @override
  String get usersSearchLabel => 'بحث';

  @override
  String get usersSearchHint => 'إيميل أو رقم بالظبط، أو اسم في الصفحة دي';

  @override
  String get usersFilterRole => 'النوع';

  @override
  String get usersFilterStatus => 'الحالة';

  @override
  String get usersRoleCustomer => 'عميل';

  @override
  String get usersRoleOwner => 'صاحب دكان';

  @override
  String get usersRoleCourier => 'مندوب';

  @override
  String get usersStatusActive => 'نشط';

  @override
  String get usersStatusSuspended => 'موقوف';

  @override
  String get usersStatusBanned => 'محظور';

  @override
  String get usersDeletedLabel => 'متمسح';

  @override
  String usersSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString متحدد';
  }

  @override
  String get usersBulkSuspend => 'إيقاف مؤقت';

  @override
  String get usersBulkUnsuspend => 'رجّعه نشط';

  @override
  String get usersBulkConfirmTitle => 'إجراء جماعي';

  @override
  String usersBulkConfirmBody(Object action) {
    return '$action للمستخدمين المحددين؟';
  }

  @override
  String usersBulkSummary(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString/$totalString تم';
  }

  @override
  String get userDetailMissingSeed =>
      'افتح الصفحة دي من قائمة المستخدمين — مفيش حاجة تتعرض هنا لسه.';

  @override
  String get userDetailBackToList => 'رجوع للمستخدمين';

  @override
  String get userDetailActionOk => 'تم';

  @override
  String get userDetailActionFailed => 'الحاجة دي متنفذتش — جرّب تاني';

  @override
  String get userDetailProfileTitle => 'الملف الشخصي';

  @override
  String get userDetailEmail => 'الإيميل';

  @override
  String get userDetailPhone => 'الموبايل';

  @override
  String get userDetailMemberSince => 'عضو من';

  @override
  String get userDetailUnknown => 'مش معروف';

  @override
  String get userDetailActionsTitle => 'إجراءات';

  @override
  String get userDetailBan => 'حظر';

  @override
  String get userDetailConfirmSuspend =>
      'توقف الحساب ده مؤقتًا؟ مش هيقدر يسجل دخول لحد ما ترجّعه.';

  @override
  String get userDetailConfirmBan =>
      'تحظر الحساب ده؟ ده أشد من الإيقاف المؤقت.';

  @override
  String get userDetailConfirmPasswordReset =>
      'تبعت إيميل استرجاع كلمة السر للحساب ده؟';

  @override
  String get userDetailSendPasswordReset => 'ابعت استرجاع كلمة السر';

  @override
  String get userDetailChangeEmail => 'غيّر الإيميل';

  @override
  String get userDetailSetPersonaRole => 'غيّر نوع الحساب';

  @override
  String get userDetailConfirmSoftDelete =>
      'تعطّل الحساب ده؟ ده قابل للاسترجاع تاني.';

  @override
  String get userDetailSoftDelete => 'تعطيل';

  @override
  String get userDetailRestore => 'استرجاع';

  @override
  String get userDetailAuthTitle => 'الدخول';

  @override
  String get userDetailEmailVerified => 'الإيميل متأكد';

  @override
  String get userDetailAuthDisabled => 'الدخول متعطل';

  @override
  String get userDetailYes => 'أيوه';

  @override
  String get userDetailNo => 'لأ';

  @override
  String get userDetailLastLogin => 'آخر دخول';

  @override
  String get userDetailStaffTitle => 'الفريق الإداري';

  @override
  String get userDetailNotStaff => 'مش من فريق العمل.';

  @override
  String get userDetailStaffRole => 'الدرجة الإدارية';

  @override
  String get userDetailStaffPermissions => 'الصلاحيات';

  @override
  String get userDetailMakeStaff => 'ضمّه للفريق';

  @override
  String get userDetailEditStaff => 'تعديل صلاحياته';

  @override
  String get userDetailRemoveStaff => 'شيله من الفريق';

  @override
  String get userDetailExtraPermissionsHint =>
      'صلاحيات إضافية، فوق صلاحيات الدرجة نفسها:';

  @override
  String get userDetailShopsTitle => 'الدكان';

  @override
  String get userDetailNoShop => 'مفيش دكان ليه.';

  @override
  String get userDetailOrdersTitle => 'الطلبات';

  @override
  String get userDetailNoOrders => 'لسه مفيش طلبات.';

  @override
  String get userDetailAuditTitle => 'النشاط';

  @override
  String get catalogPendingBannerTitle => 'تحت المراجعة';

  @override
  String get catalogPendingBannerBody =>
      'دكانك لسه مش ظاهر للعملاء — الفريق بيراجعه دلوقتي.';

  @override
  String get consoleNavShops => 'الدكاكين';

  @override
  String get shopsBoardSearchLabel => 'دور بالاسم';

  @override
  String get shopsBoardCreateAction => 'دكان جديد';

  @override
  String get shopsBoardErrorBody => 'معرفناش نجيب قائمة الدكاكين — جرب تاني.';

  @override
  String get shopsBoardEmptyTitle => 'مفيش دكاكين مطابقة';

  @override
  String get shopsBoardEmptyBody => 'جرب فلتر تاني أو دور بكلمة مختلفة.';

  @override
  String shopsBoardOwnerLabel(Object ownerUid) {
    return 'المالك: $ownerUid';
  }

  @override
  String get shopsFilterAll => 'الكل';

  @override
  String get shopsStatusPending => 'تحت المراجعة';

  @override
  String get shopsStatusActive => 'نشط';

  @override
  String get shopsStatusSuspended => 'موقوف';

  @override
  String get shopsStatusDeleted => 'محذوف';

  @override
  String get shopsFeaturedBadge => 'مميّز';

  @override
  String get shopsVerifiedBadge => 'مُوثّق';

  @override
  String get shopDetailMissingSeed =>
      'افتح الصفحة دي من قائمة الدكاكين — لسه مفيش حاجة تتعرض.';

  @override
  String get shopDetailStatusTitle => 'الحالة';

  @override
  String get shopDetailApprove => 'موافقة';

  @override
  String get shopDetailConfirmApprove =>
      'توافق على الدكان ده؟ هيبقى ظاهر للعملاء.';

  @override
  String get shopDetailReject => 'رفض';

  @override
  String get shopDetailRejectReasonLabel => 'السبب (بيتسجل في سجل النشاط)';

  @override
  String get shopDetailSuspend => 'إيقاف';

  @override
  String get shopDetailConfirmSuspend =>
      'توقف الدكان ده؟ هيختفي من عند العملاء فورًا.';

  @override
  String get shopDetailUnsuspend => 'رجّعه تاني';

  @override
  String get shopDetailFieldsTitle => 'البيانات';

  @override
  String get shopDetailHoursNoteLabel => 'ملاحظة مواعيد العمل (اختياري)';

  @override
  String get shopDetailTransferTitle => 'نقل الملكية';

  @override
  String get shopDetailTransferHint =>
      'بينقل الدكان لمالك تاني. لازم يكون عنده حساب مالك أصلاً.';

  @override
  String get shopDetailNewOwnerUidLabel => 'معرّف المستخدم للمالك الجديد';

  @override
  String get shopDetailTransferAction => 'نقل';

  @override
  String shopDetailConfirmTransfer(Object newOwnerUid) {
    return 'تنقل الدكان ده للمستخدم $newOwnerUid؟ الخطوة دي مش هترجع من هنا.';
  }

  @override
  String get shopTransferOldOwnerHint =>
      'المالك القديم لسه دوره مالك من غير دكان — عدّل حسابه من إدارة المستخدمين لو محتاج.';

  @override
  String get shopDetailDangerTitle => 'منطقة خطر';

  @override
  String get shopDetailConfirmSoftDelete =>
      'تشيل الدكان ده؟ ممكن ترجّعه تاني بعدين.';

  @override
  String get shopDetailShortcutsTitle => 'اختصارات';

  @override
  String get shopCreateOwnerTitle => 'المالك';

  @override
  String get shopCreateOwnerEmailLabel => 'إيميل المالك';

  @override
  String get shopCreateOwnerNotFound => 'مفيش مستخدم بالإيميل ده.';

  @override
  String get shopCreateOwnerNotOwnerRole => 'الحساب ده مش حساب مالك.';

  @override
  String get shopCreateOwnerRequired => 'دور على المالك الأول.';

  @override
  String get consoleNavProducts => 'المنتجات';

  @override
  String get productsBoardSearchLabel => 'دور بالاسم';

  @override
  String get productsBoardErrorBody =>
      'مقدرناش نجيب قايمة المنتجات دلوقتي — جرّب تاني.';

  @override
  String get productsBoardEmptyTitle => 'مفيش منتجات مطابقة';

  @override
  String get productsBoardEmptyBody => 'جرّب فلتر أو بحث تاني.';

  @override
  String get productsBoardActionFailed => 'الحركة دي معملتش — جرّب تاني.';

  @override
  String get productsBoardFilterShop => 'الدكان';

  @override
  String get productsBoardDeletedOnly => 'متشال';

  @override
  String get productsBoardDuplicate => 'نسخ';

  @override
  String get productsBoardSoftDelete => 'شيل';

  @override
  String get productsBoardRestore => 'رجّع';

  @override
  String get productsBoardHardDelete => 'حذف نهائي';

  @override
  String get productsBoardConfirmSoftDelete =>
      'تشيل المنتج ده؟ ممكن ترجّعه تاني بعدين.';

  @override
  String productsBoardHardDeleteWarning(Object name) {
    return 'الحركة دي هتمسح \"$name\" نهائي — مش هترجع تاني. اكتب اسم المنتج علشان تأكد.';
  }

  @override
  String get productsBoardTypeNameLabel => 'اسم المنتج';

  @override
  String productsBoardSelectedCount(Object count) {
    return '$count متحدد';
  }

  @override
  String get productsBoardBulkAction => 'حركة جماعية';

  @override
  String get productsBoardBulkPrice => 'تغيير السعر';

  @override
  String get productsBoardBulkStock => 'تحديد حالة المخزون';

  @override
  String get productsBoardBulkPromo => 'علامة العرض';

  @override
  String get productsBoardBulkCategory => 'نقل القسم';

  @override
  String get productsBoardBulkPricePercent => 'نسبة مئوية';

  @override
  String get productsBoardBulkPriceFixed => 'مبلغ ثابت';

  @override
  String get productsBoardBulkPriceIncrease => 'زيادة';

  @override
  String get productsBoardBulkPriceDecrease => 'تخفيض';

  @override
  String get productsBoardBulkPricePercentLabel => 'النسبة';

  @override
  String get productsBoardBulkPriceFixedLabel => 'المبلغ (جنيه)';

  @override
  String get consoleNavTaxonomy => 'الأقسام';

  @override
  String get consoleNavGeo => 'مناطق التوصيل';

  @override
  String get fieldCategoryNameAr => 'اسم القسم (عربي)';

  @override
  String get fieldCategoryNameEn => 'اسم القسم (إنجليزي)';

  @override
  String get fieldAreaNameAr => 'اسم المنطقة (عربي)';

  @override
  String get fieldAreaNameEn => 'اسم المنطقة (إنجليزي)';

  @override
  String get fieldGovernorate => 'المحافظة';

  @override
  String get fieldDeliveryFeeOverrideOptional => 'تغيير رسوم التوصيل (اختياري)';

  @override
  String get validateAmountInvalid => 'اكتب مبلغ صحيح';

  @override
  String get taxonomyBoardHint =>
      'الأقسام اللي بتظهر للعملاء وأصحاب الدكاكين. لو متردد، إخفاء أحسن من مسح.';

  @override
  String get taxonomyBoardAddAction => 'قسم جديد';

  @override
  String get taxonomyBoardErrorBody =>
      'معرفناش نجيب الأقسام دلوقتي — جرّب تاني.';

  @override
  String get taxonomyBoardEmptyTitle => 'لسه مفيش أقسام';

  @override
  String get taxonomyBoardActionFailed => 'الحركة دي معملتش — جرّب تاني.';

  @override
  String get taxonomyBoardHide => 'إخفاء';

  @override
  String get taxonomyBoardShow => 'إظهار';

  @override
  String get taxonomyBoardEditTitle => 'تعديل القسم';

  @override
  String get taxonomyBoardIconLabel => 'الأيقونة';

  @override
  String get taxonomyBoardDeleteConfirmTitle => 'تمسح القسم؟';

  @override
  String get taxonomyBoardDeleteConfirmBody => 'الحركة دي مش هترجع.';

  @override
  String taxonomyBoardDeleteConfirmBodyWithProducts(Object count) {
    return '$count منتج لسه بيستخدم القسم ده — هيفضلوا ظاهرين، بس الحركة دي مش هترجع. تمسح برضو؟';
  }

  @override
  String get geoBoardHint =>
      'مناطق التوصيل اللي بتظهر في الشيك أوت. لو متردد، إيقاف أحسن من مسح.';

  @override
  String get geoBoardAddAction => 'منطقة جديدة';

  @override
  String get geoBoardErrorBody => 'معرفناش نجيب المناطق دلوقتي — جرّب تاني.';

  @override
  String get geoBoardEmptyTitle => 'لسه مفيش مناطق';

  @override
  String get geoBoardActionFailed => 'الحركة دي معملتش — جرّب تاني.';

  @override
  String get geoBoardEditTitle => 'تعديل المنطقة';

  @override
  String geoBoardFeeOverrideBadge(Object fee) {
    return 'تغيير الرسوم: $fee';
  }

  @override
  String get geoBoardDeactivateInsteadTitle => 'توقف المنطقة بدل ما تتمسح؟';

  @override
  String geoBoardDeactivateInsteadBody(Object count) {
    return '$count طلب بيستخدم المنطقة دي — مينفعش تتمسح، بس ممكن توقفها فتختفي من الشيك أوت.';
  }

  @override
  String get geoBoardDeactivateAction => 'إيقاف';

  @override
  String get geoBoardDeleteConfirmTitle => 'تمسح المنطقة؟';

  @override
  String get geoBoardDeleteConfirmBody => 'الحركة دي مش هترجع.';

  @override
  String get consoleNavOrders => 'الطلبات';

  @override
  String get dashboardQuickOrdersWaiting => 'طلبات مستنية';

  @override
  String get ordersBoardSearchLabel => 'رقم الطلب أو رقم الموبايل بالظبط';

  @override
  String get ordersBoardErrorBody =>
      'معرفناش نجيب قائمة الطلبات دلوقتي — جرّب تاني.';

  @override
  String get ordersBoardEmptyTitle => 'مفيش طلبات مطابقة';

  @override
  String get ordersBoardEmptyBody => 'جرّب فلتر أو بحث تاني.';

  @override
  String get ordersBoardShopLabel => 'المتجر';

  @override
  String get ordersBoardAreaLabel => 'المنطقة';

  @override
  String get ordersBoardDateRangeLabel => 'الفترة الزمنية';

  @override
  String get ordersBoardNoDriver => 'بدون مندوب';

  @override
  String get consoleNavDrivers => 'المناديب';

  @override
  String get driversBoardErrorBody =>
      'معرفناش نجيب قايمة المناديب دلوقتي — جرّب تاني.';

  @override
  String get driversBoardEmptyTitle => 'مفيش مناديب مطابقين';

  @override
  String get driversBoardEmptyBody => 'جرّب فلتر تاني.';

  @override
  String get driversFilterPendingActivation => 'بانتظار التفعيل';

  @override
  String get driversFilterActive => 'نشط';

  @override
  String get driversFilterSuspended => 'موقوف';

  @override
  String get driversFilterOnline => 'متصل الآن';

  @override
  String get driverDetailMissingSeed => 'افتح صفحة المندوب من القايمة.';

  @override
  String get driverDetailStatusTitle => 'الحالة';

  @override
  String get driverDetailActiveSwitch => 'نشط';

  @override
  String get driverDetailVerifiedSwitch => 'موثّق';

  @override
  String get driverDetailVerifiedBadge => 'موثّق';

  @override
  String get driverDetailSuspendTitle => 'إيقاف المندوب';

  @override
  String get driverDetailSuspendReasonLabel => 'سبب الإيقاف';

  @override
  String get driverDetailFieldsTitle => 'البيانات';

  @override
  String get fieldDriverName => 'الاسم';

  @override
  String get fieldDriverPhone => 'رقم الموبايل';

  @override
  String get driverDetailAreasLabel => 'مناطق التوصيل';

  @override
  String get driverDetailMaxActiveOrdersLabel => 'أقصى عدد طلبات في نفس الوقت';

  @override
  String get driverDetailVehicleTypeLabel => 'نوع المركبة';

  @override
  String get driverDetailVehiclePlateLabel => 'رقم اللوحة';

  @override
  String get driverDetailIdDocLabel => 'صورة إثبات الشخصية';

  @override
  String get driverDetailIdDocUploadError => 'معرفناش نرفع الصورة — جرّب تاني.';

  @override
  String get driverDetailPerformanceTitle => 'الأداء';

  @override
  String get driverDetailActiveLoad => 'الحمل الحالي';

  @override
  String get driverDetailDeliveredThisMonth => 'التوصيلات الشهر ده';

  @override
  String get driverDetailDeliveredTotal => 'إجمالي التوصيلات';

  @override
  String get driverDetailAssignedOrdersTitle => 'الطلبات الحالية';

  @override
  String get driverDetailNoAssignedOrders => 'مفيش طلبات معاه دلوقتي.';

  @override
  String get consoleNavSettings => 'الإعدادات';

  @override
  String get consoleNavNotifications => 'الإشعارات';

  @override
  String get settingsSaveOk => 'تم الحفظ';

  @override
  String get settingsSaveFailed => 'حصلت مشكلة في الحفظ — جرّب تاني';

  @override
  String get settingsLoadError => 'مش قادرين نجيب الإعدادات دلوقتي — جرّب تاني';

  @override
  String settingsLastEdited(Object when) {
    return 'آخر تعديل $when';
  }

  @override
  String get settingsFooterNote =>
      'التغييرات بتتطبق على الطلبات الجديدة وأول ما التطبيق يتفتح تاني';

  @override
  String get settingsRatesTitle => 'العمولة والتوصيل';

  @override
  String get settingsCommissionLabel => 'العمولة (%)';

  @override
  String get settingsVatLabel => 'الضريبة (%)';

  @override
  String get settingsDeliveryFeeLabel => 'رسوم التوصيل (جنيه)';

  @override
  String get settingsDriverShareLabel => 'نصيب السائق (جنيه)';

  @override
  String get settingsMinOrderLabel => 'أقل قيمة للطلب (جنيه)';

  @override
  String get settingsDriverShareTooHigh =>
      'نصيب السائق مينفعش يبقى أكتر من رسوم التوصيل';

  @override
  String get settingsContactTitle => 'التواصل';

  @override
  String get settingsSupportPhoneLabel => 'تليفون الدعم';

  @override
  String get settingsSupportWhatsAppLabel => 'واتساب الدعم';

  @override
  String get settingsBusinessHoursLabel => 'مواعيد العمل';

  @override
  String get settingsAppGatesTitle => 'التطبيق';

  @override
  String get settingsMaintenanceSwitch => 'وضع الصيانة';

  @override
  String get settingsMaintenanceSwitchHint =>
      'بيوقف التطبيق لأي حد غير فريق العمل';

  @override
  String get settingsMinBuildLabel => 'أقل نسخة مدعومة';

  @override
  String get settingsAppGatesConfirmTitle => 'متأكد؟';

  @override
  String get settingsMaintenanceConfirmBody =>
      'تفعيل وضع الصيانة هيوقف التطبيق دلوقتي لكل عميل وسائق. فريق العمل بس هيقدر يدخل.';

  @override
  String get settingsMinBuildConfirmBody =>
      'أي حد بنسخة أقدم هيتطلب منه يحدّث التطبيق الأول عشان يقدر يستخدمه.';

  @override
  String get settingsFlagsTitle => 'خصائص تجريبية';

  @override
  String get settingsFlagsEmpty => 'لسه مفيش خصائص';

  @override
  String get settingsAddFlagLabel => 'اسم خاصية جديدة';

  @override
  String get maintenanceTitle => 'نرجع لكم حالًا';

  @override
  String get maintenanceBody =>
      'دكان بياخد نفسه شوية. جرّب تاني بعد كام دقيقة.';

  @override
  String get updateRequiredTitle => 'محتاجين تحدّث التطبيق';

  @override
  String get updateRequiredBody =>
      'حدّث تطبيق دكان من متجر Google Play عشان تكمل تستخدمه.';

  @override
  String get notificationsTabSend => 'إرسال';

  @override
  String get notificationsTabHistory => 'السجل';

  @override
  String get notificationsLoadError =>
      'مش قادرين نفتح مركز الإشعارات دلوقتي — جرب تاني.';

  @override
  String get notificationsSendFailed => 'الإرسال فشل — جرب تاني.';

  @override
  String get notificationsSendOk => 'اتبعت';

  @override
  String get notificationsAudienceLabel => 'الفئة المستهدفة';

  @override
  String get notificationsAudienceCustomers => 'العملاء';

  @override
  String get notificationsAudienceOwners => 'أصحاب الدكاكين';

  @override
  String get notificationsAudienceCouriers => 'المناديب';

  @override
  String get notificationsAudienceAll => 'الكل';

  @override
  String get notificationsAudienceSpecificUser => 'مستخدم محدد';

  @override
  String get notificationsTargetSearchLabel => 'دور بالإيميل أو الرقم بالظبط';

  @override
  String get notificationsTargetSearchHint => 'زي user@email.com أو ٠١٠…';

  @override
  String get notificationsTargetNotFound => 'مفيش مستخدم بالإيميل/الرقم ده.';

  @override
  String get notificationsTemplatesLabel => 'القوالب';

  @override
  String get notificationsTitleLabel => 'العنوان';

  @override
  String get notificationsBodyLabel => 'النص';

  @override
  String get notificationsSaveTemplateAction => 'احفظ كقالب';

  @override
  String get notificationsTemplateNameLabel => 'اسم القالب';

  @override
  String get notificationsTemplateRename => 'تغيير الاسم';

  @override
  String get notificationsTemplateDelete => 'حذف';

  @override
  String get notificationsPreviewLabel => 'معاينة';

  @override
  String get notificationsSendAction => 'إرسال';

  @override
  String get notificationsConfirmTitle => 'تبعت الإشعار ده؟';

  @override
  String notificationsConfirmDirectBody(Object name) {
    return 'هيتبعت لـ $name دلوقتي.';
  }

  @override
  String notificationsConfirmBroadcastBody(Object audience) {
    return 'هيتبعت لكل اللي في \"$audience\" دلوقتي. مش هنقدر نقولك عددهم كام — الإشعار العام معندوش معاينة لعدد المستقبلين.';
  }

  @override
  String get notificationsHistoryEmptyTitle => 'معدش اتبعت حاجة';

  @override
  String get notificationsHistoryEmptyBody =>
      'الإشعارات العامة والمباشرة هتظهر هنا.';

  @override
  String get notificationsResendAction => 'إعادة الإرسال';

  @override
  String get notificationsStatusSent => 'اتبعت';

  @override
  String get notificationsStatusFailed => 'فشل';

  @override
  String get notificationsStatusSkipped => 'اتجاهل';

  @override
  String notificationsStatsSent(Object count) {
    return '$count اتبعتوا';
  }

  @override
  String notificationsStatsFailed(Object count) {
    return '$count فشلوا';
  }

  @override
  String get consoleNavMedia => 'مكتبة الصور';

  @override
  String get mediaTabBrowse => 'تصفح';

  @override
  String get mediaTabUnused => 'غير مستخدم';

  @override
  String get mediaTabBroken => 'روابط معطلة';

  @override
  String get mediaLoadError => 'مش قادرين نفتح مكتبة الصور دلوقتي — جرب تاني.';

  @override
  String get mediaFolderAll => 'الكل';

  @override
  String get mediaFolderShopLogos => 'شعارات الدكاكين';

  @override
  String get mediaFolderProductImages => 'صور المنتجات';

  @override
  String get mediaFolderDriverDocs => 'مستندات المناديب';

  @override
  String get mediaFolderBanners => 'بانرات';

  @override
  String get mediaStatsCountLabel => 'صورة';

  @override
  String get mediaStatsSizeLabel => 'الحجم الكلي';

  @override
  String get mediaEmptyTitle => 'مفيش صور هنا';

  @override
  String get mediaEmptyBody => 'الصور المرفوعة للقسم ده هتظهر هنا.';

  @override
  String get mediaUploadAction => 'رفع صورة';

  @override
  String get mediaUploadErrorBody => 'الرفع فشل — جرب تاني.';

  @override
  String get mediaDeleteConfirmTitle => 'متأكد؟';

  @override
  String mediaDeleteConfirmBody(Object count) {
    return 'هيتحذف $count صورة نهائيًا — الصور لا تخضع للاسترجاع.';
  }

  @override
  String get mediaDeleteAction => 'حذف';

  @override
  String mediaSelectedCount(Object count) {
    return '$count متحدد';
  }

  @override
  String get mediaFindersScanningBody => 'جارٍ فحص الصور والروابط المرتبطة…';

  @override
  String get mediaFindersErrorBody => 'مش قادرين نفحص الصور دلوقتي — جرب تاني.';

  @override
  String get mediaUnusedEmptyTitle => 'مفيش صور غير مستخدمة';

  @override
  String get mediaUnusedEmptyBody => 'كل الصور في المكتبة مرتبطة بحاجة.';

  @override
  String get mediaUnusedSelectAllAction => 'تحديد الكل';

  @override
  String get mediaBrokenEmptyTitle => 'كل الروابط شغالة';

  @override
  String get mediaBrokenEmptyBody => 'مفيش رابط صورة معطل دلوقتي.';

  @override
  String get mediaDocTypeShop => 'دكان';

  @override
  String get mediaDocTypeProduct => 'منتج';

  @override
  String get mediaDocTypeDriver => 'مندوب';

  @override
  String get mediaDocTypeBanner => 'بانر';

  @override
  String get mediaBrokenFixAction => 'روح لمصدرها';
}
