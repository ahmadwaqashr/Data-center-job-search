import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import '../pipeline/pipeline_screen.dart';
import 'new_job_post_screen.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final Dio _dio = Dio();
  
  // Overview stats
  int _openRoles = 0;
  int _activeCandidates = 0;
  int _interviewsToday = 0;
  int _pendingReviews = 0;
  
  // Jobs with candidates
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchOverviewData();
    _fetchJobsWithCandidates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data when screen comes into focus for real-time updates
    if (mounted) {
      _loadUserData();
      _fetchOverviewData();
      _fetchJobsWithCandidates();
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

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _fetchOverviewData() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return;
      if (!mounted) return;
      setState(() => _isLoadingData = true);

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchEmployerOverview),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: jsonEncode({}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (mounted) setState(() {
            _openRoles = _toInt(data['openRoles'] ?? data['openRolesCount']);
            _activeCandidates = _toInt(data['activeCandidates'] ?? data['activeCandidatesCount']);
            _interviewsToday = _toInt(data['interviewsToday'] ?? data['interviewsTodayCount']);
            _pendingReviews = _toInt(data['pendingReviews'] ?? data['pendingReviewsCount']);
            _isLoadingData = false;
          });
        } else {
          if (mounted) setState(() => _isLoadingData = false);
        }
      } else {
        if (mounted) setState(() => _isLoadingData = false);
      }
    } catch (e) {
      if (e is DioException) {}
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _fetchJobsWithCandidates() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token for fetching jobs');
        return;
      }

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchEmployerApplications),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: jsonEncode({}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final jobsData = responseData['data'] as List<dynamic>;
          if (mounted) setState(() {
            _jobs = jobsData.map((job) => job as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (e) {
      if (e is DioException) {}
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        if (mounted) setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) setState(() {
        _isLoading = false;
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
              // Content – pull to refresh overview and jobs
              RefreshIndicator(
                onRefresh: () async {
                  await _fetchOverviewData();
                  await _fetchJobsWithCandidates();
                },
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
                      // Header with greeting and profile
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData?['companyName'] ?? 'Company',
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Track your pipeline and post new\nroles in seconds.',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          CircleAvatar(
                            radius: 24.r,
                            backgroundImage: _userData?['profilePic'] != null || _userData?['logoPath'] != null
                                ? NetworkImage(
                                    ApiConfig.getImageUrl(
                                      _userData!['logoPath'] ?? _userData!['profilePic'],
                                    ),
                                  ) as ImageProvider
                                : AssetImage('assets/images/avatar1.png') as ImageProvider,
                            onBackgroundImageError: (exception, stackTrace) {
                              // Fallback handled by CircleAvatar
                            },
                            child: (_userData?['profilePic'] == null && _userData?['logoPath'] == null)
                                ? Icon(
                                    Icons.business,
                                    color: Colors.grey[600],
                                    size: 24.sp,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      // Search bar and Post button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48.h,
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.grey[400],
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Search roles, candidates...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14.sp,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          GestureDetector(
                            onTap: () {
                              Get.to(() => NewJobPostScreen());
                            },
                            child: Container(
                              height: 48.h,
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(24.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Post',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 28.h),
                      // Overview section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Overview cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildOverviewCard(
                              title: 'Open roles',
                              value: _isLoadingData ? '...' : '$_openRoles',
                              badge: _openRoles > 0 ? '+${_openRoles} this week' : null,
                              subtitle: 'Across all locations',
                              badgeColor: Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildOverviewCard(
                              title: 'Active candidates',
                              value: _isLoadingData ? '...' : '$_activeCandidates',
                              subtitle: 'In your current pipeline',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOverviewCard(
                              title: 'Interviews today',
                              value: _isLoadingData ? '...' : '$_interviewsToday',
                              subtitle: 'Keep candidates',
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildOverviewCard(
                              title: 'Pending reviews',
                              value: _isLoadingData ? '...' : '$_pendingReviews',
                              subtitle: 'Profiles to screen',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 28.h),
                      // Open roles section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Open roles',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Manage your most recent postings',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Job cards
                      if (_isLoadingData && _jobs.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.h),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_jobs.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.h),
                            child: Text(
                              'No jobs posted yet',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._jobs.map((job) {
                          final jobId = job['jobId'] ?? job['id'];
                          final title = job['jobTitle'] ?? 'Job Title';
                          final location = job['location'] ?? 'Location';
                          final workType = job['workType'] ?? 'Full-time';
                          final locationType = job['locationType'] ?? 'On-site';
                          final minPay = job['minPay']?.toDouble() ?? 0.0;
                          final maxPay = job['maxPay']?.toDouble() ?? 0.0;
                          final salaryType = job['salaryType']?.toString().toLowerCase() ?? 'monthly';
                          
                          String salary = '';
                          if (salaryType == 'hr' || salaryType == 'hourly') {
                            salary = '\$${minPay.toStringAsFixed(0)}-\$${maxPay.toStringAsFixed(0)}/hr';
                          } else {
                            final minK = (minPay / 1000).toStringAsFixed(0);
                            final maxK = (maxPay / 1000).toStringAsFixed(0);
                            salary = '\$${minK}k-\$${maxK}k';
                          }
                          
                          final totalCandidates = _toInt(job['totalCandidates'] ?? job['totalCandidatesCount']);
                          final inScreening = _toInt(job['inScreening'] ?? job['inScreeningCount']);
                          final interviews = _toInt(job['interviews'] ?? job['interviewsCount'] ?? job['interviewsToday']);
                          
                          final isPending = totalCandidates == 0 || (totalCandidates > 0 && inScreening == 0 && interviews == 0);
                          
                          return Column(
                            children: [
                              _buildJobCard(
                                title: title,
                                location: location,
                                type: locationType,
                                salary: salary,
                                candidates: '$totalCandidates candidates',
                                screening: inScreening,
                                interviews: interviews,
                                isPending: isPending,
                                jobId: jobId,
                                jobData: job,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String subtitle,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
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
          Text(
            title,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (badge != null) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color:
                        badgeColor?.withOpacity(0.1) ??
                        Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: badgeColor ?? Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard({
    required String title,
    required String location,
    required String type,
    String? salary,
    required String candidates,
    int? screening,
    int? interviews,
    bool isPending = false,
    int? jobId,
    Map<String, dynamic>? jobData,
  }) {
    final totalCandidates = (screening ?? 0) + (interviews ?? 0);
    return GestureDetector(
      onTap: () {
        Get.to(
          () => PipelineScreen(
            jobTitle: title,
            location: location,
            totalCandidates: totalCandidates,
            jobId: jobId,
            jobData: jobData,
          ),
        );
      },
      child: Container(
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  candidates,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              '$location • $type${salary != null ? ' • $salary' : ''}',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isPending && screening != null && interviews != null)
                  Text(
                    '$screening in screening  $interviews interviews',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                  )
                else if (isPending)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    if (isPending)
                      GestureDetector(
                        onTap: () {
                          Get.snackbar(
                            'Boost listing',
                            'Coming soon',
                            backgroundColor: AppColors.primaryColor.withOpacity(0.9),
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: Duration(seconds: 2),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.rocket_launch,
                              color: AppColors.primaryColor,
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Boost listing',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Text(
                            'View pipeline',
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
