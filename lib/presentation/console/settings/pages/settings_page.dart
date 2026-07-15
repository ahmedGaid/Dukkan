import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/audit/entities/audit_entry.dart';
import '../../../../domain/config/entities/feature_flags.dart';
import '../../../../domain/config/entities/platform_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../bloc/settings_bloc.dart';

/// The Founder Console platform-settings page (`/console/settings`, FC12).
/// One BLoC, four independently-saved groups (rates+delivery, contact, app
/// gates, feature flags) — see `SettingsBloc` doc for the save/refresh/audit
/// contract each group shares.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (a, b) => a.busy && !b.busy,
        listener: (context, state) {
          if (state.actionError != null) {
            AppSnackBar.error(context, l10n.settingsSaveFailed);
          } else {
            AppSnackBar.success(context, l10n.settingsSaveOk);
          }
        },
        builder: (context, state) => switch (state.status) {
          SettingsStatus.loading => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ListShimmer(count: 4, itemHeight: 96),
            ),
          SettingsStatus.error => Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: l10n.errorTitle,
                message: l10n.settingsLoadError,
                actionLabel: l10n.actionRetry,
                onAction: () =>
                    context.read<SettingsBloc>().add(const SettingsStarted()),
              ),
            ),
          SettingsStatus.loaded => _SettingsLoaded(
              config: state.config!,
              flags: state.flags!,
              lastPlatformAudit: state.lastPlatformAudit,
              lastFlagsAudit: state.lastFlagsAudit,
              busy: state.busy,
            ),
        },
      ),
    );
  }
}

class _SettingsLoaded extends StatefulWidget {
  const _SettingsLoaded({
    required this.config,
    required this.flags,
    required this.lastPlatformAudit,
    required this.lastFlagsAudit,
    required this.busy,
  });

  final PlatformConfig config;
  final FeatureFlags flags;
  final AuditEntry? lastPlatformAudit;
  final AuditEntry? lastFlagsAudit;
  final bool busy;

  @override
  State<_SettingsLoaded> createState() => _SettingsLoadedState();
}

class _SettingsLoadedState extends State<_SettingsLoaded> {
  final _ratesFormKey = GlobalKey<FormState>();
  final _appFormKey = GlobalKey<FormState>();

  late final TextEditingController _commissionPct;
  late final TextEditingController _vatPct;
  late final TextEditingController _deliveryFee;
  late final TextEditingController _driverShare;
  late final TextEditingController _minOrder;
  late final TextEditingController _supportPhone;
  late final TextEditingController _supportWhatsApp;
  late final TextEditingController _businessHours;
  late final TextEditingController _minBuild;
  late bool _maintenanceMode;
  final _newFlagKey = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _commissionPct = TextEditingController(text: _bpsToPct(c.commissionBps));
    _vatPct = TextEditingController(text: _bpsToPct(c.vatBps));
    _deliveryFee = TextEditingController(text: _minorToPounds(c.deliveryFeeMinor));
    _driverShare = TextEditingController(text: _minorToPounds(c.driverDeliveryShareMinor));
    _minOrder = TextEditingController(text: _minorToPounds(c.minOrderMinor));
    _supportPhone = TextEditingController(text: c.supportPhone);
    _supportWhatsApp = TextEditingController(text: c.supportWhatsApp);
    _businessHours = TextEditingController(text: c.businessHoursNote);
    _minBuild = TextEditingController(text: '${c.minSupportedBuild}');
    _maintenanceMode = c.maintenanceMode;
  }

  @override
  void dispose() {
    _commissionPct.dispose();
    _vatPct.dispose();
    _deliveryFee.dispose();
    _driverShare.dispose();
    _minOrder.dispose();
    _supportPhone.dispose();
    _supportWhatsApp.dispose();
    _businessHours.dispose();
    _minBuild.dispose();
    _newFlagKey.dispose();
    super.dispose();
  }

  static String _bpsToPct(int bps) => (bps / 100).toStringAsFixed(1);
  static String _minorToPounds(int minor) => (minor / 100).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _RatesCard(
          formKey: _ratesFormKey,
          commissionPct: _commissionPct,
          vatPct: _vatPct,
          deliveryFee: _deliveryFee,
          driverShare: _driverShare,
          minOrder: _minOrder,
          busy: widget.busy,
          lastAudit: widget.lastPlatformAudit,
        ),
        const SizedBox(height: AppSpacing.md),
        _ContactCard(
          supportPhone: _supportPhone,
          supportWhatsApp: _supportWhatsApp,
          businessHours: _businessHours,
          busy: widget.busy,
          lastAudit: widget.lastPlatformAudit,
        ),
        const SizedBox(height: AppSpacing.md),
        _AppGatesCard(
          formKey: _appFormKey,
          maintenanceMode: _maintenanceMode,
          onMaintenanceChanged: (v) => setState(() => _maintenanceMode = v),
          minBuild: _minBuild,
          busy: widget.busy,
          lastAudit: widget.lastPlatformAudit,
        ),
        const SizedBox(height: AppSpacing.md),
        _FlagsCard(
          flags: widget.flags,
          newFlagKey: _newFlagKey,
          busy: widget.busy,
          lastAudit: widget.lastFlagsAudit,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.settingsFooterNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────

class _LastEdited extends StatelessWidget {
  const _LastEdited(this.entry);

  final AuditEntry? entry;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    if (entry == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final when = DateFormat.Md(locale).add_Hm().format(entry.createdAt);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        l10n.settingsLastEdited(when),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
            : Text(l10n.actionSave),
      ),
    );
  }
}

int? _parsePctToBps(String input) {
  final pct = double.tryParse(input.trim());
  if (pct == null || pct < 0) return null;
  return (pct * 100).round();
}

// ─────────────────────────────────────────────────────────────────────────
// Rates + delivery
// ─────────────────────────────────────────────────────────────────────────

class _RatesCard extends StatelessWidget {
  const _RatesCard({
    required this.formKey,
    required this.commissionPct,
    required this.vatPct,
    required this.deliveryFee,
    required this.driverShare,
    required this.minOrder,
    required this.busy,
    required this.lastAudit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController commissionPct;
  final TextEditingController vatPct;
  final TextEditingController deliveryFee;
  final TextEditingController driverShare;
  final TextEditingController minOrder;
  final bool busy;
  final AuditEntry? lastAudit;

  void _save(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!(formKey.currentState?.validate() ?? false)) return;
    final commissionBps = _parsePctToBps(commissionPct.text);
    final vatBps = _parsePctToBps(vatPct.text);
    final deliveryFeeMinor = Money.parseToMinor(deliveryFee.text);
    final driverDeliveryShareMinor = Money.parseToMinor(driverShare.text);
    final minOrderMinor = Money.parseToMinor(minOrder.text);
    if (commissionBps == null ||
        vatBps == null ||
        deliveryFeeMinor == null ||
        driverDeliveryShareMinor == null ||
        minOrderMinor == null) {
      return;
    }
    if (driverDeliveryShareMinor > deliveryFeeMinor) {
      AppSnackBar.error(context, l10n.settingsDriverShareTooHigh);
      return;
    }
    context.read<SettingsBloc>().add(SettingsRatesSaveRequested(
          commissionBps: commissionBps,
          deliveryFeeMinor: deliveryFeeMinor,
          driverDeliveryShareMinor: driverDeliveryShareMinor,
          minOrderMinor: minOrderMinor,
          vatBps: vatBps,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsRatesTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: l10n.settingsCommissionLabel,
              controller: commissionPct,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => _parsePctToBps(v ?? '') == null ? l10n.validateRequired : null,
            ),
            AppTextField(
              label: l10n.settingsVatLabel,
              controller: vatPct,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => _parsePctToBps(v ?? '') == null ? l10n.validateRequired : null,
            ),
            AppTextField(
              label: l10n.settingsDeliveryFeeLabel,
              controller: deliveryFee,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Money.parseToMinor(v ?? '') == null ? l10n.validateRequired : null,
            ),
            AppTextField(
              label: l10n.settingsDriverShareLabel,
              controller: driverShare,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Money.parseToMinor(v ?? '') == null ? l10n.validateRequired : null,
            ),
            AppTextField(
              label: l10n.settingsMinOrderLabel,
              controller: minOrder,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Money.parseToMinor(v ?? '') == null ? l10n.validateRequired : null,
            ),
            _LastEdited(lastAudit),
            const SizedBox(height: AppSpacing.sm),
            _SaveButton(busy: busy, onPressed: () => _save(context)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Contact
// ─────────────────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.supportPhone,
    required this.supportWhatsApp,
    required this.businessHours,
    required this.busy,
    required this.lastAudit,
  });

  final TextEditingController supportPhone;
  final TextEditingController supportWhatsApp;
  final TextEditingController businessHours;
  final bool busy;
  final AuditEntry? lastAudit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsContactTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: l10n.settingsSupportPhoneLabel,
            controller: supportPhone,
            keyboardType: TextInputType.phone,
          ),
          AppTextField(
            label: l10n.settingsSupportWhatsAppLabel,
            controller: supportWhatsApp,
            keyboardType: TextInputType.phone,
          ),
          AppTextField(
            label: l10n.settingsBusinessHoursLabel,
            controller: businessHours,
          ),
          _LastEdited(lastAudit),
          const SizedBox(height: AppSpacing.sm),
          _SaveButton(
            busy: busy,
            onPressed: () => context.read<SettingsBloc>().add(SettingsContactSaveRequested(
                  supportPhone: supportPhone.text.trim(),
                  supportWhatsApp: supportWhatsApp.text.trim(),
                  businessHoursNote: businessHours.text.trim(),
                )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// App gates
// ─────────────────────────────────────────────────────────────────────────

class _AppGatesCard extends StatelessWidget {
  const _AppGatesCard({
    required this.formKey,
    required this.maintenanceMode,
    required this.onMaintenanceChanged,
    required this.minBuild,
    required this.busy,
    required this.lastAudit,
  });

  final GlobalKey<FormState> formKey;
  final bool maintenanceMode;
  final ValueChanged<bool> onMaintenanceChanged;
  final TextEditingController minBuild;
  final bool busy;
  final AuditEntry? lastAudit;

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (!(formKey.currentState?.validate() ?? false)) return;
    final minSupportedBuild = int.tryParse(minBuild.text.trim());
    if (minSupportedBuild == null || minSupportedBuild < 0) return;

    if (maintenanceMode || minSupportedBuild > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.settingsAppGatesConfirmTitle),
          content: Text(
            maintenanceMode
                ? l10n.settingsMaintenanceConfirmBody
                : l10n.settingsMinBuildConfirmBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    context.read<SettingsBloc>().add(SettingsAppGatesSaveRequested(
          maintenanceMode: maintenanceMode,
          minSupportedBuild: minSupportedBuild,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsAppGatesTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
              ),
              child: SwitchListTile.adaptive(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                value: maintenanceMode,
                onChanged: busy ? null : onMaintenanceChanged,
                title: Text(l10n.settingsMaintenanceSwitch),
                subtitle: Text(l10n.settingsMaintenanceSwitchHint),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.settingsMinBuildLabel,
              controller: minBuild,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n < 0) ? l10n.validateRequired : null;
              },
            ),
            _LastEdited(lastAudit),
            const SizedBox(height: AppSpacing.sm),
            _SaveButton(busy: busy, onPressed: () => _save(context)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Feature flags
// ─────────────────────────────────────────────────────────────────────────

class _FlagsCard extends StatelessWidget {
  const _FlagsCard({
    required this.flags,
    required this.newFlagKey,
    required this.busy,
    required this.lastAudit,
  });

  final FeatureFlags flags;
  final TextEditingController newFlagKey;
  final bool busy;
  final AuditEntry? lastAudit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = flags.flags.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsFlagsTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l10n.settingsFlagsEmpty,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            )
          else
            for (final entry in entries)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: entry.value,
                onChanged: busy
                    ? null
                    : (v) => context
                        .read<SettingsBloc>()
                        .add(SettingsFlagSetRequested(key: entry.key, value: v)),
                title: Text(entry.key),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: busy
                      ? null
                      : () => context
                          .read<SettingsBloc>()
                          .add(SettingsFlagDeleteRequested(entry.key)),
                ),
              ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: l10n.settingsAddFlagLabel,
                  controller: newFlagKey,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: busy
                    ? null
                    : () {
                        final key = newFlagKey.text.trim();
                        if (key.isEmpty || flags.flags.containsKey(key)) return;
                        context
                            .read<SettingsBloc>()
                            .add(SettingsFlagSetRequested(key: key, value: false));
                        newFlagKey.clear();
                      },
              ),
            ],
          ),
          _LastEdited(lastAudit),
        ],
      ),
    );
  }
}
