import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/loan.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../catalog/presentation/catalog_page.dart';
import '../../loans/data/loan_repository.dart';
import '../../loans/presentation/loans_page.dart';
import '../../staff/presentation/handover_page.dart';
import 'home_page.dart';
import 'management_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AuthController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late List<Loan> _demoLoans;

  AppUser get user => widget.controller.user!;
  bool get isDemo => user.id.startsWith('demo-');

  @override
  void initState() {
    super.initState();
    _demoLoans = [...LoanRepository.demoLoans];
  }

  List<_TabSpec> get _tabs => switch (user.role) {
        AppRole.peminjam => const [
            _TabSpec('Beranda', Icons.home_outlined, Icons.home_rounded),
            _TabSpec('Katalog', Icons.widgets_outlined, Icons.widgets_rounded),
            _TabSpec('Peminjaman', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
            _TabSpec('Akun', Icons.person_outline, Icons.person_rounded),
          ],
        AppRole.admin => const [
            _TabSpec('Ringkasan', Icons.dashboard_outlined, Icons.dashboard_rounded),
            _TabSpec('Persetujuan', Icons.fact_check_outlined, Icons.fact_check_rounded),
            _TabSpec('Inventaris', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
            _TabSpec('Akun', Icons.person_outline, Icons.person_rounded),
          ],
        AppRole.petugasSarpras => const [
            _TabSpec('Serah-terima', Icons.qr_code_scanner_outlined, Icons.qr_code_scanner_rounded),
            _TabSpec('Antrean', Icons.list_alt_outlined, Icons.list_alt_rounded),
            _TabSpec('Akun', Icons.person_outline, Icons.person_rounded),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    if (_index >= tabs.length) _index = 0;
    final pages = _buildPages();
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppTheme.green,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          const Text('SarprasGo', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          if (isDemo)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(child: _DemoPill()),
            ),
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => _message('Notifikasi in-app akan tampil setelah backend aktif.'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    if (user.isBorrower) {
      return [
        HomePage(user: user, isDemo: isDemo, onOpenCatalog: () => setState(() => _index = 1)),
        CatalogPage(onLoanCreated: _onLoanCreated),
        LoansPage(isAdmin: false, loans: _demoLoans, onRefresh: _refreshLoans),
        AccountPage(user: user, controller: widget.controller, demo: isDemo),
      ];
    }
    if (user.isAdmin) {
      return [
        HomePage(user: user, isDemo: isDemo, onOpenCatalog: () => setState(() => _index = 1)),
        LoansPage(isAdmin: true, loans: _demoLoans, onRefresh: _refreshLoans, onChanged: _onLoanChanged),
        const ManagementPage(),
        AccountPage(user: user, controller: widget.controller, demo: isDemo),
      ];
    }
    return [
      HandoverPage(isDemo: isDemo, isActive: _index == 0),
      LoansPage(isAdmin: false, isStaff: true, loans: _demoLoans, onRefresh: _refreshLoans),
      AccountPage(user: user, controller: widget.controller, demo: isDemo),
    ];
  }

  void _onLoanCreated(String purpose) {
    if (isDemo) {
      setState(() {
        _demoLoans = [
          LoanRepository.demoLoans.first.copyWith(
            id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
            purpose: purpose,
            status: 'MENUNGGU_PERSETUJUAN',
            startTime: DateTime.now().add(const Duration(days: 2)),
            endTime: DateTime.now().add(const Duration(days: 2, hours: 2)),
          ),
          ..._demoLoans,
        ];
      });
    } else {
      _refreshLoans();
    }
    _message('Pengajuan dibuat. Admin akan meninjau permintaan Anda.');
    setState(() => _index = user.isAdmin ? 1 : 2);
  }

  void _onLoanChanged(Loan loan) {
    setState(() => _demoLoans = [for (final current in _demoLoans) if (current.id == loan.id) loan else current]);
  }

  Future<void> _refreshLoans() async {
    if (!isDemo) {
      try {
        final repository = LoanRepository();
        final rows = user.isAdmin ? await repository.pendingLoans() : await repository.myLoans();
        if (mounted) setState(() => _demoLoans = rows);
      } catch (error) {
        _message('Data belum dapat dimuat: $error');
      }
    } else {
      setState(() {});
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.user, required this.controller, required this.demo});
  final AppUser user;
  final AuthController controller;
  final bool demo;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Akun saya', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                CircleAvatar(radius: 28, backgroundColor: AppTheme.green.withValues(alpha: .1), child: const Icon(Icons.person, color: AppTheme.green)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(user.email, style: const TextStyle(color: Colors.black54)),
                  Text(_roleLabel(user.role), style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.w600)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          const _SettingsTile(icon: Icons.help_outline, title: 'Pusat bantuan'),
          const SizedBox(height: 8),
          const _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privasi dan keamanan'),
          const SizedBox(height: 8),
          const _SettingsTile(icon: Icons.info_outline, title: 'Tentang SarprasGo · v1.0'),
          const SizedBox(height: 20),
          if (demo) const Text('Sesi pratinjau: data dan aksi hanya simulasi.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: controller.signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ],
      );
}

String _roleLabel(AppRole role) => switch (role) {
      AppRole.peminjam => 'Peminjam',
      AppRole.admin => 'Admin',
      AppRole.petugasSarpras => 'Petugas Sarpras',
    };

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: AppTheme.green), title: Text(title), trailing: const Icon(Icons.chevron_right)));
}

class _DemoPill extends StatelessWidget {
  const _DemoPill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFFFF0D7), borderRadius: BorderRadius.circular(30)),
        child: const Text('DEMO', style: TextStyle(fontSize: 10, color: Color(0xFF875A0A), fontWeight: FontWeight.bold)),
      );
}

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
