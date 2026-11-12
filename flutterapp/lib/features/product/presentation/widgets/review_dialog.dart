import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/catalog_models.dart';
import '../providers/product_providers.dart';

/// Create (or edit, when [existing] is given) a review. Returns true if saved.
Future<bool> showReviewDialog(
  BuildContext context,
  WidgetRef ref, {
  required int productId,
  required String productName,
  Review? existing,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _ReviewDialog(
      productId: productId,
      productName: productName,
      existing: existing,
    ),
  );
  if (saved == true) {
    ref.invalidate(reviewsProvider(productId));
    ref.invalidate(productDetailProvider(productId));
    return true;
  }
  return false;
}

class _ReviewDialog extends ConsumerStatefulWidget {
  const _ReviewDialog({
    required this.productId,
    required this.productName,
    this.existing,
  });
  final int productId;
  final String productName;
  final Review? existing;

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  late int _rating = widget.existing?.rating ?? 5;
  late final _comment = TextEditingController(
    text: widget.existing?.comment ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final repo = ref.read(catalogRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.createReview(
          widget.productId,
          rating: _rating,
          comment: _comment.text,
        );
      } else {
        await repo.updateReview(
          widget.existing!.id,
          rating: _rating,
          comment: _comment.text,
        );
      }
      if (mounted) {
        showSnack(
          context,
          widget.existing == null ? 'Review submitted' : 'Review updated',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Write a review' : 'Edit your review',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    key: Key('star_$i'),
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF5A623),
                      size: 34,
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _comment,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Your comment'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
