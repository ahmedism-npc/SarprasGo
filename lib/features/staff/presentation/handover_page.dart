import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';

class HandoverPage extends StatefulWidget {
  const HandoverPage({super.key, required this.isDemo, required this.isActive});
  final bool isDemo;
  final bool isActive;
  @override
  State<HandoverPage> createState() => _HandoverPageState();
}

class _HandoverPageState extends State<HandoverPage> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _busy = false;
  String? _result;
  String _action = 'PICKUP';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HandoverPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.start();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 24), children: [
        Text('Serah-terima', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Pindai QR transaksi untuk memeriksa pengambilan atau pengembalian.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'PICKUP', label: Text('Pengambilan'), icon: Icon(Icons.call_received)),
            ButtonSegment(value: 'RETURN', label: Text('Pengembalian'), icon: Icon(Icons.assignment_return)),
          ],
          selected: {_action},
          onSelectionChanged: (selected) => setState(() { _action = selected.first; _result = null; }),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 320,
            child: Stack(fit: StackFit.expand, children: [
              MobileScanner(controller: _controller, onDetect: _onDetect),
              IgnorePointer(child: Center(child: Container(width: 220, height: 220, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(24))))),
              if (_busy) const ColoredBox(color: Color(0x88000000), child: Center(child: CircularProgressIndicator(color: Colors.white))),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.verified_user_outlined, color: AppTheme.green), const SizedBox(width: 10), Expanded(child: Text(_result ?? 'Pastikan nama peminjam dan kondisi fisik barang sesuai sebelum mengonfirmasi.', style: const TextStyle(height: 1.4)))]))),
        if (widget.isDemo) ...[
          const SizedBox(height: 11),
          OutlinedButton.icon(onPressed: _busy ? null : () => _onToken('DEMO-QR-demo-loan-1'), icon: const Icon(Icons.play_circle_outline), label: const Text('Simulasikan pemindaian')),
        ],
      ]);

  void _onDetect(BarcodeCapture capture) {
    if (_busy) return;
    final values = capture.barcodes.map((barcode) => barcode.rawValue).whereType<String>();
    final token = values.isEmpty ? null : values.first;
    if (token != null && token.isNotEmpty) _onToken(token);
  }

  Future<void> _onToken(String token) async {
    setState(() { _busy = true; _result = null; });
    try {
      if (!AppConfig.hasSupabaseConfig) {
        setState(() => _result = 'QR demo terbaca. Status transaksi contoh valid untuk simulasi $_action.');
        await _showDemoConfirm(token);
      } else {
        final result = await Supabase.instance.client.rpc(
          'verify_qr_transaction',
          params: {'p_qr_token': token, 'p_action': _action},
        );
        final data = result is Map ? result : <String, dynamic>{'result': result};
        if (data['ok'] != true) {
          setState(() => _result = (data['message'] ?? 'QR tidak valid untuk tindakan ini.').toString());
          return;
        }
        setState(() => _result = 'Transaksi terverifikasi. ${data['borrower_name'] ?? ''} ${data['effective_status'] ?? ''}');
        await _showBackendUnavailable();
      }
    } catch (error) {
      setState(() => _result = 'Verifikasi gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showDemoConfirm(String token) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(_action == 'PICKUP' ? 'Konfirmasi pengambilan' : 'Konfirmasi pengembalian'),
      content: Text(_action == 'PICKUP' ? 'Periksa barang dan serahkan kepada peminjam. Lanjutkan simulasi?' : 'Catat seluruh barang kembali, rusak, atau hilang. Lanjutkan simulasi?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Kembali')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Konfirmasi'))],
    ));
    if (confirm == true && mounted) setState(() => _result = 'Simulasi $_action selesai. Tidak ada perubahan pada server.');
  }

  Future<void> _showBackendUnavailable() async {
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: const Text('Konfirmasi serah-terima'),
      content: const Text('RBA belum mendefinisikan RPC mutasi PICKUP/RETURN, payload kuantitas, dan kode idempotensinya. QR sudah diverifikasi read-only; mutasi dinonaktifkan sampai kontrak tersebut tersedia.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
    ));
  }
}
