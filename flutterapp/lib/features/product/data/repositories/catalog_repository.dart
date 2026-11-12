import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/catalog_models.dart';
import '../models/product_filter.dart';

Map<String, dynamic> _map(Object? o) => (o as Map).cast<String, dynamic>();

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<PageResponse<Product>> products(
    ProductFilter filter, {
    int page = 0,
    int size = 12,
  }) async {
    final r = await _api.get(
      '/products',
      query: filter.toQuery(page: page, size: size),
    );
    return PageResponse.fromJson(r.data, Product.fromJson);
  }

  Future<Product> product(int id) async {
    final r = await _api.get('/products/$id');
    return Product.fromJson(_map(r.data));
  }

  Future<List<Category>> categories() async {
    final r = await _api.get('/categories');
    return (r.data as List).map((e) => Category.fromJson(_map(e))).toList();
  }

  Future<List<Brand>> brands() async {
    final r = await _api.get('/brands');
    return (r.data as List).map((e) => Brand.fromJson(_map(e))).toList();
  }

  Future<List<ShippingMethodInfo>> shippingMethods() async {
    final r = await _api.get('/shipping/methods');
    return (r.data as List)
        .map((e) => ShippingMethodInfo.fromJson(_map(e)))
        .toList();
  }

  Future<PageResponse<Review>> reviews(
    int productId, {
    int page = 0,
    int size = 10,
  }) async {
    final r = await _api.get(
      '/products/$productId/reviews',
      query: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(r.data, Review.fromJson);
  }

  Future<Review> createReview(
    int productId, {
    required int rating,
    required String comment,
  }) async {
    final r = await _api.post(
      '/products/$productId/reviews',
      body: {'rating': rating, 'comment': comment.trim()},
    );
    return Review.fromJson(_map(r.data));
  }

  Future<Review> updateReview(
    int reviewId, {
    required int rating,
    required String comment,
  }) async {
    final r = await _api.put(
      '/reviews/$reviewId',
      body: {'rating': rating, 'comment': comment.trim()},
    );
    return Review.fromJson(_map(r.data));
  }
}
