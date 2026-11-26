class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.available,
    this.icon = 'inventory_2',
    this.isRoom = false,
  });

  final String id;
  final String name;
  final String category;
  final int available;
  final String icon;
  final bool isRoom;

  factory CatalogItem.fromRow(Map<String, dynamic> row, {bool room = false}) =>
      CatalogItem(
        id: row['id']?.toString() ?? '',
        name: (row['name'] ?? row['room_name'] ?? row['item_name'] ?? 'Sarpras')
            .toString(),
        category: (row['category'] ?? row['location'] ??
                (room ? 'Ruang' : 'Peralatan'))
            .toString(),
        available: (row['available_qty'] ?? row['available'] ??
                row['remaining_qty'] ?? 0) as int,
        isRoom: room,
      );
}
