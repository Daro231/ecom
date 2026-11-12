import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/page_response.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/paged.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/catalog_models.dart';
import '../../data/models/product_filter.dart';

/// Filter shared by the Search tab, the filter sheet and the Home shortcuts.
class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  void set(ProductFilter f) => state = f;
  void reset() => state = const ProductFilter();
  void setKeyword(String? k) => state = state.copyWith(
    keyword: (k == null || k.trim().isEmpty) ? null : k.trim(),
  );

  /// Search entry point. When the keyword is exactly a category name
  /// (laptop, desktop, ...), filter by that category instead of matching the
  /// word in descriptions, so e.g. "laptop" does not return a dock.
  Future<void> search(String? keyword) async {
    final k = keyword?.trim() ?? '';
    if (k.isEmpty) return setKeyword(null);
    List<Category> cats = const [];
    try {
      cats = await ref.read(categoriesProvider.future);
    } catch (_) {}
    final hit = cats
        .where((c) => c.name.toLowerCase() == k.toLowerCase())
        .firstOrNull;
    if (hit != null) {
      state = ProductFilter(categoryId: hit.id, sort: state.sort);
    } else {
      setKeyword(k);
    }
  }

  void clearCategory() => state = state.copyWith(categoryId: null);

  void setSort(String sort) => state = state.copyWith(sort: sort);
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
      ProductFilterNotifier.new,
    );

class ProductListController extends PagedNotifier<Product> {
  static const pageSize = 12;

  @override
  PagedState<Product> build() {
    ref.watch(productFilterProvider);
    return beginLoad();
  }

  @override
  Future<PageResponse<Product>> fetchPage(int page) => ref
      .read(catalogRepositoryProvider)
      .products(ref.read(productFilterProvider), page: page, size: pageSize);
}

final productListProvider =
    NotifierProvider<ProductListController, PagedState<Product>>(
      ProductListController.new,
    );

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

final brandsProvider = FutureProvider<List<Brand>>(
  (ref) => ref.watch(catalogRepositoryProvider).brands(),
);

final shippingMethodsProvider = FutureProvider<List<ShippingMethodInfo>>(
  (ref) => ref.watch(catalogRepositoryProvider).shippingMethods(),
);

Future<List<Product>> _top(Ref ref, String sort) async {
  final r = await ref
      .watch(catalogRepositoryProvider)
      .products(ProductFilter(sort: sort, inStockOnly: true), size: 10);
  return r.content;
}

final newArrivalsProvider = FutureProvider<List<Product>>(
  (ref) => _top(ref, 'newest'),
);
final topRatedProvider = FutureProvider<List<Product>>(
  (ref) => _top(ref, 'rating'),
);
final popularProvider = FutureProvider<List<Product>>(
  (ref) => _top(ref, 'popular'),
);

final productDetailProvider = FutureProvider.autoDispose.family<Product, int>(
  (ref, id) => ref.watch(catalogRepositoryProvider).product(id),
);

final reviewsProvider = FutureProvider.autoDispose
    .family<PageResponse<Review>, int>(
      (ref, productId) => ref
          .watch(catalogRepositoryProvider)
          .reviews(productId, page: 0, size: 20),
    );

/// True when the signed-in customer received this product (review allowed).
final canReviewProvider = FutureProvider.autoDispose.family<bool, int>((
  ref,
  productId,
) {
  ref.watch(currentUserIdProvider);
  return ref.watch(orderRepositoryProvider).hasDeliveredPurchase(productId);
});
