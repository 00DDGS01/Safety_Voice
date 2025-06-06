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

  LatLng _center = const LatLng(36.6283, 127.4581); // 충북대 신관
  double _radius = 100;

  final List<double> _radiusOptions = [20, 50, 100, 200];

  double getZoomFromRadius(double radius) {
    if (radius <= 20) return 18.5;
    if (radius <= 50) return 17.5;
    if (radius <= 100) return 16.5;
    if (radius <= 200) return 15.5;
    return 14;
  }

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
      setState(() {
        _center = LatLng(locData.latitude!, locData.longitude!);
      });

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_center, getZoomFromRadius(_radius)),
      );
    }
  }

  void _selectRadius(double value) {
    setState(() {
      _radius = value;
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_center, getZoomFromRadius(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내 동네 설정")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: getZoomFromRadius(_radius),
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(_center, getZoomFromRadius(_radius)),
              );
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            circles: {
              Circle(
                circleId: const CircleId("safe_zone"),
                center: _center,
                radius: _radius,
                fillColor: Colors.red.withOpacity(0.3),
                strokeColor: Colors.red,
                strokeWidth: 2,
              ),
            },
          ),

          // 커스텀 반경 선택 UI
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
          return GestureDetector(
            onTap: () => _selectRadius(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 24 : 14,
              height: isSelected ? 24 : 14,
              decoration: BoxDecoration(
                color: isSelected ? const Color.fromARGB(255, 255, 34, 0) : Colors.grey[600],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 1.5,
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