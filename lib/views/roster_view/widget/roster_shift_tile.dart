import 'dart:developer';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class RosterShiftTile extends StatelessWidget {
  final Map<String, dynamic> shiftData;

  const RosterShiftTile({super.key, required this.shiftData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String shiftStart = shiftData['ShiftStart'];
    String shiftEnd = shiftData['ShiftEnd'];
    String shiftStatus = shiftData['ShiftStatus'] ?? 'NULL';
    String service = shiftData['ServiceDescription'];
    String supportWorker =
        '${shiftData['WorkerFirstName'] ?? 'UNALLOCATED'} ${shiftData['WorkerLastName'] ?? ''}';
    String client =
        shiftData['ClientFirstName'] + ' ' + shiftData['ClientLastName'];

    tz.initializeTimeZones();

    // Get the client's time zone
    String clientTimeZone = shiftData['TimeZone'];

    log("Client Timezone: $clientTimeZone");
    tz.Location location = tz.getLocation(clientTimeZone);

    DateTime startTime = tz.TZDateTime.from(DateTime.parse(shiftStart), location);
    DateTime endTime = tz.TZDateTime.from(DateTime.parse(shiftEnd), location);
    int durationHours = endTime.difference(startTime).inHours;
    String duration = "$durationHours Hr";
    if (durationHours == 0) {
      durationHours = endTime.difference(startTime).inMinutes;
      duration = "$durationHours Min";
    }
    String formattedStartTime = DateFormat('hh:mm aa').format(startTime);
    String formattedEndTime = DateFormat('hh:mm aa').format(endTime);

    // Status Colors
    Color statusColor = shiftStatus == 'Not Started'
        ? Colors.red[900]!
        : shiftStatus == 'In Progress'
            ? Colors.amber
            : shiftStatus == 'Completed'
                ? Colors.green
                : Colors.grey;

    return Container(
      width: 348.w,
      // 1. Remove `height: 140.h`
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: colorScheme.onSurface,
          width: 0.5,
        ),
      ),
      // 2. Use a Column with mainAxisSize.min, so it wraps its children
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upper Part
          Container(
            height: 60.h, // 3. Fix the height of the top part
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Status Indicator
                    Container(
                      width: 10.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Description + Assistance in one line
                    SizedBox(
                      width: 240.w,
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: service,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Next Arrow Icon
                // Container(
                //   width: 30.w,
                //   height: 30.h,
                //   decoration: BoxDecoration(
                //     color: colorScheme.primary,
                //     shape: BoxShape.circle,
                //   ),
                //   child: Center(
                //     child: Image.asset(
                //       'assets/icons_lightmode/next_arrow.png',
                //       width: 16.w,
                //       height: 16.h,
                //       fit: BoxFit.contain,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          // 2. Remove the Spacer() so we don't force extra space
          // const Spacer(),

          // Lower Part
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(13.w),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(10.r),
                top: Radius.circular(15.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$formattedStartTime - $formattedEndTime',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          duration,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                // Client Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Client',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        client,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                // Worker Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Worker',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        supportWorker,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
