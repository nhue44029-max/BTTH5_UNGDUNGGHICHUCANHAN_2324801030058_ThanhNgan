import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note_model.dart';
import '../services/note_storage_service.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.storageService});
  final NoteStorage? storageService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const blue = Color(0xFF477CE0);
  static const text = Color(0xFF34436C);
  static const muted = Color(0xFF7280A0);
  static const cardColors = [
    Color(0xFFD8EAFE),
    Color(0xFFF7CEEB),
    Color(0xFFE7D7FA),
    Color(0xFFD8F0FA),
    Color(0xFFFFE6F3),
  ];

  late final NoteStorage _storage;
  final _searchController = TextEditingController();
  List<Note> _notes = <Note>[];
  bool _isLoading = true;
  bool _isMutating = false;
  String? _loadError;

  List<Note> get _visibleNotes {
    final query = _searchController.text.trim().toLowerCase();
    final sorted = List<Note>.from(_notes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (query.isEmpty) return sorted;
    return sorted
        .where(
          (note) =>
              note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? NoteStorageService();
    _searchController.addListener(_refreshSearch);
    _loadNotes();
  }

  void _refreshSearch() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final notes = await _storage.loadNotes();
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _saveFromEditor(Note note) async {
    if (_isMutating) {
      throw const NoteStorageException(
        'Một thao tác lưu khác đang được thực hiện. Vui lòng thử lại.',
      );
    }
    _isMutating = true;
    try {
      final next = List<Note>.from(_notes);
      final index = next.indexWhere((item) => item.id == note.id);
      if (index == -1) {
        next.add(note);
      } else {
        next[index] = note;
      }
      await _storage.saveNotes(next);
      if (!mounted) return;
      setState(() => _notes = next);
    } finally {
      _isMutating = false;
    }
  }

  Future<void> _openEditor([Note? note]) async {
    if (_isMutating) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note, onSave: _saveFromEditor),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            note == null
                ? 'Đã thêm ghi chú thành công.'
                : 'Đã lưu thay đổi thành công.',
          ),
        ),
      );
    }
  }

  Future<void> _showActions(Note note) async {
    if (_isMutating) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: blue),
                title: const Text('Chỉnh sửa'),
                onTap: () => Navigator.of(sheetContext).pop('edit'),
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                title: Text(
                  'Xóa ghi chú',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                onTap: () => Navigator.of(sheetContext).pop('delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _openEditor(note);
    } else if (action == 'delete') {
      await _confirmDelete(note);
    }
  }

  Future<void> _confirmDelete(Note note) async {
    if (_isMutating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa ghi chú “${note.title}” không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isMutating = true);
    try {
      final next = _notes.where((item) => item.id != note.id).toList();
      await _storage.saveNotes(next);
      if (!mounted) return;
      setState(() => _notes = next);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa ghi chú thành công.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa thất bại: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OceanCandyBackground(child: _HomeScaffold(state: this));
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 18,
        title: const _MayNoteBrand(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state._isMutating ? null : () => state._openEditor(),
        backgroundColor: _HomeScreenState.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm ghi chú',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SizedBox.expand(
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth >= 900 ? 32.0 : 18.0;
              final columns = constraints.maxWidth >= 800 ? 2 : 1;
              return RefreshIndicator(
                onRefresh: state._loadNotes,
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 14, padding, 8),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: _Header(
                              controller: state._searchController,
                              noteCount: state._notes.length,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (state._isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state._loadError != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _LoadError(
                          message: state._loadError!,
                          onRetry: state._loadNotes,
                        ),
                      )
                    else if (state._visibleNotes.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          hasSearch: state._searchController.text
                              .trim()
                              .isNotEmpty,
                          onAdd: () => state._openEditor(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(padding, 0, padding, 100),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: columns == 1 ? 205 : 218,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final note = state._visibleNotes[index];
                            return _NoteCard(
                              note: note,
                              color:
                                  _HomeScreenState.cardColors[index %
                                      _HomeScreenState.cardColors.length],
                              onTap: () => state._openEditor(note),
                              onLongPress: () => state._showActions(note),
                              onMore: () => state._showActions(note),
                            );
                          }, childCount: state._visibleNotes.length),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OceanCandyBackground extends StatelessWidget {
  const _OceanCandyBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFCDEBFF), Color(0xFFE3E7FF), Color(0xFFFBE3F5)],
      ),
    ),
    child: child,
  );
}

class _MayNoteBrand extends StatelessWidget {
  const _MayNoteBrand();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          child: _NotesIllustration(width: 42, height: 36),
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MâyNote',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _HomeScreenState.text,
                fontSize: 22,
                height: 1.05,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ghi điều thương, lưu điều nhớ.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF586B98),
                fontSize: 13.5,
                height: 1.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.noteCount});
  final TextEditingController controller;
  final int noteCount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _WelcomeBanner(),
      const SizedBox(height: 18),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Tìm theo tiêu đề hoặc nội dung...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa từ khóa',
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Ghi chú của tôi',
              style: TextStyle(
                color: _HomeScreenState.text,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$noteCount ghi chú',
              style: const TextStyle(
                color: _HomeScreenState.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
    ],
  );
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  static const _titleColor = Color(0xFF263B69);
  static const _descriptionColor = Color(0xFF53698C);
  static const _pink = Color(0xFFD77BAA);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA6D5FF), Color(0xFFC8C7F5), Color(0xFFF3BFE5)],
          stops: [0, 0.52, 1],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF556B99).withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          return Stack(
            children: [
              const Positioned(
                top: -46,
                right: -34,
                child: _PastelBubble(size: 150, color: Color(0x45FFFFFF)),
              ),
              const Positioned(
                bottom: -58,
                left: 38,
                child: _PastelBubble(size: 118, color: Color(0x20FFFFFF)),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 20 : 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 440 : 650),
                    child: _BannerCopy(compact: compact),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BannerCopy extends StatelessWidget {
  const _BannerCopy({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Text(
          'MÂYNOTE · GÓC NHỎ CỦA BẠN',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFF3F67A7),
            fontSize: 11.5,
            letterSpacing: 0.65,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      SizedBox(height: compact ? 13 : 17),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Một chút hôm nay,\n'),
            TextSpan(
              text: 'thêm một điều để nhớ.',
              style: TextStyle(
                color: _WelcomeBanner._pink,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.48),
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        style: TextStyle(
          color: _WelcomeBanner._titleColor,
          fontSize: compact ? 25 : 31,
          height: 1.22,
          letterSpacing: -0.45,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: compact ? 10 : 12),
      const Text(
        'Ghi lại những điều khiến ngày của bạn đặc biệt.',
        style: TextStyle(
          color: _WelcomeBanner._descriptionColor,
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _PastelBubble extends StatelessWidget {
  const _PastelBubble({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _NotesIllustration extends StatelessWidget {
  const _NotesIllustration({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(width, height),
    painter: const _NotesIllustrationPainter(),
  );
}

class _NotesIllustrationPainter extends CustomPainter {
  const _NotesIllustrationPainter();

  static const blue = Color(0xFF477CE0);
  static const darkBlue = Color(0xFF263B69);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 184;
    final sy = size.height / 164;
    canvas.save();
    canvas.scale(sx, sy);

    final shadow = Paint()
      ..color = const Color(0x33435F91)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 28, 101, 119),
        const Radius.circular(19),
      ),
      shadow,
    );

    final backPage = Paint()..color = const Color(0xFFD7EAFE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 32, 94, 116),
        const Radius.circular(17),
      ),
      backPage,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 32, 94, 116),
        const Radius.circular(17),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = blue.withValues(alpha: 0.78),
    );

    final pageRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(49, 22, 101, 119),
      const Radius.circular(18),
    );
    canvas.drawRRect(pageRect, Paint()..color = const Color(0xFFFFF5FC));
    canvas.drawRRect(
      pageRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = blue,
    );

    final cloudPath = Path()
      ..moveTo(73, 57)
      ..cubicTo(62, 57, 62, 42, 74, 40)
      ..cubicTo(77, 27, 93, 23, 103, 32)
      ..cubicTo(115, 24, 131, 31, 131, 45)
      ..cubicTo(143, 45, 145, 59, 136, 64)
      ..lineTo(77, 64)
      ..cubicTo(69, 64, 66, 61, 73, 57)
      ..close();
    canvas.drawPath(cloudPath, Paint()..color = Colors.white);
    canvas.drawPath(
      cloudPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.7
        ..strokeJoin = StrokeJoin.round
        ..color = blue,
    );

    final linePaint = Paint()
      ..color = const Color(0xFF9AADE0)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(69, 82), const Offset(132, 82), linePaint);
    canvas.drawLine(const Offset(69, 95), const Offset(122, 95), linePaint);
    canvas.drawLine(const Offset(69, 108), const Offset(111, 108), linePaint);

    final heart = Path()
      ..moveTo(140, 116)
      ..cubicTo(134, 106, 118, 110, 121, 122)
      ..cubicTo(124, 131, 140, 139, 140, 139)
      ..cubicTo(140, 139, 156, 131, 159, 122)
      ..cubicTo(162, 110, 146, 106, 140, 116)
      ..close();
    canvas.drawPath(heart, Paint()..color = const Color(0xFFF18ABD));

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    canvas.drawCircle(const Offset(28, 27), 5, dotPaint);
    canvas.drawCircle(const Offset(158, 49), 3.5, dotPaint);
    canvas.drawCircle(const Offset(25, 73), 2.8, dotPaint);

    final sparklePaint = Paint()
      ..color = darkBlue.withValues(alpha: 0.48)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(158, 81), const Offset(171, 81), sparklePaint);
    canvas.drawLine(
      const Offset(164.5, 74.5),
      const Offset(164.5, 87.5),
      sparklePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NotesIllustrationPainter oldDelegate) => false;
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.color,
    required this.onTap,
    required this.onLongPress,
    required this.onMore,
  });
  final Note note;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(19, 16, 10, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomeScreenState.text,
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onMore,
                  tooltip: 'Tùy chọn',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Expanded(
              child: Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomeScreenState.muted,
                  fontSize: 14.5,
                  height: 1.48,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 17,
                  color: _HomeScreenState.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomeScreenState.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, required this.onAdd});
  final bool hasSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.note_add_outlined,
            color: _HomeScreenState.blue,
            size: 64,
          ),
          const SizedBox(height: 18),
          Text(
            hasSearch ? 'Không tìm thấy ghi chú' : 'Chưa có ghi chú nào',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _HomeScreenState.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Hãy thử một từ khóa khác nhé.'
                : 'Nhấn “Thêm ghi chú” để lưu lại ý tưởng đầu tiên của bạn.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _HomeScreenState.muted, height: 1.45),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo ghi chú đầu tiên'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade600,
            size: 52,
          ),
          const SizedBox(height: 14),
          const Text(
            'Không thể tải ghi chú',
            style: TextStyle(
              color: _HomeScreenState.text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}
