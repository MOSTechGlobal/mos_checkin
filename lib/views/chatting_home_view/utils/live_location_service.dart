import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationService {
  Timer? _timer;
  String? _groupId;
  String? _userId;

  void startSharing(String groupId, String userId, int durationMinutes) {
    _groupId = groupId;
    _userId = userId;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition();
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('live_locations')
            .doc(userId)
            .set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Handle error
      }
    });
    if (durationMinutes > 0) {
      Future.delayed(Duration(minutes: durationMinutes), stopSharing);
    }
  }

  void stopSharing() {
    _timer?.cancel();
    if (_groupId != null && _userId != null) {
      FirebaseFirestore.instance
          .collection('groups')
          .doc(_groupId)
          .collection('live_locations')
          .doc(_userId)
          .delete();
    }
  }
}
