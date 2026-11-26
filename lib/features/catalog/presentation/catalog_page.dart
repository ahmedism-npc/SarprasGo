import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/wib_time.dart';
import '../../loans/data/loan_repository.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_item.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.onLoanCreated});
  final ValueChanged<String> onLoanCreated;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _repository = CatalogRepository();
  final _search = TextEditingController();
  late Future<List<CatalogItem>> _items;
  late Future<List<CatalogItem>> _rooms;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    _items = _repository.getItems();
    _rooms = _repository.getRooms();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async => setState(_reload),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Text('Katalog fasilitas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text('Pilih sarana atau ruang untuk kegiatanmu.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 17),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama fasilitas'),
            ),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Barang'), icon: Icon(Icons.inventory_2_outlined)),
                ButtonSegment(value: 1, label: Text('Ruang'), icon: Icon(Icons.meeting_room_outlined)),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) => setState(() => _tab = selection.first),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<CatalogItem>>(
              future: _tab == 0 ? _items : _rooms,
              builder: (context, snapshot) {
                if (snapshot.hasError) return _LoadError(onRetry: () => setState(_reload), message: snapshot.error.toString());
                if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()));
                final entries = snapshot.data!
                    .where((item) => item.name.toLowerCase().contains(_search.text.toLowerCase()))
                    .toList();
                if (entries.isEmpty) return const _EmptyCatalog();
                return Column(children: [
                  for (final item in entries) ...[
                    _CatalogCard(item: item, onTap: () => _showLoanForm(item)),
                    const SizedBox(height: 11),
                  ],
                ]);
              },
            ),
          ],
        ),
      );

  Future<void> _showLoanForm(CatalogItem firstItem) async {
    late final List<List<CatalogItem>> catalogs;
    try {
      catalogs = await Future.wait([_repository.getItems(), _repository.getRooms()]);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jadwal/ketersediaan tidak dapat dimuat: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.canvas,
      builder: (context) => _LoanDraftSheet(
        firstItem: firstItem,
        items: catalogs[0],
        rooms: catalogs[1],
        repository: _repository,
        onSubmit: widget.onLoanCreated,
      ),
    );
  }
}

class _LoanDraftSheet extends StatefulWidget {
  const _LoanDraftSheet({required this.firstItem, required this.items, required this.rooms, required this.repository, required this.onSubmit});
  final CatalogItem firstItem;
  final List<CatalogItem> items;
  final List<CatalogItem> rooms;
  final CatalogRepository repository;
  final ValueChanged<String> onSubmit;

  @override
  State<_LoanDraftSheet> createState() => _LoanDraftSheetState();
}

class _LoanDraftSheetState extends State<_LoanDraftSheet> {
  final _purpose = TextEditingController();
  final _organization = TextEditingController();
  final _loanRepository = LoanRepository();
  late final String _draftId = const Uuid().v4();
  late DateTime _date;
  late DateTime _start;
  late DateTime _end;
  final Map<String, int> _quantities = {};
  bool _organizationLoan = false;
  bool _submitting = false;
  String? _error;

  String? _roomId;
  String get _dateLabel => DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date);

  @override
  void initState() {
    super.initState();
    final tomorrow = wibNow.add(const Duration(days: 1));
    _date = DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day);
    _start = DateTime.utc(_date.year, _date.month, _date.day, 9);
    _end = DateTime.utc(_date.year, _date.month, _date.day, 11);
    if (widget.firstItem.isRoom) {
      _roomId = widget.firstItem.id;
    } else {
      _quantities[widget.firstItem.id] = 1;
    }
  }

  @override
  void dispose() {
    _purpose.dispose();
    _organization.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text('Ajukan peminjaman', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(widget.firstItem.name, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 18),
            TextField(controller: _purpose, maxLength: 140, decoration: const InputDecoration(labelText: 'Keperluan kegiatan', hintText: 'Contoh: seminar fakultas')),
            const SizedBox(height: 7),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_dateLabel),
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(15)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _TimeButton(label: 'Mulai', date: _start, onTap: () => _pickTime(true))),
              const SizedBox(width: 10),
              Expanded(child: _TimeButton(label: 'Selesai', date: _end, onTap: () => _pickTime(false))),
            ]),
            const SizedBox(height: 15),
            Text('Barang yang dipinjam', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            for (final item in widget.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _QuantitySelector(item: item, quantity: _quantities[item.id] ?? 0, onChanged: (value) => setState(() => _quantities[item.id] = value)),
              ),
            const SizedBox(height: 7),
            DropdownButtonFormField<String?>(
              initialValue: _roomId,
              decoration: const InputDecoration(labelText: 'Ruang (opsional)', prefixIcon: Icon(Icons.meeting_room_outlined)),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Tanpa peminjaman ruang')),
                for (final room in widget.rooms) DropdownMenuItem<String?>(value: room.id, child: Text(room.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) => setState(() => _roomId = value),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _organizationLoan,
              onChanged: (value) => setState(() => _organizationLoan = value ?? false),
              title: const Text('Atas nama organisasi'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_organizationLoan) ...[
              TextField(controller: _organization, decoration: const InputDecoration(labelText: 'Nama organisasi')),
              const SizedBox(height: 8),
              const Text('Surat pengantar dapat dilampirkan setelah fitur unggah Storage dikonfigurasi.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
            if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red))],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _submitting ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Kirim pengajuan'),
            ),
          ]),
        ),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: wibNow.add(const Duration(days: 1)),
      lastDate: wibNow.add(const Duration(days: 180)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime.utc(picked.year, picked.month, picked.day);
      _start = DateTime.utc(picked.year, picked.month, picked.day, _start.hour, _start.minute);
      _end = DateTime.utc(picked.year, picked.month, picked.day, _end.hour, _end.minute);
    });
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _start : _end;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime.utc(_date.year, _date.month, _date.day, time.hour, time.minute);
      if (start) {
        _start = value;
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = value;
      }
    });
  }

  Future<void> _submit() async {
    if (_purpose.text.trim().isEmpty) return setState(() => _error = 'Keperluan kegiatan wajib diisi.');
    if (_organizationLoan && _organization.text.trim().isEmpty) return setState(() => _error = 'Nama organisasi wajib diisi.');
    if (!_end.isAfter(_start) || !_start.isAfter(wibNow)) return setState(() => _error = 'Pastikan jadwal berakhir setelah waktu mulai dan dimulai di masa depan.');
    if (_roomId == null && (_quantities.values.every((quantity) => quantity <= 0))) return setState(() => _error = 'Pilih minimal satu barang atau satu ruang.');
    setState(() { _submitting = true; _error = null; });
    try {
      if (AppConfig.hasSupabaseConfig) {
        final startUtc = wibWallTimeToUtc(_start);
        final endUtc = wibWallTimeToUtc(_end);
        final currentItems = await widget.repository.getItems(startTime: startUtc, endTime: endUtc);
        for (final entry in _quantities.entries.where((entry) => entry.value > 0)) {
          final matches = currentItems.where((candidate) => candidate.id == entry.key);
          final item = matches.isEmpty ? null : matches.first;
          if (item == null || item.available < entry.value) {
            throw StateError('Ketersediaan barang berubah. Muat ulang katalog dan sesuaikan jumlah.');
          }
        }
        if (_roomId != null) {
          final currentRooms = await widget.repository.getRooms(startTime: startUtc, endTime: endUtc);
          if (currentRooms.every((room) => room.id != _roomId || room.available < 1)) {
            throw StateError('Ruang tidak tersedia pada waktu pilihan. Pilih jadwal lain.');
          }
        }
      }
      await _loanRepository.createDraft(
        purpose: _purpose.text.trim(),
        start: wibWallTimeToUtc(_start),
        end: wibWallTimeToUtc(_end),
        roomId: _roomId,
        items: _quantities.entries.where((entry) => entry.value > 0).map((entry) => {'item_id': entry.key, 'requested_qty': entry.value}).toList(),
        draftId: _draftId,
        isOrganization: _organizationLoan,
        organizationName: _organizationLoan ? _organization.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmit(_purpose.text.trim());
    } catch (error) {
      setState(() => _error = 'Pengajuan belum terkirim. Coba lagi dengan draft ini. ($error)');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)), child: Row(children: [const Icon(Icons.schedule, size: 18), const SizedBox(width: 8), Text('$label · ${DateFormat('HH:mm').format(date)} WIB')]));
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({required this.item, required this.quantity, required this.onChanged});
  final CatalogItem item;
  final int quantity;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.green), title: Text(item.name), subtitle: Text('${item.available} tersedia'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null, icon: const Icon(Icons.remove_circle_outline)), Text('$quantity'), IconButton(onPressed: quantity < item.available ? () => onChanged(quantity + 1) : null, icon: const Icon(Icons.add_circle_outline))])));
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item, required this.onTap});
  final CatalogItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(borderRadius: BorderRadius.circular(20), onTap: item.available > 0 ? onTap : null, child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: item.isRoom ? const Color(0xFFEAF0FA) : const Color(0xFFE8F4EE), borderRadius: BorderRadius.circular(16)), child: Icon(_icon(item.icon), color: AppTheme.green)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 4), Text(item.category, style: const TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 7), Text(item.isRoom ? 'Cek jadwal tersedia' : '${item.available} unit tersedia', style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.w600, fontSize: 12))])), const Icon(Icons.chevron_right)]))));
}

IconData _icon(String name) => switch (name) {
      'videocam' => Icons.videocam_rounded,
      'speaker' => Icons.speaker_rounded,
      'mic' => Icons.mic_rounded,
      'cable' => Icons.cable_rounded,
      'meeting_room' => Icons.meeting_room_rounded,
      'computer' => Icons.computer_rounded,
      _ => Icons.inventory_2_rounded,
    };

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, required this.message});
  final VoidCallback onRetry;
  final String message;
  @override
  Widget build(BuildContext context) => Column(children: [const Icon(Icons.cloud_off_outlined, size: 42), const SizedBox(height: 8), const Text('Katalog belum dapat dimuat.'), TextButton(onPressed: onRetry, child: const Text('Coba lagi')), Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black45))]);
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(28), child: Column(children: [Icon(Icons.search_off, size: 40, color: Colors.black38), SizedBox(height: 8), Text('Tidak ada fasilitas yang cocok.') ]));
}
