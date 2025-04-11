import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this

class UpgraderService {
  Future<void> checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    String packageName = packageInfo.packageName;

    final newVersion = NewVersionPlus(
      androidId: packageName,
      iOSId: packageName,
    );

    final status = await newVersion.getVersionStatus();
    if (status != null && status.canUpdate) {
      await showDialog(
        context: Get.overlayContext ?? Get.context!,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Update Required'),
            content: const Text(
                'A new version is available. Please update to continue using the app.'),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await newVersion.launchAppStore(
                        packageName);
                  } catch (e) {
                    log('Failed to launch store with new_version_plus: $e');
                    final url = Uri.parse(
                      'market://details?id=$packageName',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      log('Could not launch $url');
                    }
                  }
                  SystemNavigator.pop();
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
