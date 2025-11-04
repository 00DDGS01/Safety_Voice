import 'package:flutter/material.dart';

class HintScreen extends StatefulWidget {
  const HintScreen({super.key});

  @override
  State<HintScreen> createState() => _HintScreenState();
}

class _HintScreenState extends State<HintScreen> {
  final PageController _pageController = PageController();
  int _current = 0;

  final List<String> _images = const [
    'assets/hint/zero.png',
    'assets/hint/one.png',
    'assets/hint/two.png',
    'assets/hint/three.png',
    'assets/hint/four.png',
    'assets/hint/five.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = _pageController.page;
    if (page == null) return;
    final idx = page.round();
    if (idx != _current) {
      setState(() {
        _current = idx;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 전체 흰색
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF3FF), // ✅ AppBar도 흰색
        elevation: 0.5,
        title: const Text(
          "도움말",
          style: TextStyle(
          fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final image = Image.asset(
                          _images[index],
                          fit: index == 0 ? BoxFit.fitWidth : BoxFit.fitHeight,
                        );

                        if (index == 0) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(child: image),
                          );
                        } else {
                          return Center(
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: FittedBox(
                                fit: BoxFit.fitHeight,
                                child: image,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },

                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length, (i) {
                    final active = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: active ? 10 : 8,
                      height: active ? 10 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? const Color(0xFF577BE5)
                            : Colors.black.withOpacity(0.2),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
