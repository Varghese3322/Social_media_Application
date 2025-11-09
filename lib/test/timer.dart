import 'dart:async';
import 'package:flutter/material.dart';

class OtpVerificationPagetimer extends StatefulWidget {
  const OtpVerificationPagetimer({super.key});

  @override
  State<OtpVerificationPagetimer> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPagetimer> {
  int _start = 30; // Timer duration in seconds
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void resendOtp() {
    // 🔥 Call your API to resend OTP here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP resent")),
    );
    startTimer(); // Restart timer after resend
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OTP Verification")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter the OTP sent to your number"),
            const SizedBox(height: 20),

            // Example OTP input field (use a package like pin_code_fields for better UI)
            const TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter OTP",
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Resend OTP button with timer
            _canResend
                ? TextButton(
              onPressed: resendOtp,
              child: const Text("Resend OTP"),
            )
                : Text("Resend OTP in $_start sec"),
          ],
        ),
      ),
    );
  }
}
