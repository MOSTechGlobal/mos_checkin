import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/theme_bloc.dart';
import '../utils/api.dart';
import '../utils/prefs.dart';

class ShiftRequests extends StatefulWidget {
  const ShiftRequests({super.key});

  @override
  State<ShiftRequests> createState() => _ShiftRequestsState();
}

class _ShiftRequestsState extends State<ShiftRequests> {
  DateTime _selectedDateFrom = DateTime.now().subtract(const Duration(days: 7));
  DateTime _selectedDateTo = DateTime.now().add(const Duration(days: 7));

  bool _isLoading = false;

  late List _shiftRequests = [];
  List _filteredShiftRequests = [];

  final clientId = '';

  @override
  initState() {
    super.initState();
    _fetchClientShiftRequests();
  }

  String? _getFormattedDateRange() {
    final formatter = DateFormat('dd MMM yyyy'); // Format: DD Month YYYY
    return '${formatter.format(_selectedDateFrom)} - ${formatter.format(_selectedDateTo)}';
  }

  Future<void> _fetchClientShiftRequests() async {
    final clientId = await Prefs.getClientID();
    setState(() {
      _isLoading = true;
    });
    if (!mounted) return;
    try {
      final response = await Api.get('getShiftRequestByClientId/$clientId');
      setState(() {
        _shiftRequests = response['data'];
      });
      log('Shift requests: $_shiftRequests');
    } catch (e) {
      log('Error fetching shift requests: $e');
    } finally {
      if (mounted) {
        _filterNotesByDate();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterNotesByDate() {
    setState(() {
      _filteredShiftRequests = _shiftRequests.where((note) {
        final createdOnString = note['RequestDate'] as String?;
        if (createdOnString == null) {
          return false;
        }

        final createdOn = DateTime.tryParse(createdOnString);
        if (createdOn == null) {
          log('Error parsing date: $createdOnString'); // Log invalid dates for debugging
          return false; // Exclude notes with invalid date formats
        }

        return (createdOn.isAfter(_selectedDateFrom) ||
                createdOn.isAtSameMomentAs(_selectedDateFrom)) &&
            createdOn.isBefore(_selectedDateTo.add(const Duration(days: 1)));
      }).toList();
    });
  }

  Future<void> _cancelShiftRequest(shiftRequest) async {
    // take a reason for cancelling the shift request
    String reason = '';

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text('Cancel Shift Request',
              style: TextStyle(color: colorScheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a reason for cancelling the shift request',
                  style: TextStyle(color: colorScheme.primary)),
              const SizedBox(height: 8),
              TextField(
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                decoration: const InputDecoration(
                  hintText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  reason = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.secondary)),
            ),
            TextButton(
              onPressed: () async {
                // if the reason is not empty, proceed to cancel the shift request
                if (reason.isNotEmpty) {
                  final Map<String, dynamic> data = {
                    'Status': 'C',
                    'StatusReason': 'cancelled by client: $reason',
                    'UpdateUser': FirebaseAuth.instance.currentUser?.email,
                  };
                  try {
                    final id = shiftRequest['ID'];
                    final response =
                        await Api.put('updateShiftRequestStatus/$id', data);
                    if (response['success']) {
                      log('Shift request cancelled successfully');
                      _fetchClientShiftRequests();
                    } else {
                      log('Error cancelling shift request: ${response['message']}');
                    }
                  } catch (e) {
                    log('Error cancelling shift request: $e');
                  }
                }
                Navigator.pop(context);
              },
              child: Text('OK', style: TextStyle(color: colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: colorScheme.primary,
            title: Text('Shift Requests',
                style: TextStyle(color: colorScheme.onPrimary)),
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _showDatePickerModal(context),
                        // _showDateRangePicker,
                        child: Card(
                          color: colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              _getFormattedDateRange() ?? 'Select Date Range',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Display a loading spinner while fetching data
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchClientShiftRequests,
                    child: ListView.builder(
                      itemCount: _filteredShiftRequests.length,
                      itemBuilder: (context, index) {
                        final shiftRequest = _filteredShiftRequests[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Card(
                              color: colorScheme.secondaryContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            shiftRequest[
                                                'ServiceDescription'],
                                            style: TextStyle(
                                              color: colorScheme.tertiary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            _deleteShiftRequestDialog(
                                                shiftRequest);
                                          },
                                          child: Icon(
                                            Icons.cancel_presentation,
                                            color: colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                    shiftRequest['RecurrenceSentence'] != null
                                        ? Column(
                                            children: [
                                              const SizedBox(height: 8),
                                              Text(
                                                shiftRequest[
                                                    'RecurrenceSentence'],
                                                style: TextStyle(
                                                  color: colorScheme.tertiary,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          )
                                        : Text(
                                            DateFormat('dd MMM yyyy').format(
                                              DateTime.tryParse(shiftRequest[
                                                          'ShiftDate'])
                                                      ?.toLocal() ??
                                                  DateTime.now(),
                                            ),
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontSize: 16,
                                            ),
                                          ),
                                    Row(
                                      children: [
                                        Text(
                                          DateFormat('hh:mm a').format(
                                            DateFormat('HH:mm:ss').parse(
                                              shiftRequest['ShiftStart']
                                                  .toString(),
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(' - ',
                                            style: TextStyle(
                                                color: colorScheme.primary)),
                                        Text(
                                          DateFormat('hh:mm a').format(
                                            DateFormat('HH:mm:ss').parse(
                                              shiftRequest['ShiftEnd']
                                                  .toString(),
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: shiftRequest['Status'] == 'P'
                                              ? colorScheme.secondary
                                              : shiftRequest['Status'] == 'A'
                                                  ? colorScheme.primary
                                                  : colorScheme.error,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'Status: ',
                                                          style: TextStyle(
                                                            color: colorScheme
                                                                .inversePrimary,
                                                            fontSize: 16,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          shiftRequest['Status'] == 'P' ? 'Pending' : shiftRequest['Status'] == 'A' ? 'Approved' : shiftRequest['Status'] == 'R' ? 'Rejected' : 'Cancelled',
                                                          style: TextStyle(
                                                            color: colorScheme
                                                                .onPrimary,
                                                            fontSize: 16,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'Requested On: ',
                                                          style: TextStyle(
                                                            color: colorScheme
                                                                .inversePrimary,
                                                            fontSize: 16,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          DateFormat('dd MMM yyyy').format(
                                                            DateTime.tryParse(
                                                                shiftRequest[
                                                                'RequestDate']) ??
                                                                DateTime.now(),
                                                          ),
                                                          style: TextStyle(
                                                            color: colorScheme
                                                                .onPrimary,
                                                            fontSize: 16,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (shiftRequest['Status'] == 'C' || shiftRequest['Status'] == 'R')
                                                      Text(
                                                        "${shiftRequest['StatusReason'] ?? 'N/A'}",
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .onError,
                                                          fontSize: 16,
                                                          fontWeight:
                                                          FontWeight
                                                              .bold,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDatePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, innerSetState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDatePicker(context, _selectedDateFrom, (date) {
                          innerSetState(() {
                            _selectedDateFrom = date;
                          });
                          // Update the main widget state to reflect date changes
                          setState(() {});
                        }, 'From'),
                        _buildDatePicker(context, _selectedDateTo, (date) {
                          innerSetState(() {
                            _selectedDateTo = date;
                          });
                          // Update the main widget state to reflect date changes
                          setState(() {});
                        }, 'To'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        _filterNotesByDate();
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            colorScheme.secondaryContainer),
                      ),
                      child: Text('Search',
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    DateTime initialDate,
    Function(DateTime) onDateChanged,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: initialDate,
            onDateTimeChanged: onDateChanged,
            minimumDate: DateTime(2020),
            maximumDate: DateTime.now().add(const Duration(days: 365)),
          ),
        ),
      ],
    );
  }

  void _deleteShiftRequestDialog(shiftRequest) {
    if (shiftRequest['Status'] == 'A') {
      showDialog(
        context: context,
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: Text('Approved Shift Request',
                style: TextStyle(color: colorScheme.primary)),
            content: Text(
                'You cannot cancel an approved shift request. Please contact your manager for assistance.',
                style: TextStyle(color: colorScheme.primary)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK', style: TextStyle(color: colorScheme.primary)),
              ),
            ],
          );
        },
      );
    } else if (shiftRequest['Status'] == 'R') {
      showDialog(
        context: context,
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: Text('Rejected Shift Request',
                style: TextStyle(color: colorScheme.primary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'You cannot cancel a rejected shift request. Please contact your manager for assistance.',
                    style: TextStyle(color: colorScheme.primary)),
                const SizedBox(height: 8),
                Text('Reason: ${shiftRequest['StatusReason'] ?? 'N/A'}',
                    style: TextStyle(color: colorScheme.error)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK', style: TextStyle(color: colorScheme.primary)),
              ),
            ],
          );
        },
      );
    } else if (shiftRequest['Status'] == 'P') {
      if (shiftRequest['RequestDate'] != null) {
        final requestDate = DateFormat('yyyy-MM-dd').parse(
          shiftRequest['RequestDate'],
        );
        final now = DateTime.now();
        final difference = now.difference(requestDate).inDays;
        if (difference > 7) {
          showDialog(
            context: context,
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return AlertDialog(
                title: Text('Cancel Shift Request',
                    style: TextStyle(color: colorScheme.primary)),
                content: Text(
                    'You cannot cancel a shift request that was requested more than 7 day ago. Please contact your manager for assistance.',
                    style: TextStyle(color: colorScheme.primary)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK',
                        style: TextStyle(color: colorScheme.primary)),
                  ),
                ],
              );
            },
          );
        } else {
          showDialog(
            context: context,
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return AlertDialog(
                title: Text('Cancel Shift Request',
                    style: TextStyle(color: colorScheme.primary)),
                content: Text(
                    'Are you sure you want to cancel this shift request?',
                    style: TextStyle(color: colorScheme.primary)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('No',
                        style: TextStyle(color: colorScheme.secondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _cancelShiftRequest(shiftRequest);
                    },
                    child:
                        Text('Yes', style: TextStyle(color: colorScheme.error)),
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }
}
