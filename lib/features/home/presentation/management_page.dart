import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog_item.dart';

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});
  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  final _repository = CatalogRepository();
  late Future<List<CatalogItem>> _items = _repository.getItems();
  late Future<List<CatalogItem>> _rooms = _repository.getRooms();

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 24), children: [
        Text('Inventaris', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Pantau barang dan fasilitas yang tersedia.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        if (!AppConfig.hasSupabaseConfig)
          const _DemoNotice()
        else
          const _BackendNotice(),
        const SizedBox(height: 16),
        Text('Barang', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        FutureBuilder<List<CatalogItem>>(future: _items, builder: (context, snapshot) => _InventoryList(snapshot: snapshot, onRetry: () => setState(() => _items = _repository.getItems()))),
        const SizedBox(height: 18),
        Text('Ruang', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        FutureBuilder<List<CatalogItem>>(future: _rooms, builder: (context, snapshot) => _InventoryList(snapshot: snapshot, onRetry: () => setState(() => _rooms = _repository.getRooms()))),
      ]);
}

class _InventoryList extends StatelessWidget {
  const _InventoryList({required this.snapshot, required this.onRetry});
  final AsyncSnapshot<List<CatalogItem>> snapshot;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) return TextButton(onPressed: onRetry, child: const Text('Gagal memuat. Coba lagi.'));
    if (!snapshot.hasData) return const LinearProgressIndicator();
    if (snapshot.data!.isEmpty) return const Text('Belum ada data.');
    return Column(children: [
      for (final item in snapshot.data!)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFE8F4EE), child: Icon(item.isRoom ? Icons.meeting_room : Icons.inventory_2, color: AppTheme.green)), title: Text(item.name), subtitle: Text(item.category), trailing: Text(item.isRoom ? 'Aktif' : '${item.available} unit', style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold))))),
    ]);
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();
  @override
  Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Mode demo hanya menampilkan data contoh. Penambahan metadata dan penyesuaian stok membutuhkan koneksi Supabase serta RPC adjust_item_stock.', style: TextStyle(height: 1.4))));
}

class _BackendNotice extends StatelessWidget {
  const _BackendNotice();
  @override
  Widget build(BuildContext context) => const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Daftar master dan ketersediaan dibaca lewat RPC agregat. Kontrak RPC manajemen metadata dan adjust_item_stock belum tersedia lengkap di RBA, sehingga perubahan stok dinonaktifkan untuk mencegah mutasi tanpa audit.', style: TextStyle(height: 1.4))));
}
