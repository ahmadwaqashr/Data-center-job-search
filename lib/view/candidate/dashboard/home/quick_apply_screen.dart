import 'dart:convert';
import 'package:data_center_job/utils/custom_button.dart';
import 'package:data_center_job/view/candidate/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import '../../test/skill_test_screen.dart';

class QuickApplyScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const QuickApplyScreen({super.key, required this.jobData});

  @override
  State<QuickApplyScreen> createState() => _QuickApplyScreenState();
}

class _QuickApplyScreenState extends State<QuickApplyScreen> {
  // User profile data
  String _name = '';
  String _phone = '';
  String _location = '';
  
  // CV/Resume data
  String _cvFileName = '';
  String _cvUpdatedDate = '';
  String _cvPages = '';

  // Controllers for short questions
  final TextEditingController _goodFitController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();

  bool _shareProfile = true;
  bool _isLoading = true;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _goodFitController.dispose();
    _startDateController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    if (authToken != null && authToken.isNotEmpty) {
      return authToken;
    }

    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      final token = userData['token']?.toString();
      if (token != null && token.isNotEmpty) {
        return token;
      }
    }

    return null;
  }

  Future<void> _fetchUserProfile() async {
    // Note: editMyProfile is a POST endpoint that requires FormData for editing
    // For fetching profile data, we rely on SharedPreferences which is updated
    // after login/signup and profile edits. This avoids unnecessary API calls
    // and prevents 415 errors.
    // If you need to fetch latest profile data, use a dedicated GET endpoint.
    print('ℹ️ Using profile data from SharedPreferences (updated on login/signup/edit)');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data when screen comes into focus for real-time updates
    if (mounted) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        
        print('📋 Loading user data for quick apply:');
        print('   Available fields: ${userData.keys.toList()}');
        
        setState(() {
          // Load contact & profile details
          _name = userData['fullName']?.toString() ?? '';
          _phone = userData['phone']?.toString() ?? '';
          _location = userData['location']?.toString() ?? '';
          
          // Load CV/Resume data - check multiple possible field names
          // Check cvFilePath first (from API response)
          final cvPath = userData['cvFilePath']?.toString() ?? '';
          print('   🔍 CV Path from cvFilePath: "$cvPath"');
          
          if (cvPath.isNotEmpty && cvPath != 'null') {
            // Extract filename from path
            final pathParts = cvPath.split('/');
            _cvFileName = pathParts.isNotEmpty ? pathParts.last : cvPath;
            // If still empty or just the path, use the full path
            if (_cvFileName.isEmpty || _cvFileName == cvPath) {
              _cvFileName = cvPath;
            }
            print('   ✅ Extracted CV filename: "$_cvFileName"');
          } else {
            // Try other field names
            _cvFileName = userData['cvFileName']?.toString() ?? 
                         userData['resumeFileName']?.toString() ?? 
                         userData['cvName']?.toString() ??
                         userData['cv_file_name']?.toString() ??
                         userData['resume_file_name']?.toString() ??
                         userData['cv']?.toString() ??
                         userData['resume']?.toString() ??
                         '';
            if (_cvFileName.isNotEmpty) {
              print('   ✅ Found CV filename from alternative field: "$_cvFileName"');
            }
          }
          
          // Try to get CV updated date
          _cvUpdatedDate = userData['cvUpdatedDate']?.toString() ?? 
                          userData['resumeUpdatedDate']?.toString() ?? 
                          userData['cv_updated_date']?.toString() ??
                          userData['resume_updated_date']?.toString() ??
                          userData['cvUpdatedAt']?.toString() ??
                          userData['resumeUpdatedAt']?.toString() ??
                          '';
          
          // If still empty, try to parse from updatedAt or createdAt
          if (_cvUpdatedDate.isEmpty && userData['updatedAt'] != null) {
            try {
              final updatedAt = userData['updatedAt'].toString();
              if (updatedAt.isNotEmpty && updatedAt != 'null') {
                _cvUpdatedDate = updatedAt;
              }
            } catch (e) {
              print('   ⚠️ Could not parse updatedAt: $e');
            }
          }
          
          // Try to get CV pages
          _cvPages = userData['cvPages']?.toString() ?? 
                    userData['resumePages']?.toString() ?? 
                    userData['cv_pages']?.toString() ??
                    userData['resume_pages']?.toString() ??
                    userData['pages']?.toString() ??
                    '';
          
          print('   📄 CV Data loaded:');
          print('      - File Name: "${_cvFileName}" (empty: ${_cvFileName.isEmpty})');
          print('      - File Path: "$cvPath"');
          print('      - Updated Date: "${_cvUpdatedDate}" (empty: ${_cvUpdatedDate.isEmpty})');
          print('      - Pages: "${_cvPages}" (empty: ${_cvPages.isEmpty})');
          
          // Debug: Print all CV-related fields
          print('   🔍 All CV-related fields in userData:');
          userData.forEach((key, value) {
            if (key.toLowerCase().contains('cv') || 
                key.toLowerCase().contains('resume') ||
                key.toLowerCase().contains('file')) {
              print('      - $key: ${value?.toString() ?? 'null'}');
            }
          });
          
          _isLoading = false;
        });
      } else {
        print('⚠️ No user_data found in SharedPreferences');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEditDialog(
    String field,
    String currentValue,
    Function(String) onSave,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          title: Text(
            'Edit $field',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(fontSize: 14.sp, color: Colors.black),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick apply',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Review and submit in one tap',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '1 step',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),
                          // You're applying to
                          Text(
                            'You\'re applying to',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Job card
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.jobData['jobTitle'] ?? 
                                        widget.jobData['title'] ??
                                            'Data Center Technician',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF7C3AED,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          15.r,
                                        ),
                                      ),
                                      child: Text(
                                        'High match',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Color(0xFF7C3AED),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '${widget.jobData['companyName'] ?? widget.jobData['company'] ?? 'EdgeCore Systems'} • ${widget.jobData['workType'] ?? widget.jobData['type'] ?? 'Full-time'}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    if (widget.jobData['locationType'] != null)
                                      _buildInfoChip(widget.jobData['locationType'].toString()),
                                    if (widget.jobData['shifts'] != null && (widget.jobData['shifts'] as List).isNotEmpty)
                                      _buildInfoChip((widget.jobData['shifts'] as List)[0].toString())
                                    else
                                      _buildInfoChip('Shift-based'),
                                    _buildInfoChip(
                                      widget.jobData['location'] ??
                                          'Seattle, WA',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    Text(
                                      '${_formatTimeAgo(widget.jobData['createdAt']?.toString())} • Quick apply',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _formatSalary(widget.jobData),
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Match 92%',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Using your profile
                          Text(
                            'Using your profile',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Contact & profile details
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Contact & profile details',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'From your completed candidate profile',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // GestureDetector(
                                    //   onTap: () {
                                    //     // Navigate to edit profile
                                    //   },
                                    //   child: Text(
                                    //     'Edit profile',
                                    //     style: TextStyle(
                                    //       fontSize: 14.sp,
                                    //       color: AppColors.primaryColor,
                                    //       fontWeight: FontWeight.w500,
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                // Name
                                _buildProfileField(
                                  label: 'Name',
                                  value: _name,
                                ),
                                SizedBox(height: 16.h),
                                // Phone
                                _buildProfileField(
                                  label: 'Phone',
                                  value: _phone,
                                ),
                                SizedBox(height: 16.h),
                                // Location
                                _buildProfileField(
                                  label: 'Location',
                                  value: _location,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // CV / Resume
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CV / Resume',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40.w,
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.description_outlined,
                                          color: AppColors.primaryColor,
                                          size: 24.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _cvFileName.isEmpty ? 'No CV uploaded' : _cvFileName,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              _cvUpdatedDate.isNotEmpty && _cvPages.isNotEmpty
                                                  ? 'Updated $_cvUpdatedDate • $_cvPages pages'
                                                  : _cvUpdatedDate.isNotEmpty
                                                      ? 'Updated $_cvUpdatedDate'
                                                      : _cvPages.isNotEmpty
                                                          ? '$_cvPages pages'
                                                          : 'No CV uploaded',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Short questions
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Short questions',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Question 1
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Why are you a good fit for this role?',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                TextField(
                                  controller: _goodFitController,
                                  maxLines: null,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Add a short note (2–3 sentences)',
                                    hintStyle: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.all(12),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Question 2
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Available start date',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                GestureDetector(
                                  onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(Duration(days: 365 * 5)), // 5 years from now
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: AppColors.primaryColor,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _startDateController.text =
                                            '${picked.day}/${picked.month}/${picked.year}';
                                      });
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: TextField(
                                      controller: _startDateController,
                                      readOnly: true,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Select or enter a date',
                                        hintStyle: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[400],
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.withOpacity(.1),
                                        suffixIcon: Icon(
                                          Icons.calendar_today_outlined,
                                          color: Colors.grey[600],
                                          size: 20.sp,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25.r),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25.r),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 12.h,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Checkbox
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(
                                          () => _shareProfile = !_shareProfile,
                                        );
                                      },
                                      child: Container(
                                        width: 20.w,
                                        height: 20.h,
                                        decoration: BoxDecoration(
                                          color:
                                              _shareProfile
                                                  ? AppColors.primaryColor
                                                  : Colors.white,
                                          border: Border.all(
                                            color:
                                                _shareProfile
                                                    ? AppColors.primaryColor
                                                    : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                        ),
                                        child:
                                            _shareProfile
                                                ? Icon(
                                                  Icons.check,
                                                  size: 14.sp,
                                                  color: Colors.white,
                                                )
                                                : null,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        'Share my profile and application details with ${widget.jobData['companyName'] ?? widget.jobData['company'] ?? 'the company'} for this role.',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Submit button
                          Builder(
                            builder: (context) {
                              final isApplied = widget.jobData['applied'] == true || 
                                               widget.jobData['applicationStatus'] == 'applied';
                              
                              return GestureDetector(
                                onTap: isApplied
                                    ? null // Disable tap if already applied
                                    : () {
                                      Get.to(() => SkillTestScreen(
                                        jobTitle: widget.jobData['jobTitle'] ?? 
                                                 widget.jobData['title'] ?? 
                                                 'Data Center Technician',
                                        company: widget.jobData['companyName'] ?? 
                                                widget.jobData['company'] ?? 
                                                'EdgeCore Systems',
                                        jobData: widget.jobData,
                                        goodFitAnswer: _goodFitController.text.trim(),
                                        startDate: _startDateController.text.trim(),
                                        shareProfile: _shareProfile,
                                      ));
                                    },
                                child: Opacity(
                                  opacity: isApplied ? 0.6 : 1.0,
                                  child: CustomButton(
                                    text: isApplied ? 'Applied' : 'Submit application',
                                    icon: isApplied ? Icons.check_circle : Icons.send_outlined,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12.h),
                          // Footer text
                          Center(
                            child: Text(
                              'By submitting, you confirm your details are accurate and up to date.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
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

  Widget _buildInfoChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatSalary(Map<String, dynamic> jobData) {
    final minPay = jobData['minPay']?.toDouble();
    final maxPay = jobData['maxPay']?.toDouble();
    final salaryType = jobData['salaryType']?.toString().toLowerCase() ?? 'monthly';
    
    // Fallback to hourlyRate if minPay/maxPay not available
    if (minPay == null || maxPay == null) {
      if (jobData['hourlyRate'] != null) {
        return jobData['hourlyRate'].toString();
      }
      return '\$0/hr';
    }
    
    if (salaryType == 'hr' || salaryType == 'hourly') {
      final minPayStr = minPay.toStringAsFixed(0);
      final maxPayStr = maxPay.toStringAsFixed(0);
      return '\$${minPayStr}-\$${maxPayStr}/hr';
    } else {
      final minK = (minPay / 1000).toStringAsFixed(0);
      final maxK = (maxPay / 1000).toStringAsFixed(0);
      return '\$${minK}k-\$${maxK}k';
    }
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return 'Posted recently';
    }
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return 'Posted ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return 'Posted ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return 'Posted ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Posted recently';
      }
    } catch (e) {
      return 'Posted recently';
    }
  }
}
