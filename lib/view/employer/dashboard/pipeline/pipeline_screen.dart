import 'dart:convert';
import 'package:data_center_job/view/employer/dashboard/pipeline/move_to_interview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import '../candidate/move_to_offer_screen.dart';
import 'candidate_details_screen.dart';

class PipelineScreen extends StatefulWidget {
  final String jobTitle;
  final String location;
  final int totalCandidates;
  final int? jobId;
  final Map<String, dynamic>? jobData;

  const PipelineScreen({
    super.key,
    required this.jobTitle,
    required this.location,
    required this.totalCandidates,
    this.jobId,
    this.jobData,
  });

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  final Dio _dio = Dio();
  List<Map<String, dynamic>> _candidates = [];
  bool _isLoadingCandidates = true;
  String? _selectedStageFilter = 'In screening';
  String? _fetchError;

  // Stage counts
  int _appliedCount = 0;
  int _screeningCount = 0;
  int _interviewsCount = 0;
  @override
  void initState() {
    super.initState();
    _fetchCandidates();
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

  Future<void> _fetchCandidates() async {
    if (widget.jobId == null) {
      print('⚠️ Pipeline: jobId is null, skipping fetch');
      setState(() {
        _candidates = [];
        _appliedCount = 0;
        _screeningCount = 0;
        _interviewsCount = 0;
        _isLoadingCandidates = false;
        _fetchError = null;
      });
      return;
    }

    setState(() {
      _fetchError = null;
      _isLoadingCandidates = true;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token for fetching candidates');
        setState(() {
          _isLoadingCandidates = false;
          _fetchError = 'Please sign in again.';
        });
        return;
      }

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchCandidatesByJob),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: jsonEncode({
          'jobId': widget.jobId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final candidatesData = responseData['data'] as List<dynamic>;
          final candidates = candidatesData.map((c) => c as Map<String, dynamic>).toList();

          // Count by stage (match candidate_details_screen stages: Pending, Initial screening, Technical interview, Offer & onboarding)
          int applied = 0, screening = 0, interviews = 0;
          for (var candidate in candidates) {
            final stage = (candidate['stage'] ?? candidate['applicationStatus'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            if (stage.isEmpty || stage.contains('pending') || stage.contains('applied')) {
              applied++;
            } else if (stage.contains('screening') || stage.contains('initial')) {
              screening++;
            } else if (stage.contains('interview') || stage.contains('technical')) {
              interviews++;
            } else if (stage.contains('offer') || stage.contains('onboarding')) {
              interviews++;
            } else {
              applied++;
            }
          }

          setState(() {
            _candidates = candidates;
            _appliedCount = applied;
            _screeningCount = screening;
            _interviewsCount = interviews;
            _isLoadingCandidates = false;
            _fetchError = null;
          });
        } else {
          setState(() {
            _isLoadingCandidates = false;
            _fetchError = 'Could not load candidates.';
          });
        }
      } else {
        print('⚠️ Candidates API returned status: ${response.statusCode}');
        final msg = response.data is Map ? (response.data['message'] ?? 'Server error.') : 'Server error.';
        setState(() {
          _isLoadingCandidates = false;
          _fetchError = msg.toString();
        });
      }
    } catch (e) {
      print('❌ Error fetching candidates: $e');
      if (e is DioException) {
        print('   Status: ${e.response?.statusCode}');
        print('   Message: ${e.response?.data}');
      }
      String message = 'Unable to load candidates. Please try again.';
      if (e is DioException && e.response?.statusCode != null) {
        final code = e.response!.statusCode!;
        final serverMsg = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
        if (code == 401) {
          message = serverMsg ?? 'Session expired. Please sign in again.';
        } else if (code == 403) {
          message = serverMsg ?? 'You don\'t have access to this job.';
        } else if (code == 400) {
          message = serverMsg ?? 'Invalid request.';
        } else if (code == 500) {
          message = serverMsg ?? 'Server error. Please try again later or check with your admin.';
        } else if (serverMsg != null && serverMsg.isNotEmpty) {
          message = serverMsg;
        }
      }
      setState(() {
        _isLoadingCandidates = false;
        _fetchError = message;
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
                                'Pipeline',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${widget.jobTitle} • ${widget.location}',
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
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_isLoadingCandidates ? widget.totalCandidates : _candidates.length}\ncandidates',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              height: 1.3,
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
                          // Job details card
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.jobTitle,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(.1),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Text(
                                        'High match',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  '${widget.jobData?['companyName'] ?? 'Company'} • ${widget.location} • ${widget.jobData?['locationType'] ?? 'On-site'}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final minPay = widget.jobData?['minPay']?.toDouble() ?? 0.0;
                                        final maxPay = widget.jobData?['maxPay']?.toDouble() ?? 0.0;
                                        final salaryType = widget.jobData?['salaryType']?.toString().toLowerCase() ?? 'monthly';
                                        String salary = '';
                                        if (salaryType == 'hr' || salaryType == 'hourly') {
                                          salary = '\$${minPay.toStringAsFixed(0)}-\$${maxPay.toStringAsFixed(0)}/hr';
                                        } else {
                                          final minK = (minPay / 1000).toStringAsFixed(0);
                                          final maxK = (maxPay / 1000).toStringAsFixed(0);
                                          salary = '\$${minK}k-\$${maxK}k';
                                        }
                                        return Text(
                                          '$salary • ${widget.jobData?['workType'] ?? 'Full-time'} • Posted ${_formatTimeAgo(widget.jobData?['createdAt']?.toString())}',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(
                                                  .1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                '${widget.totalCandidates} candidates',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 5.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(
                                                  .1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Text(
                                                '$_screeningCount in screening',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Text(
                                            '$_interviewsCount interviews',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Job ID • #${widget.jobData?['referenceId'] ?? widget.jobId ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pipeline overview',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'View board',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.primaryColor,
                                    size: 14.sp,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Track candidates by stage.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Pipeline overview card
                          Row(
                            children: [
                              Expanded(
                                child: _buildPipelineStageCard(
                                  'Applied',
                                  '$_appliedCount',
                                  (_candidates.isNotEmpty)
                                      ? '${((_appliedCount / _candidates.length) * 100).toStringAsFixed(0)}%'
                                      : '0%',
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildPipelineStageCard(
                                  'In screening',
                                  '$_screeningCount',
                                  (_candidates.isNotEmpty)
                                      ? '${((_screeningCount / _candidates.length) * 100).toStringAsFixed(0)}%'
                                      : '0%',
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildPipelineStageCard(
                                  'Interviews',
                                  '$_interviewsCount',
                                  (_candidates.isNotEmpty)
                                      ? '${((_interviewsCount / _candidates.length) * 100).toStringAsFixed(0)}%'
                                      : '0%',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          // Stage selector and candidates
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_selectedStageFilter • ${_candidates.where((c) {
                                      final stage = c['stage']?.toString().toLowerCase() ?? 
                                                   c['applicationStatus']?.toString().toLowerCase() ?? '';
                                      if (_selectedStageFilter == 'In screening') {
                                        return stage.contains('screening');
                                      } else if (_selectedStageFilter == 'Interviews') {
                                        return stage.contains('interview');
                                      } else if (_selectedStageFilter == 'Applied') {
                                        return stage.contains('pending') || stage.contains('applied');
                                      }
                                      return true;
                                    }).length} candidates',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Sorted by match score',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Show stage filter dropdown
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      padding: EdgeInsets.all(20.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Filter by stage',
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          ...['Applied', 'In screening', 'Interviews'].map((stage) {
                                            return ListTile(
                                              title: Text(stage),
                                              trailing: _selectedStageFilter == stage
                                                  ? Icon(Icons.check, color: AppColors.primaryColor)
                                                  : null,
                                              onTap: () {
                                                setState(() {
                                                  _selectedStageFilter = stage;
                                                });
                                                Navigator.pop(context);
                                              },
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'Stage',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 18.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Current stage • $_selectedStageFilter',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Candidate cards
                          if (_isLoadingCandidates)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.h),
                                child: CircularProgressIndicator(color: AppColors.primaryColor),
                              ),
                            )
                          else if (_fetchError != null)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.h),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline, size: 48.sp, color: Colors.grey),
                                    SizedBox(height: 12.h),
                                    Text(
                                      _fetchError!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    TextButton.icon(
                                      onPressed: () => _fetchCandidates(),
                                      icon: Icon(Icons.refresh, size: 18.sp),
                                      label: Text('Retry'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_candidates.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.h),
                                child: Text(
                                  'No candidates found',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._candidates.where((candidate) {
                              final stage = (candidate['stage'] ?? candidate['applicationStatus'] ?? '')
                                  .toString()
                                  .trim()
                                  .toLowerCase();
                              if (_selectedStageFilter == 'In screening') {
                                return stage.contains('screening') || stage.contains('initial');
                              } else if (_selectedStageFilter == 'Interviews') {
                                return stage.contains('interview') || stage.contains('technical') ||
                                       stage.contains('offer') || stage.contains('onboarding');
                              } else if (_selectedStageFilter == 'Applied') {
                                return stage.isEmpty || stage.contains('pending') || stage.contains('applied');
                              }
                              return true;
                            }).map((candidate) {
                              final applicationId = candidate['id'] ?? candidate['applicationId'];
                              final candidateId = candidate['candidateId'] ?? candidate['candidate']?['id'];
                              final candidateData = candidate['candidate'] ?? {};
                              final name = candidateData['fullName'] ?? 
                                          candidateData['fullname'] ?? 
                                          candidate['candidateName'] ?? 
                                          'Candidate';
                              final experience = candidateData['experienced']?.toString() ?? 
                                               candidateData['experience']?.toString() ?? 
                                               'N/A';
                              final location = candidateData['location'] ?? 'Location';
                              final skillTestScore = candidate['skillTestScore']?.toDouble() ?? 
                                                   candidate['skillTestScore']?.toDouble() ?? 
                                                   0.0;
                              final matchPercent = candidate['matchPercent']?.toString() ?? 
                                                  candidate['matchPercentage']?.toString() ?? 
                                                  '0%';
                              final stage = candidate['stage'] ?? 
                                          candidate['applicationStatus'] ?? 
                                          'Pending';
                              
                              return Column(
                                children: [
                                  _buildCandidateCard(
                                    name: name,
                                    experience: '$experience yrs',
                                    shiftType: 'Shift-based',
                                    location: location,
                                    skillTest: '${skillTestScore.toStringAsFixed(0)}%',
                                    availability: candidate['startDate']?.toString(),
                                    matchPercent: matchPercent,
                                    actionText: stage == 'In screening' ? 'Move to interview' : 'View details',
                                    actionIcon: stage == 'In screening' ? null : Icons.arrow_forward,
                                    stage: stage.toString(),
                                    actionType: stage.toString().toLowerCase().contains('screening') ? 'interview' : 'details',
                                    candidateId: _toInt(candidateId),
                                    candidateData: {
                                      ...candidate,
                                      'id': _toInt(applicationId),
                                    },
                                  ),
                                  SizedBox(height: 12.h),
                                ],
                              );
                            }).toList(),
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

  Widget _buildPipelineStageCard(String title, String count, String percent) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  percent,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return 'recently';
    }
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}${difference.inDays == 1 ? ' day' : ' days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}${difference.inHours == 1 ? ' hour' : ' hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}${difference.inMinutes == 1 ? ' minute' : ' minutes'} ago';
      } else {
        return 'recently';
      }
    } catch (e) {
      return 'recently';
    }
  }

  /// Coerce API value (int, num, or null) to int? for screen params
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Widget _buildCandidateCard({
    required String name,
    required String experience,
    required String shiftType,
    required String location,
    required String skillTest,
    String? availability,
    required String matchPercent,
    required String actionText,
    IconData? actionIcon,
    required String stage,
    String? actionType, // 'interview', 'offer', or 'details'
    int? candidateId,
    Map<String, dynamic>? candidateData,
  }) {
    final applicationId = _toInt(candidateData?['id']);
    final cId = _toInt(candidateId);
    return GestureDetector(
      onTap: () {
        try {
          Get.to(
            () => CandidateDetailsScreen(
              candidateName: name,
              experience: experience,
              shiftType: shiftType,
              location: location,
              skillTest: skillTest,
              availability: availability,
              matchPercent: matchPercent,
              stage: stage,
              candidateId: cId,
              applicationId: applicationId,
              candidateData: candidateData,
              jobTitle: widget.jobTitle,
              jobLocation: widget.location,
            ),
          );
        } catch (e) {
          print('❌ Navigation error: $e');
          Get.snackbar(
            'Error',
            'Failed to navigate: ${e.toString()}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
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
            children: [
              // Profile avatar
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/avatar6.png'),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$experience • $shiftType • $location',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Match $matchPercent',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Skill test $skillTest',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                ),
              ),
              if (availability != null) ...[
                SizedBox(width: 16.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    availability,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    actionIcon ?? Icons.arrow_forward,
                    color: AppColors.primaryColor,
                    size: 14.sp,
                  ),
                ],
              ),
              Text(
                stage,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
