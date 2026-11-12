import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../core/utils/qr_export.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../order/presentation/providers/order_providers.dart';
import '../../data/models/khqr_models.dart';

/// How often the payment status is polled (overridden in tests).
final khqrPollIntervalProvider = Provider<Duration>(
  (_) => const Duration(seconds: 3),
);

class KhqrPaymentScreen extends ConsumerStatefulWidget {
  const KhqrPaymentScreen({super.key, required this.orderNumber});
  final String orderNumber;

  @override
  ConsumerState<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends ConsumerState<KhqrPaymentScreen>
    with WidgetsBindingObserver {
  KhqrSession? _session;
  bool _loading = true;
  ApiException? _fatal; // QR could not be generated
  bool _expired = false;
  String? _failureReason; // payment FAILED with a mismatch reason
  String? _finalMessage; // REFUNDED / PAID_AFTER_CANCEL
  String? _warning; // 502 / 504 / offline while polling
  bool _simulating = false;
  bool _polling = false;
  bool _done = false;
  Duration _remaining = Duration.zero;

  Timer? _pollTimer;
  Timer? _tick;
  final _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wakelock(true);
    _generate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _tick?.cancel();
    _wakelock(false);
    super.dispose();
  }

  Future<void> _wakelock(bool on) async {
    if (kIsWeb) return; // not needed in a browser tab
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } catch (_) {
      // Not supported on this platform (e.g. tests) - the screen just may dim.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _wakelock(true);
      if (_canPoll) {
        _poll();
        _startPolling();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  bool get _canPoll =>
      !_done &&
      !_loading &&
      _session != null &&
      !_expired &&
      _failureReason == null &&
      _finalMessage == null;

  Future<void> _generate() async {
    _pollTimer?.cancel();
    setState(() {
      _loading = true;
      _fatal = null;
      _expired = false;
      _failureReason = null;
      _warning = null;
    });
    try {
      final s = await ref
          .read(paymentRepositoryProvider)
          .generateKhqr(widget.orderNumber);
      if (!mounted) return;
      setState(() {
        _session = s;
        _loading = false;
        _remaining = s.remaining();
      });
      _startTicker();
      _startPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      // 400: the order is cancelled or already paid - find out which.
      if (e.type == ApiErrorType.validation) {
        final paid = await _checkAlreadyPaid();
        if (paid || !mounted) return;
      }
      setState(() {
        _loading = false;
        _fatal = e;
      });
    }
  }

  Future<bool> _checkAlreadyPaid() async {
    try {
      final p = await ref
          .read(paymentRepositoryProvider)
          .status(widget.orderNumber);
      if (p.status == 'PAID') {
        _goSuccess();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _startTicker() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = _session;
      if (s == null || !mounted) return;
      final r = s.remaining();
      setState(() => _remaining = r);
      if (r <= Duration.zero && !_expired && !_done) {
        _pollTimer?.cancel();
        setState(() => _expired = true);
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!_canPoll) return;
    _pollTimer = Timer.periodic(
      ref.read(khqrPollIntervalProvider),
      (_) => _poll(),
    );
  }

  Future<void> _poll() async {
    if (_polling || !_canPoll) return;
    _polling = true;
    try {
      final p = await ref
          .read(paymentRepositoryProvider)
          .status(widget.orderNumber);
      if (!mounted) return;
      if (_warning != null) setState(() => _warning = null);
      switch (p.status) {
        case 'PAID':
          _goSuccess();
        case 'FAILED':
          _pollTimer?.cancel();
          final reason = p.failureReason ?? '';
          if (reason.isEmpty || reason.toLowerCase().contains('expired')) {
            setState(() => _expired = true);
          } else {
            setState(() => _failureReason = reason);
          }
        case 'REFUNDED':
          _pollTimer?.cancel();
          setState(() => _finalMessage = 'This payment was refunded.');
        case 'PAID_AFTER_CANCEL':
          _pollTimer?.cancel();
          setState(
            () => _finalMessage =
                'We received your payment after the order was cancelled. Our team will restore your order or refund you.',
          );
        default:
          break; // PENDING - keep polling
      }
    } on ApiException catch (e) {
      // 502 / 504 / offline are NOT payment failures: keep polling, warn softly.
      if (!mounted) return;
      if (e.isProviderProblem || e.isConnectivity) {
        setState(
          () => _warning = e.type == ApiErrorType.badGateway
              ? 'Payment provider unavailable. Still checking…'
              : e.type == ApiErrorType.gatewayTimeout
              ? 'Payment provider is slow. Still checking…'
              : 'Connection problem. Still checking…',
        );
      }
    } finally {
      _polling = false;
    }
  }

  void _goSuccess() {
    if (_done) return;
    _done = true;
    _pollTimer?.cancel();
    _tick?.cancel();
    ref.invalidate(orderDetailProvider(widget.orderNumber));
    ref.read(ordersProvider.notifier).refresh().catchError((_) {});
    if (mounted)
      context.pushReplacement('/success/${widget.orderNumber}?paid=1');
  }

  Future<void> _simulate() async {
    setState(() => _simulating = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .simulatePayment(widget.orderNumber);
      await _poll();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  Future<void> _saveQr() async {
    final s = _session;
    if (s == null) return;
    try {
      final png = await renderQrPng(s.data.qrString);
      if (kIsWeb) {
        // Browser has no gallery: download the PNG instead.
        final ok = await downloadBytes(
          png,
          'khqr_${widget.orderNumber}.png',
          mimeType: 'image/png',
        );
        if (mounted)
          showSnack(
            context,
            ok ? 'QR downloaded as PNG' : 'Could not download the QR',
            error: !ok,
          );
        return;
      }
      final res = await ImageGallerySaverPlus.saveImage(
        png,
        quality: 100,
        name: 'khqr_${widget.orderNumber}',
      );
      final ok = res is Map
          ? (res['isSuccess'] == true || res['filePath'] != null)
          : res != null;
      if (mounted)
        showSnack(
          context,
          ok ? 'QR saved to your gallery' : 'Could not save the QR',
          error: !ok,
        );
    } catch (_) {
      if (mounted)
        showSnack(
          context,
          'Could not save the QR. Check storage/photos permission.',
          error: true,
        );
    }
  }

  Future<void> _shareQr() async {
    final s = _session;
    if (s == null) return;
    try {
      final png = await renderQrPng(s.data.qrString);
      if (kIsWeb) {
        // Web Share API with files is not available on desktop browsers: download.
        final ok = await downloadBytes(
          png,
          'khqr_${widget.orderNumber}.png',
          mimeType: 'image/png',
        );
        if (mounted)
          showSnack(
            context,
            ok
                ? 'Sharing is not available in the browser - QR downloaded instead'
                : 'Could not share the QR',
            error: !ok,
          );
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/khqr_${widget.orderNumber}.png');
      await file.writeAsBytes(png);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'KHQR payment for order ${widget.orderNumber}',
        ),
      );
    } catch (_) {
      if (mounted) showSnack(context, 'Could not share the QR', error: true);
    }
  }

  String _amountText(KhqrData d) => d.currency == 'USD'
      ? formatUsd(d.amount)
      : '${d.amount.toStringAsFixed(d.currency == 'KHR' ? 0 : 2)} ${d.currency}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay with KHQR')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_fatal != null) {
      return EmptyState(
        icon: Icons.qr_code_2_rounded,
        title: 'Cannot show the QR code',
        message: _fatal!.message,
        actionLabel: _fatal!.type == ApiErrorType.validation
            ? 'View order'
            : 'Try again',
        onAction: _fatal!.type == ApiErrorType.validation
            ? () => context.go('/order/${widget.orderNumber}')
            : _generate,
      );
    }
    final s = _session!;
    final d = s.data;
    final t = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              if (_warning != null)
                Container(
                  key: const Key('khqr_warning'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _warning!,
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFE21A1A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Text(
                        'KHQR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: DefaultTextStyle(
                        style: const TextStyle(color: Colors.black87),
                        child: Column(
                          children: [
                            const Text(
                              Env.merchantName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _amountText(d),
                              key: const Key('khqr_amount'),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                RepaintBoundary(
                                  key: _qrKey,
                                  child: QrImageView(
                                    key: const Key('khqr_qr'),
                                    data: d.qrString,
                                    size: 250,
                                    backgroundColor: Colors.white,
                                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                if (_expired)
                                  Container(
                                    key: const Key('khqr_expired'),
                                    width: 250,
                                    height: 250,
                                    color: Colors.white.withValues(alpha: 0.94),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.timer_off_outlined,
                                          size: 44,
                                          color: AppColors.danger,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'QR expired',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton(
                                          key: const Key('khqr_regenerate'),
                                          onPressed: _generate,
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size(170, 44),
                                          ),
                                          child: const Text('Generate new QR'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Order ${d.orderNumber}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            if (!_expired &&
                                _failureReason == null &&
                                _finalMessage == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Expires in ${formatCountdown(_remaining)}',
                                      key: const Key('khqr_countdown'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_failureReason != null)
                _notice(
                  icon: Icons.error_outline,
                  color: AppColors.danger,
                  key: const Key('khqr_failure'),
                  text: _failureReason!,
                  actionLabel: 'Generate new QR',
                  onAction: _generate,
                ),
              if (_finalMessage != null)
                _notice(
                  icon: Icons.info_outline,
                  color: AppColors.warning,
                  key: const Key('khqr_final'),
                  text: _finalMessage!,
                  actionLabel: 'View order',
                  onAction: () => context.go('/order/${widget.orderNumber}'),
                ),
              if (_failureReason == null && _finalMessage == null) ...[
                if (!_expired)
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Waiting for payment…',
                          style: t.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('khqr_save'),
                        onPressed: _expired ? null : _saveQr,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Save QR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('khqr_share'),
                        onPressed: _expired ? null : _shareQr,
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('Share QR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Paying from this phone? Save or share the QR, then open your bank app and pick the image.',
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodySmall,
                ),
              ],
              if (d.isMock && !_done) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(
                  key: const Key('khqr_simulate'),
                  onPressed: _simulating ? null : _simulate,
                  child: _simulating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simulate payment (test mode)'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/order/${widget.orderNumber}'),
                child: const Text('Pay later – view order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required Color color,
    required Key key,
    required String text,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
