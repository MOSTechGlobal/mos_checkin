import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      // Handle error
    }
  }

  void _shareStaticLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {'type': 'static', 'location': _selectedLocation});
    }
  }

  void _shareLiveLocation(int? duration) {
    if (_selectedLocation != null) {
      Navigator.pop(context, {'type': 'live', 'location': _selectedLocation, 'duration': duration});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _controller = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 15,
            ),
            onTap: (latLng) {
              setState(() {
                _selectedLocation = latLng;
              });
            },
            markers: _selectedLocation != null
                ? {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation!,
              ),
            }
                : {},
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _shareStaticLocation,
                  child: const Text('Share This Location'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _shareLiveLocation(60),
                  child: const Text('Share Live for 1 Hour'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _shareLiveLocation(180),
                  child: const Text('Share Live for 3 Hours'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _shareLiveLocation(null),
                  child: const Text('Share Live Until Stopped'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}