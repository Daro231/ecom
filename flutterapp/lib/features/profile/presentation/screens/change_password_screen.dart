import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/state_views.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  Map<String, String> _server = {};

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _server = {});
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      if (mounted) {
        showSnack(context, 'Password changed');
        context.pop();
      }
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

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    suffixIcon: IconButton(
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _current,
                obscureText: _obscure,
                decoration: _dec('Current password'),
                validator: (v) =>
                    Validators.loginPassword(v) ?? _server['currentPassword'],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _new,
                obscureText: _obscure,
                decoration: _dec('New password'),
                validator: (v) =>
                    Validators.password(v) ?? _server['newPassword'],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: _dec('Confirm new password'),
                validator: Validators.match(
                  () => _new.text,
                  'Passwords do not match',
                ),
              ),
              const SizedBox(height: 24),
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
                    : const Text('Update password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
