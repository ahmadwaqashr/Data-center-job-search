import 'dart:io';
import 'dart:convert';
import 'package:data_center_job/utils/custom_button.dart';
import 'package:data_center_job/view/employer/auth/employer_under_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';

class EmployerLogoScreen extends StatefulWidget {
  final Map<String, String>? companyData;
  
  const EmployerLogoScreen({super.key, this.companyData});

  @override
  State<EmployerLogoScreen> createState() => _EmployerLogoScreenState();
}

class _EmployerLogoScreenState extends State<EmployerLogoScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final Dio _dio = Dio();
  File? _selectedLogo;
  String? _companyInitials; // Store company initials for fallback
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default initials (can be updated from previous screen)
    _companyInitials = 'AC';
    // Extract initials from company name if available
    if (widget.companyData != null && widget.companyData!['companyName'] != null) {
      final companyName = widget.companyData!['companyName']!;
      if (companyName.isNotEmpty) {
        final words = companyName.trim().split(' ');
        if (words.length >= 2) {
          _companyInitials = '${words[0][0]}${words[1][0]}'.toUpperCase();
        } else if (words.length == 1 && words[0].isNotEmpty) {
          _companyInitials = words[0][0].toUpperCase();
        }
      }
    }
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedLogo = File(image.path);
        });
        print('✅ Logo selected: ${_selectedLogo!.path}');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryColor),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitEmployerSignup() async {
    if (widget.companyData == null) {
      Get.snackbar(
        'Error',
        'Company data is missing',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('📤 Submitting employer signup...');
      
      // Prepare FormData
      final formData = FormData.fromMap({
        'role': 'employer',
        'email': widget.companyData!['email'] ?? '',
        'companyName': widget.companyData!['companyName'] ?? '',
        'fullName': widget.companyData!['fullName'] ?? '',
        'yourRole': widget.companyData!['yourRole'] ?? '',
        'companySize': widget.companyData!['companySize'] ?? '',
        'monthlyHiring': widget.companyData!['monthlyHiring'] ?? '',
        'companyLocation': widget.companyData!['companyLocation'] ?? '',
        'companyWebsite': widget.companyData!['companyWebsite'] ?? '',
        'fbLink': widget.companyData!['fbLink'] ?? '',
        'linkedinLink': widget.companyData!['linkedinLink'] ?? '',
        'instagramLink': widget.companyData!['instagramLink'] ?? '',
      });

      // Add logo file if selected (as profilePic)
      if (_selectedLogo != null) {
        final fileName = _selectedLogo!.path.split('/').last;
        formData.files.add(
          MapEntry(
            'profilePic',
            await MultipartFile.fromFile(
              _selectedLogo!.path,
              filename: fileName,
            ),
          ),
        );
        print('📎 Logo file added as profilePic: $fileName');
      }

      print('📤 API Request:');
      print('   URL: ${ApiConfig.getUrl(ApiConfig.candidateSignup)}');
      print('   Email: ${widget.companyData!['email']}');
      print('   Company: ${widget.companyData!['companyName']}');

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.candidateSignup),
        options: Options(
          method: 'POST',
        ),
        data: formData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('✅ Signup successful:');
        print('   Response: ${jsonEncode(responseData)}');

        // Save user data to SharedPreferences
        await _saveUserData(responseData);

        setState(() {
          _isSubmitting = false;
        });

        // Navigate to under review screen
        Get.offAll(() => EmployerUnderReviewScreen());
      } else {
        throw Exception('Signup failed: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Signup error: $e');
      setState(() {
        _isSubmitting = false;
      });

      String errorMessage = 'Failed to complete signup';
      if (e is DioException) {
        if (e.response != null) {
          errorMessage = e.response!.data['message'] ?? 
                        e.response!.data['error'] ?? 
                        errorMessage;
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else {
        errorMessage = e.toString();
      }

      Get.snackbar(
        'Signup Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      print('💾 Saving employer data to SharedPreferences...');
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
      // Always save role as 'employer'
      await prefs.setString('user_role', 'employer');
      print('   ✅ user_role saved: employer');
      
      print('✅ All employer data saved to SharedPreferences successfully');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
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
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress indicator
                          Row(
                            children: [
                              Text(
                                'Step 4 of 4',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '• Company logo',
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
                                widthFactor: 1.0,
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
                          SizedBox(height: 24.h),
                          // Title
                          Text(
                            'Make your brand recognizable',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Add your company logo',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Your logo appears on job posts and candidate messages so people know they\'re applying to the right place.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 40.h),
                          // Logo preview section
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              children: [
                                // Logo preview circle
                                Container(
                                  height: 95.h,
                                  width: 95.w,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(.15),
                                    shape: BoxShape.circle
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: 70.h,
                                      width: 70.w,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _selectedLogo != null
                                            ? Image.file(
                                                _selectedLogo!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  // Fallback to initials if image fails to load
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primaryColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        _companyInitials ?? 'AC',
                                                        style: TextStyle(
                                                          fontSize: 18.sp,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    _companyInitials ?? 'AC',
                                                    style: TextStyle(
                                                      fontSize: 18.sp,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Description
                                Text(
                                  'Preview of your logo. You can upload a square logo or we\'ll use your initials instead.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Upload logo button
                                GestureDetector(
                                  onTap: () {
                                    _showImageSourceDialog();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 50.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.upload_outlined,
                                          color: Colors.white,
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          _selectedLogo != null ? 'Change logo' : 'Upload logo',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                if (_selectedLogo != null) ...[
                                  SizedBox(height: 12.h),
                                  // Use different image button
                                  GestureDetector(
                                    onTap: () {
                                      _showImageSourceDialog();
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(.1),
                                        borderRadius: BorderRadius.circular(25.r),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            color: Colors.grey[700],
                                            size: 18.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Use different image',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  // Remove logo button
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedLogo = null;
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(.1),
                                        borderRadius: BorderRadius.circular(25.r),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 18.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Remove logo',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.red,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8.h),
                                // Recommendation text
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Recommended: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              'Square PNG or JPG, at least 240×240px, with a transparent or solid background. You can change this any time from Company profile.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Bottom section
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 20.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              children: [
                                // Completion message with badge
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'You\'re almost done. Next you\'ll land in your recruiter home.',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Column(
                                      children: [
                                        Text(
                                          'Finish',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'setup',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                // Save & continue button
                                GestureDetector(
                                  onTap: _isSubmitting ? null : () async {
                                    await _submitEmployerSignup();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 50.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                    alignment: Alignment.center,
                                    child: _isSubmitting
                                        ? Padding(
                                            padding: EdgeInsets.all(12.h),
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Save & Continue',
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
                                // Skip for now button
                                TextButton(
                                  onPressed: _isSubmitting ? null : () async {
                                    await _submitEmployerSignup();
                                  },
                                  child: Text(
                                    'Skip for now',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
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

// Custom painter for dashed circle border
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * 3.14159 * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashWidth + dashSpace) / radius);
      final sweepAngle = dashWidth / radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
