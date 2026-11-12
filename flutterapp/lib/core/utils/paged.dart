import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/page_response.dart';

class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.page = 0,
    this.last = false,
    this.total = 0,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.loadMoreError,
  });

  final List<T> items;
  final int page;
  final bool last;
  final int total;
  final bool loading; // first page (or refresh with empty list)
  final bool loadingMore;
  final Object? error; // first page failed
  final Object? loadMoreError; // next page failed (items are kept)

  bool get isEmpty => items.isEmpty && !loading && error == null;

  PagedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? last,
    int? total,
    bool? loading,
    bool? loadingMore,
    Object? error,
    Object? loadMoreError,
    bool clearErrors = false,
  }) => PagedState<T>(
    items: items ?? this.items,
    page: page ?? this.page,
    last: last ?? this.last,
    total: total ?? this.total,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearErrors ? null : (error ?? this.error),
    loadMoreError: clearErrors ? null : (loadMoreError ?? this.loadMoreError),
  );
}

/// Base class for infinite-scroll lists. Subclasses implement [fetchPage] and
/// call [beginLoad] from `build()` (after `ref.watch`-ing their inputs).
abstract class PagedNotifier<T> extends Notifier<PagedState<T>> {
  int _gen = 0;

  Future<PageResponse<T>> fetchPage(int page);

  bool _alive(int gen) => ref.mounted && gen == _gen;

  PagedState<T> beginLoad() {
    final gen = ++_gen;
    Future.microtask(() => _loadFirst(gen));
    return PagedState<T>(loading: true);
  }

  Future<void> _loadFirst(int gen) async {
    try {
      final r = await fetchPage(0);
      if (!_alive(gen)) return;
      state = PagedState<T>(
        items: r.content,
        page: 0,
        last: r.last,
        total: r.totalElements,
      );
    } catch (e) {
      if (!_alive(gen)) return;
      state = PagedState<T>(error: e);
    }
  }

  /// Pull-to-refresh: keeps the current items visible until new data arrives.
  Future<void> refresh() async {
    final gen = ++_gen;
    if (state.items.isEmpty)
      state = state.copyWith(loading: true, clearErrors: true);
    try {
      final r = await fetchPage(0);
      if (!_alive(gen)) return;
      state = PagedState<T>(
        items: r.content,
        page: 0,
        last: r.last,
        total: r.totalElements,
      );
    } catch (e) {
      if (!_alive(gen)) return;
      state = state.items.isEmpty
          ? PagedState<T>(error: e)
          : state.copyWith(loading: false, loadMoreError: e);
      rethrow;
    }
  }

  Future<void> loadMore() async {
    final s = state;
    if (s.loading || s.loadingMore || s.last || s.error != null) return;
    final gen = _gen;
    state = s.copyWith(loadingMore: true, loadMoreError: null);
    try {
      final r = await fetchPage(s.page + 1);
      if (!_alive(gen)) return;
      state = state.copyWith(
        items: [...state.items, ...r.content],
        page: s.page + 1,
        last: r.last,
        total: r.totalElements,
        loadingMore: false,
      );
    } catch (e) {
      if (!_alive(gen)) return;
      state = state.copyWith(loadingMore: false, loadMoreError: e);
    }
  }
}
