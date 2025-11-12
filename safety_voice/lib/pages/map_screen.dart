import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding; // ✅ 별칭 추가
import 'package:safety_voice/services/trigger_listener.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Location _location = Location();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _center;
  double _radius = 100;
  bool _isEditing = false;
  final List<double> _radiusOptions = [20, 50, 100, 200];
  bool _isInSafeZone = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToLocationChanges();
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

  void _listenToLocationChanges() {
    _location.onLocationChanged.listen((locData) {
      if (_center == null) return;

      final currentPos = LatLng(locData.latitude!, locData.longitude!);
      final distance = _calculateDistance(_center!, currentPos);

      if (distance <= _radius && !_isInSafeZone) {
        _isInSafeZone = true;
        print("🛑 안전지대 진입 → 마이크 정지");
        TriggerListener.instance.stopListening();
      } else if (distance > _radius && _isInSafeZone) {
        _isInSafeZone = false;
        print("✅ 안전지대 벗어남 → 마이크 재개");
        TriggerListener.instance.startListening();
      }
    });
  }

  void _onMapTap(LatLng tappedPoint) {
    if (!_isEditing) return;
    setState(() {
      _center = tappedPoint;
    });
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

  Future<void> _searchAndNavigate() async {
  String query = _searchController.text;
  if (query.isEmpty) return;

  try {
    // ✅ geocoding prefix로 구분
    List<geocoding.Location> locations = await geocoding.locationFromAddress(query);

    if (locations.isNotEmpty) {
      final location = locations.first;
      final LatLng searchedLatLng =
          LatLng(location.latitude, location.longitude);

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(searchedLatLng, 16.5),
      );

      if (_isEditing) {
        setState(() {
          _center = searchedLatLng;
        });
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('검색에 실패했습니다: $e')),
    );
  }
}

  Widget _buildSearchBar() {
    return Positioned(
      top: 30,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "검색할 장소를 입력하세요",
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchAndNavigate,
            ),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _searchAndNavigate(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 239, 243, 255),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          '안전지대 설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: () {
              if (_center != null) {
                Navigator.pop(context, {
                  'latitude': _center!.latitude,
                  'longitude': _center!.longitude,
                  'radius': _radius,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('지도를 탭해서 안전지대를 선택하세요!')),
                );
              }
            },
          ),
          Switch(
            value: _isEditing,
            activeColor: const Color(0xFF5C7CFA),
            onChanged: (val) => setState(() => _isEditing = val),
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
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
          ),

          // ✅ 검색창 표시
          _buildSearchBar(),

          // ✅ 반경 조절 UI
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
                          padding: const EdgeInsets.all(6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 24 : 14,
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

// ✅ 거리 계산 함수 (State 클래스 밖)
double _calculateDistance(LatLng p1, LatLng p2) {
  const R = 6371000;
  final dLat = (p2.latitude - p1.latitude) * (pi / 180);
  final dLon = (p2.longitude - p1.longitude) * (pi / 180);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(p1.latitude * (pi / 180)) *
          cos(p2.latitude * (pi / 180)) *
          sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}