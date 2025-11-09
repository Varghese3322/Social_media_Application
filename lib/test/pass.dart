import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';



class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final SmartAuth smartAuth = SmartAuth.instance;
  final TextEditingController otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenForOtp();
  }

  /// Listen for OTP using User Consent API
  Future<void> _listenForOtp() async {
    // Optional: get app signature (for SMS Retriever API use)
    final sigRes = await smartAuth.getAppSignature();
    debugPrint("App Signature: ${sigRes.data}");

    // Start listening for OTP
    final res = await smartAuth.getSmsWithUserConsentApi();
    if (res.hasData) {
      final code = res.requireData.code;
      if (code != null) {
        otpController.text = code; // Autofill the OTP
      }
    } else if (res.hasError) {
      debugPrint("Error: ${res.error}");
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    smartAuth.removeUserConsentApiListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OTP Autofill Example"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter the OTP sent to your phone",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // OTP Input Field
            Pinput(
              length: 6,
              controller: otpController,
              /*crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,*/
              onCompleted: (pin) {
                debugPrint("OTP Entered: $pin");
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                debugPrint("Submitted OTP: ${otpController.text}");
              },
              child: const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}