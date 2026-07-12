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
}
