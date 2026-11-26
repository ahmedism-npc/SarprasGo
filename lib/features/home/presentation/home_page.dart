import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user, required this.isDemo, required this.onOpenCatalog});
  final AppUser user;
  final bool isDemo;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final admin = user.isAdmin;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        Text('Halo, ${user.name.split(' ').first} 👋', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
        const SizedBox(height: 3),
        Text(admin ? 'Ringkasan operasional' : 'Mau pinjam apa hari ini?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.ink)),
        const SizedBox(height: 20),
        if (admin) _AdminSummary(onOpenQueue: onOpenCatalog, isDemo: isDemo) else _BorrowerBanner(onTap: onOpenCatalog),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(admin ? 'Perlu ditinjau' : 'Jelajahi sarana', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(onPressed: onOpenCatalog, child: Text(admin ? 'Lihat antrean' : 'Lihat semua')),
        ]),
        if (admin) ...[
          if (isDemo) const _AdminQueuePreview() else const _BackendSummaryNotice(),
        ] else if (isDemo) ...[
          const _QuickItemCard(icon: Icons.videocam_rounded, title: 'Proyektor Epson', detail: 'Audio visual · 4 tersedia', tone: Color(0xFFE8F4EE)),
          const SizedBox(height: 10),
          const _QuickItemCard(icon: Icons.meeting_room_rounded, title: 'Aula Microteaching', detail: 'Gedung A · bisa dipesan', tone: Color(0xFFEAF0FA)),
        ] else
          const _BackendSummaryNotice(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: const Color(0xFFEAF3ED), borderRadius: BorderRadius.circular(18)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: AppTheme.green),
            SizedBox(width: 11),
            Expanded(child: Text('Ajukan lebih awal agar Admin dapat memeriksa ketersediaan dan jadwal fasilitas.', style: TextStyle(height: 1.35, color: AppTheme.ink))),
          ]),
        ),
      ],
    );
  }
}

class _BorrowerBanner extends StatelessWidget {
  const _BorrowerBanner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF126B50), Color(0xFF278565)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Fasilitas kampus\nsiap menemani kegiatanmu.', style: TextStyle(color: Colors.white, fontSize: 19, height: 1.25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            FilledButton.tonal(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.green), child: const Text('Cari fasilitas')),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.event_available_rounded, size: 72, color: Color(0x99FFFFFF)),
        ]),
      );
}

class _AdminSummary extends StatelessWidget {
  const _AdminSummary({required this.onOpenQueue, required this.isDemo});
  final VoidCallback onOpenQueue;
  final bool isDemo;
  @override
  Widget build(BuildContext context) => Column(children: [
        if (isDemo)
        Row(children: const [
          Expanded(child: _MetricCard(value: '3', label: 'Menunggu', icon: Icons.hourglass_top, color: Color(0xFFB77A15))),
          SizedBox(width: 10),
          Expanded(child: _MetricCard(value: '12', label: 'Dipinjam', icon: Icons.outbox_outlined, color: AppTheme.green)),
          SizedBox(width: 10),
          Expanded(child: _MetricCard(value: '2', label: 'Terlambat', icon: Icons.warning_amber, color: Color(0xFFB4493F))),
        ]),
        if (!isDemo) const _BackendSummaryNotice(),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onOpenQueue, icon: const Icon(Icons.fact_check_outlined), label: const Text('Tinjau pengajuan'))),
      ]);
}

class _BackendSummaryNotice extends StatelessWidget {
  const _BackendSummaryNotice();
  @override
  Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Ringkasan langsung memerlukan RPC statistik Admin yang belum tercantum dalam kontrak RBA.', style: TextStyle(color: Colors.black54))));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label, required this.icon, required this.color});
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10), child: Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54))])));
}

class _AdminQueuePreview extends StatelessWidget {
  const _AdminQueuePreview();
  @override
  Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(16), child: Row(children: [CircleAvatar(backgroundColor: Color(0xFFFFF0D7), child: Icon(Icons.event_note, color: Color(0xFFB77A15))), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Seminar Himpunan Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 3), Text('Aula · besok, 09.00–12.00', style: TextStyle(color: Colors.black54, fontSize: 12))])), Icon(Icons.chevron_right)])));
}

class _QuickItemCard extends StatelessWidget {
  const _QuickItemCard({required this.icon, required this.title, required this.detail, required this.tone});
  final IconData icon;
  final String title;
  final String detail;
  final Color tone;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), leading: CircleAvatar(backgroundColor: tone, child: Icon(icon, color: AppTheme.green)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(detail), trailing: const Icon(Icons.chevron_right)));
}
