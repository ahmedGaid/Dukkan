part of 'settings_bloc.dart';

enum SettingsStatus { loading, loaded, error }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.loading,
    this.config,
    this.flags,
    this.lastPlatformAudit,
    this.lastFlagsAudit,
    this.busy = false,
    this.actionError,
  });

  final SettingsStatus status;
  final PlatformConfig? config;
  final FeatureFlags? flags;

  /// Newest `targetId: 'platform'` audit entry — the rates/contact/app-gates
  /// groups all write there, so one "آخر تعديل" line covers all three.
  final AuditEntry? lastPlatformAudit;

  /// Newest `targetId: 'flags'` audit entry.
  final AuditEntry? lastFlagsAudit;

  /// True while any save is in flight — every group's save button disables
  /// together (v1 simplicity; mirrors `DriverDetailState.actionBusy`).
  final bool busy;

  final String? actionError;

  static const _unset = Object();

  SettingsState copyWith({
    SettingsStatus? status,
    PlatformConfig? config,
    FeatureFlags? flags,
    Object? lastPlatformAudit = _unset,
    Object? lastFlagsAudit = _unset,
    bool? busy,
    Object? actionError = _unset,
  }) {
    return SettingsState(
      status: status ?? this.status,
      config: config ?? this.config,
      flags: flags ?? this.flags,
      lastPlatformAudit: lastPlatformAudit == _unset
          ? this.lastPlatformAudit
          : lastPlatformAudit as AuditEntry?,
      lastFlagsAudit: lastFlagsAudit == _unset
          ? this.lastFlagsAudit
          : lastFlagsAudit as AuditEntry?,
      busy: busy ?? this.busy,
      actionError: actionError == _unset ? this.actionError : actionError as String?,
    );
  }

  @override
  List<Object?> get props =>
      [status, config, flags, lastPlatformAudit, lastFlagsAudit, busy, actionError];
}
