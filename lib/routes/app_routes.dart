import 'package:get/get.dart';

import '../auth/auth.dart';
import '../views/account_view/binding/account_binding.dart';
import '../views/account_view/my_account_view.dart';
import '../views/form_view/binding/form_binding.dart';
import '../views/form_view/binding/form_detail_bonding.dart';
import '../views/form_view/form_view.dart';
import '../views/home_view/binding/home_binding.dart';
import '../views/home_view/binding/weather_binding.dart';
import '../views/home_view/home_view.dart';
import '../views/login_view/binding/login_binding.dart';
import '../views/login_view/login_view.dart';
import '../views/privacy_view/privacy_policy.dart';
import '../views/roster_view/binding/roster_view_binding.dart';
import '../views/roster_view/rosters_view.dart';
import '../views/shifts_view/make_shift_request_view/binding/make_shift_request_binding.dart';
import '../views/shifts_view/make_shift_request_view/make_shift_request_view.dart';
import '../views/shifts_view/shift_request_view/binding/shift_request_view_binding.dart';
import '../views/shifts_view/shift_request_view/shift_requests_view.dart';

class AppRoutes {
  static const String initialRoute = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String shiftRequest = '/shiftRequest';
  static const String roster = '/roster';
  static const String formView = '/form_view';
  static const String makeShiftRequest = '/makeShiftRequest';
  static const String account = '/account';
  static const String privacy = '/privacy';

  static List<GetPage> routes = [
    GetPage(
      name: initialRoute,
      page: () => const AuthPage(),
    ),
    GetPage(
        name: login, page: () => const LoginView(), binding: LoginBinding()),
    GetPage(
        name: home,
        page: () => const HomeView(),
        bindings: [HomeBinding(), WeatherBinding()]),
    GetPage(
        name: shiftRequest,
        page: () => const ShiftRequestsView(),
        binding: ShiftRequestViewBinding()),
    GetPage(
        name: roster,
        page: () => const RostersView(),
        binding: RosterViewBinding()),
    GetPage(
      name: formView,
      page: () => const FormsView(),
      bindings: [FormsBinding(), FormDetailBinding()],
    ),
    GetPage(
      name: account,
      page: () => const MyAccountView(),
      bindings: [AccountBinding()],
    ),
    GetPage(
      name: privacy,
      page: () => const PrivacyPolicyView(),
    ),
    GetPage(
      name: makeShiftRequest,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return MakeShiftRequestView(
          clientId: args['clientId'],
          clientName: args['clientName'],
          // services: args['services'],
        );
      },
      binding: MakeShiftRequestBinding(),
    ),
  ];
}
