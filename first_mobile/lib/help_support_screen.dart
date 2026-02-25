import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@atibyan.com',
      queryParameters: {
        'subject': 'Help & Support Request from Atibyan Tech Academy App',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          _buildFAQItem(
            question: 'How do I reset my password?',
            answer: 'Go to the Login screen and tap "Forgot Password". Follow the instructions sent to your email.',
          ),
          _buildFAQItem(
            question: 'Why am I not receiving verification code?',
            answer: 'Check your spam/junk folder. Make sure you\'re using a valid email. Try requesting a new code.',
          ),
          _buildFAQItem(
            question: 'How can I delete my account?',
            answer: 'Contact support — we\'ll assist you with account deletion for privacy reasons.',
          ),
          _buildFAQItem(
            question: 'Is my data safe?',
            answer: 'Yes, we use Supabase with row-level security and encrypted storage. Your data is protected.',
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          Text(
            'Contact Us',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.email_outlined, color: Color(0xFF4CAF50)),
            title: const Text('Email Support'),
            subtitle: const Text('support@atibyan.com'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _launchEmail(context),  // ← FIXED: pass context here
          ),

          const SizedBox(height: 40),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Profile'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(answer, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}