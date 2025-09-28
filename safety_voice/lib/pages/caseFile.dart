import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class CaseFile extends StatefulWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onUpdate;

  const CaseFile({super.key, required this.data, required this.onUpdate});

  @override
  _CaseFileState createState() => _CaseFileState();
}

class _CaseFileState extends State<CaseFile> {
  bool _isExpanded = false;

  late String title;
  late String description;

  @override
  void initState() {
    super.initState();
    title = widget.data['title'];
    description = widget.data['description'];
  }

  void _openEditModal() {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 12, bottom: bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("사건 파일 수정",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "제목",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "설명",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("취소"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          title = titleCtrl.text.trim();
                          description = descCtrl.text.trim();
                        });

                        final updated = Map<String, dynamic>.from(widget.data);
                        updated['title'] = title;
                        updated['description'] = description;

                        widget.onUpdate(updated);

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사건 파일이 수정되었습니다')),
                        );
                      },
                      child: const Text("저장"),
                    ),
                  ),
                ],
              )
            ],
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
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40.0,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      icon: Icon(
                        _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      '사건 설명',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _openEditModal,
                  child: const Text('수정', style: TextStyle(color: Color(0xFF787878))),
                ),
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
