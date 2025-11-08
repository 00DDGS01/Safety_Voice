import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Location _location = Location();

  LatLng? _center; // ✅ null이면 원 표시 안 함
  double _radius = 100;
  bool _isEditing = false; // ✅ 토글 on/off
  final List<double> _radiusOptions = [20, 50, 100, 200];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final hasPermission = await _location.requestPermission();
    final serviceEnabled = await _location.requestService();

    if (hasPermission == PermissionStatus.granted && serviceEnabled) {
      final locData = await _location.getLocation();
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(locData.latitude!, locData.longitude!),
          16.5,
        ),
      );
    }
  }

  double getZoomFromRadius(double radius) {
    if (radius <= 20) return 18.5;
    if (radius <= 50) return 17.5;
    if (radius <= 100) return 16.5;
    if (radius <= 200) return 15.5;
    return 14;
  }

  void _selectRadius(double value) {
    setState(() {
      _radius = value;
    });
    if (_center != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_center!, getZoomFromRadius(value)),
      );
    }
  }

  void _onMapTap(LatLng tappedPoint) {
    if (!_isEditing) return; // ✅ 편집 모드 아닐 때는 무시
    setState(() {
      _center = tappedPoint;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
    backgroundColor: const Color.fromARGB(255, 239, 243, 255),
    centerTitle: true,
    elevation: 0, // ✅ 그림자 제거
    title: const Text(
      '안전지대 설정',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.black,
      ),
    ),
    actions: [
      Switch(
        value: _isEditing,
        activeColor: const Color(0xFF5C7CFA), // ✅ 포인트 컬러 통일
        onChanged: (val) {
          setState(() {
            _isEditing = val;
          });
        },
      ),
    ],
  ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(36.6283, 127.4581),
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTap,
            markers: _center != null
                ? {
                    Marker(
                      markerId: const MarkerId("center_marker"),
                      position: _center!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _center = newPosition;
                        });
                      },
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  }
                : {},
            circles: _center != null
                ? {
                    Circle(
                      circleId: const CircleId("safe_zone"),
                      center: _center!,
                      radius: _radius,
                      fillColor: Colors.red.withOpacity(0.3),
                      strokeColor: Colors.red,
                      strokeWidth: 2,
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // ✅ 반경 조절 UI (편집 모드일 때만 표시)
          if (_isEditing)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _radiusOptions.map((value) {
                      final bool isSelected = _radius == value;
                      return InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => _selectRadius(value),
                        child: Container(
                          padding: const EdgeInsets.all(6), // ✅ 터치 범위 약 1.4배 확장 (기존 대비)
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 24 : 14, // 🎨 기존 디자인 그대로 유지
                            height: isSelected ? 24 : 14,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color.fromARGB(255, 255, 34, 0)
                                  : Colors.grey[600],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Text("20m", style: TextStyle(fontSize: 12)),
                      Text("50m", style: TextStyle(fontSize: 12)),
                      Text("100m", style: TextStyle(fontSize: 12)),
                      Text("200m", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}