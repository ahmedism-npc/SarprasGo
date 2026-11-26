import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/wib_time.dart';
import '../domain/catalog_item.dart';

class CatalogRepository {
  bool get isConfigured => AppConfig.hasSupabaseConfig;

  DateTime get _defaultStart {
    final tomorrow = wibNow.add(const Duration(days: 1));
    return wibWallTimeToUtc(DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day, 9));
  }

  Future<List<CatalogItem>> getItems({DateTime? startTime, DateTime? endTime}) async {
    if (!isConfigured) return demoItems;
    final result = await Supabase.instance.client.rpc(
      'get_availability_summary',
      params: {
        'p_start_time': (startTime ?? _defaultStart).toUtc().toIso8601String(),
        'p_end_time': (endTime ?? _defaultStart.add(const Duration(hours: 2))).toUtc().toIso8601String(),
      },
    );
    final payload = result is Map && result['data'] is Map ? result['data'] : result;
    final rows = payload is List ? payload : (payload['items'] as List? ?? []);
    return rows
        .whereType<Map<String, dynamic>>()
        .where((row) => row['is_room'] != true)
        .map(CatalogItem.fromRow)
        .toList();
  }

  Future<List<CatalogItem>> getRooms({DateTime? startTime, DateTime? endTime}) async {
    if (!isConfigured) return demoRooms;
    final result = await Supabase.instance.client.rpc(
      'get_availability_summary',
      params: {
        'p_start_time': (startTime ?? _defaultStart).toUtc().toIso8601String(),
        'p_end_time': (endTime ?? _defaultStart.add(const Duration(hours: 2))).toUtc().toIso8601String(),
      },
    );
    final payload = result is Map && result['data'] is Map ? result['data'] : result;
    final rows = payload is List ? payload : (payload['rooms'] as List? ?? []);
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => CatalogItem.fromRow(row, room: true))
        .toList();
  }

  static const demoItems = [
    CatalogItem(id: 'item-projector', name: 'Proyektor Epson', category: 'Audio Visual', available: 4, icon: 'videocam'),
    CatalogItem(id: 'item-speaker', name: 'Speaker Aktif', category: 'Audio', available: 6, icon: 'speaker'),
    CatalogItem(id: 'item-mic', name: 'Mikrofon Wireless', category: 'Audio', available: 8, icon: 'mic'),
    CatalogItem(id: 'item-cable', name: 'Kabel HDMI 10m', category: 'Aksesori', available: 3, icon: 'cable'),
  ];
  static const demoRooms = [
    CatalogItem(id: 'room-aula', name: 'Aula Microteaching', category: 'Gedung A · Lantai 2', available: 1, isRoom: true, icon: 'meeting_room'),
    CatalogItem(id: 'room-lab', name: 'Laboratorium Komputer', category: 'Gedung B · Lantai 1', available: 1, isRoom: true, icon: 'computer'),
    CatalogItem(id: 'room-class', name: 'Ruang Kelas 204', category: 'Gedung C · Lantai 2', available: 1, isRoom: true, icon: 'door_front'),
  ];
}
