import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});
  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  AppRole _demoRole = AppRole.peminjam;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 76,
                      width: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.inventory_2_rounded,
                          size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 26),
                    Text('SarprasGo',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 6),
                    Text('Peminjaman fasilitas fakultas, lebih mudah.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black54,
                            )),
                    const SizedBox(height: 32),
                    TextField(
                      key: const Key('login-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Email kampus',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('login-password'),
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (widget.controller.error != null) ...[
                      const SizedBox(height: 12),
                      Text(widget.controller.error!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: widget.controller.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: widget.controller.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Masuk'),
                    ),
                    if (!widget.controller.isConfigured) ...[
                      const SizedBox(height: 22),
                      const Row(children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('PRATINJAU'),
                        ),
                        Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<AppRole>(
                        initialValue: _demoRole,
                        decoration: const InputDecoration(
                          labelText: 'Lihat tampilan sebagai',
                          prefixIcon: Icon(Icons.visibility_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: AppRole.peminjam, child: Text('Peminjam')),
                          DropdownMenuItem(value: AppRole.admin, child: Text('Admin')),
                          DropdownMenuItem(value: AppRole.petugasSarpras, child: Text('Petugas Sarpras')),
                        ],
                        onChanged: (role) => setState(() => _demoRole = role ?? AppRole.peminjam),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => widget.controller.enterDemo(_demoRole),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Masuk mode demo'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mode demo memakai data contoh di perangkat dan tidak membuat transaksi di server.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ] else ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Akun yang baru terdaftar perlu diaktifkan oleh Admin sebelum dapat masuk.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi email dan kata sandi terlebih dahulu.')),
      );
      return;
    }
    await widget.controller.signIn(_email.text, _password.text);
  }
}
