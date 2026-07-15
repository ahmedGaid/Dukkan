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
  String get roleCourier => 'Courier';

  @override
  String get roleBadgeCustomer => 'Customer';

  @override
  String get roleBadgeOwner => 'Shop owner';

  @override
  String get roleBadgeCourier => 'Courier';

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
  String get navHome => 'Home';

  @override
  String get navCategories => 'Categories';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navOrders => 'Orders';

  @override
  String get navMore => 'More';

  @override
  String get homeSearchHint => 'Search for a product or shop';

  @override
  String get sectionOffers => 'Offers';

  @override
  String get sectionCategories => 'Categories';

  @override
  String get sectionNearbyShops => 'Shops near you';

  @override
  String get categoryAll => 'All';

  @override
  String get shopOpen => 'Open';

  @override
  String get shopClosed => 'Closed';

  @override
  String get shopsEmptyTitle => 'No shops near you yet';

  @override
  String get shopsEmptyBody => 'We add new shops every day — check back soon.';

  @override
  String get categoryEmptyTitle => 'No shops in this category';

  @override
  String get categoryEmptyBody => 'Try another category or see all shops.';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorBody => 'We can\'t load the shops right now — try again.';

  @override
  String get actionRetry => 'Try again';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyBody =>
      'Tap the heart on any shop or product you love — it\'ll be saved here.';

  @override
  String get favoriteActionErrorBody => 'We couldn\'t save that — try again.';

  @override
  String get favoritesSectionShops => 'Shops';

  @override
  String get favoritesSectionProducts => 'Products';

  @override
  String get favoritesErrorBody =>
      'We can\'t load your favorites right now — try again.';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyBody =>
      'Once you order from a shop, you\'ll track it here step by step.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLangArabic => 'العربية';

  @override
  String get settingsLangEnglish => 'English';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLogoutConfirmTitle => 'Log out?';

  @override
  String get settingsLogoutConfirmBody =>
      'You\'ll need to sign in again to continue.';

  @override
  String get categoriesComingSoonTitle => 'Browse by category — coming soon';

  @override
  String get categoriesComingSoonBody =>
      'You\'ll browse each category on its own here soon. For now, categories are on Home.';

  @override
  String get promoBadge => 'Offer';

  @override
  String get productStockIn => 'In stock';

  @override
  String get productStockLow => 'Low stock';

  @override
  String get productStockOut => 'Out of stock';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionAddToCart => 'Add to cart';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionEnable => 'Enable';

  @override
  String get actionDisable => 'Disable';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClearAndAdd => 'Clear and add';

  @override
  String get actionCheckout => 'Checkout';

  @override
  String get actionPlaceOrder => 'Place order';

  @override
  String get actionBackHome => 'Back to home';

  @override
  String get qtyLabel => 'Quantity';

  @override
  String get qtyIncrease => 'Increase by one';

  @override
  String get qtyDecrease => 'Decrease by one';

  @override
  String get cartItemAdded => 'Added to cart';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartClearAll => 'Clear cart';

  @override
  String get cartClearConfirmTitle => 'Clear the cart?';

  @override
  String get cartClearConfirmBody => 'This removes every item from your cart.';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyBody => 'Add products from a shop to see them here.';

  @override
  String get cartEmptyAction => 'Browse shops';

  @override
  String get cartSwitchShopTitle => 'Start a new cart?';

  @override
  String get cartSwitchShopBody =>
      'Your cart has items from another shop. Adding this will clear it first.';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutAddressSection => 'Delivery address';

  @override
  String get checkoutSummary => 'Order summary';

  @override
  String get checkoutErrorBody => 'We couldn\'t place your order — try again.';

  @override
  String get fieldAddressLine => 'Address';

  @override
  String get fieldCity => 'City';

  @override
  String get fieldNotesOptional => 'Notes (optional)';

  @override
  String get codLabel => 'Cash on delivery';

  @override
  String get orderPlacedTitle => 'Order placed!';

  @override
  String get orderPlacedBody =>
      'The shop will start preparing your order soon.';

  @override
  String get ordersErrorBody =>
      'We can\'t load your orders right now — try again.';

  @override
  String get orderDetailTitle => 'Order details';

  @override
  String get orderStatusPending => 'Awaiting confirmation';

  @override
  String get orderStatusAccepted => 'Accepted';

  @override
  String get orderStatusPreparing => 'Preparing';

  @override
  String get orderStatusOutForDelivery => 'Out for delivery';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusRejected => 'Rejected';

  @override
  String get actionCancelOrder => 'Cancel order';

  @override
  String get orderCancelConfirmTitle => 'Cancel this order?';

  @override
  String get orderCancelConfirmBody => 'You won\'t be able to undo this.';

  @override
  String get orderCancelErrorBody =>
      'We couldn\'t cancel your order — try again.';

  @override
  String get orderRateTitle => 'Rate this shop';

  @override
  String get orderRateBody => 'How was your experience with this shop?';

  @override
  String get orderRatedTitle => 'Your rating';

  @override
  String get orderRateErrorBody => 'We couldn\'t save your rating — try again.';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navOrderDesk => 'Orders';

  @override
  String get orderDeskTitle => 'Orders';

  @override
  String get orderDeskEmptyTitle => 'No orders yet';

  @override
  String get orderDeskEmptyBody =>
      'New orders from your customers will show up here.';

  @override
  String get orderDeskErrorBody =>
      'We can\'t load your orders right now — try again.';

  @override
  String get orderDeskTodayLabel => 'Today';

  @override
  String get actionAcceptOrder => 'Accept';

  @override
  String get actionRejectOrder => 'Reject';

  @override
  String get actionStartPreparing => 'Start preparing';

  @override
  String get actionStartDelivery => 'Out for delivery';

  @override
  String get actionMarkDelivered => 'Mark delivered';

  @override
  String get orderRejectConfirmTitle => 'Reject this order?';

  @override
  String get orderRejectConfirmBody =>
      'The customer will be notified it was rejected.';

  @override
  String get orderActionErrorBody =>
      'We couldn\'t update this order — try again.';

  @override
  String get orderCustomerSection => 'Customer';

  @override
  String get orderPaymentMethod => 'Payment method';

  @override
  String get orderSubtotalLabel => 'Subtotal';

  @override
  String get orderDeliveryFeeLabel => 'Delivery fee';

  @override
  String get orderDriverSection => 'Driver';

  @override
  String get orderAssignDriverButton => 'Assign courier';

  @override
  String get orderAssignDriverSheetTitle => 'Assign a courier';

  @override
  String get orderAssignDriverEmptyTitle => 'No couriers available';

  @override
  String get orderAssignDriverEmptyBody =>
      'No couriers available right now — you can deliver it yourself';

  @override
  String get orderAssignDriverConfirmTitle => 'Assign this courier?';

  @override
  String get orderAssignDriverConfirmBody =>
      'The order moves to this courier once assigned.';

  @override
  String get orderAssignDriverErrorOffline =>
      'This courier just went offline — try another one.';

  @override
  String get orderAssignDriverErrorCapacity =>
      'This courier is at full capacity — try another one.';

  @override
  String get orderAssignDriverErrorArea =>
      'This courier doesn\'t cover this area — try another one.';

  @override
  String get orderAssignDriverErrorTaken =>
      'This order already has a courier assigned.';

  @override
  String get orderAssignDriverErrorGeneric =>
      'We couldn\'t assign this courier — try again.';

  @override
  String get orderAssignedAtLabel => 'Assigned';

  @override
  String get orderTimelineTitle => 'Order history';

  @override
  String get orderForcedChip => 'Staff correction';

  @override
  String get orderNotesTitle => 'Internal notes';

  @override
  String get orderNotesEmpty => 'No notes yet.';

  @override
  String get orderNotesAddHint => 'Add a note for other staff…';

  @override
  String get orderForceStatusAction => 'Force status';

  @override
  String get orderForceStatusWarning =>
      'This skips the normal order flow — use it only to correct a mistake.';

  @override
  String get orderForceStatusLabel => 'New status';

  @override
  String get orderStaffReasonLabel => 'Reason (required)';

  @override
  String get orderReassignDriverAction => 'Reassign driver';

  @override
  String get orderUnassignDriverAction => 'Unassign driver';

  @override
  String get orderRefundNoteLabel => 'Refund note (optional)';

  @override
  String get orderRefundNoteHelper => 'COD ledger note only — no money moves.';

  @override
  String get staffOrderActionErrorBody =>
      'We couldn\'t complete this action — try again.';

  @override
  String get notifyNewOrderTitle => 'New order!';

  @override
  String get notifyNewOrderBody =>
      'You\'ve got a new order — open your shop to check it out.';

  @override
  String get notifyOrderStatusTitle => 'Order update';

  @override
  String notifyOrderStatusBody(Object status) {
    return 'Your order is now $status.';
  }

  @override
  String get notifyDriverAssignedTitle => 'New delivery';

  @override
  String notifyDriverAssignedBody(Object area, Object shop) {
    return '$shop has a delivery for you in $area.';
  }

  @override
  String get notifyOrderDeliveredTitle => 'Order delivered';

  @override
  String get notifyOrderDeliveredBody => 'The courier delivered the order.';

  @override
  String get shopProductsEmptyTitle => 'This shop is still stocking up';

  @override
  String get shopProductsEmptyBody =>
      'Products will show up here as soon as the shop adds them.';

  @override
  String get productsCategoryEmptyTitle => 'No products in this category';

  @override
  String get productsCategoryEmptyBody =>
      'Try another category or see all products.';

  @override
  String get shopErrorBody => 'We can\'t open this shop right now — try again.';

  @override
  String get productNotFoundTitle => 'Product not found';

  @override
  String get productNotFoundBody =>
      'It may have been removed. Go back and see the other products.';

  @override
  String get searchPromptTitle => 'Search the marketplace';

  @override
  String get searchPromptBody =>
      'Type a product or shop name and we\'ll find it.';

  @override
  String get searchNoResultsTitle => 'No results';

  @override
  String get searchNoResultsBody => 'Try another word or a shorter name.';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchErrorBody =>
      'We can\'t finish the search right now — try again.';

  @override
  String get shopOnboardingTitle => 'Set up your shop';

  @override
  String get shopOnboardingSubtitle =>
      'Customers will see this as soon as you\'re done.';

  @override
  String get fieldShopName => 'Shop name (English)';

  @override
  String get fieldShopNameAr => 'Shop name (Arabic)';

  @override
  String get fieldShopAddress => 'Shop address';

  @override
  String get shopOnboardingLogoLabel => 'Shop logo';

  @override
  String get shopOnboardingLogoHint => 'Tap to add a photo';

  @override
  String get shopOnboardingOpenLabel => 'Open for orders';

  @override
  String get actionCreateShop => 'Create shop';

  @override
  String get shopOnboardingErrorBody =>
      'We couldn\'t create your shop — try again.';

  @override
  String get shopOnboardingLogoErrorBody =>
      'We couldn\'t upload the logo — try again.';

  @override
  String get catalogEmptyTitle => 'No products yet';

  @override
  String get catalogEmptyBody =>
      'Add your first product and it\'ll show up here.';

  @override
  String get catalogErrorBody =>
      'We can\'t load your catalog right now — try again.';

  @override
  String get actionAddProduct => 'Add product';

  @override
  String get addProductTitle => 'Add product';

  @override
  String get editProductTitle => 'Edit product';

  @override
  String get fieldProductName => 'Product name (English)';

  @override
  String get fieldProductNameAr => 'Product name (Arabic)';

  @override
  String get fieldProductCategory => 'Category';

  @override
  String get fieldProductSubcategory => 'Subcategory';

  @override
  String get categoryRequired => 'Choose a category';

  @override
  String get subcategoryRequired => 'Choose a subcategory';

  @override
  String get taxonomyErrorBody =>
      'We can\'t load categories right now — try again.';

  @override
  String get fieldProductPrice => 'Price (EGP)';

  @override
  String get fieldProductStock => 'Stock';

  @override
  String get fieldProductPromoLabel => 'Mark as an offer';

  @override
  String get productImageLabel => 'Product photo';

  @override
  String get actionSave => 'Save';

  @override
  String get productFormErrorBody =>
      'We couldn\'t save this product — try again.';

  @override
  String get productImageErrorBody =>
      'We couldn\'t upload the photo — try again.';

  @override
  String get validatePriceInvalid => 'Enter a valid price';

  @override
  String get productDeleteConfirmTitle => 'Delete this product?';

  @override
  String get productDeleteConfirmBody =>
      'It\'ll be removed from your shop right away.';

  @override
  String get actionDelete => 'Delete';

  @override
  String get productDeleteErrorBody =>
      'We couldn\'t delete this product — try again.';

  @override
  String get actionCreate => 'Create';

  @override
  String get catalogCollectionsEntry => 'Collections';

  @override
  String get collectionsEmptyTitle => 'No collections yet';

  @override
  String get collectionsEmptyAction => 'Create a collection';

  @override
  String get collectionsErrorBody =>
      'We can\'t load your collections right now — try again.';

  @override
  String get collectionsCreateTitle => 'New collection';

  @override
  String get collectionsRenameTitle => 'Edit collection';

  @override
  String get fieldCollectionNameAr => 'Name (Arabic)';

  @override
  String get fieldCollectionNameEn => 'Name (English)';

  @override
  String get collectionNameArHint => 'e.g. عروض';

  @override
  String get collectionNameEnHint => 'e.g. Offers';

  @override
  String get collectionsDeleteConfirmTitle => 'Delete this collection?';

  @override
  String get collectionsDeleteConfirmBody =>
      'Deleting the collection keeps the products';

  @override
  String get collectionsActionErrorBody => 'Something went wrong — try again.';

  @override
  String get productCollections => 'Collections (optional)';

  @override
  String get fieldArea => 'Area';

  @override
  String get areaRequired => 'Choose your area';

  @override
  String get areasErrorBody => 'We can\'t load areas right now — try again.';

  @override
  String get navDeliveries => 'Deliveries';

  @override
  String get courierOnlineLabel => 'Online';

  @override
  String get courierOfflineLabel => 'Offline';

  @override
  String get courierSuspendedBannerBody =>
      'Your account is under review — contact Dukkan';

  @override
  String get courierActiveTabLabel => 'Active';

  @override
  String get courierHistoryTabLabel => 'History';

  @override
  String get courierActiveEmptyTitle => 'No deliveries right now';

  @override
  String get courierHistoryEmptyTitle => 'No delivery history yet';

  @override
  String get courierActionPickedUp => 'Picked up';

  @override
  String get courierActionDelivered => 'Delivered';

  @override
  String get courierActionDeliveredConfirmTitle => 'Confirm delivery?';

  @override
  String get courierActionDeliveredConfirmBody =>
      'You won\'t be able to undo this.';

  @override
  String get financeTitle => 'Finance';

  @override
  String get financeLedgerNote =>
      'Ledger figures — settlement with shops is manual';

  @override
  String get financeTotalOrders => 'Total orders';

  @override
  String get financeDeliveredOrders => 'Delivered orders';

  @override
  String get financeCancelledOrders => 'Cancelled orders';

  @override
  String get financeTotalCommission => 'Total commission';

  @override
  String get financeDeliveryRevenue => 'Delivery revenue';

  @override
  String get financeTotalPlatformRevenue => 'Total platform revenue';

  @override
  String get financeErrorBody =>
      'We can\'t load the finance numbers right now — try again.';

  @override
  String get consoleTitle => 'Console';

  @override
  String get consoleNavDashboard => 'Dashboard';

  @override
  String get consoleNavAudit => 'Activity log';

  @override
  String get consoleNavUsers => 'Users';

  @override
  String get consoleDashboardSubtitle =>
      'Your platform overview will appear here soon.';

  @override
  String get consoleComingSoon => 'This section is coming soon.';

  @override
  String get settingsConsoleRow => 'Console';

  @override
  String get roleFounder => 'Founder';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleModerator => 'Moderator';

  @override
  String get roleSupport => 'Support';

  @override
  String get auditFilterAction => 'Action';

  @override
  String get auditFilterType => 'Type';

  @override
  String get auditFilterTargetId => 'Target ID';

  @override
  String get auditFilterAll => 'All';

  @override
  String get auditFilterDateRange => 'Date range';

  @override
  String get auditFilterClear => 'Clear filters';

  @override
  String get auditReported => 'Reported';

  @override
  String get auditLoadMore => 'Load more';

  @override
  String get auditEmptyTitle => 'No activity yet';

  @override
  String get auditEmptyBody => 'Actions across the platform will show up here.';

  @override
  String get auditErrorBody =>
      'We couldn\'t load the log right now — try again.';

  @override
  String get auditDetailTarget => 'Target';

  @override
  String get auditDetailActor => 'Performed by';

  @override
  String get auditDetailWhen => 'When';

  @override
  String get auditDetailReason => 'Reason';

  @override
  String get auditDetailIp => 'IP address';

  @override
  String get auditDetailChanges => 'Changes';

  @override
  String get auditDetailField => 'Field';

  @override
  String get auditDetailBefore => 'Before';

  @override
  String get auditDetailAfter => 'After';

  @override
  String get auditDetailNoChanges => 'No field changes recorded.';

  @override
  String get auditTimeJustNow => 'Just now';

  @override
  String auditTimeMinutesAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}m ago';
  }

  @override
  String auditTimeHoursAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}h ago';
  }

  @override
  String auditTimeDaysAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}d ago';
  }

  @override
  String get dashboardOrdersToday => 'Orders today';

  @override
  String get dashboardRevenueToday => 'Revenue today';

  @override
  String get dashboardCommissionToday => 'Commission today';

  @override
  String get dashboardOrdersWaiting => 'Orders waiting';

  @override
  String get dashboardTotalUsers => 'Users';

  @override
  String get dashboardTotalShops => 'Shops';

  @override
  String get dashboardTotalProducts => 'Products';

  @override
  String get dashboardDriversOnline => 'Drivers online';

  @override
  String get dashboardPendingShops => 'Shops pending approval';

  @override
  String get dashboardChartTitle => 'Orders — last 7 days';

  @override
  String get dashboardActivityTitle => 'Recent activity';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardActivityEmpty => 'No recent activity yet.';

  @override
  String get dashboardQuickActionsTitle => 'Quick actions';

  @override
  String get dashboardQuickAudit => 'Open activity log';

  @override
  String get dashboardExternalTitle => 'External tools';

  @override
  String get dashboardCrashlyticsTitle => 'Crashlytics';

  @override
  String get dashboardCrashlyticsNote =>
      'Crash reports open in the Firebase console.';

  @override
  String get dashboardErrorBody =>
      'We can\'t load the dashboard right now — try again.';

  @override
  String get usersErrorBody =>
      'We can\'t load the user list right now — try again.';

  @override
  String get usersEmptyTitle => 'No users found';

  @override
  String get usersEmptyBody => 'Try a different search or filter.';

  @override
  String get usersSearchLabel => 'Search';

  @override
  String get usersSearchHint => 'Exact email or phone, else name on this page';

  @override
  String get usersFilterRole => 'Role';

  @override
  String get usersFilterStatus => 'Status';

  @override
  String get usersRoleCustomer => 'Customer';

  @override
  String get usersRoleOwner => 'Owner';

  @override
  String get usersRoleCourier => 'Courier';

  @override
  String get usersStatusActive => 'Active';

  @override
  String get usersStatusSuspended => 'Suspended';

  @override
  String get usersStatusBanned => 'Banned';

  @override
  String get usersDeletedLabel => 'Deleted';

  @override
  String usersSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString selected';
  }

  @override
  String get usersBulkSuspend => 'Suspend';

  @override
  String get usersBulkUnsuspend => 'Reactivate';

  @override
  String get usersBulkConfirmTitle => 'Bulk action';

  @override
  String usersBulkConfirmBody(Object action) {
    return '$action the selected users?';
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

    return '$doneString/$totalString done';
  }

  @override
  String get userDetailMissingSeed =>
      'Open this page from the user list — there\'s nothing to show yet.';

  @override
  String get userDetailBackToList => 'Back to users';

  @override
  String get userDetailActionOk => 'Done';

  @override
  String get userDetailActionFailed => 'That didn\'t work — try again.';

  @override
  String get userDetailProfileTitle => 'Profile';

  @override
  String get userDetailEmail => 'Email';

  @override
  String get userDetailPhone => 'Phone';

  @override
  String get userDetailMemberSince => 'Member since';

  @override
  String get userDetailUnknown => 'Unknown';

  @override
  String get userDetailActionsTitle => 'Actions';

  @override
  String get userDetailBan => 'Ban';

  @override
  String get userDetailConfirmSuspend =>
      'Suspend this account? They won\'t be able to sign in until reactivated.';

  @override
  String get userDetailConfirmBan =>
      'Ban this account? This is more severe than a suspension.';

  @override
  String get userDetailConfirmPasswordReset =>
      'Send a password reset email to this account?';

  @override
  String get userDetailSendPasswordReset => 'Send password reset';

  @override
  String get userDetailChangeEmail => 'Change email';

  @override
  String get userDetailSetPersonaRole => 'Change persona role';

  @override
  String get userDetailConfirmSoftDelete =>
      'Deactivate this account? This is reversible — you can restore it later.';

  @override
  String get userDetailSoftDelete => 'Deactivate';

  @override
  String get userDetailRestore => 'Restore';

  @override
  String get userDetailAuthTitle => 'Sign-in';

  @override
  String get userDetailEmailVerified => 'Email verified';

  @override
  String get userDetailAuthDisabled => 'Sign-in disabled';

  @override
  String get userDetailYes => 'Yes';

  @override
  String get userDetailNo => 'No';

  @override
  String get userDetailLastLogin => 'Last login';

  @override
  String get userDetailStaffTitle => 'Staff';

  @override
  String get userDetailNotStaff => 'Not a staff member.';

  @override
  String get userDetailStaffRole => 'Staff role';

  @override
  String get userDetailStaffPermissions => 'Permissions';

  @override
  String get userDetailMakeStaff => 'Make staff';

  @override
  String get userDetailEditStaff => 'Edit staff';

  @override
  String get userDetailRemoveStaff => 'Remove staff';

  @override
  String get userDetailExtraPermissionsHint =>
      'Extra permissions, added on top of the role\'s own set:';

  @override
  String get userDetailShopsTitle => 'Shop';

  @override
  String get userDetailNoShop => 'No shop owned.';

  @override
  String get userDetailOrdersTitle => 'Orders';

  @override
  String get userDetailNoOrders => 'No orders yet.';

  @override
  String get userDetailAuditTitle => 'Activity';

  @override
  String get catalogPendingBannerTitle => 'Under review';

  @override
  String get catalogPendingBannerBody =>
      'Your shop isn\'t visible to customers yet — the team is reviewing it.';

  @override
  String get consoleNavShops => 'Shops';

  @override
  String get shopsBoardSearchLabel => 'Search by name';

  @override
  String get shopsBoardCreateAction => 'New shop';

  @override
  String get shopsBoardErrorBody =>
      'We can\'t load the shop list right now — try again.';

  @override
  String get shopsBoardEmptyTitle => 'No shops match';

  @override
  String get shopsBoardEmptyBody => 'Try a different filter or search.';

  @override
  String shopsBoardOwnerLabel(Object ownerUid) {
    return 'Owner: $ownerUid';
  }

  @override
  String get shopsFilterAll => 'All';

  @override
  String get shopsStatusPending => 'Under review';

  @override
  String get shopsStatusActive => 'Active';

  @override
  String get shopsStatusSuspended => 'Suspended';

  @override
  String get shopsStatusDeleted => 'Deleted';

  @override
  String get shopsFeaturedBadge => 'Featured';

  @override
  String get shopsVerifiedBadge => 'Verified';

  @override
  String get shopDetailMissingSeed =>
      'Open this page from the shop list — there\'s nothing to show yet.';

  @override
  String get shopDetailStatusTitle => 'Status';

  @override
  String get shopDetailApprove => 'Approve';

  @override
  String get shopDetailConfirmApprove =>
      'Approve this shop? It becomes visible to customers.';

  @override
  String get shopDetailReject => 'Reject';

  @override
  String get shopDetailRejectReasonLabel => 'Reason (shown in the audit log)';

  @override
  String get shopDetailSuspend => 'Suspend';

  @override
  String get shopDetailConfirmSuspend =>
      'Suspend this shop? It disappears from customer surfaces immediately.';

  @override
  String get shopDetailUnsuspend => 'Reactivate';

  @override
  String get shopDetailFieldsTitle => 'Details';

  @override
  String get shopDetailHoursNoteLabel => 'Working hours note (optional)';

  @override
  String get shopDetailTransferTitle => 'Transfer ownership';

  @override
  String get shopDetailTransferHint =>
      'Moves this shop to a different owner. The new owner must already have an owner account.';

  @override
  String get shopDetailNewOwnerUidLabel => 'New owner\'s user ID';

  @override
  String get shopDetailTransferAction => 'Transfer';

  @override
  String shopDetailConfirmTransfer(Object newOwnerUid) {
    return 'Transfer this shop to user $newOwnerUid? This can\'t be undone from here.';
  }

  @override
  String get shopTransferOldOwnerHint =>
      'The previous owner still has the owner role with no shop — update their account in user management if needed.';

  @override
  String get shopDetailDangerTitle => 'Danger zone';

  @override
  String get shopDetailConfirmSoftDelete =>
      'Remove this shop? It can be restored later.';

  @override
  String get shopDetailShortcutsTitle => 'Shortcuts';

  @override
  String get shopCreateOwnerTitle => 'Owner';

  @override
  String get shopCreateOwnerEmailLabel => 'Owner\'s email';

  @override
  String get shopCreateOwnerNotFound => 'No user with that email.';

  @override
  String get shopCreateOwnerNotOwnerRole =>
      'That account isn\'t an owner account.';

  @override
  String get shopCreateOwnerRequired => 'Find the owner first.';

  @override
  String get consoleNavProducts => 'Products';

  @override
  String get productsBoardSearchLabel => 'Search by name';

  @override
  String get productsBoardErrorBody =>
      'We can\'t load the product list right now — try again.';

  @override
  String get productsBoardEmptyTitle => 'No products match';

  @override
  String get productsBoardEmptyBody => 'Try a different filter or search.';

  @override
  String get productsBoardActionFailed =>
      'That didn\'t go through — try again.';

  @override
  String get productsBoardFilterShop => 'Shop';

  @override
  String get productsBoardDeletedOnly => 'Deleted';

  @override
  String get productsBoardDuplicate => 'Duplicate';

  @override
  String get productsBoardSoftDelete => 'Remove';

  @override
  String get productsBoardRestore => 'Restore';

  @override
  String get productsBoardHardDelete => 'Delete forever';

  @override
  String get productsBoardConfirmSoftDelete =>
      'Remove this product? It can be restored later.';

  @override
  String productsBoardHardDeleteWarning(Object name) {
    return 'This permanently deletes \"$name\" — it can\'t be restored. Type the product\'s name to confirm.';
  }

  @override
  String get productsBoardTypeNameLabel => 'Product name';

  @override
  String productsBoardSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get productsBoardBulkAction => 'Bulk action';

  @override
  String get productsBoardBulkPrice => 'Change price';

  @override
  String get productsBoardBulkStock => 'Set stock status';

  @override
  String get productsBoardBulkPromo => 'Promo flag';

  @override
  String get productsBoardBulkCategory => 'Move category';

  @override
  String get productsBoardBulkPricePercent => 'Percent';

  @override
  String get productsBoardBulkPriceFixed => 'Fixed amount';

  @override
  String get productsBoardBulkPriceIncrease => 'Increase';

  @override
  String get productsBoardBulkPriceDecrease => 'Decrease';

  @override
  String get productsBoardBulkPricePercentLabel => 'Percent';

  @override
  String get productsBoardBulkPriceFixedLabel => 'Amount (EGP)';

  @override
  String get consoleNavTaxonomy => 'Categories';

  @override
  String get consoleNavGeo => 'Delivery Areas';

  @override
  String get fieldCategoryNameAr => 'Category name (Arabic)';

  @override
  String get fieldCategoryNameEn => 'Category name (English)';

  @override
  String get fieldAreaNameAr => 'Area name (Arabic)';

  @override
  String get fieldAreaNameEn => 'Area name (English)';

  @override
  String get fieldGovernorate => 'Governorate';

  @override
  String get fieldDeliveryFeeOverrideOptional =>
      'Delivery fee override (optional)';

  @override
  String get validateAmountInvalid => 'Enter a valid amount';

  @override
  String get taxonomyBoardHint =>
      'Categories shown to customers and shop owners. Hide instead of delete when in doubt.';

  @override
  String get taxonomyBoardAddAction => 'Add category';

  @override
  String get taxonomyBoardErrorBody =>
      'We can\'t load the categories right now — try again.';

  @override
  String get taxonomyBoardEmptyTitle => 'No categories yet';

  @override
  String get taxonomyBoardActionFailed =>
      'That didn\'t go through — try again.';

  @override
  String get taxonomyBoardHide => 'Hide';

  @override
  String get taxonomyBoardShow => 'Show';

  @override
  String get taxonomyBoardEditTitle => 'Edit category';

  @override
  String get taxonomyBoardIconLabel => 'Icon';

  @override
  String get taxonomyBoardDeleteConfirmTitle => 'Delete category?';

  @override
  String get taxonomyBoardDeleteConfirmBody => 'This can\'t be undone.';

  @override
  String taxonomyBoardDeleteConfirmBodyWithProducts(Object count) {
    return '$count products still use this category — they\'ll keep showing, but this can\'t be undone. Delete anyway?';
  }

  @override
  String get geoBoardHint =>
      'Delivery districts shown at checkout. Deactivate instead of delete when in doubt.';

  @override
  String get geoBoardAddAction => 'Add area';

  @override
  String get geoBoardErrorBody =>
      'We can\'t load the areas right now — try again.';

  @override
  String get geoBoardEmptyTitle => 'No areas yet';

  @override
  String get geoBoardActionFailed => 'That didn\'t go through — try again.';

  @override
  String get geoBoardEditTitle => 'Edit area';

  @override
  String geoBoardFeeOverrideBadge(Object fee) {
    return 'Fee override: $fee';
  }

  @override
  String get geoBoardDeactivateInsteadTitle => 'Deactivate instead?';

  @override
  String geoBoardDeactivateInsteadBody(Object count) {
    return '$count orders reference this area — it can\'t be deleted, but you can deactivate it so it stops showing at checkout.';
  }

  @override
  String get geoBoardDeactivateAction => 'Deactivate';

  @override
  String get geoBoardDeleteConfirmTitle => 'Delete area?';

  @override
  String get geoBoardDeleteConfirmBody => 'This can\'t be undone.';

  @override
  String get consoleNavOrders => 'Orders';

  @override
  String get dashboardQuickOrdersWaiting => 'Orders waiting';

  @override
  String get ordersBoardSearchLabel => 'Order id or exact phone';

  @override
  String get ordersBoardErrorBody =>
      'We can\'t load the order list right now — try again.';

  @override
  String get ordersBoardEmptyTitle => 'No orders match';

  @override
  String get ordersBoardEmptyBody => 'Try a different filter or search.';

  @override
  String get ordersBoardShopLabel => 'Shop';

  @override
  String get ordersBoardAreaLabel => 'Area';

  @override
  String get ordersBoardDateRangeLabel => 'Date range';

  @override
  String get ordersBoardNoDriver => 'No driver';

  @override
  String get consoleNavDrivers => 'Drivers';

  @override
  String get driversBoardErrorBody =>
      'We can\'t load the driver list right now — try again.';

  @override
  String get driversBoardEmptyTitle => 'No drivers match';

  @override
  String get driversBoardEmptyBody => 'Try a different filter.';

  @override
  String get driversFilterPendingActivation => 'Pending activation';

  @override
  String get driversFilterActive => 'Active';

  @override
  String get driversFilterSuspended => 'Suspended';

  @override
  String get driversFilterOnline => 'Online now';

  @override
  String get driverDetailMissingSeed => 'Open a driver\'s page from the list.';

  @override
  String get driverDetailStatusTitle => 'Status';

  @override
  String get driverDetailActiveSwitch => 'Active';

  @override
  String get driverDetailVerifiedSwitch => 'Verified';

  @override
  String get driverDetailVerifiedBadge => 'Verified';

  @override
  String get driverDetailSuspendTitle => 'Suspend driver';

  @override
  String get driverDetailSuspendReasonLabel => 'Suspension reason';

  @override
  String get driverDetailFieldsTitle => 'Details';

  @override
  String get fieldDriverName => 'Name';

  @override
  String get fieldDriverPhone => 'Phone number';

  @override
  String get driverDetailAreasLabel => 'Delivery areas';

  @override
  String get driverDetailMaxActiveOrdersLabel => 'Max orders at once';

  @override
  String get driverDetailVehicleTypeLabel => 'Vehicle type';

  @override
  String get driverDetailVehiclePlateLabel => 'Plate number';

  @override
  String get driverDetailIdDocLabel => 'ID document photo';

  @override
  String get driverDetailIdDocUploadError =>
      'We couldn\'t upload the photo — try again.';

  @override
  String get driverDetailPerformanceTitle => 'Performance';

  @override
  String get driverDetailActiveLoad => 'Current load';

  @override
  String get driverDetailDeliveredThisMonth => 'Delivered this month';

  @override
  String get driverDetailDeliveredTotal => 'Total delivered';

  @override
  String get driverDetailAssignedOrdersTitle => 'Current orders';

  @override
  String get driverDetailNoAssignedOrders => 'No orders assigned right now.';
}
