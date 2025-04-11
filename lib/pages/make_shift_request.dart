import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/theme_bloc.dart';
import '../components/service_modal.dart';
import '../utils/api.dart';
import '../utils/prefs.dart';

class MakeShiftRequest extends StatefulWidget {
  final String clientId;
  final String clientName;
  final List<Map<String, dynamic>> services;

  const MakeShiftRequest(
      {super.key,
      required this.clientId,
      required this.clientName,
      required this.services});

  @override
  State<MakeShiftRequest> createState() => _MakeShiftRequestState();
}

class _MakeShiftRequestState extends State<MakeShiftRequest> {
  final TextEditingController dateController =
      TextEditingController(); // Start Date Controller
  final TextEditingController endDateController =
      TextEditingController(); // End Date Controller
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController dayController =
      TextEditingController(); // Daily/Monthly day input controller
  final TextEditingController occuranceController =
      TextEditingController(); // Monthly occurrence controller

  final TextEditingController repeatEveryController =
      TextEditingController(); // Repeat every controller
  final TextEditingController mDayController = TextEditingController();

  DateTime? selectedStartDate;
  String? selectedService;
  String? _selectedRecurringShiftType = 'days';

  bool _isRecurringShift = false;
  bool _isDayBasedRecurrence = true; // For Monthly Recurrence

  final Map _selectedWeekDays = {
    'Mo': false,
    'Tu': false,
    'We': false,
    'Th': false,
    'Fr': false,
    'Sa': false,
    'Su': false,
  };

  int? dDay;
  int? wWeek;
  bool? wMO, wTU, wWE, wTH, wFR, wSA, wSU;
  int? mOccurance, mOccDay, mOccMonth;
  int? mDay, mMonth;
  String? type;

  // Dropdown selections
  String _selectedWeekDay = 'Mon'; // Day of week dropdown for Monthly
  String _selectedOccurance = '1st'; // Occurrence dropdown for Monthly

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedStartDate = now;
    dateController.text = DateFormat('dd-MM-yyyy').format(now); // Start Date
    endDateController.text = DateFormat('dd-MM-yyyy').format(now); // End Date
    startTimeController.text = DateFormat('hh:mm aa').format(now);
    endTimeController.text =
        DateFormat('hh:mm aa').format(now.add(const Duration(hours: 1)));

    repeatEveryController.text = '1';
    mDayController.text = '1';
  }

  String formSentence() {
    String sentence = '';

    if (_selectedRecurringShiftType == 'days') {
      sentence =
          'This is a daily shift recurring every ${repeatEveryController.text.isEmpty ? '1' : repeatEveryController.text} day(s).';
    } else if (_selectedRecurringShiftType == 'weeks') {
      List selectedDays = _selectedWeekDays.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      String days = selectedDays.join(', ');
      sentence =
          'This is a weekly shift recurring every ${repeatEveryController.text} week(s) on $days.';
    } else if (_selectedRecurringShiftType == 'months') {
      if (_isDayBasedRecurrence) {
        sentence =
            'This is a monthly shift occurring on the ${mDayController.text} of every ${repeatEveryController.text} month(s).';
      } else {
        sentence =
            'This is a monthly shift on the $_selectedOccurance occurrence of $_selectedWeekDay, every ${repeatEveryController.text} month(s).';
      }
    }

    return sentence;
  }

  void extractData() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final sentence = formSentence();
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          content: Text(
            sentence,
            style: TextStyle(
                color: Theme.of(context).colorScheme.secondary, fontSize: 20),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary)),
            ),
          ],
        );
      },
    );
    // Reset all data to null
    dDay = null;
    wWeek = null;
    wMO = wTU = wWE = wTH = wFR = wSA = wSU = null;
    mOccurance = mOccDay = mOccMonth = mDay = mMonth = null;

    // Extracting weekly data
    if (_selectedRecurringShiftType == 'weeks') {
      wWeek =
          int.tryParse(repeatEveryController.text) ?? 1; // Parse week count
      wMO = _selectedWeekDays['Mo'];
      wTU = _selectedWeekDays['Tu'];
      wWE = _selectedWeekDays['We'];
      wTH = _selectedWeekDays['Th'];
      wFR = _selectedWeekDays['Fr'];
      wSA = _selectedWeekDays['Sa'];
      wSU = _selectedWeekDays['Su'];

      // type is weekly since the user selected weeks
      type = 'Weekly';
    }

    // Extracting monthly data
    if (_selectedRecurringShiftType == 'months') {
      // Check if day or occurrence-based recurrence is selected
      if (_isDayBasedRecurrence) {
        mDay = (int.tryParse(mDayController.text) ?? 1);
        mMonth =
            (int.parse(repeatEveryController.text)); // Convert month to int
      } else {
        mOccurance = _getOccuranceFromString(
            _selectedOccurance); // Convert occurrence to int
        mOccDay = _getDayFromString(_selectedWeekDay); // Convert day to int
        mOccMonth = (int.parse(repeatEveryController.text));
      }

      // type is monthly since the user selected months
      type = 'Monthly';
    }

    // For daily recurrence
    if (_selectedRecurringShiftType == 'days') {
      dDay = int.tryParse(repeatEveryController.text) ?? 1; // Parse day count
      type = 'Daily';
    }

    Map<String, dynamic> intervalData = {
      "dDay": dDay,
      "wWeek": wWeek,
      "wMO": wMO,
      "wTU": wTU,
      "wWE": wWE,
      "wTH": wTH,
      "wFR": wFR,
      "wSA": wSA,
      "wSU": wSU,
      "mOccurance": mOccurance,
      "mOccDay": mOccDay,
      "mOccMonth": mOccMonth,
      "mDay": mDay,
      "mMonth": mMonth,
      "type": type,
    };

    // Submit the request
    await submitRequest(intervalData);
  }

  int _getOccuranceFromString(String occurance) {
    const occuranceMap = {
      '1st': 1,
      '2nd': 2,
      '3rd': 3,
      '4th': 4,
      'Last': 5,
    };
    return occuranceMap[occurance] ?? 1;
  }

  int _getDayFromString(String day) {
    const dayMap = {
      'Mon': 1,
      'Tue': 2,
      'Wed': 3,
      'Thu': 4,
      'Fri': 5,
      'Sat': 6,
      'Sun': 7,
    };
    return dayMap[day] ?? 1;
  }

  // Date Picker with restrictions for end date
  void _showDatePicker(BuildContext context, TextEditingController controller,
      {bool isEndDate = false}) {
    final now = DateTime.now();

    // If selecting the end date, restrict range to 2 days after start date
    final firstDate = isEndDate
        ? (selectedStartDate ??
            now) // Ensure end date is at least 1 day after start date
        : now; // Start date can be from today onwards
    final lastDate = isEndDate
        ? (selectedStartDate ?? now)
            .add(const Duration(days: 2)) // Max 2 days after start date
        : DateTime(2101); // For start date, allow any future date

    showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateFormat('dd-MM-yyyy').parse(controller.text)
          : (isEndDate && selectedStartDate != null)
              ? (selectedStartDate ?? now).add(const Duration(
                  days:
                      1)) // Default initial date for end date is 1 day after start date
              : now,
      firstDate: firstDate,
      lastDate: lastDate,
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          controller.text = DateFormat('dd-MM-yyyy').format(pickedDate);
          if (!isEndDate) {
            // When start date changes, update end date initial range
            selectedStartDate = pickedDate;

            // Optionally update the end date to 1 day after the selected start date if desired
            endDateController.text =
                DateFormat('dd-MM-yyyy').format(pickedDate);
          }
        });
      }
    });
  }

  // Time Picker
  void _showTimePicker(BuildContext context, TextEditingController controller) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((pickedTime) {
      if (pickedTime != null) {
        setState(() {
          final now = DateTime.now();
          final selectedDateTime = DateTime(
              now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
          controller.text = DateFormat('hh:mm aa').format(selectedDateTime);
        });
      }
    });
  }

  void _showServicePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) {
        return ServicesModal(
          allServices: widget.services.toSet(),
          currentServices: {
            if (selectedService != null)
              widget.services.firstWhere((service) =>
                  service['Service_Code'].toString() == selectedService)
          },
          agreementCode: 'agreementCode',
          onAddServices: (selectedServices) {
            setState(() {
              if (selectedServices.isNotEmpty) {
                selectedService = selectedServices.first['Service_Code'];
              }
            });
          },
        );
      },
    );
  }

  Future<void> submitRequest(Map intervalData) async {
    if (selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a service',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onErrorContainer)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }

    String convertDateToMySQLFormat(String date) {
      DateFormat inputFormat = DateFormat('dd-MM-yyyy');
      DateFormat outputFormat = DateFormat('yyyy-MM-dd');
      DateTime parsedDate = inputFormat.parse(date);
      return outputFormat.format(parsedDate);
    }

    String convertTimeToMySQLFormat(String time) {
      DateFormat inputFormat = DateFormat('hh:mm aa');
      DateFormat outputFormat = DateFormat('HH:mm:ss');
      DateTime parsedTime = inputFormat.parse(time);
      return outputFormat.format(parsedTime);
    }

    final user = FirebaseAuth.instance.currentUser;
    final clientID = await Prefs.getClientID();
    final jsonIntervalData = const JsonEncoder().convert(intervalData);
    Map<String, dynamic> data = {
      "ClientID": clientID,
      "ShiftDate": convertDateToMySQLFormat(dateController.text),
      "ShiftEndDate": convertDateToMySQLFormat(endDateController.text),
      "ShiftStart": convertTimeToMySQLFormat(startTimeController.text),
      "ShiftEnd": convertTimeToMySQLFormat(endTimeController.text),
      "RequestDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "RequestBy": user!.email,
      "Status": "P",
      "MakerUser": user.email,
      "ServiceCode": selectedService,
      "IntervalData": jsonIntervalData,
      'RecurrenceSentence': formSentence(),
    };
    final sm = ScaffoldMessenger.of(context);
    // Send data to the backend
    print(data);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      // Send data to the backend
      await Api.post('postShiftRequest', data);
      // Show success message
      sm.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.secondary,
          content: Text('Request submitted successfully',
              style: TextStyle(color: colorScheme.onSecondary)),
        ),
      );
    } catch (e) {
      // Show error message
      sm.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.errorContainer,
          content: Text('Failed to submit request',
              style: TextStyle(color: colorScheme.onErrorContainer)),
        ),
      );
    } finally {
      // Close the modal
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            backgroundColor: colorScheme.primary,
            title: Text('Make Service Request',
                style: TextStyle(color: colorScheme.onPrimary)),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    _widgetBackground(
                      Text(
                        widget.clientName,
                        style: TextStyle(
                          fontSize: 20,
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose start time',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                    _widgetBackground(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () => _showDatePicker(context,
                                dateController), // Start Date Controller
                            child: Card(
                              color: colorScheme.secondary,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  dateController.text,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _showTimePicker(context, startTimeController),
                            child: Card(
                              color: colorScheme.secondary,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  startTimeController.text,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose End time',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                    _widgetBackground(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () => _showDatePicker(
                                context, endDateController,
                                isEndDate: true), // End Date Controller
                            child: Card(
                              color: colorScheme.secondary,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  endDateController.text, // End Date Display
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _showTimePicker(context, endTimeController),
                            child: Card(
                              color: colorScheme.secondary,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  endTimeController.text,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose Service',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                    _widgetBackground(
                      GestureDetector(
                        onTap: () => _showServicePicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  selectedService != null
                                      ? widget.services.firstWhere((service) =>
                                          service['Service_Code'].toString() ==
                                          selectedService)['Description']
                                      : 'Select Service',
                                  style: TextStyle(
                                      color: colorScheme.tertiary,
                                      fontSize: 16),
                                  maxLines: null,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: colorScheme.onSurface),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // switch button to enable recurring shift so that it shows recurring shift options
                    // if recurring shift is enabled, show the recurring shift options
                    // if recurring shift is disabled, hide the recurring shift options
                    Row(
                      children: [
                        Text(
                          'Recurring Shift',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Switch(
                          value: _isRecurringShift,
                          onChanged: (value) {
                            setState(() {
                              _isRecurringShift = value;
                            });
                          },
                          activeColor: colorScheme.secondary,
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                    Divider(
                      color: colorScheme.primary,
                      thickness: 1,
                    ),
                    _isRecurringShift
                        ? Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Repeat Every',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Container(
                                        width: 50,
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: TextField(
                                          controller: TextEditingController()
                                            ..text = repeatEveryController.text,
                                          style: TextStyle(
                                            color: colorScheme.onSecondary,
                                          ),
                                          cursorColor: colorScheme.onSecondary,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            hintText: '1',
                                            hintStyle: TextStyle(
                                              color: colorScheme.onSecondary,
                                              fontSize: 14,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (value) {
                                            // Ensure the input is between 1 and 99
                                            if (int.parse(value) > 99) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Please enter a valid number between 1 and 99',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: colorScheme
                                                              .onSecondary)),
                                                ),
                                              );
                                              setState(() {
                                                repeatEveryController.text =
                                                    '1';
                                              });
                                            } else {
                                              repeatEveryController.text =
                                                  value;
                                            }
                                          },
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButton<String>(
                                          style: TextStyle(
                                            color: colorScheme.onSecondary,
                                          ),
                                          dropdownColor: colorScheme.secondary,
                                          iconSize: 30,
                                          iconEnabledColor:
                                              colorScheme.onSecondary,
                                          value: _selectedRecurringShiftType,
                                          items: <String>[
                                            'days',
                                            'weeks',
                                            'months',
                                          ].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      colorScheme.onSecondary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedRecurringShiftType =
                                                  value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_selectedRecurringShiftType ==
                                      'weeks') ...[
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        for (var day in [
                                          'Mo',
                                          'Tu',
                                          'We',
                                          'Th',
                                          'Fr',
                                          'Sa',
                                          'Su'
                                        ])
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedWeekDays[day] =
                                                    !_selectedWeekDays[day];
                                              });
                                            },
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: _selectedWeekDays[day]
                                                    ? colorScheme.secondary
                                                    : colorScheme.secondary
                                                        .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  day,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: _selectedWeekDays[
                                                            day]
                                                        ? colorScheme
                                                            .onSecondary
                                                        : colorScheme.onSurface
                                                            .withOpacity(0.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  if (_selectedRecurringShiftType ==
                                      'months') ...[
                                    const SizedBox(height: 20),
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Radio(
                                              value: true,
                                              groupValue: _isDayBasedRecurrence,
                                              onChanged: (value) {
                                                setState(() {
                                                  _isDayBasedRecurrence =
                                                      value as bool;
                                                });
                                              },
                                              activeColor:
                                                  colorScheme.secondary,
                                            ),
                                            Text(
                                              'On day',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Container(
                                              width: 50,
                                              decoration: BoxDecoration(
                                                color: _isDayBasedRecurrence
                                                    ? colorScheme.secondary
                                                    : colorScheme.secondary
                                                        .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: TextField(
                                                controller: mDayController,
                                                style: TextStyle(
                                                  color:
                                                      colorScheme.onSecondary,
                                                ),
                                                textAlign: TextAlign.center,
                                                cursorColor:
                                                    colorScheme.onSecondary,
                                                decoration: InputDecoration(
                                                  hintText: '1',
                                                  hintStyle: TextStyle(
                                                    color:
                                                        colorScheme.onSecondary,
                                                    fontSize: 14,
                                                  ),
                                                  border: InputBorder.none,
                                                ),
                                                onChanged: (value) {
                                                  if (int.parse(value) > 31) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Please enter a valid number between 1 and 31',
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: colorScheme
                                                                    .onSecondary)),
                                                      ),
                                                    );
                                                    setState(() {
                                                      mDayController.text = '1';
                                                    });
                                                  }
                                                },
                                                keyboardType:
                                                    TextInputType.number,
                                                enabled: _isDayBasedRecurrence,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Radio(
                                              value: false,
                                              groupValue: _isDayBasedRecurrence,
                                              onChanged: (value) {
                                                setState(() {
                                                  _isDayBasedRecurrence =
                                                      value as bool;
                                                });
                                              },
                                              activeColor:
                                                  colorScheme.secondary,
                                            ),
                                            Text(
                                              'On the',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              decoration: BoxDecoration(
                                                color: !_isDayBasedRecurrence
                                                    ? colorScheme.secondary
                                                    : colorScheme.secondary
                                                        .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: DropdownButton<String>(
                                                style: TextStyle(
                                                  color:
                                                      colorScheme.onSecondary,
                                                ),
                                                dropdownColor:
                                                    colorScheme.secondary,
                                                iconSize: 30,
                                                iconEnabledColor:
                                                    colorScheme.onSecondary,
                                                value: _selectedOccurance,
                                                items: <String>[
                                                  '1st',
                                                  '2nd',
                                                  '3rd',
                                                  '4th',
                                                  'Last'
                                                ].map((String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: colorScheme
                                                            .onSecondary,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: _isDayBasedRecurrence
                                                    ? null
                                                    : (value) {
                                                        setState(() {
                                                          _selectedOccurance =
                                                              value!;
                                                        });
                                                      },
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              decoration: BoxDecoration(
                                                color: !_isDayBasedRecurrence
                                                    ? colorScheme.secondary
                                                    : colorScheme.secondary
                                                        .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: DropdownButton<String>(
                                                style: TextStyle(
                                                  color:
                                                      colorScheme.onSecondary,
                                                ),
                                                dropdownColor:
                                                    colorScheme.secondary,
                                                iconSize: 30,
                                                iconEnabledColor:
                                                    colorScheme.onSecondary,
                                                value: _selectedWeekDay,
                                                items: <String>[
                                                  'Mon',
                                                  'Tue',
                                                  'Wed',
                                                  'Thu',
                                                  'Fri',
                                                  'Sat',
                                                  'Sun'
                                                ].map((String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: colorScheme
                                                            .onSecondary,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: _isDayBasedRecurrence
                                                    ? null
                                                    : (value) {
                                                        setState(() {
                                                          _selectedWeekDay =
                                                              value!;
                                                        });
                                                      },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          )
                        : Container(),

                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          extractData();
                        },
                        child: const Text('Submit',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _widgetBackground(Widget widget) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: widget,
      ),
    );
  }
}
