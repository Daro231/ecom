import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderNumber,
    this.paid = false,
  });
  final String orderNumber;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 96,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    paid ? 'Payment received!' : 'Order placed!',
                    style: t.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Order $orderNumber', style: t.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    paid
                        ? 'Thank you. Your order is confirmed and we are preparing it.'
                        : 'Thank you for your purchase. We will keep you updated.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const Key('view_order'),
                    onPressed: () {
                      context.go('/orders');
                      context.push('/order/$orderNumber');
                    },
                    child: const Text('View order'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Continue shopping'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
