import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/delete_feature_flag.dart';
import '../../../../domain/admin/usecases/set_feature_flag.dart';
import '../../../../domain/admin/usecases/update_settings_fields.dart';
import '../../../../domain/audit/entities/audit_entry.dart';
import '../../../../domain/audit/entities/audit_filter.dart';
import '../../../../domain/audit/usecases/get_audit_entries.dart';
import '../../../../domain/config/entities/feature_flags.dart';
import '../../../../domain/config/entities/platform_config.dart';
import '../../../../domain/config/usecases/get_feature_flags.dart';
import '../../../../domain/config/usecases/get_platform_config.dart';
import '../../../../domain/config/usecases/refresh_feature_flags.dart';
import '../../../../domain/config/usecases/refresh_platform_config.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Drives the console platform-settings page (`/console/settings`, FC12).
/// Every save is Firestore-direct + best-effort audit (see
/// `AdminSettingsRepositoryImpl`); after each one succeeds this refreshes the
/// relevant config/flags read (so `PlatformConfigRepository`'s app-session
/// memo stays correct too) and the matching "آخر تعديل" audit entry.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required GetPlatformConfig getPlatformConfig,
    required RefreshPlatformConfig refreshPlatformConfig,
    required GetFeatureFlags getFeatureFlags,
    required RefreshFeatureFlags refreshFeatureFlags,
    required GetAuditEntries getAuditEntries,
    required UpdateSettingsFields updateSettingsFields,
    required SetFeatureFlag setFeatureFlag,
    required DeleteFeatureFlag deleteFeatureFlag,
  })  : _getPlatformConfig = getPlatformConfig,
        _refreshPlatformConfig = refreshPlatformConfig,
        _getFeatureFlags = getFeatureFlags,
        _refreshFeatureFlags = refreshFeatureFlags,
        _getAuditEntries = getAuditEntries,
        _updateSettingsFields = updateSettingsFields,
        _setFeatureFlag = setFeatureFlag,
        _deleteFeatureFlag = deleteFeatureFlag,
        super(const SettingsState()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsRatesSaveRequested>((e, emit) => _savePlatformFields(
          emit,
          fields: {
            'commissionBps': e.commissionBps,
            'deliveryFeeMinor': e.deliveryFeeMinor,
            'driverDeliveryShareMinor': e.driverDeliveryShareMinor,
            'minOrderMinor': e.minOrderMinor,
            'vatBps': e.vatBps,
          },
        ));
    on<SettingsContactSaveRequested>((e, emit) => _savePlatformFields(
          emit,
          fields: {
            'supportPhone': e.supportPhone,
            'supportWhatsApp': e.supportWhatsApp,
            'businessHoursNote': e.businessHoursNote,
          },
        ));
    on<SettingsAppGatesSaveRequested>((e, emit) => _savePlatformFields(
          emit,
          fields: {
            'maintenanceMode': e.maintenanceMode,
            'minSupportedBuild': e.minSupportedBuild,
          },
        ));
    on<SettingsFlagSetRequested>(_onFlagSet);
    on<SettingsFlagDeleteRequested>(_onFlagDelete);

    add(const SettingsStarted());
  }

  final GetPlatformConfig _getPlatformConfig;
  final RefreshPlatformConfig _refreshPlatformConfig;
  final GetFeatureFlags _getFeatureFlags;
  final RefreshFeatureFlags _refreshFeatureFlags;
  final GetAuditEntries _getAuditEntries;
  final UpdateSettingsFields _updateSettingsFields;
  final SetFeatureFlag _setFeatureFlag;
  final DeleteFeatureFlag _deleteFeatureFlag;

  Future<void> _onStarted(SettingsStarted event, Emitter<SettingsState> emit) async {
    try {
      final results = await Future.wait([
        _getPlatformConfig(),
        _getFeatureFlags(),
        _latestAudit('platform'),
        _latestAudit('flags'),
      ]);
      emit(state.copyWith(
        status: SettingsStatus.loaded,
        config: results[0] as PlatformConfig,
        flags: results[1] as FeatureFlags,
        lastPlatformAudit: results[2] as AuditEntry?,
        lastFlagsAudit: results[3] as AuditEntry?,
      ));
    } catch (_) {
      emit(state.copyWith(status: SettingsStatus.error));
    }
  }

  Future<AuditEntry?> _latestAudit(String targetId) async {
    final page = await _getAuditEntries(
      filter: AuditFilter(targetType: 'config', targetId: targetId),
    );
    return page.entries.isEmpty ? null : page.entries.first;
  }

  /// [fields] only carries the one save-group's keys — [before] is that same
  /// subset read off the current state's config, so the audit diff shows
  /// exactly what changed.
  Future<void> _savePlatformFields(
    Emitter<SettingsState> emit, {
    required Map<String, dynamic> fields,
  }) async {
    final before = <String, dynamic>{};
    final current = state.config?.toFieldMap();
    if (current != null) {
      for (final key in fields.keys) {
        before[key] = current[key];
      }
    }
    emit(state.copyWith(busy: true, actionError: null));
    try {
      await _updateSettingsFields(fields: fields, before: before, after: fields);
      final results = await Future.wait([
        _refreshPlatformConfig(),
        _latestAudit('platform'),
      ]);
      emit(state.copyWith(
        busy: false,
        config: results[0] as PlatformConfig,
        lastPlatformAudit: results[1] as AuditEntry?,
      ));
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: e.toString()));
    }
  }

  Future<void> _onFlagSet(
    SettingsFlagSetRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null));
    try {
      await _setFeatureFlag(key: event.key, value: event.value);
      final results = await Future.wait([
        _refreshFeatureFlags(),
        _latestAudit('flags'),
      ]);
      emit(state.copyWith(
        busy: false,
        flags: results[0] as FeatureFlags,
        lastFlagsAudit: results[1] as AuditEntry?,
      ));
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: e.toString()));
    }
  }

  Future<void> _onFlagDelete(
    SettingsFlagDeleteRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(busy: true, actionError: null));
    try {
      await _deleteFeatureFlag(event.key);
      final results = await Future.wait([
        _refreshFeatureFlags(),
        _latestAudit('flags'),
      ]);
      emit(state.copyWith(
        busy: false,
        flags: results[0] as FeatureFlags,
        lastFlagsAudit: results[1] as AuditEntry?,
      ));
    } catch (e) {
      emit(state.copyWith(busy: false, actionError: e.toString()));
    }
  }
}
