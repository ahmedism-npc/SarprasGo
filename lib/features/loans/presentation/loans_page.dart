import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/loan.dart';
import '../../../core/utils/wib_time.dart';
import '../data/loan_repository.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key, required this.isAdmin, required this.loans, required this.onRefresh, this.isStaff = false, this.onChanged});
  final bool isAdmin;
  final bool isStaff;
  final List<Loan> loans;
  final Future<void> Function() onRefresh;
  final ValueChanged<Loan>? onChanged;

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  late Future<List<Loan>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant LoansPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loans != widget.loans) _future = _load();
  }

  Future<List<Loan>> _load() async {
    if (widget.isStaff) return widget.loans;
    if (!AppConfig.hasSupabaseConfig) return widget.loans;
    return widget.isAdmin ? LoanRepository().pendingLoans() : LoanRepository().myLoans();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStaff) return _staffQueue();
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh();
        if (mounted) setState(() => _future = _load());
      },
      child: FutureBuilder<List<Loan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final loans = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            children: [
              Text(widget.isAdmin ? 'Antrean pengajuan' : 'Peminjaman saya', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(widget.isAdmin ? 'Tinjau permintaan dan tentukan jumlah yang disetujui.' : 'Pantau status permintaan dan jadwal peminjaman.', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              if (loans.isEmpty) const _EmptyLoans()
              else for (final loan in loans) Padding(padding: const EdgeInsets.only(bottom: 12), child: _LoanCard(loan: loan, isAdmin: widget.isAdmin, onApprove: _approve, onReject: _reject, onShowQr: _showQr)),
            ],
          );
        },
      ),
    );
  }

  Widget _staffQueue() => RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Antrean serah-terima', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          const Text('Daftar petugas harus disajikan oleh RPC terlingkup; aplikasi tidak membaca tabel loans secara massal.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          if (!AppConfig.hasSupabaseConfig)
            for (final loan in widget.loans.where((loan) => loan.status == 'DISETUJUI' || loan.status == 'SEDANG_DIPINJAM'))
              Padding(padding: const EdgeInsets.only(bottom: 10), child: _LoanCard(loan: loan, isAdmin: false, onApprove: _approve, onReject: _reject, onShowQr: _showQr))
          else
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Kontrak RPC antrean petugas belum tersedia di RBA. Sambungkan get_handover_queue setelah kontrak backend ditetapkan.'))),
        ]),
      );

  Widget _error(String error) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 38), const SizedBox(height: 10), const Text('Data peminjaman tidak dapat dimuat.'), TextButton(onPressed: () => setState(() => _future = _load()), child: const Text('Coba lagi')), Text(error, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black45))])));

  Future<void> _approve(Loan loan) async {
    final quantities = await _editApproval(loan);
    if (quantities == null || !mounted) return;
    if (loan.roomId == null && quantities.values.every((quantity) => quantity == 0)) {
      _toast('Setujui minimal satu unit barang atau satu ruang.');
      return;
    }
    try {
      if (!AppConfig.hasSupabaseConfig) {
        widget.onChanged?.call(loan.copyWith(status: 'DISETUJUI'));
      } else {
        await LoanRepository().approve(loan, approvedQuantities: quantities);
        await widget.onRefresh();
      }
      if (mounted) {
        _toast('Pengajuan disetujui.');
        setState(() => _future = _load());
      }
    } catch (error) {
      _toast('Persetujuan gagal: $error');
    }
  }

  Future<Map<String, int>?> _editApproval(Loan loan) async {
    final quantities = {for (var index = 0; index < loan.items.length; index++) loan.items[index].itemId: loan.items[index].quantity};
    if (!AppConfig.hasSupabaseConfig) return quantities;
    return showDialog<Map<String, int>>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
        title: const Text('Jumlah yang disetujui'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final item in loan.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('Diminta ${item.requestedQuantity ?? item.quantity} unit'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(onPressed: (quantities[item.itemId] ?? 0) > 0 ? () => setDialog(() => quantities[item.itemId] = quantities[item.itemId]! - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
                Text('${quantities[item.itemId] ?? 0}'),
                IconButton(onPressed: (quantities[item.itemId] ?? 0) < (item.requestedQuantity ?? item.quantity) ? () => setDialog(() => quantities[item.itemId] = (quantities[item.itemId] ?? 0) + 1) : null, icon: const Icon(Icons.add_circle_outline)),
              ]),
            ),
          if (loan.items.isEmpty) const Text('Tidak ada detail barang untuk disetujui.'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali')), FilledButton(onPressed: () => Navigator.pop(context, quantities), child: const Text('Setujui'))],
      )),
    );
  }

  Future<void> _reject(Loan loan) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Tolak pengajuan'),
          content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: const InputDecoration(labelText: 'Alasan wajib')),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Tolak'))],
        );
      },
    );
    if (reason == null || reason.isEmpty) return _toast('Alasan penolakan wajib diisi.');
    if (!AppConfig.hasSupabaseConfig) {
      widget.onChanged?.call(loan.copyWith(status: 'DITOLAK'));
      setState(() => _future = _load());
      return;
    }
    _toast('RPC penolakan belum memiliki kontrak di RBA.');
  }

  Future<void> _showQr(Loan loan) async {
    try {
      final value = await LoanRepository().getMyQr(loan.id);
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('QR peminjaman'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          QrImageView(data: value, size: 190, backgroundColor: Colors.white),
          const Text('Tunjukkan QR ini kepada Petugas Sarpras saat pengambilan atau pengembalian.'),
          const SizedBox(height: 6),
          Text('${formatWib(loan.startTime, 'd MMM yyyy · HH:mm')} WIB', style: const TextStyle(color: Colors.black54)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ));
    } catch (error) {
      _toast('QR belum dapat diambil: $error');
    }
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.isAdmin, required this.onApprove, required this.onReject, required this.onShowQr});
  final Loan loan;
  final bool isAdmin;
  final ValueChanged<Loan> onApprove;
  final ValueChanged<Loan> onReject;
  final ValueChanged<Loan> onShowQr;

  @override
  Widget build(BuildContext context) {
    final tone = _statusTone(loan.status);
    return Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(loan.purpose, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: tone.$2, borderRadius: BorderRadius.circular(20)), child: Text(_statusLabel(loan.status), style: TextStyle(color: tone.$1, fontSize: 10, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 11),
      _DetailLine(icon: Icons.event_outlined, text: '${formatWib(loan.startTime, 'EEE, d MMM · HH:mm')} – ${formatWib(loan.endTime, 'HH:mm')} WIB'),
      if (loan.roomName != null) _DetailLine(icon: Icons.meeting_room_outlined, text: loan.roomName!),
      for (final item in loan.items) _DetailLine(icon: Icons.inventory_2_outlined, text: '${item.name} · ${item.quantity} unit'),
      if (loan.borrowerName != null) _DetailLine(icon: Icons.person_outline, text: loan.borrowerName!),
      if (isAdmin && loan.status == 'MENUNGGU_PERSETUJUAN') ...[
        const SizedBox(height: 12),
        Row(children: [Expanded(child: OutlinedButton(onPressed: () => onReject(loan), child: const Text('Tolak'))), const SizedBox(width: 9), Expanded(child: FilledButton(onPressed: () => onApprove(loan), child: const Text('Tinjau & setujui')))]),
      ],
      if (!isAdmin && loan.status == 'DISETUJUI') ...[
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => onShowQr(loan), icon: const Icon(Icons.qr_code_2), label: const Text('Tampilkan QR'))),
      ],
    ])));
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [Icon(icon, size: 16, color: Colors.black45), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)))]));
}

class _EmptyLoans extends StatelessWidget {
  const _EmptyLoans();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(30), child: Column(children: [Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black38), SizedBox(height: 10), Text('Belum ada peminjaman untuk ditampilkan.') ]));
}

(Color, Color) _statusTone(String status) => switch (status) {
      'DISETUJUI' => (const Color(0xFF126B50), const Color(0xFFE5F3EB)),
      'SEDANG_DIPINJAM' => (const Color(0xFF2563A6), const Color(0xFFEAF1FB)),
      'TERLAMBAT' => (const Color(0xFFB4493F), const Color(0xFFFCEBE8)),
      'DITOLAK' || 'DIBATALKAN' || 'KEDALUWARSA' => (const Color(0xFF756E66), const Color(0xFFF0EFED)),
      _ => (const Color(0xFFB77A15), const Color(0xFFFFF0D7)),
    };

String _statusLabel(String status) => switch (status) {
      'MENUNGGU_PERSETUJUAN' => 'Menunggu',
      'DISETUJUI' => 'Disetujui',
      'SEDANG_DIPINJAM' => 'Dipinjam',
      'TERLAMBAT' => 'Terlambat',
      'SELESAI' => 'Selesai',
      'KEDALUWARSA' => 'Kedaluwarsa',
      'DITOLAK' => 'Ditolak',
      'DITUTUP_ADMIN' => 'Ditutup Admin',
      'DIBATALKAN' => 'Dibatalkan',
      _ => status,
    };
