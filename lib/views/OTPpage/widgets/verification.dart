import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';
import '../../changepasswoed/changepassword.dar.dart';

class OtpScreenpage extends StatefulWidget {
  final String phone; // can be phone or email
  final String otp;

  const OtpScreenpage({
    super.key,
    required this.phone,
    required this.otp,
  });

  @override
  State<OtpScreenpage> createState() => _OtpScreenpageState();
}

class _OtpScreenpageState extends State<OtpScreenpage> {
  int _start = 30;
  bool _canResend = false;
  Timer? _timer;
  bool isLoading = false;
  final TextEditingController otpController = TextEditingController();
  final SmartAuth smartAuth = SmartAuth.instance;

  final String apiKey = "02d22c19-69a0-4082-a1fc-46b0e45f6340";

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenForOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _start = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _start--);
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse("http://192.168.1.33:8000/api/resend_otp/");
      final isEmail = widget.phone.contains('@');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "api_key": apiKey,
          "phone": isEmail ? "" : widget.phone,
          "email": isEmail ? widget.phone : "",
          "channel": "both",
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint("Resend Response: $data");

      if (response.statusCode == 200 &&
          data["message"] == "OTP sent successfully!") {
        _showSnackBar("OTP resent successfully!", Color(0xFF4CAF50));
        _startTimer(); // restart countdown
      } else {
        _showSnackBar(data["error"] ?? "Failed to resend OTP", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error resending OTP: $e", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _listenForOtp() async {
    final sigRes = await smartAuth.getAppSignature();
    debugPrint("App Signature: ${sigRes.data}");

    final res = await smartAuth.getSmsWithUserConsentApi();
    if (res.hasData) {
      final code = res.requireData.code;
      if (code != null) otpController.text = code;
    } else if (res.hasError) {
      debugPrint("Error: ${res.error}");
    }
  }

  Future<void> _verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      _showSnackBar("Please enter OTP", Colors.orange);
      return;
    }

    setState(() => isLoading = true);
    try {
      final isEmail = widget.phone.contains('@');
      final url = Uri.parse("http://192.168.1.33:8000/api/verify_otp/");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "api_key": apiKey,
          "phone": isEmail ? "" : widget.phone,
          "email": isEmail ? widget.phone : "",
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint("Verify Response: $data");

      if (response.statusCode == 200 &&
          data["message"] == "OTP verified successfully!") {
        _showSnackBar("OTP verified successfully!", Color(0xFF4CAF50));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const change_password()),
        );
      } else {
        _showSnackBar(data["error"] ?? "Invalid OTP", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error verifying OTP: $e", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1A1A1A)),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(height: 20),

                    // Header Section
                    _buildHeaderSection(),
                    SizedBox(height: 40),

                    // OTP Input Section
                    _buildOtpSection(),
                    SizedBox(height: 24),

                    // Resend Section
                    _buildResendSection(),
                    SizedBox(height: 40),

                    // Verify Button
                    _buildVerifyButton(),
                    SizedBox(height: 24),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),

            // Loading Overlay
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Verifying...",
                          style: GoogleFonts.poppins(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "OTP Verification",
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Enter the verification code sent to your phone or email",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.phone,
            style: GoogleFonts.poppins(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter OTP Code",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 16),
          Pinput(
            length: 4,
            controller: otpController,
            keyboardType: TextInputType.number,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            onCompleted: (pin) => _verifyOtp(),
            defaultPinTheme: PinTheme(
              width: 56,
              height: 60,
              textStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 56,
              height: 60,
              textStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF6C63FF), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C63FF).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            submittedPinTheme: PinTheme(
              width: 56,
              height: 60,
              textStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              decoration: BoxDecoration(
                color: Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF6C63FF)),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Enter the 4-digit code sent to your registered phone or email",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: Column(
        children: [
          Text(
            _canResend
                ? "Didn't receive the code?"
                : "Resend code in $_start seconds",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          if (_canResend)
            TextButton(
              onPressed: isLoading ? null : _resendOtp,
              child: Text(
                "Resend OTP",
                style: GoogleFonts.poppins(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          "Verify OTP",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: Colors.grey.shade300),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                // Navigate to Privacy Policy
              },
              child: Text(
                "Privacy Policy",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 12,
              color: Colors.grey.shade300,
            ),
            TextButton(
              onPressed: () {
                // Navigate to Terms and Conditions
              },
              child: Text(
                "Terms & Conditions",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}