import '../../../domain/driver/entities/driver.dart';

class DriverModel extends Driver {
  const DriverModel({
    required super.uid,
    required super.name,
    required super.areaIds,
    required super.maxActiveOrders,
    required super.activeOrdersCount,
    required super.isOnline,
    required super.isSuspended,
    super.phone,
  });

  factory DriverModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return DriverModel(
      uid: uid,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
      areaIds: (data['areaIds'] as List? ?? const [])
          .map((e) => e as String)
          .toList(),
      maxActiveOrders: (data['maxActiveOrders'] as num?)?.toInt() ?? 5,
      activeOrdersCount: (data['activeOrdersCount'] as num?)?.toInt() ?? 0,
      isOnline: data['isOnline'] as bool? ?? false,
      isSuspended: data['isSuspended'] as bool? ?? true,
    );
  }

  /// Defaults for a brand-new driver profile at courier signup — every field
  /// a founder later manages starts at its safest value.
  factory DriverModel.newProfile({required String uid, required String name, String? phone}) {
    return DriverModel(
      uid: uid,
      name: name,
      phone: phone,
      areaIds: const [],
      maxActiveOrders: 5,
      activeOrdersCount: 0,
      isOnline: false,
      isSuspended: true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        'areaIds': areaIds,
        'maxActiveOrders': maxActiveOrders,
        'activeOrdersCount': activeOrdersCount,
        'isOnline': isOnline,
        'isSuspended': isSuspended,
      };
}
