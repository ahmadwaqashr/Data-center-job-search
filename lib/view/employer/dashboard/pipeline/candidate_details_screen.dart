import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import '../../../candidate/dashboard/messages/chat_screen.dart';
import 'move_to_interview_screen.dart';

class CandidateDetailsScreen extends StatefulWidget {
  final String candidateName;
  final String experience;
  final String shiftType;
  final String location;
  final String skillTest;
  final String? availability;
  final String matchPercent;
  final String stage;
  final int? candidateId;
  final int? applicationId;
  final Map<String, dynamic>? candidateData;
  final String? jobTitle;
  final String? jobLocation;

  const CandidateDetailsScreen({
    super.key,
    required this.candidateName,
    required this.experience,
    required this.shiftType,
    required this.location,
    required this.skillTest,
    this.availability,
    required this.matchPercent,
    required this.stage,
    this.candidateId,
    this.applicationId,
    this.candidateData,
    this.jobTitle,
    this.jobLocation,
  });

  @override
  State<CandidateDetailsScreen> createState() => _CandidateDetailsScreenState();
}

class _CandidateDetailsScreenState extends State<CandidateDetailsScreen> {
  int _selectedTab = 0; // 0: Profile, 1: CV, 2: Activity
  String? _selectedStage;
  bool _showStageDropdown = false;
  final Dio _dio = Dio();
  bool _isUpdatingStage = false;
  Map<String, dynamic>? _candidateDetails;
  bool _isLoadingDetails = false;
  
  final List<String> _stages = [
    'Pending',
    'Initial screening',
    'Technical interview',
    'Offer & onboarding'
  ];
  
  String _formatStageForDisplay(String stage) {
    if (stage.isEmpty) return stage;
    return stage[0].toUpperCase() + stage.substring(1).toLowerCase();
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      return '${(diff.inDays / 30).floor()}mo ago';
    } catch (_) {
      return dateStr;
    }
  }

  String get _displayName =>
      _candidateDetails?['candidate']?['fullName']?.toString() ??
      _candidateDetails?['candidate']?['fullname']?.toString() ??
      widget.candidateName;

  String get _displayExperience =>
      _candidateDetails?['candidate']?['experienced']?.toString() ??
      _candidateDetails?['candidate']?['experience']?.toString() ??
      widget.experience;

  String get _displayLocation =>
      _candidateDetails?['candidate']?['location']?.toString() ??
      widget.location;

  String get _displaySkillTest {
    final score = _candidateDetails?['application']?['skillTestScore'];
    if (score != null) return '${(score is num ? score.toDouble() : double.tryParse(score.toString()) ?? 0).toStringAsFixed(0)}%';
    return widget.skillTest;
  }

  String get _displayMatch =>
      _candidateDetails?['application']?['matchPercent']?.toString() ??
      widget.matchPercent;

  String? get _displayAvailability =>
      _candidateDetails?['application']?['startDate']?.toString() ??
      widget.availability;

  String get _displayJobTitle =>
      widget.jobTitle ?? _candidateDetails?['application']?['jobTitle']?.toString() ?? 'Job';

  String get _displayJobLocation =>
      widget.jobLocation ?? widget.location;
  
  @override
  void initState() {
    super.initState();
    _selectedStage = widget.stage;
    if (widget.candidateId != null || widget.applicationId != null) {
      _fetchCandidateDetails();
    }
  }

  @override
  void dispose() {
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

  Future<void> _fetchCandidateDetails() async {
    if (widget.applicationId == null && widget.candidateId == null) {
      return;
    }

    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token for fetching candidate details');
        return;
      }

      setState(() {
        _isLoadingDetails = true;
      });

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchCandidateDetails),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: jsonEncode({
          'applicationId': widget.applicationId,
          'candidateId': widget.candidateId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          final app = data['application'] as Map<String, dynamic>?;
          setState(() {
            _candidateDetails = data;
            _selectedStage = app?['stage']?.toString() ?? _selectedStage ?? widget.stage;
            _isLoadingDetails = false;
          });
        } else {
          setState(() {
            _isLoadingDetails = false;
          });
        }
      } else {
        print('⚠️ Candidate Details API returned status: ${response.statusCode}');
        setState(() {
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching candidate details: $e');
      if (e is DioException) {
        print('   Status: ${e.response?.statusCode}');
        print('   Message: ${e.response?.data}');
      }
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _updateCandidateStage(String newStage) async {
    if (widget.applicationId == null) {
      Get.snackbar(
        'Error',
        'Application ID not found',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isUpdatingStage = true;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        Get.snackbar(
          'Error',
          'Authentication required',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() {
          _isUpdatingStage = false;
        });
        return;
      }

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.updateCandidateStage),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: jsonEncode({
          'applicationId': widget.applicationId,
          'stage': newStage.toLowerCase(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          setState(() {
            _selectedStage = newStage;
            _isUpdatingStage = false;
          });
          
          Get.snackbar(
            'Success',
            responseData['message'] ?? 'Stage updated successfully',
            backgroundColor: Color(0xFF10B981),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 2),
          );
          
          // Refresh candidate details after stage update
          _fetchCandidateDetails();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update stage');
        }
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating stage: $e');
      String errorMessage = 'Failed to update stage';
      if (e is DioException) {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      setState(() {
        _isUpdatingStage = false;
      });
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
                    padding: EdgeInsets.all(16),
                    child: Row(
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
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Candidate details',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '$_displayJobTitle • $_displayJobLocation',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            _formatStageForDisplay(_selectedStage ?? widget.stage).replaceAll(' ', '\n'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
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
                          // Candidate info card
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isLoadingDetails && _candidateDetails == null
                                ? Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.h),
                                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                                  )
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Profile avatar
                                    Container(
                                      width: 56.w,
                                      height: 56.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: AssetImage(
                                            'assets/images/avatar6.png',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayName,
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            '$_displayExperience • ${widget.shiftType} • $_displayLocation',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF10B981,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                      ),
                                      child: Text(
                                        'Match\n$_displayMatch',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(.1),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        'Skill test $_displaySkillTest',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    if (_displayAvailability != null && _displayAvailability!.isNotEmpty) ...[
                                      SizedBox(width: 16.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(.1),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Text(
                                          _displayAvailability!,
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    '${_candidateDetails?['application']?['locationType'] ?? _candidateDetails?['candidate']?['locationType'] ?? 'On-site'} • ${_candidateDetails?['application']?['workType'] ?? _candidateDetails?['candidate']?['workType'] ?? widget.shiftType}',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _candidateDetails?['application']?['updatedAt'] != null
                                          ? 'Last updated • ${_formatTimeAgo(_candidateDetails!['application']?['updatedAt']?.toString())}'
                                          : 'Last updated',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(ChatScreen(name: _displayName, avatar: 'avatar', isOnline: true));
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                        ),
                                        child: Text(
                                          'Message',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Status & actions card
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status & actions',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Update where this candidate is in your pipeline.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current stage',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 6.h),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: AppColors.primaryColor,
                                              size: 18.sp,
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              _formatStageForDisplay(_selectedStage ?? widget.stage),
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: AppColors.primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showStageDropdown = !_showStageDropdown;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 5.w,
                                          vertical: 5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Change stage',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(width: 4.w),
                                            Icon(
                                              _showStageDropdown
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              size: 18.sp,
                                              color: Colors.grey[700],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Stage dropdown
                                if (_showStageDropdown) ...[
                                  SizedBox(height: 12.h),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: _stages.map((stage) {
                                        final isSelected = _selectedStage == stage;
                                        return GestureDetector(
                                          onTap: _isUpdatingStage
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _showStageDropdown = false;
                                                  });
                                                  _updateCandidateStage(stage);
                                                },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 12.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primaryColor.withOpacity(0.1)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  stage,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    color: isSelected
                                                        ? AppColors.primaryColor
                                                        : Colors.black,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check,
                                                    color: AppColors.primaryColor,
                                                    size: 20.sp,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Get.to(
                                            () => MoveToInterviewScreen(
                                              candidateName: _displayName,
                                              jobTitle: _displayJobTitle,
                                              currentStage: _selectedStage ?? widget.stage,
                                              applicationId: widget.applicationId,
                                              candidateId: widget.candidateId,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              25.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Move to interview',
                                                style: TextStyle(
                                                  fontSize: 15.sp,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white,
                                                size: 16.sp,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.more_horiz,
                                          size: 18.sp,
                                          color: Colors.grey[700],
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'More',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Tab selector
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Row(
                              children: [
                                _buildTab('Profile', 0),
                                _buildTab('CV', 1),
                                _buildTab('Activity', 2),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Tab content
                          if (_selectedTab == 0) ..._buildProfileTab(),
                          if (_selectedTab == 1) ..._buildCVTab(),
                          if (_selectedTab == 2) ..._buildActivityTab(),
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

  Widget _buildTab(String label, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProfileTab() {
    return [
      // Profile snapshot
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile snapshot',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Key info at a glance',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Headline',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 4.h),
            Text(
              _candidateDetails?['candidate']?['headline']?.toString() ??
                  _candidateDetails?['candidate']?['bio']?.toString() ??
                  '$_displayExperience experience • $_displayLocation',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Experience',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 4.h),
            Text(
              _candidateDetails?['candidate']?['experienceSummary']?.toString() ??
                  _candidateDetails?['candidate']?['experienced']?.toString() ??
                  '$_displayExperience yrs • ${_candidateDetails?['candidate']?['currentCompany'] ?? '—'}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Core skills',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 4.h),
            Text(
              () {
                final skills = _candidateDetails?['candidate']?['skills'];
                if (skills != null) {
                  if (skills is List) return (skills as List).map((e) => e.toString()).join(' • ');
                  return skills.toString();
                }
                return _candidateDetails?['candidate']?['coreSkills']?.toString() ?? '—';
              }(),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildCVTab() {
    return [
      // CV & documents
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CV & documents',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Download all',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Review resume before moving stages.',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 16.h),
            // Resume file
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _candidateDetails?['candidate']?['cvFileName']?.toString() ??
                              _candidateDetails?['candidate']?['cvPath']?.toString().split('/').last ??
                              '${_displayName.replaceAll(' ', '_')}_Resume.pdf',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _candidateDetails?['candidate']?['cvUpdatedDate'] != null
                              ? 'Updated ${_formatTimeAgo(_candidateDetails!['candidate']?['cvUpdatedDate']?.toString())}'
                              : 'Resume',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Skill test report
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Skill test report attached',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                ),
                Row(
                  children: [
                    Text(
                      _displaySkillTest,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '• Skill test',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildActivityTab() {
    return [
      // Recent activity
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent activity',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Add note',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'What changed recently',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 10.h),
            if (_candidateDetails?['activity'] != null && _candidateDetails!['activity'] is List && (_candidateDetails!['activity'] as List).isNotEmpty)
              ...(_candidateDetails!['activity'] as List).map<Widget>((a) {
                final m = a is Map<String, dynamic> ? a : <String, dynamic>{};
                return Padding(
                  padding: EdgeInsets.only(bottom: 5.h),
                  child: _buildActivityItem(
                    m['title']?.toString() ?? m['action']?.toString() ?? 'Activity',
                    m['time']?.toString() ?? _formatTimeAgo(m['createdAt']?.toString()) ?? '—',
                  ),
                );
              }).toList()
            else ...[
              if (_candidateDetails?['application']?['updatedAt'] != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 5.h),
                  child: _buildActivityItem('Stage updated', _formatTimeAgo(_candidateDetails!['application']?['updatedAt']?.toString())),
                ),
              if (_candidateDetails?['application']?['updatedAt'] != null) SizedBox(height: 5.h),
              Padding(
                padding: EdgeInsets.only(bottom: 5.h),
                child: _buildActivityItem(
                  'Application received',
                  _candidateDetails?['application']?['createdAt'] != null
                      ? _formatTimeAgo(_candidateDetails!['application']?['createdAt']?.toString())
                      : '—',
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _buildActivityItem(String title, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 14.sp, color: Colors.grey[700])),
        Text(time, style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
      ],
    );
  }
}
