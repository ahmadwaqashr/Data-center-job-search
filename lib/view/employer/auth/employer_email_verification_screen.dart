import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:data_center_job/view/employer/auth/employer_company_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';

class EmployerEmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmployerEmailVerificationScreen({super.key, required this.email});

  @override
  State<EmployerEmailVerificationScreen> createState() =>
      _EmployerEmailVerificationScreenState();
}

class _EmployerEmailVerificationScreenState
    extends State<EmployerEmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = Dio();
  
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerifying = false;
  int _timerSeconds = 60;
  Timer? _countdownTimer;
  String? _storedOtp;
  DateTime? _otpExpiryTime;

  @override
  void initState() {
    super.initState();
    _sendEmailOTP();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _dio.close();
    super.dispose();
  }

  // Generate 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP via email
  Future<void> _sendEmailOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate OTP
      final otp = _generateOTP();
      _storedOtp = otp;
      _otpExpiryTime = DateTime.now().add(Duration(minutes: 5));
      
      print('📧 Sending OTP to ${widget.email}');
      print('   OTP: $otp');
      
      // Store OTP in SharedPreferences with expiry
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_otp_${widget.email}', otp);
      await prefs.setString('email_otp_expiry_${widget.email}', _otpExpiryTime!.toIso8601String());
      
      // Send OTP via email using Firebase or backend API
      // Option 1: Use Firebase sendPasswordResetEmail (workaround - sends email)
      // Option 2: Use backend API to send OTP email
      // For now, we'll use a backend API approach
      
      // Send OTP via backend API
      final otpForDisplay = await _sendOTPEmail(otp);
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      if (otpForDisplay != null) {
        // Email service not configured - show OTP to user
        Get.snackbar(
          'OTP Code',
          'Email service not configured. Your OTP code is: $otpForDisplay',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 15),
          isDismissible: true,
          messageText: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email service not configured on backend.',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your OTP Code:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            otpForDisplay,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please enter this code to continue',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        );
      } else {
        // Email sent successfully
        Get.snackbar(
          'OTP Sent',
          'A 6-digit code has been sent to ${widget.email}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('❌ Error sending OTP: $e');
      Get.snackbar(
        'Error',
        'Failed to send OTP. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Send OTP email via backend API
  // Returns the OTP if email service is not configured (for display to user)
  Future<String?> _sendOTPEmail(String otp) async {
    try {
      print('📧 Calling backend API to send OTP email...');
      print('   Endpoint: ${ApiConfig.getUrl(ApiConfig.sendEmailOTP)}');
      print('   Email: ${widget.email}');
      print('   OTP: $otp');
      print('   Role: employer');
      
      final response = await _dio.post(
        ApiConfig.getUrl(ApiConfig.sendEmailOTP),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          'email': widget.email,
          'otp': otp,
          'role': 'employer',
        }),
      );

      print('📧 Email OTP API Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Data: ${jsonEncode(response.data)}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final message = responseData['message'] ?? 'OTP email sent successfully';
          print('✅ OTP email sent successfully: $message');
          
          // Check if email service is not configured
          if (message.toLowerCase().contains('not configured') || 
              message.toLowerCase().contains('fallback')) {
            print('⚠️ Email service not configured on backend, showing OTP to user');
            // Return the OTP so it can be displayed to user
            return otp;
          }
        } else {
          throw Exception(responseData['message'] ?? 'Failed to send OTP email');
        }
      } else {
        throw Exception('Failed to send OTP email: ${response.statusCode}');
      }
      
      return null; // Email sent successfully
    } on DioException catch (e) {
      print('❌ Email OTP API Error:');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Error: ${e.message}');
      print('   Response: ${e.response?.data}');
      
      // Handle specific error responses
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Invalid request';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Email OTP service not available. Please contact support.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to send OTP email');
      }
    } catch (e) {
      print('❌ Unexpected error sending OTP email: $e');
      throw Exception('Failed to send OTP email. Please try again.');
    }
  }

  // Verify OTP
  Future<void> _verifyOTP(String otp) async {
    if (_isVerifying) return;
    
    setState(() {
      _isVerifying = true;
    });

    try {
      // Get stored OTP from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedOtp = prefs.getString('email_otp_${widget.email}');
      final expiryString = prefs.getString('email_otp_expiry_${widget.email}');
      
      if (storedOtp == null || expiryString == null) {
        throw Exception('OTP expired or not found. Please request a new code.');
      }
      
      final expiryTime = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiryTime)) {
        throw Exception('OTP has expired. Please request a new code.');
      }
      
      // Verify OTP
      if (otp != storedOtp) {
        throw Exception('Invalid verification code. Please try again.');
      }
      
      print('✅ OTP verified successfully');
      
      // Clear stored OTP
      await prefs.remove('email_otp_${widget.email}');
      await prefs.remove('email_otp_expiry_${widget.email}');
      
      setState(() {
        _isVerifying = false;
      });
      
      // Navigate to next screen
      Get.to(() => EmployerCompanyDetailsScreen());
      
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      
      print('❌ OTP verification error: $e');
      Get.snackbar(
        'Verification Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Resend OTP
  Future<void> _resendOTP() async {
    if (_isResending) return;
    
    setState(() {
      _isResending = true;
      _timerSeconds = 60;
    });
    
    await _sendEmailOTP();
    _startCountdown();
    
    setState(() {
      _isResending = false;
    });
  }

  // Start countdown timer
  void _startCountdown() {
    _countdownTimer?.cancel();
    _timerSeconds = 60;
    
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
            ),
          ),
          child: Stack(
            children: [
              // First radial gradient (purple/indigo) - top left
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF6366F1).withOpacity(0.15),
                        Color(0xFF6366F1).withOpacity(0.0),
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              // Second radial gradient (blue) - bottom right
              Positioned(
                bottom: -150,
                right: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF2563EB).withOpacity(0.15),
                        Color(0xFF2563EB).withOpacity(0.0),
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              // Content
              Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 18.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Text(
                        //   'Recruiter',
                        //   style: TextStyle(
                        //     fontSize: 14.sp,
                        //     color: Colors.grey[700],
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step indicator
                          Row(
                            children: [
                              Text(
                                'Step 2 of 4',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '• Fill the Otp',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          // Progress bar
                          Stack(
                            children: [
                              Container(
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: 0.50,
                                child: Container(
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          // Title
                          Text(
                            'Check your work email',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Description
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(text: 'We sent a 6-digit code to '),
                                TextSpan(
                                  text: widget.email,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(text: '. Enter it below to continue.'),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
                          // Main content card
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email display row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          color: Colors.grey[600],
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Email',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              widget.email,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                      },
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                // Verification code label
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Verification code',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      _timerSeconds > 0 
                                          ? '${_formatTimer(_timerSeconds)} left'
                                          : 'Expired',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: _timerSeconds > 0 
                                            ? AppColors.primaryColor 
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Code input using Pinput
                                Center(
                                  child: Pinput(
                                    controller: _otpController,
                                    focusNode: _otpFocusNode,
                                    length: 6,
                                    defaultPinTheme: PinTheme(
                                      width: 48.w,
                                      height: 56.h,
                                      textStyle: TextStyle(
                                        fontSize: 24.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    focusedPinTheme: PinTheme(
                                      width: 48.w,
                                      height: 56.h,
                                      textStyle: TextStyle(
                                        fontSize: 24.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    submittedPinTheme: PinTheme(
                                      width: 48.w,
                                      height: 56.h,
                                      textStyle: TextStyle(
                                        fontSize: 24.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    showCursor: true,
                                    onCompleted: (pin) {
                                      // Verify OTP when completed
                                      _verifyOTP(pin);
                                    },
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Didn't get a code
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Didn\'t get a code?',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _timerSeconds > 0 || _isResending 
                                          ? null 
                                          : _resendOTP,
                                      child: _isResending
                                          ? SizedBox(
                                              width: 16.w,
                                              height: 16.h,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppColors.primaryColor,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              'Resend code',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: _timerSeconds > 0 
                                                    ? Colors.grey[400] 
                                                    : AppColors.primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                // Continue button
                                GestureDetector(
                                  onTap: _isVerifying || _otpController.text.length != 6
                                      ? null
                                      : () {
                                          _verifyOTP(_otpController.text);
                                        },
                                  child: Container(
                                    width: double.infinity,
                                    height: 50.h,
                                    decoration: BoxDecoration(
                                      color: (_isVerifying || _otpController.text.length != 6)
                                          ? AppColors.primaryColor.withOpacity(0.6)
                                          : AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                    alignment: Alignment.center,
                                    child: _isVerifying
                                        ? SizedBox(
                                            width: 20.w,
                                            height: 20.h,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Continue',
                                                style: TextStyle(
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              Container(
                                                height: 18.h,
                                                width: 18.w,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF2052C1),
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward_sharp,
                                                  color: Colors.white,
                                                  size: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Use different method
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: Text(
                                      'Use a different method',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40.h),
                          // Bottom info text
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Text(
                              'Make sure you can access your work inbox; this email will be used for candidate updates and hiring alerts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
