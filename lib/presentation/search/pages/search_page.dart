import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeletons.dart';
import '../../shop/widgets/product_card.dart';
import '../bloc/search_bloc.dart';

/// Global marketplace search: one field in the app bar, a product grid below.
/// Owns its [SearchBloc]; every state (prompt / loading / no-results / error)
/// is designed. Replaces the C2a `/search` placeholder.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchBloc>()..add(const SearchStarted()),
      child: const SearchView(),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  Timer? _debounce;

  static const _debounceMs = 300;

  void _onChanged(String value) {
    // Debounce the dispatch so filtering doesn't run on every keystroke; the
    // bloc filter itself is synchronous.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      context.read<SearchBloc>().add(SearchQueryChanged(value));
    });
    setState(() {}); // refresh the clear button's visibility
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    context.read<SearchBloc>().add(const SearchQueryChanged(''));
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: l10n.homeSearchHint,
            hintStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: l10n.searchClear,
                    onPressed: _clear,
                  ),
          ),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) => switch (state.status) {
          SearchStatus.loading => const _SearchLoading(),
          SearchStatus.error => _SearchError(
              onRetry: () =>
                  context.read<SearchBloc>().add(const SearchRetryRequested()),
            ),
          SearchStatus.ready => _SearchBody(state: state),
        },
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    // Blank query → invite; matched → grid; typed-but-no-match → no-results.
    if (state.query.trim().isEmpty) return const _SearchPrompt();
    if (state.results.isEmpty) return const _SearchNoResults();
    return _ResultsGrid(state: state);
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final results = state.results;

    return GridView.builder(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        // Taller than the shop grid (0.64) to fit the shop-name subtitle line.
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, i) {
        final product = results[i];
        final Shop? shop = state.shopsById[product.shopId];
        final shopName =
            shop == null ? null : (isArabic ? shop.nameAr : shop.name);
        return ProductCard(
          key: ValueKey(product.id),
          product: product,
          subtitle: shopName,
          onTap: () => context.push(
            '/shop/${product.shopId}/product/${product.id}',
            extra: product,
          ),
        );
      },
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.search_rounded,
      title: l10n.searchPromptTitle,
      message: l10n.searchPromptBody,
    );
  }
}

class _SearchNoResults extends StatelessWidget {
  const _SearchNoResults();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: l10n.searchNoResultsTitle,
      message: l10n.searchNoResultsBody,
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: GridShimmer(count: 6, columns: 2, aspectRatio: 0.58),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: l10n.errorTitle,
      message: l10n.searchErrorBody,
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }
}
