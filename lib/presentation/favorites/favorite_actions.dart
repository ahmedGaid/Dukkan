import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injector.dart';
import '../../domain/favorites/usecases/toggle_favorite_product.dart';
import '../../domain/favorites/usecases/toggle_favorite_shop.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import '../widgets/common/app_snackbar.dart';

/// Direct usecase call, same pattern as `CatalogProductCard._delete` / the S3
/// order desk actions — [FavoritesBloc]'s realtime watch reflects the change
/// back, so there is no local patch to make here.
Future<void> toggleFavoriteShop(BuildContext context, String shopId) async {
  final uid = context.read<AuthBloc>().state.user!.uid;
  final l10n = AppLocalizations.of(context)!;
  try {
    await sl<ToggleFavoriteShop>()(uid, shopId);
  } catch (_) {
    if (!context.mounted) return;
    AppSnackBar.error(context, l10n.favoriteActionErrorBody);
  }
}

Future<void> toggleFavoriteProduct(BuildContext context, String productId) async {
  final uid = context.read<AuthBloc>().state.user!.uid;
  final l10n = AppLocalizations.of(context)!;
  try {
    await sl<ToggleFavoriteProduct>()(uid, productId);
  } catch (_) {
    if (!context.mounted) return;
    AppSnackBar.error(context, l10n.favoriteActionErrorBody);
  }
}
