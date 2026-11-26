import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sarprasgo/app/app.dart';
import 'package:sarprasgo/core/models/app_user.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));
  testWidgets('peminjam dapat membuka katalog dari mode demo', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SarprasGoApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Masuk mode demo'));
    await tester.tap(find.text('Masuk mode demo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Halo, Nadia'), findsOneWidget);
    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();
    expect(find.text('Katalog fasilitas'), findsOneWidget);
    expect(find.text('Proyektor Epson'), findsOneWidget);
  });

  testWidgets('Admin melihat antrean persetujuan', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SarprasGoApp());
    await tester.pumpAndSettle();
    final roleDropdown = find.byWidgetPredicate((widget) => widget is DropdownButtonFormField<AppRole>);
    await tester.ensureVisible(roleDropdown);
    await tester.tap(roleDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk mode demo'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan operasional'), findsOneWidget);
    await tester.tap(find.text('Persetujuan'));
    await tester.pumpAndSettle();
    expect(find.text('Antrean pengajuan'), findsOneWidget);
    expect(find.text('Presentasi tugas akhir'), findsOneWidget);
  });
}
