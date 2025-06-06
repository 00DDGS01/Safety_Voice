import 'package:flutter/material.dart';

class CaseFile extends StatefulWidget {
  final String title;
  final String description;

  const CaseFile({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  _CaseFileState createState() => _CaseFileState();
}

class _CaseFileState extends State<CaseFile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          title: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/listhome'),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/back.png',
                  height: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                  ),
                ),
              ],
            ),
          ),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
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
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        icon: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        '사건 설명',
                        style: TextStyle(fontSize: 18.0, color: Colors.black),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // 수정 버튼 구현 가능
                    },
                    child: const Text(
                      '수정',
                      style: TextStyle(fontSize: 16.0, color: Color(0xFF787878)),
                    ),
                  ),
                ],
              ),
            ),
            if (_isExpanded)
              Container(
                width: MediaQuery.of(context).size.width * 0.95,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(top: 4.0),
                child: Text(
                  widget.description,
                  style: const TextStyle(fontSize: 14.0, color: Colors.black),
                ),
              ),
            const Divider(color: Color(0xFFCACACA), thickness: 1.0),
            // 추가 내용 (빈 상자들)
            Container(
              width: double.infinity,
              height: 99.0, // 빈 상자 높이
              color: Colors.transparent, // 상자 투명
            ),
            Container(
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: const Color(0xFFCACACA), // 실선 색상
            ),
            Container(
              width: double.infinity,
              height: 99.0, // 빈 상자 높이
              color: Colors.transparent, // 상자 투명
            ),
            Container(
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: const Color(0xFFCACACA), // 실선 색상
            ),
            Container(
              width: double.infinity,
              height: 99.0, // 빈 상자 높이
              color: Colors.transparent, // 상자 투명
            ),
            Container(
              width: double.infinity,
              height: 1.0, // 실선 두께
              color: const Color(0xFFCACACA), // 실선 색상
            ),
          ],
        ),
      ),
    );
  }
}