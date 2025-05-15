import 'package:get/get.dart';

import '../auth/auth.dart';
import '../views/account_view/binding/account_binding.dart';
import '../views/account_view/my_account_view.dart';
import '../views/chatting_home_view/add_group_members_view/add_group_members_view.dart';
import '../views/chatting_home_view/add_group_members_view/binding/add_group_members_binding.dart';
import '../views/chatting_home_view/bindings/chatting_home_binding.dart';
import '../views/chatting_home_view/chat_screen_view/binding/chat_screen_binding.dart';
import '../views/chatting_home_view/chat_screen_view/chat_screen_view.dart';
import '../views/chatting_home_view/chatting_home_screen.dart';
import '../views/chatting_home_view/group_chat_view/binding/group_chat_binding.dart';
import '../views/chatting_home_view/group_chat_view/group_chat_view.dart';
import '../views/chatting_home_view/group_profile_view/binding/group_profile_binding.dart';
import '../views/chatting_home_view/group_profile_view/group_profile_view.dart';
import '../views/chatting_home_view/group_user_add_view/binding/group_user_add_binding.dart';
import '../views/chatting_home_view/group_user_add_view/group_user_add_view.dart';
import '../views/chatting_home_view/users_screen_view/binding/users_screen_binding.dart';
import '../views/chatting_home_view/users_screen_view/users_screen_view.dart';
import '../views/chatting_home_view/view_profile_view/binding/view_profile_binding.dart';
import '../views/chatting_home_view/view_profile_view/view_profile_view.dart';
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
  static const String chattingHome = '/chatting_home';
  static const String viewProfileView = '/view_profile_view';
  static const String groupUserAddView = '/group_user_add_view';
  static const String groupChatView = '/group_chat_view';
  static const String groupProfileView = '/group_profile_view';
  static const String addGroupMembersView = '/add_group_members_view';
  static const String chatScreenView = '/chat_screen_view';
  static const String usersScreenView = '/users_screen_view';

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
    GetPage(
        name: chattingHome,
        page: () => const ChattingHomeScreen(),
        binding: ChattingHomeBinding()),
    GetPage(
        name: usersScreenView,
        page: () => const UsersScreenView(),
        binding: UsersScreenBinding()),
    GetPage(
        name: chatScreenView,
        page: () => const ChatScreenView(),
        binding: ChatScreenBinding()),
    GetPage(
        name: viewProfileView,
        page: () => const ViewProfileView(),
        binding: ViewProfileBinding()),
    GetPage(
        name: groupUserAddView,
        page: () => const GroupUserAddView(),
        binding: GroupUserAddBinding()),
    GetPage(
        name: groupChatView,
        page: () => const GroupChatView(),
        binding: GroupChatBinding()),
    GetPage(
        name: groupProfileView,
        page: () => const GroupProfileView(),
        binding: GroupProfileBinding()),
    GetPage(
        name: addGroupMembersView,
        page: () => const AddGroupMembersView(),
        binding: AddGroupMembersBinding()),
  ];
}
