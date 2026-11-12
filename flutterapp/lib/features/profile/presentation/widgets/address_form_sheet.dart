import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/geocoder.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/location_map.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/address.dart';
import '../providers/profile_providers.dart';

/// Add (or edit, when [existing] is set) an address. Returns the saved id's
/// success flag.
Future<bool> showAddressForm(
  BuildContext context, {
  Address? existing,
  bool forceDefault = false,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        AddressFormSheet(existing: existing, forceDefault: forceDefault),
  );
  return ok ?? false;
}

class AddressFormSheet extends ConsumerStatefulWidget {
  const AddressFormSheet({super.key, this.existing, this.forceDefault = false});
  final Address? existing;
  final bool forceDefault;

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.receiverName);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _line1 = TextEditingController(text: widget.existing?.line1);
  late final _city = TextEditingController(
    text: widget.existing?.city ?? 'Phnom Penh',
  );
  late bool _default = widget.existing?.isDefault ?? widget.forceDefault;
  bool _busy = false;
  Map<String, String> _server = {};

  // ---- map / location ----
  final _mapCtl = MapController();
  late LatLng? _pin = (widget.existing?.hasLocation ?? false)
      ? LatLng(widget.existing!.latitude!, widget.existing!.longitude!)
      : null;
  double? _accuracy; // metres; set only while the pin is the GPS fix
  bool _locating = false;
  bool _lookingUp = false;
  String? _locationMessage;
  Timer? _debounce;

  /// Address / City are only filled from the map while the user has not typed
  /// in them. When editing an address they already contain the user's data.
  late bool _lineTouched = widget.existing != null;
  late bool _cityTouched = widget.existing != null;

  @override
  void dispose() {
    _debounce?.cancel();
    _mapCtl.dispose();
    for (final c in [_name, _phone, _line1, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setPin(LatLng p, {double? accuracy}) {
    setState(() {
      _pin = p;
      _accuracy = accuracy; // a manual move makes the GPS accuracy meaningless
      _locationMessage = null;
    });
    // Debounce (1 s): dragging fires many updates, Nominatim allows 1 req/s.
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), _reverseGeocode);
  }

  void _clearPin() {
    _debounce?.cancel();
    setState(() {
      _pin = null;
      _accuracy = null;
      _lookingUp = false;
    });
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    final r = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    if (r.isOk) {
      final p = LatLng(r.latitude!, r.longitude!);
      setState(() => _locating = false);
      _setPin(p, accuracy: r.accuracy);
      // Zoom out far enough to show the whole accuracy circle.
      showAccuracy(_mapCtl, p, r.accuracy);
    } else {
      setState(() {
        _locating = false;
        _locationMessage = r.message;
      });
      // Never leave the map somewhere odd: fall back to Phnom Penh.
      if (_pin == null) _mapCtl.move(phnomPenh, 12);
    }
  }

  Future<void> _reverseGeocode() async {
    final p = _pin;
    if (p == null || !mounted) return;
    if (_lineTouched && _cityTouched) return; // nothing we may fill
    setState(() => _lookingUp = true);
    try {
      final g = await ref
          .read(geocoderProvider)
          .reverse(p.latitude, p.longitude);
      if (!mounted || _pin != p) return; // pin moved meanwhile
      if (g != null) {
        if (!_lineTouched && (g.line1 ?? '').isNotEmpty) _line1.text = g.line1!;
        if (!_cityTouched && (g.city ?? '').isNotEmpty) _city.text = g.city!;
      }
      setState(() {
        _lookingUp = false;
        _locationMessage = g == null
            ? 'No address found for this spot - please type it below.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _locationMessage =
            'Could not look up the address. The pin is kept - please type the address below.';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _server = {});
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final c = ref.read(addressesProvider.notifier);
    try {
      if (widget.existing == null) {
        await c.add(
          receiverName: _name.text,
          phone: _phone.text,
          line1: _line1.text,
          city: _city.text,
          isDefault: _default,
          latitude: _pin?.latitude,
          longitude: _pin?.longitude,
        );
      } else {
        await c.edit(
          widget.existing!.id,
          receiverName: _name.text,
          phone: _phone.text,
          line1: _line1.text,
          city: _city.text,
          isDefault: _default,
          latitude: _pin?.latitude,
          longitude: _pin?.longitude,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _server = e.fieldErrors;
      });
      _form.currentState!.validate();
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'New address' : 'Edit address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              LocationPickerMap(
                key: const Key('address_map'),
                pin: _pin,
                controller: _mapCtl,
                onPinChanged: _setPin,
                accuracyMeters: _accuracy,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('use_my_location'),
                      onPressed: _locating ? null : _useMyLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _locating
                            ? 'Getting your location…'
                            : 'Use my current location',
                      ),
                    ),
                  ),
                  if (_pin != null)
                    IconButton(
                      key: const Key('clear_pin'),
                      tooltip: 'Remove pin',
                      onPressed: _clearPin,
                      icon: const Icon(Icons.location_off_outlined),
                    ),
                ],
              ),
              if (accuracyWarning(_accuracy) case final warning?)
                Container(
                  key: const Key('accuracy_warning'),
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _lookingUp
                      ? Text(
                          'Looking up the address…',
                          key: const Key('lookup_progress'),
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : _locationMessage != null
                      ? Text(
                          _locationMessage!,
                          key: const Key('location_message'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        )
                      : Text(
                          _pin == null
                              ? 'Optional: tap the map or use your location to drop a pin.'
                              : 'Pin set - tap the map or drag the pin to adjust.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Receiver name'),
                validator: (v) =>
                    Validators.required(v, 'Receiver name') ??
                    _server['receiverName'],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => Validators.phone(v) ?? _server['phone'],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line1,
                onChanged: (_) => _lineTouched = true,
                decoration: const InputDecoration(
                  labelText: 'Address (house, street, district)',
                ),
                validator: (v) =>
                    Validators.required(v, 'Address') ?? _server['line1'],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                onChanged: (_) => _cityTouched = true,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) =>
                    Validators.required(v, 'City') ?? _server['city'],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default'),
                value: _default,
                onChanged: (v) => setState(() => _default = v),
              ),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
