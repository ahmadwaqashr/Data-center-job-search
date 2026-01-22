import 'dart:convert';
import 'package:data_center_job/view/candidate/auth/complete_profile_screen.dart';
import 'package:data_center_job/view/candidate/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';
import '../../../models/signup_data.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = Dio();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
  }

  void _onOtpChanged() {
    setState(() {
      // Update UI when OTP changes
    });
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _verifyOTP(String otp) async {
    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      
      print('✅ Firebase OTP verified successfully');
      
      // Save phone number to SignupData
      SignupData.instance.phone = widget.phoneNumber;
      
      // Call login API after successful OTP verification
      await _callLoginAPI();
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Invalid verification code';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'The verification code is invalid';
      } else if (e.code == 'session-expired') {
        errorMessage = 'The verification code has expired. Please request a new one.';
      }

      Get.snackbar(
        'Verification Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to verify code: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _callLoginAPI() async {
    try {
      print('🔐 Calling login API...');
      print('   Phone: ${widget.phoneNumber}');
      print('   Role: candidate');
      
      // Prepare request data
      final requestData = jsonEncode({
        'role': 'candidate', // Role is always 'candidate' for candidate login flow
        'phone': widget.phoneNumber,
      });

      // Make login API call
      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.candidateLogin),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      print('📥 Login API Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Data: ${jsonEncode(response.data)}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        print('✅ Login successful!');
        print('   User ID: ${responseData['id']}');
        print('   Email: ${responseData['email']}');
        print('   Full Name: ${responseData['fullName']}');
        print('   Token: ${responseData['token']?.substring(0, 20) ?? "NULL"}...');
        
        // Save user data to SharedPreferences
        await _saveUserData(responseData);
        
        setState(() {
          _isLoading = false;
        });

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
            (route) => false, // Remove all previous routes
          );
        }
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Login API Error:');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Error: ${e.message}');
      print('   Response: ${e.response?.data}');

      // Handle 401 Unauthorized - user doesn't exist, continue with signup
      if (e.response?.statusCode == 401) {
        print('ℹ️ User not found (401), continuing with signup flow');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CompleteProfileScreen()),
          );
        }
        return;
      }

      // Other errors
      Get.snackbar(
        'Login Failed',
        e.response?.data?['message'] ?? e.message ?? 'Failed to login. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Unexpected error during login: $e');
      Get.snackbar(
        'Error',
        'Failed to login: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      print('💾 Saving user data to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      
      // Save all user data as JSON
      await prefs.setString('user_data', jsonEncode(userData));
      print('   ✅ user_data saved');
      
      // Save individual important fields for easy access
      if (userData['token'] != null) {
        await prefs.setString('auth_token', userData['token']);
        print('   ✅ auth_token saved');
      }
      if (userData['id'] != null) {
        await prefs.setString('user_id', userData['id'].toString());
        print('   ✅ user_id saved: ${userData['id']}');
      }
      if (userData['email'] != null) {
        await prefs.setString('user_email', userData['email']);
        print('   ✅ user_email saved: ${userData['email']}');
      }
      if (userData['fullName'] != null) {
        await prefs.setString('user_name', userData['fullName']);
        print('   ✅ user_name saved: ${userData['fullName']}');
      }
      if (userData['role'] != null) {
        await prefs.setString('user_role', userData['role']);
        print('   ✅ user_role saved: ${userData['role']}');
      }
      
      print('✅ All user data saved to SharedPreferences successfully');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          setState(() {
            _isResending = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isResending = false;
          });
          Get.snackbar(
            'Resend Failed',
            e.message ?? 'Failed to resend verification code',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isResending = false;
          });
          Get.snackbar(
            'Code Resent',
            'A new verification code has been sent to your phone',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          // Update verification ID if needed
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      Get.snackbar(
        'Error',
        'Failed to resend code: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50.w,
      height: 56.h,
      textStyle: TextStyle(
        fontSize: 20.sp,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Color(0xFF2563EB),
          width: 2,
        ),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
    );

    return SafeArea(
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
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
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      // Back Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
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
                      SizedBox(height: 30.h),
                      // Subtitle
                      Text(
                        'Data Center Job Search',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Title
                      Text(
                        'Enter the 6-digit code',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Description
                      Text(
                        'We\'ve sent a verification code to your phone number. Enter it below to continue.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 40.h),
                      // Verification code label
                      Text(
                        'Verification code',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // OTP Input using Pinput
                      Center(
                        child: Pinput(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          length: 6,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: submittedPinTheme,
                          showCursor: true,
                          onCompleted: (pin) {
                            _verifyOTP(pin);
                          },
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // SMS verification text
                      Center(
                        child: Text(
                          'Enter the 6-digit code sent via SMS to your phone number.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Resend code and Change number
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Didn\'t get it? ',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: _isResending ? null : _resendOTP,
                            child: _isResending
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2563EB),
                                      ),
                                    ),
                                  )
                                : Text(
                              'Resend code',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 40.w),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Change number',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Verify & Continue Button
                      GestureDetector(
                        onTap: _isLoading || _otpController.text.length != 6
                            ? null
                            : () {
                                _verifyOTP(_otpController.text);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: (_isLoading || _otpController.text.length != 6)
                                ? AppColors.primaryColor.withOpacity(0.6)
                                : AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verify & continue',
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
                      SizedBox(height: 20.h),
                      // Terms and Privacy text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'We\'ll only use your number to secure your account and send important updates.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 190.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
