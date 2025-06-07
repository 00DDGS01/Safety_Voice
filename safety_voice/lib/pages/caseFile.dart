import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class CaseFile extends StatefulWidget {
  const CaseFile({super.key});

  @override
  _CaseFileState createState() => _CaseFileState();
}

class _CaseFileState extends State<CaseFile> {
  bool _isExpanded = false; // 세부사항 표시 여부

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
            "사건 파일 1",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.05,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            // "사건 설명" + 토글 버튼 + 수정 버튼
            SizedBox(
              height: 40.0, // 빈 상자 높이
              width: MediaQuery.of(context).size.width * 0.95, // 가로폭 85%
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 토글 버튼 + "사건 설명"
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded; // 토글 상태 변경
                          });
                        },
                        icon: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_down // 세부사항이 보이면 아래 방향
                              : Icons.keyboard_arrow_right, // 세부사항이 숨겨지면 오른쪽 방향
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const Text(
                        '사건 설명',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // 오른쪽: 수정 버튼
                  TextButton(
                    onPressed: () {
                      // 수정 버튼 동작
                    },
                    child: const Text(
                      '수정',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Color(0xFF787878) // 텍스트 색상
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 세부사항 표시
            if (_isExpanded)
              Container(
                width: MediaQuery.of(context).size.width * 0.95, // 가로폭 85%
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(top: 4.0), // 상단 여백
                child: const Text(
                  '클라이언트와 계약할 때 작성하지 않은 것을 요구하거나 구두계약을 이행하지 않을 때가 있다. 이로 인해 상사에게 언어폭력에 시달리고 있다. 따라서 구두계약 시 증거 자료로써 녹음을 해두고, 상사에게 부당한 대우를 받거나 언어폭력을 당할 때 상사가 눈치채지 못하게 증거자료를 모으려고 한다.',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                ),
              ),
            const Divider(color: Color(0xFFCACACA), thickness: 1.0), // 구분선
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