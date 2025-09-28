import 'package:flutter/material.dart';

class CaseFile extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;

  /// (선택) 제목 중복 검사 콜백. 새 제목이 기존과 다를 때만 호출됨.
  final bool Function(String newTitle)? isTitleDuplicate;

  const CaseFile({
    super.key,
    required this.data,
    required this.onUpdate,
    this.isTitleDuplicate,
  });

  @override
  _CaseFileState createState() => _CaseFileState();
}

class _CaseFileState extends State<CaseFile> {
  bool _isExpanded = false;

  late String title;
  late String description;
  late Color badgeColor; // 배경색
  late Color textColor;  // 텍스트색

  @override
  void initState() {
    super.initState();
    title       = (widget.data['title'] ?? '') as String;
    description = (widget.data['description'] ?? '') as String;
    badgeColor  = _hexToColor(widget.data['color'] ?? '#E7F0FE');
    textColor   = _hexToColor(widget.data['textColor'] ?? '#1A73E8');
  }

  // ===== Helpers =====
  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// 선택된 색에 "검정 비율을 섞은" 더 진한 색 (텍스트용)
  Color _mixWithBlack(Color base, [double t = 0.6]) {
    final r = (base.red   * (1 - t)).round();
    final g = (base.green * (1 - t)).round();
    final b = (base.blue  * (1 - t)).round();
    return Color.fromARGB(255, r, g, b);
  }

  void _showSheetSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openEditModal() {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl  = TextEditingController(text: description);

    final preset = <Color>[
      const Color(0xFFFDEDED), // 빨강 라이트
      const Color(0xFFEBF8ED), // 초록 라이트
      const Color(0xFFE7F0FE), // 파랑 라이트
      const Color(0xFFFFF4E0), // 주황 라이트
      const Color(0xFFEFEFEF), // 회색 라이트
    ];
    Color selected = badgeColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // 키보드 높이에 맞춰 시트 안쪽 패딩을 부드럽게 변경
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: FractionallySizedBox(
            heightFactor: 0.6, // Home과 동일: 화면의 60%
            child: SafeArea(
              top: false, // 상단만 둥근 모서리 보여주려고 top은 false
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
                // ✅ 스크롤 가능하게 해서 키보드가 올라와도 영역이 줄어들 때 자연스럽게 스크롤
                child: StatefulBuilder(
                  builder: (ctx, setSheet) {
                    Widget rowField(String label, Widget trailing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: trailing),
                        ],
                      ),
                    );

                    return SingleChildScrollView(
                      // 키보드가 올라오면 이 부분이 스크롤되어 컨트롤들이 가려지지 않음
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "사건 파일 수정",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // 제목
                          rowField(
                            '제목',
                            TextField(
                              controller: titleCtrl,
                              decoration: const InputDecoration(
                                hintText: '제목 입력',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),

                          // 설명
                          rowField(
                            '설명',
                            TextField(
                              controller: descCtrl,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              decoration: const InputDecoration(
                                hintText: '간단한 설명',
                                border: OutlineInputBorder(),
                                isDense: true,
                                alignLabelWithHint: true,
                              ),
                            ),
                          ),

                          // 색상
                          rowField(
                            '색상',
                            Wrap(
                              spacing: 10,
                              children: [
                                for (final c in preset)
                                  GestureDetector(
                                    onTap: () => setSheet(() => selected = c),
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: c == selected ? Colors.black : Colors.black26,
                                          width: c == selected ? 2 : 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    foregroundColor: Colors.black87,
                                    overlayColor: Colors.black12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('취소', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    final newTitle = titleCtrl.text.trim();
                                    final newDesc  = descCtrl.text.trim();

                                    if (newTitle.isEmpty) {
                                      _showSheetSnack(ctx, '제목을 입력하세요');
                                      return;
                                    }
                                    if (newTitle != title &&
                                        (widget.isTitleDuplicate?.call(newTitle) ?? false)) {
                                      _showSheetSnack(ctx, '이미 존재하는 파일 이름입니다');
                                      return;
                                    }

                                    final newBadge = selected;
                                    final newText  = _mixWithBlack(newBadge, 0.6);

                                    setState(() {
                                      title       = newTitle;
                                      description = newDesc;
                                      badgeColor  = newBadge;
                                      textColor   = newText;
                                    });

                                    final updated = Map<String, dynamic>.from(widget.data)
                                      ..['title']       = newTitle
                                      ..['description'] = newDesc
                                      ..['color']       = _colorToHex(newBadge)
                                      ..['textColor']   = _colorToHex(newText);

                                    widget.onUpdate(updated);

                                    Navigator.pop(ctx);
                                    _showSheetSnack(context, '사건 파일이 수정되었습니다');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    foregroundColor: Colors.black87,
                                    overlayColor: Colors.black12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('저장', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 239, 243, 255),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', height: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.05,
              color: Colors.black,
            ),
          ),
          actions: [
            // 우측 끝 ⋮ 아이콘으로 수정 모달 열기 (Home과 통일)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: _openEditModal,
              tooltip: '수정',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40.0,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.black,
                  ),
                ),
                const Text('사건 설명',
                    style: TextStyle(fontSize: 18, color: Colors.black)),
              ],
            ),
          ),
          if (_isExpanded)
            Container(
              width: MediaQuery.of(context).size.width * 0.95,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          const Divider(color: Color(0xFFCACACA), thickness: 1.0),

        ],
      ),
    );
  }
}
