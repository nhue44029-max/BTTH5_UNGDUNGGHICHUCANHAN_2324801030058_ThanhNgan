import 'dart:math';

import 'package:flutter/material.dart';

import '../models/note_model.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note, required this.onSave});

  final Note? note;
  final Future<void> Function(Note note) onSave;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  static const _blue = Color(0xFF477CE0);
  static const _text = Color(0xFF34436C);
  static const _muted = Color(0xFF7280A0);
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final String _initialTitle;
  late final String _initialContent;
  bool _isSaving = false;
  bool _allowPop = false;

  bool get _isEditing => widget.note != null;
  bool get _hasChanges =>
      _titleController.text != _initialTitle ||
      _contentController.text != _initialContent;

  @override
  void initState() {
    super.initState();
    _initialTitle = widget.note?.title ?? '';
    _initialContent = widget.note?.content ?? '';
    _titleController = TextEditingController(text: _initialTitle);
    _contentController = TextEditingController(text: _initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(0x7fffffff)}';

  Future<void> _save() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            title.isEmpty
                ? 'Vui lòng nhập tiêu đề ghi chú.'
                : 'Vui lòng nhập nội dung ghi chú.',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final now = DateTime.now();
    final note = widget.note == null
        ? Note(
            id: _newId(),
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now,
          )
        : widget.note!.copyWith(title: title, content: content, updatedAt: now);
    try {
      await widget.onSave(note);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _allowPop = true;
      });
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu thất bại: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _requestPop() async {
    if (_isSaving) return;
    if (!_hasChanges) {
      setState(() => _allowPop = true);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text(
          'Bạn có thay đổi chưa được lưu. Bạn có muốn rời khỏi màn hình này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestPop();
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCDEBFF), Color(0xFFE3E7FF), Color(0xFFFBE3F5)],
          ),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              onPressed: _isSaving ? null : _requestPop,
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              _isEditing ? 'Chỉnh sửa ghi chú' : 'Thêm ghi chú',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SizedBox.expand(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 760,
                        minHeight: constraints.maxHeight - 44,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _EditorHeading(isEditing: _isEditing),
                            const SizedBox(height: 22),
                            const _FieldLabel('Tiêu đề'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _titleController,
                              enabled: !_isSaving,
                              maxLength: 100,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Ví dụ: Ý tưởng cho ngày mới',
                                prefixIcon: Icon(Icons.title_rounded),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 20),
                            const _FieldLabel('Nội dung'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contentController,
                              enabled: !_isSaving,
                              minLines: 8,
                              maxLines: 14,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                hintText: 'Hãy ghi lại điều bạn đang nghĩ...',
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 54,
                              child: FilledButton.icon(
                                onPressed: _isSaving ? null : _save,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: _isSaving
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(
                                  _isSaving
                                      ? 'Đang lưu...'
                                      : (_isEditing
                                            ? 'Lưu thay đổi'
                                            : 'Lưu ghi chú'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _NoteEditorScreenState._text,
      fontWeight: FontWeight.w700,
      fontSize: 15,
    ),
  );
}

class _EditorHeading extends StatelessWidget {
  const _EditorHeading({required this.isEditing});
  final bool isEditing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _NoteEditorScreenState._blue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            isEditing ? Icons.edit_note_rounded : Icons.note_add_rounded,
            color: _NoteEditorScreenState._blue,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Cập nhật ý tưởng' : 'Một trang mới',
                style: const TextStyle(
                  color: _NoteEditorScreenState._text,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Viết theo cách của bạn, MâyNote sẽ lưu giữ.',
                style: TextStyle(
                  color: _NoteEditorScreenState._muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
