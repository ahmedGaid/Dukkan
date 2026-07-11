import '../../../core/network/network_info.dart';
import '../../../domain/taxonomy/entities/category.dart';
import '../../../domain/taxonomy/repositories/taxonomy_repository.dart';
import '../datasources/taxonomy_local_datasource.dart';
import '../datasources/taxonomy_remote_datasource.dart';

class TaxonomyRepositoryImpl implements TaxonomyRepository {
  TaxonomyRepositoryImpl(this._remote, this._local, this._networkInfo);

  final TaxonomyRemoteDataSource _remote;
  final TaxonomyLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  Future<List<Category>> getTaxonomy() async {
    if (await _networkInfo.isConnected) {
      final categories = await _remote.getTaxonomy();
      await _local.cacheTaxonomy(categories);
      return categories;
    }
    return _local.getCachedTaxonomy();
  }
}
