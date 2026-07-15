import 'package:flutter/material.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/config/usecases/get_platform_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/empty_state.dart';

/// Full-screen block shown when `PlatformConfig.maintenanceMode` is on for a
/// non-staff session (`AppRouter._redirect`, M12 Task D). Staff bypass this —
/// they need the app working DURING maintenance to fix things. Reads its own
/// support phone (memoized read, no extra round-trip beyond the redirect's
/// own gate check) rather than threading it through the route builder.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

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
                  icon: Icons.build_circle_outlined,
                  title: l10n.maintenanceTitle,
                  message: l10n.maintenanceBody,
                ),
                FutureBuilder(
                  future: sl<GetPlatformConfig>()(),
                  builder: (context, snapshot) {
                    final phone = snapshot.data?.supportPhone ?? '';
                    if (phone.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: SelectableText(
                        phone,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
