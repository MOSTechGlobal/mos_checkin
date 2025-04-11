import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../bloc/theme_bloc.dart';
import '../../../utils/api.dart';
import '../../../utils/util_func.dart';

class ShiftDetails extends StatefulWidget {
  final Map shiftData;

  const ShiftDetails({super.key, required this.shiftData});

  @override
  State<ShiftDetails> createState() => _ShiftDetailsState();
}

class _ShiftDetailsState extends State<ShiftDetails> {
  final workerDetails = {};

  @override
  initState() {
    super.initState();
    getWorkerDetails();
  }

  Future<void> getWorkerDetails() async {
    // there are supportWorker1 2,3,4 in the shiftData
    // we need to get the details of each worker if they exist
    for (var i = 1; i < 5; i++) {
      if (widget.shiftData['SupportWorker$i'] != null &&
          widget.shiftData['SupportWorker$i'] != '') {
        final workerId = widget.shiftData['SupportWorker$i'];
        final workerData = await getWorkerData(workerId);
        setState(() {
          workerDetails['SupportWorker$i'] = workerData['data'][0];
        });
        log('workerDetails: $workerDetails');
      }
    }
  }

  Future<Map> getWorkerData(String workerId) async {
    final result = await Api.get('getWorkerDataForVAM/$workerId');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text('Shift Details',
                style: TextStyle(fontSize: 20, color: colorScheme.onPrimary)),
            backgroundColor: colorScheme.primary,
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  '#${widget.shiftData['ShiftID']}',
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Worker(s) for the shift:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // show dropdown for each worker
                  for (var i = 1; i <= workerDetails.length; i++)
                    if (workerDetails['SupportWorker$i'] != null)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: 1,
                        child: _buildWorkerCard(
                            workerDetails['SupportWorker$i'], colorScheme),
                      ),

                  // show shift details
                  const SizedBox(height: 20),
                  Text(
                    'Shift Details:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildShiftCard(widget.shiftData, colorScheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkerCard(workerDetails, colorScheme) {
    return ExpansionTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      collapsedBackgroundColor: colorScheme.secondaryContainer.withOpacity(0.5),
      backgroundColor: colorScheme.secondaryContainer,
      enableFeedback: true,
      iconColor: colorScheme.primary,
      title: Text(
        '${workerDetails['FirstName']} ${workerDetails['LastName']}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.badge, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Worker ID: ',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${workerDetails['WorkerID']}',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Gender: ',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${workerDetails['Gender'] ?? 'N/A'}',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.cake, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'DOB: ',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  workerDetails['DOB'] != null
                      ? Text(
                          '${DateFormat('dd/MM/yyyy').format(DateTime.parse(workerDetails['DOB']))} (${workerDetails['Age'] ?? ''})',
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          'N/A',
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.phone, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Worker Num.: ',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${workerDetails['WorkerNumber'] ?? 'N/A'}',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.code, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'CarerCode: ',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    workerDetails['CarerCode'] ?? 'N/A',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.supervisor_account,
                          color: colorScheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        'TL: ',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        workerDetails['CaseManager'] ?? 'N/A',
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.supervisor_account,
                          color: colorScheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        'RM: ',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        workerDetails['CaseManager2'] ?? 'N/A',
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // address
              Row(
                children: [
                  Icon(Icons.home, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Address: ',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${workerDetails['AddressLine1'] ?? ''}, ${workerDetails['AddressLine2'] ?? ''}, ${workerDetails['Suburb'] ?? ''}, ${workerDetails['Postcode'] ?? ''}',
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // interests
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.favorite, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Interests: ',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${workerDetails['Interests'] ?? ''}',
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // is Pet Friendly
              const SizedBox(height: 10),
              workerDetails['PetFriendly'] == null
                  ? Container()
                  : Row(
                      children: [
                        Icon(Icons.pets, color: colorScheme.primary),
                        const SizedBox(width: 5),
                        Text(
                          'Pet Friendly: ',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          workerDetails['PetFriendly'] == 1
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: workerDetails['PetFriendly'] == 1
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
              // skills
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.build, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Skills: ',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${workerDetails['Skills'] ?? ''}',
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftCard(shiftData, colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Text(
          '${shiftData['ServiceDescription'] ?? 'N/A'}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          color: colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 5),
                    Text(
                      'Shift Date: ',
                      style:
                          TextStyle(color: colorScheme.onSurface, fontSize: 16),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy')
                          .format(DateTime.parse(shiftData['ShiftStart'])),
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'Start Time',
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 14),
                        ),
                        Text(
                          DateFormat('hh:mm aa').format(
                              DateTime.parse(shiftData['ShiftStart'])
                                  .toUtc()
                                  .toLocal()),
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'End Time',
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 14),
                        ),
                        Text(
                          DateFormat('hh:mm aa').format(
                              DateTime.parse(shiftData['ShiftEnd'])
                                  .toUtc()
                                  .toLocal()),
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'Duration',
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 14),
                        ),
                        Text(
                          calculateShiftDuration(
                              shiftData['ShiftStart'], shiftData['ShiftEnd']),
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'Break',
                          style: TextStyle(
                              color: colorScheme.onSurface, fontSize: 14),
                        ),
                        Text(
                          '${shiftData['BreakDuration'] ?? 0} min',
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Shift Status: ${shiftData['ShiftStatus'] ?? 'N/A'}',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
