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
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyBody =>
      'Once you order from a shop, you\'ll track it here step by step.';

  @override
  String get moreTitle => 'More';

  @override
  String get moreComingSoonTitle => 'Settings coming soon';

  @override
  String get moreComingSoonBody =>
      'Your account and settings will live here soon.';

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
  String get qtyLabel => 'Quantity';

  @override
  String get qtyIncrease => 'Increase by one';

  @override
  String get qtyDecrease => 'Decrease by one';

  @override
  String get cartComingSoon => 'The cart arrives in the next update.';

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
  String get promo1Title => 'Welcome to Dukkan';

  @override
  String get promo1Body => 'Your neighborhood shops, in your pocket.';

  @override
  String get promo2Title => 'Delivery from your shop';

  @override
  String get promo2Body => 'Order what you need — it comes to your door.';

  @override
  String get promo3Title => 'Neighborhood prices';

  @override
  String get promo3Body => 'The same prices as the shop downstairs, exactly.';
}
