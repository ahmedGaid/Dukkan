import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../cart/bloc/cart_bloc.dart';

/// The one cart entry point — an app-bar icon with a badge of distinct
/// products (Shoppy lesson: never sum quantities). Reused on Home, the shop
/// page, and product detail; never forked.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartBloc, CartState, int>(
      selector: (state) => state.itemCount,
      builder: (context, count) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
          if (count > 0)
            PositionedDirectional(
              top: 6,
              end: 4,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: AppRadius.roundAll,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
