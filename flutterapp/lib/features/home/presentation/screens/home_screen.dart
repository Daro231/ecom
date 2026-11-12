import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../notification/presentation/providers/notification_providers.dart';
import '../../../notification/presentation/widgets/bell_button.dart';
import '../../../product/data/models/catalog_models.dart';
import '../../../product/data/models/product_filter.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../product/presentation/widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _search(BuildContext context, WidgetRef ref, ProductFilter f) {
    ref.read(productFilterProvider.notifier).set(f);
    context.go('/search');
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(brandsProvider);
    ref.invalidate(newArrivalsProvider);
    ref.invalidate(topRatedProvider);
    ref.invalidate(popularProvider);
    ref.read(unreadCountProvider.notifier).refresh();
    await ref.read(newArrivalsProvider.future).catchError((_) => <Product>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final brands = ref.watch(brandsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ECOM',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
        actions: const [BellButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.navyDark
                  : AppColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: TextField(
                key: const Key('home_search'),
                textInputAction: TextInputAction.search,
                onSubmitted: (v) async {
                  final n = ref.read(productFilterProvider.notifier);
                  n.set(const ProductFilter());
                  await n.search(v);
                  if (context.mounted) context.go('/search');
                },
                decoration: const InputDecoration(
                  hintText: 'Search laptops, PCs, accessories…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _BannerCarousel(),
            SizedBox(
              height: 56,
              child: categories.when(
                data: (list) => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ActionChip(
                    label: Text(list[i].name),
                    onPressed: () => _search(
                      context,
                      ref,
                      ProductFilter(categoryId: list[i].id),
                    ),
                  ),
                ),
                loading: () => const Shimmered(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SkeletonBox(height: 30, radius: 20),
                  ),
                ),
                error: (e, _) => Center(
                  child: TextButton.icon(
                    onPressed: () => ref.invalidate(categoriesProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry categories'),
                  ),
                ),
              ),
            ),
            _ProductRow(
              title: 'New arrivals',
              provider: newArrivalsProvider,
              onSeeAll: () =>
                  _search(context, ref, const ProductFilter(sort: 'newest')),
            ),
            _ProductRow(
              title: 'Top rated',
              provider: topRatedProvider,
              onSeeAll: () =>
                  _search(context, ref, const ProductFilter(sort: 'rating')),
            ),
            const SectionHeader('Brands'),
            SizedBox(
              height: 52,
              child: brands.when(
                data: (list) => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(90, 44),
                    ),
                    onPressed: () => _search(
                      context,
                      ref,
                      ProductFilter(brandId: list[i].id),
                    ),
                    child: Text(list[i].name),
                  ),
                ),
                loading: () => const Shimmered(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SkeletonBox(height: 44, radius: 12),
                  ),
                ),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(brandsProvider),
                    child: const Text('Retry brands'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({
    required this.title,
    required this.provider,
    required this.onSeeAll,
  });
  final String title;
  final FutureProvider<List<Product>> provider;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, onSeeAll: onSeeAll),
        SizedBox(
          height: 270,
          child: value.when(
            data: (list) => list.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nothing here yet',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SizedBox(
                      width: 170,
                      child: ProductCard(
                        product: list[i],
                        onTap: () => context.push('/product/${list[i].id}'),
                      ),
                    ),
                  ),
            loading: () => Shimmered(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, _) =>
                    const SkeletonBox(width: 170, radius: 14),
              ),
            ),
            error: (e, _) =>
                ErrorState(error: e, onRetry: () => ref.invalidate(provider)),
          ),
        ),
      ],
    );
  }
}

/// Coupon promo slide followed by the store's most popular products.
class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel();

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      final count = (ref.read(popularProvider).value?.take(3).length ?? 0) + 1;
      _controller.animateToPage(
        (_page + 1) % count,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popular =
        ref.watch(popularProvider).value?.take(3).toList() ?? const <Product>[];
    final slides = <Widget>[
      _PromoSlide(code: Env.promoCoupon),
      for (final p in popular) _ProductSlide(product: p),
    ];
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: slides,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.accent : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF1B3F73)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Special offer',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use coupon at checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    showSnack(context, 'Coupon $code copied');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_offer_rounded,
            size: 64,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _ProductSlide extends StatelessWidget {
  const _ProductSlide({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: double.infinity,
              child: ProductImage(
                url: product.firstImage,
                category: product.category?.name,
                brand: product.brand?.name,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatUsd(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
