/// Backend `PageResponse` -> `{ content, page, size, totalElements, totalPages, last }`.
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  factory PageResponse.fromJson(
    Object? json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final m = (json as Map).cast<String, dynamic>();
    final list = (m['content'] as List? ?? const [])
        .map((e) => itemParser((e as Map).cast<String, dynamic>()))
        .toList();
    return PageResponse<T>(
      content: list,
      page: (m['page'] as num?)?.toInt() ?? 0,
      size: (m['size'] as num?)?.toInt() ?? list.length,
      totalElements: (m['totalElements'] as num?)?.toInt() ?? list.length,
      totalPages: (m['totalPages'] as num?)?.toInt() ?? 1,
      last: m['last'] as bool? ?? true,
    );
  }
}
