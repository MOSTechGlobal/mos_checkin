import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/theme_bloc.dart';
import '../components/drawer.dart';
import '../components/shift_tile/listTile.dart';
import '../utils/api.dart';
import '../utils/prefs.dart';
import '../utils/routes.dart';
import '../weather/weather_widget.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<dynamic> shifts = [];
  late List<Map<String, dynamic>> services = [];
  late dynamic clientData = [];
  late dynamic _client = {};

  final Set<String> _selectedSegment = {'Today'};
  String? errorMessage;
  bool isLoading = true;
  bool isServiceLoading = false;
  late bool showWeather = true;

  late dynamic clientID;

  final _advancedDrawerController = AdvancedDrawerController();

  Future<void> _signOut(colorScheme) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
            content: Text('Are you sure you want to sign out?',
                style: TextStyle(color: colorScheme.primary)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.clear();
                  });
                  // Clear all previous routes and navigate to LoginPage
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false, // Remove all routes
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                ),
                child: Text('Sign Out',
                    style: TextStyle(color: colorScheme.onErrorContainer)),
              ),
            ],
          );
        });
  }

  void _fetchPrefs() async {
    final showW = await Prefs.getShowWeather();
    setState(() {
      showWeather = showW;
    });
  }

  Future<void> _fetchClientShifts() async {
    final user = FirebaseAuth.instance.currentUser!.email;
    try {
      final res = await Api.get('getClientMasterDataByEmail/$user');
      _client = res['data'];
      await Prefs.setClientID(_client['ClientID']);
      final clientShifts =
      await Api.get('getApprovedShiftsByClientID/${_client['ClientID']}');
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        try {
          await Api.post('upsertClientFCMToken', {
            'ClientID': _client['ClientID'],
            'FCMToken': fcmToken,
          });
        } catch (e) {
          log('Error inserting FCM token: $e');
        }
      }
      setState(() {
        shifts = [];
        shifts = clientShifts['data'];
      });
      if (shifts.isEmpty) {
        setState(() {
          errorMessage = 'No shifts found';
        });
      }
    } catch (e) {
      log('Error fetching client shifts: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchClientServices() async {
    setState(() {
      isServiceLoading = true;
    });
    final result =
    await Api.get('getServiceAsPerAgreementWithoutShiftType/${_client['ClientID']}');
    setState(() {
      // convert from List to List<Map<String, dynamic>>
      services = List<Map<String, dynamic>>.from(result['data']);
      isServiceLoading = false;
    });
  }

  @override
  void initState() {
    _fetchClientShifts();
    _fetchPrefs();
    super.initState();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _handleMenuButtonPressed() {
    // NOTICE: Manage Advanced Drawer state through the Controller.
    // _advancedDrawerController.value = AdvancedDrawerValue.visible();
    _advancedDrawerController.showDrawer();
  }

  void _handleRequestShift(colorScheme, BuildContext context) async {
    await _fetchClientServices();
    // navigate to request shift page
    Navigator.push(
        context,
        routeToMakeShiftRequestPage(
          _client['ClientID'].toString(),
          '${_client['FirstName']} ${_client["LastName"]}',
          services,
        ));
  }

  DateTime parseDateString(String dateString) {
    final formats = [
      "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      "yyyy-MM-dd'T'HH:mm:ss'Z'",
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss",
      "yyyy-MM-dd",
      // Add more formats if needed
    ];

    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateString, true);
      } catch (e) {
        // Ignore and try the next format
      }
    }
    throw FormatException('Cannot parse date string: $dateString');
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc().toLocal();

    final todayShifts = shifts.where((shift) {
      final shiftStart = parseDateString(shift['ShiftStart']);
      return isSameDay(shiftStart, today);
    }).toList();

    final fortnightShifts = shifts.where((shift) {
      final shiftStart = parseDateString(shift['ShiftStart']);
      return !isSameDay(shiftStart, today) &&
          shiftStart.isAfter(today) &&
          shiftStart.isBefore(today.add(const Duration(days: 14)));
    }).toList();

    final groupedFortnightShifts = groupBy(fortnightShifts, (shift) {
      final shiftStart = parseDateString(shift['ShiftStart']);
      return DateFormat('yyyy-MM-dd').format(shiftStart);
    });

    final sortedFortnightDates = groupedFortnightShifts.keys.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a);
        final dateB = DateTime.parse(b);
        return dateA.compareTo(dateB);
      });

    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme
            .of(context)
            .colorScheme;
        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: colorScheme.primary,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: ImageIcon(
              const AssetImage('assets/images/logo.png'),
              color: colorScheme.primary,
              size: 40,
            ),
            centerTitle: true,
          ),
          drawer: Drawer(
            child: mDrawer(
              colorScheme: colorScheme,
              onSignOut: () => _signOut(colorScheme),
            ),
          ),
          floatingActionButton: isLoading || isServiceLoading
              ? isLoading
              ? null
              : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.tertiary.withOpacity(0.7)),
          )
              : SizedBox(
            width: 150,
            child: FloatingActionButton(
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              onPressed: () {
                _handleRequestShift(colorScheme, context);
              },
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 5),
                    Text('Request Shift'),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                WeatherWidget(
                  city: 'Sydney',
                  userName: _client['FirstName'] ?? 'Client',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedSegment.contains('Today')
                            ? DateFormat('EE d MMMM').format(DateTime.now())
                            : 'Fortnight\'s Shifts',
                        style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.secondary.withOpacity(0.7)),
                      ),
                      SegmentedButton(
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          padding:
                          WidgetStateProperty.resolveWith<EdgeInsets>(
                                (Set<WidgetState> states) {
                              if (states.contains(WidgetState.hovered)) {
                                return const EdgeInsets.all(10);
                              }
                              return const EdgeInsets.all(10);
                            },
                          ),
                          enableFeedback: true,
                          foregroundColor:
                          WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                              if (states.contains(WidgetState.disabled)) {
                                return colorScheme.secondary;
                              }
                              return colorScheme.secondary;
                            },
                          ),
                          animationDuration:
                          const Duration(milliseconds: 300),
                        ),
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: 'Today',
                              label: Text('Today',
                                  style: TextStyle(fontSize: 13))),
                          ButtonSegment(
                              value: 'Fortnight',
                              label: Text('Fortnight',
                                  style: TextStyle(fontSize: 13))),
                        ],
                        selected: _selectedSegment,
                        onSelectionChanged: (Set<String> newSelection) {
                          if (newSelection.contains('Today')) {
                            setState(() {
                              errorMessage = null;
                              isLoading = true;
                              _selectedSegment.clear();
                              _selectedSegment.add('Today');
                            });
                          } else {
                            setState(() {
                              _selectedSegment.clear();
                              _selectedSegment.add('Fortnight');
                              errorMessage = null;
                            });
                          }
                          _fetchClientShifts();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: isLoading
                      ? const Center(
                    child: SizedBox(
                      width: 150,
                      child: LinearProgressIndicator(),
                    ),
                  )
                      : errorMessage != null
                      ? Center(
                      child: Text(errorMessage!,
                          style:
                          TextStyle(color: colorScheme.primary)))
                      : RefreshIndicator(
                    onRefresh: _fetchClientShifts,
                    child: ListView.builder(
                      itemCount: _selectedSegment.contains('Today')
                          ? todayShifts.length
                          : sortedFortnightDates.length,
                      itemBuilder: (context, index) {
                        if (_selectedSegment.contains('Today')) {
                          if (todayShifts.isEmpty) {
                            return Center(
                              child: Text('No shifts found',
                                  style: TextStyle(
                                      color: colorScheme.primary)),
                            );
                          } else {
                            final shift = todayShifts[index];
                            log('Shift: $shift');
                            return mShiftTile(
                              key: ValueKey(shift['ShiftID']),
                              date: DateFormat('yyyy-MM-dd').format(
                                  DateTime.parse(
                                      shift['ShiftStart'])),
                              shiftsForDate: shift,
                              colorScheme: colorScheme,
                            );
                          }
                        } else {
                          final date = sortedFortnightDates[index];
                          return Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18),
                                child: Text(
                                  DateFormat('EE d MMMM')
                                      .format(DateTime.parse(date)),
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.secondary),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                itemCount:
                                groupedFortnightShifts[date]!
                                    .length,
                                itemBuilder: (context, shiftIndex) {
                                  if (fortnightShifts.isEmpty) {
                                    return Center(
                                      child: Text(
                                          'No shifts found for this fortnight',
                                          style: TextStyle(
                                              color: colorScheme
                                                  .primary)),
                                    );
                                  } else {
                                    final shift =
                                    groupedFortnightShifts[
                                    date]![shiftIndex];
                                    return mShiftTile(
                                      key: ValueKey(
                                          shift['ShiftID']),
                                      date: date,
                                      shiftsForDate: shift,
                                      colorScheme: colorScheme,
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Route _routeToLoginPage() {
    return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOut;

          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: curve)),
            child: child,
          );
        });
  }
}
