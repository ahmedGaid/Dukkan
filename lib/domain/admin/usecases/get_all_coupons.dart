import '../../promos/entities/coupon.dart';
import '../repositories/admin_promos_repository.dart';

class GetAllCoupons {
  const GetAllCoupons(this._repository);

  final AdminPromosRepository _repository;

  Future<List<Coupon>> call() => _repository.getAllCoupons();
}
