import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:s3_storage/s3_storage.dart';

import '../../pages/shift_details/shift_details.dart';
import '../../utils/prefs.dart';

class mShiftTile extends StatelessWidget {
  final String date;
  final Map<String, dynamic> shiftsForDate;
  final ColorScheme colorScheme;

  const mShiftTile(
      {super.key,
      required this.date,
      required this.shiftsForDate,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _buildShiftCard(context, shiftsForDate, colorScheme);
  }

  String calculateShiftDuration(String shiftStart, String shiftEnd) {
    final start =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftStart, true);
    var end = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(shiftEnd, true);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final duration = end.difference(start);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0
        ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
        : '$minutes min';
  }

  Future<String> _getWorkerPfp(workerID) async {
    try {
      final s3Storage = S3Storage(
        endPoint: 's3.ap-southeast-2.amazonaws.com',
        accessKey: dotenv.env['S3_ACCESS_KEY']!,
        secretKey: dotenv.env['S3_SECRET_KEY']!,
        region: 'ap-southeast-2',
      );

      final company = await Prefs.getCompanyName();

      final url = await s3Storage.presignedGetObject(
        'moscaresolutions',
        '$company/worker/$workerID/profile_picture/pfp.jpg',
      );

      return url;
    } catch (e) {
      log('Error getting profile picture: $e');
      return '';
    }
  }

  Widget _buildShiftCard(
      context, Map<String, dynamic> shift, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ShiftDetails(shiftData: shift);
        }));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          color: colorScheme.secondaryContainer,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.tertiary,
                      child: shift['WorkerProfilePhoto'] != null
                          ? FutureBuilder(
                              future: _getWorkerPfp(shift['SupportWorker1']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator(
                                      color: Colors.white);
                                }
                                if (snapshot.hasError) {
                                  return const Icon(Icons.error);
                                }
                                return CircleAvatar(
                                  radius: 80,
                                  backgroundImage:
                                      NetworkImage(snapshot.data.toString()),
                                );
                              },
                            )
                          : Text(
                              '${shift['WorkerFirstName'][0].toString().toUpperCase()}${shift['WorkerLastName'][0].toString().toUpperCase()}',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shift['ServiceDescription'],
                            style: TextStyle(
                                fontSize: 18, color: colorScheme.tertiary)),
                        Text(
                            'with ${shift['WorkerFirstName']} ${shift['WorkerLastName']}',
                            style: TextStyle(
                                fontSize: 16, color: colorScheme.primary)),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Card(
                              color:
                                  colorScheme.primaryContainer.withOpacity(0.5),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${DateFormat('hh:mm aa').format(DateTime.parse(shift['ShiftStart']).toUtc().toLocal())} - ${DateFormat('hh:mm aa').format(DateTime.parse(shift['ShiftEnd']).toUtc().toLocal())} (${calculateShiftDuration(shift['ShiftStart'], shift['ShiftEnd'])})',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
