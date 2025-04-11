import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/routes.dart';

class mDrawer extends StatelessWidget {
  final ColorScheme colorScheme;
  final Function onSignOut;

  const mDrawer(
      {super.key, required this.colorScheme, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!.email;

        final colorScheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.onPrimaryContainer,
                      width: 1,
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'mAbout Me',
                          style: TextStyle(
                            fontSize: 20,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.logout, color: colorScheme.errorContainer),
                          onPressed: () {
                            onSignOut();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    // ListTile(
                    //   leading: Icon(Icons.person, color: colorScheme.secondary),
                    //   title: Text('My Account',
                    //       style: TextStyle(
                    //           fontSize: 16, color: colorScheme.primary)),
                    //   onTap: () {},
                    // ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.request_page, color: colorScheme.secondary),
                title: Text('Shift Requests',
                    style: TextStyle(fontSize: 16, color: colorScheme.secondary)),
                onTap: () {
                  Navigator.push(context, routeToShiftRequestPage());
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.calendar_month, color: colorScheme.secondary),
                title: Text('Rosters',
                    style: TextStyle(fontSize: 16, color: colorScheme.secondary)),
                onTap: () {
                  Navigator.push(context, routeToRostersPage());
                },
              ),
            ],
          ),
        );
  }
}
