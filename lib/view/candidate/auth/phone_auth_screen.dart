import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:data_center_job/view/candidate/auth/otp_verification_screen.dart';
import 'package:data_center_job/view/candidate/auth/complete_profile_screen.dart';
import 'package:data_center_job/view/candidate/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';
import '../../../models/signup_data.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Dio _dio = Dio();
  String _countryCode = '+1';
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your phone number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String phoneNumber = _countryCode + _phoneController.text.trim();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification completed (Android only)
          setState(() {
            _isLoading = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          Get.snackbar(
            'Verification Failed',
            e.message ?? 'Failed to send verification code',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
          });
          
          // Navigate to OTP verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to send OTP: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      print('🔐 Starting Google Sign-In...');
      
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        print('⚠️ Google Sign-In cancelled by user');
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      print('✅ Google Sign-In successful');
      print('   Email: ${googleUser.email}');
      print('   Display Name: ${googleUser.displayName}');
      print('   ID: ${googleUser.id}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);
      print('✅ Firebase authentication successful');

      // Call login API with Google email
      await _callGoogleLoginAPI(googleUser.email ?? '', googleUser.displayName ?? '');
      
    } catch (e) {
      setState(() {
        _isGoogleLoading = false;
      });
      
      print('❌ Google Sign-In error: $e');
      Get.snackbar(
        'Error',
        'Failed to sign in with Google: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _callGoogleLoginAPI(String email, String displayName) async {
    try {
      print('🔐 Calling login API with Google credentials...');
      print('   Email: $email');
      print('   Role: candidate');
      
      // Prepare request data - for Google login, send email in "phone" field
      // Format: {"role": "candidate", "phone": "email"}
      final requestData = jsonEncode({
        'role': 'candidate',
        'phone': email, // Send email in phone field for Google login
      });
      
      print('📤 Request data: $requestData');

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
        
        print('✅ Login successful! User exists.');
        print('   User ID: ${responseData['id']}');
        print('   Email: ${responseData['email']}');
        print('   Full Name: ${responseData['fullName']}');
        print('   Token: ${responseData['token']?.substring(0, 20) ?? "NULL"}...');
        
        // Save user data to SharedPreferences
        await _saveUserData(responseData);
        
        setState(() {
          _isGoogleLoading = false;
        });

        // Navigate to dashboard - user exists
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
        _isGoogleLoading = false;
      });

      print('❌ Login API Error:');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Error: ${e.message}');
      print('   Response: ${e.response?.data}');

      // Save Google user info to SignupData for pre-filling in CompleteProfileScreen
      try {
        final googleUser = await _googleSignIn.signInSilently();
        if (googleUser != null) {
          SignupData.instance.email = googleUser.email ?? email;
          SignupData.instance.fullName = googleUser.displayName ?? displayName;
          print('✅ Saved Google user info for profile completion');
          print('   Email: ${SignupData.instance.email}');
          print('   Full Name: ${SignupData.instance.fullName}');
        } else {
          // If signInSilently fails, use provided values
          SignupData.instance.email = email;
          SignupData.instance.fullName = displayName;
          print('✅ Saved Google user info from parameters');
        }
      } catch (e) {
        print('⚠️ Could not save Google user info: $e');
        // Fallback: use provided values
        SignupData.instance.email = email;
        SignupData.instance.fullName = displayName;
        print('✅ Saved Google user info from parameters (fallback)');
      }

      // Handle any error (401, 400, etc.) - user doesn't exist, navigate to complete profile
      print('ℹ️ User does not exist or error occurred, navigating to complete profile...');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CompleteProfileScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isGoogleLoading = false;
      });
      print('❌ Unexpected error during login: $e');
      
      // Save Google user info even on unexpected error
      try {
        SignupData.instance.email = email;
        SignupData.instance.fullName = displayName;
      } catch (e2) {
        print('⚠️ Could not save user info: $e2');
      }
      
      // Navigate to complete profile on any error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CompleteProfileScreen()),
        );
      }
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

  @override
  Widget build(BuildContext context) {
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
                        'Enter your phone to continue',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Description
                      Text(
                        'We\'ll send a one-time code to verify your number.No password needed.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 40.h),
                      // Phone number label
                      Text(
                        'Phone number',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Phone Input Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 16.sp, color: Colors.black),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter phone number',
                          hintStyle: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: CountryCodePicker(
                            onChanged: (country) {
                              setState(() {
                                _countryCode = country.dialCode ?? '+1';
                              });
                            },
                            initialSelection: 'US',
                            favorite: ['+1', 'US'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            padding: EdgeInsets.zero,
                            textStyle: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // SMS verification text
                      Text(
                        'You\'ll receive a 6-digit verification code via SMS.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Continue Button
                      GestureDetector(
                        onTap: _isLoading ? null : _sendOTP,
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: _isLoading 
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
                      SizedBox(height: 20.h),
                      // Or continue with text
                      Center(
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Continue with Google Button
                      GestureDetector(
                        onTap: _isGoogleLoading ? null : _signInWithGoogle,
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: _isGoogleLoading 
                                ? Colors.grey[200]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: _isGoogleLoading
                              ? Center(
                                  child: SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[600]!,
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/google.png',
                                      height: 18.h,
                                      width: 18.w,
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Continue with Apple Button
                      GestureDetector(
                        onTap: () {
                          // Apple sign in
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/apple.png',
                                height: 18.h,
                                width: 18.w,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Continue with Apple',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Already have an account
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 65.h),
                      // Terms and Privacy text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'By continuing, you agree to receive account-related messages and accept our Terms & Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
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
