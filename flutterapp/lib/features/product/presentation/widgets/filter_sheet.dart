import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_filter.dart';
import '../providers/product_providers.dart';

const double kMaxPrice = 5000;
const _ramOptions = [4, 8, 16, 32, 64];

Future<void> showFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FilterSheet(),
    );

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ProductFilter _f = ref.read(productFilterProvider);
  late RangeValues _range = RangeValues(
    _f.minPrice ?? 0,
    _f.maxPrice ?? kMaxPrice,
  );

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final brands = ref.watch(brandsProvider).value ?? const [];
    final t = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Filters', style: t.textTheme.titleLarge),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _f = ProductFilter(keyword: _f.keyword, sort: _f.sort);
                      _range = const RangeValues(0, kMaxPrice);
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              _title('Category'),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in cats)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _f.categoryId == c.id,
                      onSelected: (s) => setState(
                        () => _f = _f.copyWith(categoryId: s ? c.id : null),
                      ),
                    ),
                ],
              ),
              _title('Brand'),
              Wrap(
                spacing: 8,
                children: [
                  for (final b in brands)
                    ChoiceChip(
                      label: Text(b.name),
                      selected: _f.brandId == b.id,
                      onSelected: (s) => setState(
                        () => _f = _f.copyWith(brandId: s ? b.id : null),
                      ),
                    ),
                ],
              ),
              _title(
                'Price: \$${_range.start.round()} – \$${_range.end.round()}${_range.end >= kMaxPrice ? '+' : ''}',
              ),
              RangeSlider(
                values: _range,
                min: 0,
                max: kMaxPrice,
                divisions: 100,
                labels: RangeLabels(
                  '\$${_range.start.round()}',
                  '\$${_range.end.round()}',
                ),
                onChanged: (v) => setState(() => _range = v),
              ),
              _title('RAM'),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in _ramOptions)
                    ChoiceChip(
                      label: Text('$r GB'),
                      selected: _f.ram == r,
                      onSelected: (s) =>
                          setState(() => _f = _f.copyWith(ram: s ? r : null)),
                    ),
                ],
              ),
              _title('Minimum rating'),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in [4.0, 3.0, 2.0])
                    ChoiceChip(
                      label: Text('${r.toInt()}★ & up'),
                      selected: _f.minRating == r,
                      onSelected: (s) => setState(
                        () => _f = _f.copyWith(minRating: s ? r : null),
                      ),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In stock only'),
                value: _f.inStockOnly,
                onChanged: (v) =>
                    setState(() => _f = _f.copyWith(inStockOnly: v)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  ref
                      .read(productFilterProvider.notifier)
                      .set(
                        _f.copyWith(
                          minPrice: _range.start <= 0 ? null : _range.start,
                          maxPrice: _range.end >= kMaxPrice ? null : _range.end,
                        ),
                      );
                  Navigator.pop(context);
                },
                child: const Text('Apply filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String s) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      s,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
