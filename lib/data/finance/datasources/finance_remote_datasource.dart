import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../models/finance_summary_model.dart';

/// Six metrics via `count()`/`aggregate()` queries — no document downloads.
/// The `delivered` count and both money sums share one round trip since
/// `aggregate()` takes multiple `AggregateField`s at once; `total` and
/// `cancelled` each need their own `count()` because they're different
/// `where` filters over the same collection.
class FinanceRemoteDataSource {
  FinanceRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<FinanceSummaryModel> getSummary() async {
    try {
      final orders = _firestore.collection('orders');
      final delivered = orders.where('status', isEqualTo: 'delivered');
      final cancelledOrRejected =
          orders.where('status', whereIn: ['cancelled', 'rejected']);

      final results = await Future.wait([
        orders.count().get(),
        delivered
            .aggregate(
              count(),
              sum('commissionMinor'),
              sum('platformDeliveryShareMinor'),
            )
            .get(),
        cancelledOrRejected.count().get(),
      ]);

      final totalSnap = results[0];
      final deliveredSnap = results[1];
      final cancelledSnap = results[2];

      return FinanceSummaryModel(
        totalOrders: totalSnap.count ?? 0,
        deliveredOrders: deliveredSnap.count ?? 0,
        cancelledOrders: cancelledSnap.count ?? 0,
        commissionMinor:
            (deliveredSnap.getSum('commissionMinor') ?? 0).round(),
        deliveryRevenueMinor:
            (deliveredSnap.getSum('platformDeliveryShareMinor') ?? 0).round(),
      );
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
