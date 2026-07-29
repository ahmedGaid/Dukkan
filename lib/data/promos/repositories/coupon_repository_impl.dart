import '../../../domain/promos/entities/coupon.dart';
import '../../../domain/promos/repositories/coupon_repository.dart';
import '../datasources/coupon_remote_datasource.dart';

class CouponRepositoryImpl implements CouponRepository {
  CouponRepositoryImpl(this._remote);

  final CouponRemoteDataSource _remote;

  @override
  Future<Coupon?> getByCode(String code) => _remote.getByCode(code);

  @override
  Future<void> redeem(String code) => _remote.redeem(code);
}
