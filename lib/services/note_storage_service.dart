import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_model.dart';

class NoteStorageException implements Exception {
  const NoteStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

abstract interface class NoteStorage {
  Future<List<Note>> loadNotes();
  Future<void> saveNotes(List<Note> notes);
}

class NoteStorageService implements NoteStorage {
  NoteStorageService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String storageKey = 'peach_notes_data';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Note>> loadNotes() async {
    try {
      final jsonString = await _preferences.getString(storageKey);
      if (jsonString == null || jsonString.trim().isEmpty) return <Note>[];
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        throw const FormatException('Danh sách ghi chú không hợp lệ.');
      }
      return decoded
          .map((item) => Note.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (error) {
      throw NoteStorageException(
        'Không thể đọc dữ liệu ghi chú trên thiết bị.',
        error,
      );
    }
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    try {
      final jsonString = jsonEncode(
        notes.map((note) => note.toJson()).toList(),
      );
      await _preferences.setString(storageKey, jsonString);
    } catch (error) {
      throw NoteStorageException(
        'Không thể lưu dữ liệu ghi chú trên thiết bị.',
        error,
      );
    }
  }
}
