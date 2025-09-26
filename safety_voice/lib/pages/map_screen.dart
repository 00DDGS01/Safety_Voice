import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:kpostal/kpostal.dart';
import 'package:safety_voice/utils/secrets.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late KakaoMapController _mapController;

  // 초기 중심 (충북대 신관 근처) — const 사용 금지
  LatLng _center = LatLng(36.6283, 127.4581);

  // 주소 표기
  String _address = '주소 검색 또는 지도를 이동해 위치를 선택하세요';

  // 직경 옵션(10/20/30m) — 지도 원 radius는 직경/2
  final List<double> _diameterOptions = [10, 20, 30];
  double _selectedDiameter = 20; // m

  bool _mapReady = false;
  bool _circleAdded = false;

  double get _circleRadiusMeters => _selectedDiameter / 2.0;

  Future<void> _moveCamera(LatLng pos, {int level = 3}) async {
    await _mapController.setCenter(pos);
    await _mapController.setLevel(level); // kakao_map_plugin은 level 사용
  }

  /// 주소 -> 좌표 (카카오 Local REST: address search)
  Future<LatLng?> _geocodeAddress(String address) async {
    final url = Uri.https(
      'dapi.kakao.com',
      '/v2/local/search/address.json',
      {'query': address},
    );

    final resp = await http.get(
      url,
      headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final docs = (data['documents'] as List?) ?? [];
      if (docs.isNotEmpty) {
        final x = double.tryParse(docs.first['x'].toString()); // longitude
        final y = double.tryParse(docs.first['y'].toString()); // latitude
        if (x != null && y != null) {
          return LatLng(y, x);
        }
      }
    }
    return null;
  }

  /// 좌표 -> 주소 (카카오 Local REST: coord2address)
  Future<void> _reverseGeocode(LatLng pos) async {
    final url = Uri.https(
      'dapi.kakao.com',
      '/v2/local/geo/coord2address.json',
      {
        'x': pos.longitude.toString(),
        'y': pos.latitude.toString(),
      },
    );

    final resp = await http.get(
      url,
      headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final docs = (data['documents'] as List?) ?? [];
      if (docs.isNotEmpty) {
        final road = docs.first['road_address'];
        final addr = docs.first['address'];
        final text = road != null
            ? (road['address_name'] ?? '')
            : (addr != null ? (addr['address_name'] ?? '') : '');
        if (text.isNotEmpty && mounted) {
          setState(() => _address = text);
        }
      }
    }
  }

  /// 다음 주소검색 팝업 → 결과(주소)로 좌표 구해서 이동
  Future<void> _openAddressSearch() async {
    final result = await Navigator.push<Kpostal>(
      context,
      MaterialPageRoute(
        builder: (_) => KpostalView(
          // 구버전 호환: callback으로 pop
          callback: (Kpostal res) => Navigator.pop(context, res),
          useLocalServer: false, // 기본값 사용
        ),
      ),
    );

    if (result != null) {
      setState(() => _address = result.address);

      final pos = await _geocodeAddress(result.address);
      if (pos != null) {
        await _moveCamera(pos, level: 3);
        setState(() => _center = pos);
        await _updateCircle();
      }
    }
  }

  /// 카메라 정지 시: 중심좌표/원/주소 갱신
  void _handleCameraIdle(LatLng latLng, int level) {
    setState(() => _center = latLng);
    _updateCircle();            // fire-and-forget
    _reverseGeocode(latLng);    // fire-and-forget
  }

  /// 원(반지름) 갱신
  Future<void> _updateCircle() async {
    final circle = Circle(
      circleId: 'safe_zone',
      center: _center,
      radius: _circleRadiusMeters, // meters (반지름)
      // 일부 버전은 Color 미지원 → hex + opacity 사용
      strokeColor: const Color.fromARGB(255, 255, 0, 0),
      strokeWidth: 2,
      strokeOpacity: 1,
      fillColor: const Color.fromARGB(255, 0, 47, 255),
      fillOpacity: 0.25,
      zIndex: 1,
    );

    if (_circleAdded) {
      try {
        await _mapController.clearCircle(circleIds: ['safe_zone']);
      } catch (_) {}
    }

    await _mapController.addCircle(circles: [circle]);
    _circleAdded = true;
  }

  Future<void> _selectDiameter(double d) async {
    setState(() => _selectedDiameter = d);
    await _updateCircle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: GestureDetector(
          onTap: _openAddressSearch,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          KakaoMap(
            center: _center,
            currentLevel: 3,
            onMapCreated: (c) async {
              _mapController = c;
              _mapReady = true;
              await _updateCircle();
              await _reverseGeocode(_center);
            },
            onCameraIdle: _handleCameraIdle, // (LatLng, int)
          ),


          // 중앙 고정 핀
          if (_mapReady)
            const IgnorePointer(
              child: Center(
                child: Icon(Icons.place, size: 38, color: Colors.red),
              ),
            ),

          // 하단 직경 선택
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _diameterOptions.map((d) {
                    final selected = _selectedDiameter == d;
                    return GestureDetector(
                      onTap: () => _selectDiameter(d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? Colors.red : Colors.white,
                          border: Border.all(color: Colors.black87),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 2,
                              offset: Offset(0, 1),
                              color: Colors.black12,
                            )
                          ],
                        ),
                        child: Text(
                          '${d.toInt()}m',
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  '현재 원 반지름: ${_circleRadiusMeters.toStringAsFixed(0)} m (직경 ${_selectedDiameter.toInt()} m)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
