import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/common_widgets/common_app_bar.dart';
import '../../utils/common_widgets/common_button.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  void _openPrivacyPolicyLink() async {
    final url = Uri.parse('https://mostech.solutions/privacy-policy/');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        log('Could not launch the privacy policy page.');
      }
    } catch (e) {
      log('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          CommonAppBar(
            title: 'Privacy Policy',
            iconPath: 'assets/icons/forms.png',
            colorScheme: colorScheme,
          ),
          SizedBox(height: 4.h),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.9),
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                children: [
                  _buildSection(
                    context,
                    'Privacy Policy',
                    '''Mostech Solutions ("us," "we," or "our") operates the website www.mostech.solutions (the "Website") and the mobile applications MosHustle, MosBoss, and MosCheckIn (collectively referred to as the "Services").

This Privacy Policy explains our policies regarding the collection, use, and disclosure of personal data when you use our Services and the choices you have associated with that data. By using the Services, you agree to the collection and use of information in accordance with this Privacy Policy.

Unless otherwise defined in this Privacy Policy, the terms used here have the same meanings as in our Terms and Conditions, accessible from www.mostech.solutions.''',
                  ),
                  _buildSection(
                    context,
                    'Information Collection and Use',
                    '''We collect several types of information to provide, improve, and personalize our Services, including the MosHustle, MosBoss, and MosCheckIn mobile applications, as well as the www.mostech.solutions website (collectively referred to as "the Services").''',
                  ),
                  _buildSection(
                    context,
                    'Types of Data Collected',
                    '''1. Personal Data

While using the Services, we may ask you to provide certain personally identifiable information that can be used to contact or identify you. Personal data collected may include but is not limited to:

- Name (first and last name)
- Email address
- Phone number
- Profile information

2. Usage Data

We may collect information about how the Services are accessed and used. This may include:

- Your device's Internet Protocol (IP) address.
- Browser type and version
- Device type and operating system
- Pages or features you visit within the Services
- Timestamps (e.g., date and time of access, time spent on pages)
- Unique device identifiers and other diagnostic data

3. Tracking & Cookies Data

We use cookies and similar tracking technologies to enhance user experience and analyze Service usage. These technologies may collect information such as:

- Session Cookies: To manage your session while using the Services.
- Preference Cookies: To remember your preferences (e.g., language or display settings).
- Security Cookies: To enhance the security of the Services.

You can manage or refuse cookies through your browser settings. However, disabling cookies may limit your ability to use some features of the Services.

4. Location Data

4.1 Prominent Disclosure
MosHustle collects location data to enable accurate shift tracking for workers, ensuring seamless monitoring of shift activities even when the app is closed or not in use. This data is essential for maintaining operational efficiency, providing real-time updates to employers, and ensuring the full functionality of MosHustle.

MosBoss collects location data to enable shift creation and ensure user safety in emergency situations, even when the app is closed or running in the background. This data is essential for facilitating smooth shift management, providing timely support during emergencies, and ensuring the full functionality of MosBoss.

For example:

MosHustle: Collects location data to enable accurate shift tracking for workers, even when the app is closed or in the background.
MosBoss: Collects location data to enable shift creation and ensure user safety in emergency situations, even when the app is closed or in the background.
By granting background location access, you acknowledge that your device's location information will be collected and used as described in this Privacy Policy.

4.2 Types of Location Data

Precise Location Data: Obtained through GPS or other location technologies.
Background Location Data: Collected continuously (only with your explicit permission) to ensure the proper functioning of the Services (e.g., tracking shifts, responding to emergencies).

5. Mobile Device Access

For all mobile applications, we may request permission to access:

- Camera: For uploading profile photos or documents (e.g., MosCheckIn, MosHustle, MosBoss).
- Storage: For saving or retrieving files and documents.
- Push Notifications: To send you reminders, updates, or important alerts.

If you wish to change these permissions, you can do so in your device's settings.''',
                  ),
                  _buildSection(
                    context,
                    'Use of Data',
                    '''Mostech Solutions uses the data collected through its Services (including the MosHustle, MosBoss, and MosCheckIn applications, and the www.mostech.solutions website) for the following purposes:

a. To provide and maintain the Services: Ensuring the core functionality and accessibility of our mobile applications and website.
b. To improve and personalize user experience: Tailoring the Services based on user preferences and behavior.
c. To notify you about updates or changes: Sending notifications regarding new features, policies, or modifications to the Services.
d. To allow participation in interactive features: Enabling functionalities such as shift tracking (MosHustle), shift creation (MosBoss), or shift request (MosCheckIn).
e. To provide customer care and support: Responding to inquiries, resolving technical issues, and addressing user concerns.
f. To analyze and improve the Services: Monitoring usage patterns to enhance performance, functionality, and usability.
g. To ensure security and fraud prevention: Detecting, preventing, and addressing fraudulent or unauthorized activities.
h. To comply with legal obligations: Retaining data or sharing information as required by applicable laws and regulations.''',
                  ),
                  _buildSection(
                    context,
                    'Transfer of Data',
                    '''Global Data Transfers
Your information, including personal data, may be transferred to and stored on servers located outside your state, province, country, or other governmental jurisdiction where data protection laws may differ from those in your jurisdiction.

For users located outside Australia, your information will be transferred to and processed in Australia, where our primary servers are located. By using the Services, you consent to this transfer, storage, and processing.

Steps to Ensure Security
We take the following steps to safeguard your data during transfer:

a. Data Encryption: Ensuring data is encrypted in transit and at rest using industry-standard encryption protocols.
b. Contractual Safeguards: Using contractual agreements, such as Standard Contractual Clauses, to ensure data is handled securely and in compliance with applicable laws.
c. Access Control: Restricting access to personal data to authorized personnel only.

We will take all steps reasonably necessary to ensure that your data is treated securely and in accordance with this Privacy Policy. No transfer of personal data will occur to an organization or country unless adequate controls are in place, including the security of your data and other personal information.''',
                  ),
                  _buildSection(
                    context,
                    'Legal Requirements',
                    '''Mostech Solutions may disclose your personal data in good faith if such action is necessary to:

a. Comply with a legal obligation or respond to lawful requests by public authorities, including court orders or subpoenas.
b. Protect and defend the rights or property of Mostech Solutions, including enforcing agreements and policies.
c. Prevent or investigate possible wrongdoing related to the Services.
d. Protect the personal safety of users of the Services or the public.
e. Protect against legal liability or fraud.''',
                  ),
                  _buildSection(
                    context,
                    'When and with whom do we share your personal information?',
                    '''We may share your personal information in specific situations described below and with the following third parties:

1. Service Providers
We may engage third-party companies and individuals to perform services on our behalf, such as:

Hosting and server maintenance.
Data analytics and usage monitoring.
Customer support.
These service providers have access to your personal data only to perform their specific tasks and are obligated to maintain confidentiality and security.

2. Google Maps Platform APIs
For apps like MosHustle and MosBoss, we may use Google Maps APIs to provide geolocation-based services. Google Maps collects GPS, Wi-Fi, and cell tower data to estimate your location. While GPS is accurate within approximately 20 meters, Wi-Fi and cell tower data improve accuracy when GPS signals are weak (e.g., indoors).

Your location data may cached locally on your device.
You can revoke location permissions via your device settings.

3. Compliance with Laws
We may share personal data to comply with legal obligations or respond to lawful government requests.''',
                  ),
                  _buildSection(
                    context,
                    'Security of Data',
                    '''We prioritize the security of your personal data and implement commercially acceptable practices to protect it. These measures include:

a. Data encryption (both in transit and at rest).
b. Regular security audits and monitoring.
c. Access controls to ensure only authorized personnel can access sensitive data.

However, no method of transmission over the Internet or electronic storage is 100% secure. While we strive to protect your data, we cannot guarantee its absolute security.''',
                  ),
                  _buildSection(
                    context,
                    'Links to Other Sites',
                    '''Our Services may include links to external websites not operated by Mostech Solutions. When you click on these links, you will leave our platform. We encourage you to review the privacy policies of these third-party sites, as we have no control over their content, data collection practices, or security measures.''',
                  ),
                  _buildSection(
                    context,
                    'Children\'s Privacy',
                    '''Our Services are not intended for individuals under the age of 18, and we do not knowingly collect personal data from children.

If we discover that a child under 18 has provided personal data, we will delete it immediately.
Parents or guardians who believe their child has provided us with personal data can contact us at info@mostech.solutions to request deletion.''',
                  ),
                  _buildSection(
                    context,
                    'Changes To This Privacy Policy',
                    '''We may update this Privacy Policy from time to time to reflect changes in legal, regulatory, or operational requirements.

Updates will be posted on our website at www.mostech.solutions and within the mobile applications.
Continued use of the Services after changes are made constitutes acceptance of the revised Privacy Policy.
We encourage you to review this Privacy Policy periodically to stay informed about how we are protecting the information we collect.''',
                  ),
                  _buildSection(
                    context,
                    'Data Retention Policy',
                    '''a. Retention: We retain personal data as long as it is necessary to fulfill the purposes outlined in this Privacy Policy, comply with legal obligations, or resolve disputes.
b. Deletion: You can request the deletion of your data by contacting us at info@mostech.solutions. We will respond to such requests within a reasonable timeframe.''',
                  ),
                  _buildSection(
                    context,
                    'Opt-Out Rights',
                    '''You can stop data collection by:

a. Uninstalling the App: Use the standard uninstall process available on your device or the app marketplace.
b. Revoking Permissions: Adjust app permissions via your device's settings (e.g., location, notifications).''',
                  ),
                  _buildSection(
                    context,
                    'Contact Us',
                    '''If you have any questions or concerns about this Privacy Policy or how we handle your personal data, please contact us:

Email: info@mostech.solutions
Phone: +61 414189500
Website: www.mostech.solutions''',
                  ),
                  _buildSection(
                    context,
                    'Effective Date',
                    '''This Privacy Policy is effective as of 2025-01-07.''',
                  ),
                  _buildActionButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return CommonButton(
        text: 'Read Full Policy Online', onPressed: _openPrivacyPolicyLink);
  }
}
