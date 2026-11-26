import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/loan.dart';

class LoanRepository {
  bool get isConfigured => AppConfig.hasSupabaseConfig;

  Future<List<Loan>> myLoans() async {
    if (!isConfigured) return demoLoans;
    final rows = await Supabase.instance.client
        .from('loans')
        .select('id,purpose,room_id,start_time,end_time,status,created_at,rooms(name),loan_items(item_id,requested_qty,approved_qty,items(name))')
        .order('created_at', ascending: false);
    return rows.map((row) => Loan.fromRow(row)).toList();
  }

  Future<List<Loan>> pendingLoans() async {
    if (!isConfigured) {
      return demoLoans
          .where((loan) => loan.status == 'MENUNGGU_PERSETUJUAN')
          .toList();
    }
    final rows = await Supabase.instance.client
        .from('loans')
        .select('id,borrower_id,purpose,room_id,start_time,end_time,status,created_at,rooms(name),users!loans_borrower_id_fkey(name),loan_items(item_id,requested_qty,approved_qty,items(name))')
        .eq('status', 'MENUNGGU_PERSETUJUAN')
        .gt('end_time', DateTime.now().toUtc().toIso8601String())
        .order('created_at');
    return rows.map((row) => Loan.fromRow(row)).toList();
  }

  Future<String> getMyQr(String loanId) async {
    if (!isConfigured) return 'DEMO-QR-$loanId';
    final result = await Supabase.instance.client.rpc(
      'get_my_loan_qr',
      params: {'p_loan_id': loanId},
    );
    if (result is String) return result;
    if (result is Map && result['qr_token'] is String) {
      return result['qr_token'] as String;
    }
    if (result is Map && result['data'] is Map && result['data']['qr_token'] is String) {
      return result['data']['qr_token'] as String;
    }
    throw const FormatException('Respons QR dari server tidak sesuai kontrak.');
  }

  Future<void> approve(Loan loan, {required Map<String, int> approvedQuantities}) async {
    if (!isConfigured) return;
    final prefs = await SharedPreferences.getInstance();
    final keyName = 'idempotency:approve_loan:${loan.id}';
    final key = prefs.getString(keyName) ?? const Uuid().v4();
    await prefs.setString(keyName, key);
    final response = await Supabase.instance.client.rpc('approve_loan_atomic', params: {
      'p_loan_id': loan.id,
      'p_approved_items': loan.items
          .where((item) => item.itemId.isNotEmpty)
          .map((item) => {'item_id': item.itemId, 'approved_qty': approvedQuantities[item.itemId] ?? 0})
          .toList(),
      'p_idempotency_key': key,
    });
    await _throwIfRejected(response, prefs: prefs, keyName: keyName);
    await prefs.remove(keyName);
  }

  Future<void> createDraft({
    required String purpose,
    required DateTime start,
    required DateTime end,
    required String? roomId,
    required List<Map<String, dynamic>> items,
    required String draftId,
    required bool isOrganization,
    required String? organizationName,
  }) async {
    if (!isConfigured) return;
    final prefs = await SharedPreferences.getInstance();
    final keyName = 'idempotency:create_loan:$draftId';
    final idempotencyKey = prefs.getString(keyName) ?? const Uuid().v4();
    await prefs.setString(keyName, idempotencyKey);
    final response = await Supabase.instance.client.rpc(
      'create_loan',
      params: {
        'p_idempotency_key': idempotencyKey,
        'p_loan': {
          'purpose': purpose,
          'start_time': start.toUtc().toIso8601String(),
          'end_time': end.toUtc().toIso8601String(),
          'room_id': roomId,
          'items': items,
          'is_organization': isOrganization,
          'organization_name': organizationName,
        },
      },
    );
    await _throwIfRejected(response, prefs: prefs, keyName: keyName);
    await prefs.remove(keyName);
  }

  Future<void> _throwIfRejected(dynamic response, {required SharedPreferences prefs, required String keyName}) async {
    if (response is Map && response['ok'] == false) {
      if (response['code'] != 'IDEMPOTENCY_PAYLOAD_MISMATCH') {
        await prefs.remove(keyName);
      }
      throw StateError((response['message'] ?? response['code'] ?? 'Permintaan ditolak server').toString());
    }
  }

  static final demoLoans = [
    Loan(
      id: 'demo-loan-1',
      purpose: 'Seminar Himpunan Mahasiswa',
      startTime: DateTime.now().add(const Duration(days: 2)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
      status: 'DISETUJUI',
      roomName: 'Aula Microteaching',
      items: const [LoanItem(name: 'Proyektor Epson', quantity: 1), LoanItem(name: 'Speaker Aktif', quantity: 2)],
    ),
    Loan(
      id: 'demo-loan-2',
      purpose: 'Presentasi tugas akhir',
      startTime: DateTime.now().add(const Duration(days: 4)),
      endTime: DateTime.now().add(const Duration(days: 4, hours: 2)),
      status: 'MENUNGGU_PERSETUJUAN',
      roomName: 'Ruang Kelas 204',
      items: const [LoanItem(name: 'Proyektor Epson', quantity: 1)],
    ),
  ];
}
