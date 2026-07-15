import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/empty_state.dart';

/// Full-screen block shown when the running build is below
/// `PlatformConfig.minSupportedBuild` (`AppRouter._redirect`, M12 Task D). The
/// Play Store link is selectable text, not a launched url — no `url_launcher`
/// dependency for one screen.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.dukkan.dukkan';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyState(
                  icon: Icons.system_update_outlined,
                  title: l10n.updateRequiredTitle,
                  message: l10n.updateRequiredBody,
                ),
                const SizedBox(height: AppSpacing.md),
                const SelectableText(_playStoreUrl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
