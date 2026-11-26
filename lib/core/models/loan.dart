class Loan {
  const Loan({
    required this.id,
    required this.purpose,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.borrowerName,
    this.roomName,
    this.roomId,
    this.items = const [],
  });

  final String id;
  final String purpose;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? borrowerName;
  final String? roomName;
  final String? roomId;
  final List<LoanItem> items;

  Loan copyWith({
    String? id,
    String? purpose,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? roomName,
    List<LoanItem>? items,
  }) =>
      Loan(
        id: id ?? this.id,
        purpose: purpose ?? this.purpose,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        borrowerName: borrowerName,
        roomName: roomName ?? this.roomName,
        roomId: roomId,
        items: items ?? this.items,
      );

  factory Loan.fromRow(Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? 'MENUNGGU_PERSETUJUAN';
    final start = DateTime.tryParse(row['start_time']?.toString() ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(row['end_time']?.toString() ?? '') ?? DateTime.now();
    final now = DateTime.now().toUtc();
    final effectiveStatus = switch (status) {
      'MENUNGGU_PERSETUJUAN' when !end.isAfter(now) => 'KEDALUWARSA',
      'DISETUJUI' when !start.add(const Duration(minutes: 30)).isAfter(now) => 'KEDALUWARSA',
      'SEDANG_DIPINJAM' when !end.isAfter(now) => 'TERLAMBAT',
      _ => status,
    };
    return Loan(
        id: row['id']?.toString() ?? '',
        purpose: row['purpose']?.toString() ?? 'Peminjaman sarana',
        startTime: start,
        endTime: end,
        status: row['effective_status']?.toString() ?? effectiveStatus,
        roomName: row['room_name']?.toString() ?? row['rooms']?['name']?.toString(),
        roomId: row['room_id']?.toString(),
        borrowerName: row['borrower_name']?.toString() ?? row['users']?['name']?.toString(),
        items: ((row['loan_items'] ?? row['items']) as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(LoanItem.fromRow)
            .toList(),
      );
  }
}

class LoanItem {
  const LoanItem({required this.name, required this.quantity, this.requestedQuantity, this.itemId = ''});
  final String name;
  final int quantity;
  final int? requestedQuantity;
  final String itemId;

  factory LoanItem.fromRow(Map<String, dynamic> row) => LoanItem(
        name: (row['item_name'] ?? row['name'] ?? row['items']?['name'] ?? 'Barang').toString(),
        quantity: (row['approved_qty'] ?? row['requested_qty'] ?? 1) as int,
        requestedQuantity: row['requested_qty'] as int?,
        itemId: (row['item_id'] ?? '').toString(),
      );
}
