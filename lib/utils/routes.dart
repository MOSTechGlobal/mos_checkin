import 'package:flutter/material.dart';

import '../pages/rosters.dart';
import '../pages/shift_requests.dart';
import '../views/shifts_view/make_shift_request_view/make_shift_request_view.dart';

Route routeToShiftRequestPage() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const ShiftRequests(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

Route routeToMakeShiftRequestPage(
    String clientId, String clientName, List<Map<String, dynamic>> services) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        MakeShiftRequestView(
      clientId: clientId,
      clientName: clientName, /*services: services*/
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

Route routeToRostersPage() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const Rosters(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      animation.drive(tween);
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
