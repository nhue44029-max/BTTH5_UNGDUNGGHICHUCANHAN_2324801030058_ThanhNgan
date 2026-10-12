import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th5_notes/models/note_model.dart';
import 'package:th5_notes/screens/home_screen.dart';
import 'package:th5_notes/services/note_storage_service.dart';

class _FakeStorage implements NoteStorage {
  List<Note> notes = <Note>[];

  @override
  Future<List<Note>> loadNotes() async => List<Note>.from(notes);

  @override
  Future<void> saveNotes(List<Note> notes) async {
    this.notes = List<Note>.from(notes);
  }
}

void main() {
  testWidgets('hiển thị trạng thái trống và mở màn hình thêm ghi chú', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(storageService: _FakeStorage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('MâyNote'), findsOneWidget);
    expect(find.text('Chưa có ghi chú nào'), findsOneWidget);

    await tester.ensureVisible(find.text('Tạo ghi chú đầu tiên'));
    await tester.pump();
    await tester.tap(find.text('Tạo ghi chú đầu tiên'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm ghi chú'), findsOneWidget);
    expect(find.text('Lưu ghi chú'), findsOneWidget);
  });

  testWidgets('banner vừa màn hình Android nhỏ và không bị overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(storageService: _FakeStorage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('MÂYNOTE · GÓC NHỎ CỦA BẠN'), findsOneWidget);
    expect(
      find.text('Ghi lại những điều khiến ngày của bạn đặc biệt.'),
      findsOneWidget,
    );
    expect(find.text('Lưu giữ mỗi ngày'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
