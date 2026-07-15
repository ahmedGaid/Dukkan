import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injector.dart';
import '../../core/impersonation/impersonation_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/auth/usecases/get_user_by_id.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';

/// Wraps the whole routed app (installed as `MaterialApp.router`'s `builder`
/// in `main.dart`) so the impersonation strip renders ABOVE every screen,
/// including dialog barriers — one `Column` at the builder level, not a
/// per-page banner, so it survives every route change (FC15 Task B).
///
/// Whether impersonation is ACTIVE is derived from the signed-in user's
/// ID-token claims (`impersonatedBy`), never from [ImpersonationSession]'s
/// in-memory state — the claim is baked into the custom token Firebase
/// re-issues on relaunch, so the banner survives an app kill mid-
/// impersonation even though the session object (and its return token) does
/// not.
class ImpersonationOverlay extends StatefulWidget {
  const ImpersonationOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ImpersonationOverlay> createState() => _ImpersonationOverlayState();
}

class _ImpersonationOverlayState extends State<ImpersonationOverlay> {
  String? _checkedForUid;
  String? _impersonatedByUid;
  String? _impersonatedByName;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    // Covers the relaunch-mid-impersonation case: no AuthBloc transition
    // fires for a uid that was already signed in before this widget mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthBloc>().state.user?.uid;
      if (uid != null) _checkClaims(uid);
    });
  }

  Future<void> _checkClaims(String uid) async {
    _checkedForUid = uid;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return;
    String? byUid;
    try {
      final result = await user.getIdTokenResult();
      byUid = result.claims?['impersonatedBy'] as String?;
    } catch (_) {
      byUid = null;
    }
    if (!mounted || _checkedForUid != uid) return;
    if (byUid == null) {
      setState(() {
        _impersonatedByUid = null;
        _impersonatedByName = null;
      });
      return;
    }
    String? name;
    try {
      name = (await sl<GetUserById>()(byUid))?.name;
    } catch (_) {
      // Falls back to showing the raw uid below.
    }
    if (!mounted || _checkedForUid != uid) return;
    setState(() {
      _impersonatedByUid = byUid;
      _impersonatedByName = name;
    });
  }

  Future<void> _exit() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    try {
      await sl<ImpersonationSession>().exit();
    } finally {
      if (mounted) setState(() => _exiting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.user?.uid != b.user?.uid,
      listener: (context, state) {
        final uid = state.user?.uid;
        if (uid == null) {
          _checkedForUid = null;
          setState(() {
            _impersonatedByUid = null;
            _impersonatedByName = null;
          });
        } else {
          _checkClaims(uid);
        }
      },
      child: _impersonatedByUid == null
          ? widget.child
          : Column(
              children: [
                _Banner(
                  label: _impersonatedByName ?? _impersonatedByUid!,
                  busy: _exiting,
                  onExit: _exit,
                ),
                Expanded(child: widget.child),
              ],
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.label, required this.busy, required this.onExit});

  final String label;
  final bool busy;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Material(
        color: AppColors.warning,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, color: AppColors.surface, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n?.impersonationBannerLabel(label) ?? label,
                  style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                  ),
                )
              else
                TextButton(
                  onPressed: onExit,
                  style: TextButton.styleFrom(foregroundColor: AppColors.surface),
                  child: Text(l10n?.impersonationExitAction ?? 'Exit'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
