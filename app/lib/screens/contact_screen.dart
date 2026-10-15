import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const String email = 'indihnid@gmail.com';
  static const String phone = '+919368139028';
  static const String displayPhone = '9368139028';

  Future<void> _openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'ToolForge Feedback & Inquiries'},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _copyToClipboard(email, 'Email copied to clipboard');
    }
  }

  Future<void> _openDialer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _copyToClipboard(displayPhone, 'Phone number copied to clipboard');
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xff242424),
      colorText: const Color(0xffffd000),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff181818),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xffffd000),
                      size: 24,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  const Text(
                    'ToolForge',
                    style: TextStyle(
                      color: Color(0xffffd000),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Title Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact & About Us',
                    style: TextStyle(
                      color: Color(0xffffcce9),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 140,
                    height: 2.5,
                    color: const Color(0xff555555),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // About Us Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff242424),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xffffd000),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xffffd000),
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Who We Are',
                          style: TextStyle(
                            color: Color(0xffffd000),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Text(
                      'We are a passionate team dedicated to redefining how students and lifelong learners retain knowledge. ToolForge bridges fast local-first media extraction with modern intelligence, turning long-form lectures, documents, and videos into high-yield, interactive study assessments in seconds.',
                      style: TextStyle(
                        color: Color(0xffffcce9),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Built by students for builders, our focus is high speed, clean design, and reliable utility without clutter.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Get in Touch',
                style: TextStyle(
                  color: Color(0xffffd000),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Email Tile
              _buildContactCard(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
                actionLabel: 'Send Email',
                onTap: _openEmail,
                onCopy: () => _copyToClipboard(email, 'Email copied!'),
              ),
              const SizedBox(height: 14),

              // Phone Tile
              _buildContactCard(
                icon: Icons.phone_outlined,
                label: 'Phone / WhatsApp',
                value: displayPhone,
                actionLabel: 'Call',
                onTap: _openDialer,
                onCopy: () => _copyToClipboard(displayPhone, 'Phone number copied!'),
              ),
              const SizedBox(height: 32),

              // Footer Note
              Center(
                child: Text(
                  'Have feature requests or feedback? We reply promptly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String value,
    required String actionLabel,
    required VoidCallback onTap,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xff242424),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xff333333),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff181818),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xffffd000), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xffffd000),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xffffcce9), size: 18),
            onPressed: onCopy,
            tooltip: 'Copy',
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffffd000),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}