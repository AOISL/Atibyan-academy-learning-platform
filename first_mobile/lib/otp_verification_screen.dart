import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:first_mobile/main.dart' show supabase;

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) FocusScope.of(context).requestFocus(FocusNode());
    });

    _otpController.addListener(() {
      final otp = _otpController.text.trim();
      if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp) && !_isVerifying) {
        _verifyOtp();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Enter a valid 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final response = await supabase.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user != null) {
        setState(() => _errorMessage = null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account verified! Redirecting...'),
            backgroundColor: Colors.green,
          ),
        );

        // Redirect to home – use named route if defined, or replace with direct widget
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
          // Alternative if no named routes:
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => const AppShell()),
          // );
        }
      } else {
        setState(() => _errorMessage = 'Verification succeeded but no user returned');
      }
    } on AuthException catch (e) {
      String msg = e.message.toLowerCase();
      if (msg.contains('expired') || msg.contains('invalid')) {
        msg = 'Code expired or invalid. Please request a new one.';
      } else if (msg.contains('rate limit') || msg.contains('exceeded')) {
        msg = 'Rate limit hit. Try a new email or wait a few minutes.';
      } else if (msg.contains('unexpected_failure') || msg.contains('sending')) {
        msg = 'Failed to send confirmation email. Please try again.';
      } else {
        msg = e.message;
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New code sent! Check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resend failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo-black-1.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),

              Text(
                'Enter 6-digit code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Text(
                'Sent to ${widget.email}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, letterSpacing: 16),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMessage,
                  errorStyle: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text('Verify Code', style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _isResending ? null : _resendOtp,
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Text(
                        'Resend Code',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}