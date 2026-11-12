import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/state_views.dart';
import '../../../notification/presentation/widgets/bell_button.dart';
import '../providers/product_providers.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_card.dart';

const _sortLabels = {
  'newest': 'Newest',
  'price_asc': 'Price: low to high',
  'price_desc': 'Price: high to low',
  'rating': 'Top rated',
  'popular': 'Most popular',
};

/// Search tab: keyword search, filters, sort, grid/list, infinite scroll.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  bool _grid = true;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(productFilterProvider).keyword ?? '';
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        ref.read(productListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(productFilterProvider, (_, f) {
      if ((f.keyword ?? '') != _search.text.trim())
        _search.text = f.keyword ?? '';
    });
    final filter = ref.watch(productFilterProvider);
    final state = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search_field'),
          controller: _search,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Search products',
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      _search.clear();
                      ref.read(productFilterProvider.notifier).setKeyword(null);
                    },
                  ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) =>
              ref.read(productFilterProvider.notifier).search(v),
        ),
        actions: const [BellButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: filter.activeCount > 0,
                  label: Text('${filter.activeCount}'),
                  child: OutlinedButton.icon(
                    key: const Key('open_filters'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => showFilterSheet(context),
                    icon: const Icon(Icons.tune),
                    label: const Text('Filter'),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Sort',
                  initialValue: filter.sort,
                  onSelected: ref.read(productFilterProvider.notifier).setSort,
                  itemBuilder: (_) => [
                    for (final e in _sortLabels.entries)
                      PopupMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort),
                        const SizedBox(width: 4),
                        Text(_sortLabels[filter.sort] ?? 'Sort'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (filter.activeCount > 0 || (filter.keyword ?? '').isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        ref.read(productFilterProvider.notifier).reset(),
                    child: const Text('Clear'),
                  ),
                IconButton(
                  tooltip: _grid ? 'List view' : 'Grid view',
                  onPressed: () => setState(() => _grid = !_grid),
                  icon: Icon(
                    _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  ),
                ),
              ],
            ),
          ),
          if (filter.categoryId != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: InputChip(
                  key: const Key('category_chip'),
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(
                    ref
                            .watch(categoriesProvider)
                            .value
                            ?.where((c) => c.id == filter.categoryId)
                            .firstOrNull
                            ?.name ??
                        'Category',
                  ),
                  onDeleted: ref
                      .read(productFilterProvider.notifier)
                      .clearCategory,
                ),
              ),
            ),
          Expanded(child: _body(state)),
        ],
      ),
    );
  }

  Widget _body(state) {
    if (state.loading)
      return _grid ? const ShimmerGrid() : const ShimmerList(itemHeight: 124);
    if (state.error != null) {
      return ErrorState(
        error: state.error!,
        onRetry: () =>
            ref.read(productListProvider.notifier).refresh().catchError((_) {}),
      );
    }
    if (state.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No products found',
        message: 'Try a different keyword or clear the filters.',
        actionLabel: 'Clear filters',
        onAction: ref.read(productFilterProvider.notifier).reset,
      );
    }
    final items = state.items;
    final footer = state.loadingMore
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        : state.loadMoreError != null
        ? TextButton(
            onPressed: ref.read(productListProvider.notifier).loadMore,
            child: const Text('Could not load more. Tap to retry'),
          )
        : const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(productListProvider.notifier).refresh().catchError((_) {}),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_grid)
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(
                    product: items[i],
                    onTap: () => context.push('/product/${items[i].id}'),
                  ),
                  childCount: items.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => ProductCard(
                  horizontal: true,
                  product: items[i],
                  onTap: () => context.push('/product/${items[i].id}'),
                ),
              ),
            ),
          SliverToBoxAdapter(child: footer),
        ],
      ),
    );
  }
}
