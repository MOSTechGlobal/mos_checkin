import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:s3_storage/s3_storage.dart';

import '../bloc/theme_bloc.dart';
import '../components/calendar_view.dart';
import '../utils/api.dart';
import '../utils/prefs.dart';

class Rosters extends StatefulWidget {
  const Rosters({super.key});

  @override
  State<Rosters> createState() => _RostersState();
}

class _RostersState extends State<Rosters> {
  final shifts = [];
  late int clientId = 1;

  bool _isLoading = false;

  DateTime? _selectedDate;

  Future<void> fetchShifts() async {
    setState(() {
      _isLoading = true;
    });
    // Fetch shifts from the server
    final results = await Api.get('getApprovedShiftsByClientID/$clientId');
    setState(() {
      shifts.clear();
      shifts.addAll(results['data']);
      _isLoading = false;
    });
    log('Shifts: $shifts');
  }

  void _fetchPrefs() async {
    setState(() {
      _isLoading = true;
    });
    final id = await Prefs.getClientID();
    setState(() {
      clientId = id!;
      _isLoading = false;
    });
  }

  Future<String> _getWorkerPfp(workerID, URL) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final bucket = URL.split('/')[0];
      final key = URL.split('/').sublist(1).join('/');

      final url = await s3Storage.presignedGetObject(
        '$bucket',
        '$key',
      );

      return url;
    } catch (e) {
      log('Error getting profile picture: $e');
      return '';
    }
  }

  @override
  void initState() {
    _fetchPrefs();
    fetchShifts();
    setState(() {
      _selectedDate = DateTime.now().toUtc().toLocal();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        final filteredShifts = _selectedDate == null
            ? shifts
            : shifts.where((shift) {
                final shiftDate = DateTime.parse(shift['ShiftStart']).toLocal();
                return shiftDate.year == _selectedDate!.year &&
                    shiftDate.month == _selectedDate!.month &&
                    shiftDate.day == _selectedDate!.day;
              }).toList();
        return Scaffold(
          appBar: AppBar(
            title:
                Text('Rosters', style: TextStyle(color: colorScheme.onPrimary)),
            backgroundColor: colorScheme.primary,
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 16),
                WeeklyCalendarView(
                  colorScheme: colorScheme,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await fetchShifts();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ListView.builder(
                              itemCount: filteredShifts.length,
                              itemBuilder: (context, index) {
                                final shift = filteredShifts[index];
                                return filteredShifts.isEmpty
                                    ? const Center(
                                        child: Text('No shifts found'),
                                      )
                                    : Card(
                                        elevation: 0,
                                        color: colorScheme.secondaryContainer,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: CircleAvatar(
                                                  radius: 50,
                                                  backgroundColor:
                                                      colorScheme.tertiary,
                                                  child:
                                                      shift['WorkerProfilePhoto'] !=
                                                              null
                                                          ? FutureBuilder(
                                                              future: _getWorkerPfp(
                                                                  shift[
                                                                      'SupportWorker1'],
                                                                  shift[
                                                                      'WorkerProfilePhoto']),
                                                              builder: (context,
                                                                  snapshot) {
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .waiting) {
                                                                  return const CircularProgressIndicator(
                                                                      color: Colors
                                                                          .white);
                                                                }
                                                                if (snapshot
                                                                    .hasError) {
                                                                  return const Icon(
                                                                      Icons
                                                                          .error);
                                                                }
                                                                return CircleAvatar(
                                                                  radius: 80,
                                                                  backgroundImage:
                                                                      NetworkImage(snapshot
                                                                          .data
                                                                          .toString()),
                                                                );
                                                              },
                                                            )
                                                          : Text(
                                                              '${shift['WorkerFirstName'][0].toString().toUpperCase()}${shift['WorkerLastName'][0].toString().toUpperCase()}',
                                                              style: TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: colorScheme
                                                                      .onPrimary),
                                                            ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        shift[
                                                            'ServiceDescription'],
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            color: colorScheme
                                                                .tertiary)),
                                                    Text(
                                                        'with ${shift['WorkerFirstName']} ${shift['WorkerLastName']}',
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color: colorScheme
                                                                .primary)),
                                                    Text(
                                                        '${DateFormat('hh:mm aa').format(DateTime.parse(shift['ShiftStart']).toUtc().toLocal())} - ${DateFormat('hh:mm aa').format(DateTime.parse(shift['ShiftEnd']).toUtc().toLocal())}',
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color: colorScheme
                                                                .onSecondaryContainer)),
                                                    Card(
                                                      color: colorScheme
                                                          .tertiaryContainer
                                                          .withOpacity(0.4),
                                                      elevation: 0,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                            _getDateOnly(shift[
                                                                'ShiftStart']),
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                color: colorScheme
                                                                    .onTertiaryContainer)),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                              },
                            ),
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

  String _getDateOnly(String dateTime) {
    final parts = dateTime.split('T');
    return parts[0];
  }
}
