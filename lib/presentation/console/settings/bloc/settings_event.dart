part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads config, flags, and each doc's newest
/// audit entry (for the "آخر تعديل" line).
class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class SettingsRatesSaveRequested extends SettingsEvent {
  const SettingsRatesSaveRequested({
    required this.commissionBps,
    required this.deliveryFeeMinor,
    required this.driverDeliveryShareMinor,
    required this.minOrderMinor,
    required this.vatBps,
  });

  final int commissionBps;
  final int deliveryFeeMinor;
  final int driverDeliveryShareMinor;
  final int minOrderMinor;
  final int vatBps;

  @override
  List<Object?> get props =>
      [commissionBps, deliveryFeeMinor, driverDeliveryShareMinor, minOrderMinor, vatBps];
}

class SettingsContactSaveRequested extends SettingsEvent {
  const SettingsContactSaveRequested({
    required this.supportPhone,
    required this.supportWhatsApp,
    required this.businessHoursNote,
  });

  final String supportPhone;
  final String supportWhatsApp;
  final String businessHoursNote;

  @override
  List<Object?> get props => [supportPhone, supportWhatsApp, businessHoursNote];
}

class SettingsAppGatesSaveRequested extends SettingsEvent {
  const SettingsAppGatesSaveRequested({
    required this.maintenanceMode,
    required this.minSupportedBuild,
  });

  final bool maintenanceMode;
  final int minSupportedBuild;

  @override
  List<Object?> get props => [maintenanceMode, minSupportedBuild];
}

class SettingsFlagSetRequested extends SettingsEvent {
  const SettingsFlagSetRequested({required this.key, required this.value});

  final String key;
  final bool value;

  @override
  List<Object?> get props => [key, value];
}

class SettingsFlagDeleteRequested extends SettingsEvent {
  const SettingsFlagDeleteRequested(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}
