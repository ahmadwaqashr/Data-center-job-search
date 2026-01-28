import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import '../pipeline/pipeline_screen.dart';

class EmployerJobsScreen extends StatefulWidget {
  const EmployerJobsScreen({super.key});

  @override
  State<EmployerJobsScreen> createState() => _EmployerJobsScreenState();
}

class _EmployerJobsScreenState extends State<EmployerJobsScreen> {
  int _selectedTab = 0; // 0: Open, 1: Closed, 2: Drafts
  final Dio _dio = Dio();
  List<Map<String, dynamic>> _openJobs = [];
  List<Map<String, dynamic>> _closedJobs = [];
  List<Map<String, dynamic>> _draftJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    if (authToken != null && authToken.isNotEmpty) return authToken;
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      final token = userData['token']?.toString();
      if (token != null && token.isNotEmpty) return token;
    }
    return null;
  }

  Future<void> _fetchJobs() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _isLoading = true);
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
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final jobsData = responseData['data'] as List<dynamic>;
          final all = jobsData.map((j) => j as Map<String, dynamic>).toList();
          final statusKey = 'status';
          final open = all.where((j) {
            final s = (j[statusKey] ?? 'active').toString().toLowerCase();
            return s == 'active' || s == 'open' || !s.contains('closed') && !s.contains('draft');
          }).toList();
          final closed = all.where((j) {
            final s = (j[statusKey] ?? '').toString().toLowerCase();
            return s.contains('closed') || s == 'archived' || s == 'filled';
          }).toList();
          final draft = all.where((j) {
            final s = (j[statusKey] ?? '').toString().toLowerCase();
            return s.contains('draft');
          }).toList();
          setState(() {
            _openJobs = open.isNotEmpty ? open : all;
            _closedJobs = closed;
            _draftJobs = draft;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (e is DioException) {
        print('❌ Employer jobs fetch: ${e.response?.statusCode} ${e.response?.data}');
      }
      setState(() => _isLoading = false);
    }
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
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
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return dateStr;
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
              // Content – pull to refresh jobs
              RefreshIndicator(
                onRefresh: _fetchJobs,
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
                        // Header
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jobs',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _selectedTab == 0
                                ? 'Track open roles and candidate pipelines'
                                : _selectedTab == 1
                                ? 'Review closed roles and outcomes'
                                : 'Manage your draft postings',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Search bar and Filters
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
                                        hintText:
                                            _selectedTab == 0
                                                ? 'Search roles, locations...'
                                                : 'Search closed roles, locations...',
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
                          Container(
                            height: 48.h,
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Center(
                              child: Text(
                                'Filters',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Tab buttons
                      Row(
                        children: [
                          _buildTabButton('Open', 0),
                          SizedBox(width: 12.w),
                          _buildTabButton('Closed', 1),
                          SizedBox(width: 12.w),
                          _buildTabButton('Drafts', 2),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Active roles header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedTab == 0
                                ? 'Active roles'
                                : _selectedTab == 1
                                ? 'Closed roles'
                                : 'Draft roles',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _selectedTab == 0
                                ? '${_openJobs.length} open'
                                : _selectedTab == 1
                                ? '${_closedJobs.length} archived'
                                : '${_draftJobs.length} drafts',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Job listings based on selected tab
                      if (_isLoading)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                        )
                        else ...(_selectedTab == 0
                            ? _buildOpenJobs()
                            : _selectedTab == 1
                                ? _buildClosedJobs()
                                : _buildDraftJobs()),
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

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOpenJobs() {
    if (_openJobs.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: Text(
              'No open roles',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ),
        ),
      ];
    }
    return _openJobs.map((job) {
      final jobId = job['jobId'] ?? job['id'];
      final title = job['jobTitle'] ?? 'Job Title';
      final company = job['companyName'] ?? 'Company';
      final location = job['location'] ?? 'Location';
      final locationType = job['locationType'] ?? 'On-site';
      final workType = job['workType'] ?? 'Full-time';
      final minPay = job['minPay']?.toDouble() ?? 0.0;
      final maxPay = job['maxPay']?.toDouble() ?? 0.0;
      final salaryType = (job['salaryType'] ?? 'monthly').toString().toLowerCase();
      final salary = (salaryType == 'hr' || salaryType == 'hourly')
          ? '\$${minPay.toStringAsFixed(0)}-\$${maxPay.toStringAsFixed(0)}/hr'
          : '\$${(minPay / 1000).toStringAsFixed(0)}k-\$${(maxPay / 1000).toStringAsFixed(0)}k';
      final totalCandidates = _toInt(job['totalCandidates'] ?? job['totalCandidatesCount']);
      final inScreening = _toInt(job['inScreening'] ?? job['inScreeningCount']);
      final interviews = _toInt(job['interviews'] ?? job['interviewsCount']);
      final postedTime = _formatTimeAgo(job['createdAt']?.toString()) ?? 'Posted';
      return Column(
        children: [
          _buildOpenJobCard(
            title: title,
            company: company,
            location: location,
            type: locationType,
            salary: salary,
            schedule: workType,
            candidates: '$totalCandidates candidates',
            screening: inScreening,
            interviews: interviews,
            isOpen: true,
            postedTime: postedTime.isEmpty ? 'Posted' : 'Posted $postedTime',
            jobId: jobId,
            jobData: job,
          ),
          SizedBox(height: 12.h),
        ],
      );
    }).toList();
  }

  List<Widget> _buildClosedJobs() {
    if (_closedJobs.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: Text(
              'No closed roles',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ),
        ),
      ];
    }
    return _closedJobs.map((job) {
      final title = job['jobTitle'] ?? 'Job Title';
      final company = job['companyName'] ?? 'Company';
      final location = job['location'] ?? 'Location';
      final locationType = job['locationType'] ?? 'On-site';
      final workType = job['workType'] ?? 'Full-time';
      final minPay = job['minPay']?.toDouble() ?? 0.0;
      final maxPay = job['maxPay']?.toDouble() ?? 0.0;
      final salaryType = (job['salaryType'] ?? 'monthly').toString().toLowerCase();
      final salary = (salaryType == 'hr' || salaryType == 'hourly')
          ? '\$${minPay.toStringAsFixed(0)}-\$${maxPay.toStringAsFixed(0)}/hr'
          : '\$${(minPay / 1000).toStringAsFixed(0)}k-\$${(maxPay / 1000).toStringAsFixed(0)}k';
      final totalCandidates = _toInt(job['totalCandidates'] ?? job['totalCandidatesCount']);
      return Column(
        children: [
          _buildClosedJobCard(
            title: title,
            company: company,
            location: location,
            type: locationType,
            salary: salary,
            schedule: workType,
            hires: _toInt(job['hires']),
            archived: totalCandidates,
            closedDate: () {
                              final ago = _formatTimeAgo(job['updatedAt']?.toString());
                              return ago.isNotEmpty ? 'Closed $ago' : 'Closed';
                            }(),
          ),
          SizedBox(height: 12.h),
        ],
      );
    }).toList();
  }

  List<Widget> _buildDraftJobs() {
    if (_draftJobs.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: Text(
              'No draft roles',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ),
        ),
      ];
    }
    return _draftJobs.map((job) {
      final title = job['jobTitle'] ?? 'Job Title';
      final company = job['companyName'] ?? 'Company';
      final location = job['location'] ?? 'Location';
      final locationType = job['locationType'];
      final workType = job['workType'] ?? 'Full-time';
      final minPay = job['minPay']?.toDouble() ?? 0.0;
      final maxPay = job['maxPay']?.toDouble() ?? 0.0;
      final salaryType = (job['salaryType'] ?? 'monthly').toString().toLowerCase();
      final salary = (salaryType == 'hr' || salaryType == 'hourly')
          ? '\$${minPay.toStringAsFixed(0)}-\$${maxPay.toStringAsFixed(0)}/hr'
          : '\$${(minPay / 1000).toStringAsFixed(0)}k-\$${(maxPay / 1000).toStringAsFixed(0)}k';
      final lastEdited = _formatTimeAgo(job['updatedAt']?.toString());
      return Column(
        children: [
          _buildDraftJobCard(
            title: title,
            company: company,
            location: location,
            type: locationType,
            salary: salary,
            schedule: workType,
            lastEdited: lastEdited.isEmpty ? 'Draft' : 'Edited $lastEdited',
            completionPercent: job['completionPercent'] ?? 0,
          ),
          SizedBox(height: 12.h),
        ],
      );
    }).toList();
  }

  Widget _buildOpenJobCard({
    required String title,
    required String company,
    required String location,
    String? type,
    required String salary,
    required String schedule,
    String? additionalInfo,
    String? badge,
    Color? badgeColor,
    required String candidates,
    required int screening,
    required int interviews,
    required bool isOpen,
    required String postedTime,
    dynamic jobId,
    Map<String, dynamic>? jobData,
  }) {
    return Container(
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
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '$company • $location${type != null ? ' • $type' : ''}',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Text(
                '$salary • $schedule',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
              if (additionalInfo != null) ...[
                Text(
                  ' • $additionalInfo',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          if (badge != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color:
                    badgeColor?.withOpacity(0.1) ??
                    Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: badgeColor ?? Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$screening in screening  $interviews interviews',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 36.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Colors.grey[700],
                            size: 18.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 36.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Open • $postedTime',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      final totalRaw = jobData != null
                          ? (jobData['totalCandidates'] ?? jobData['totalCandidatesCount'] ?? screening + interviews)
                          : (screening + interviews);
                      final total = totalRaw is int ? totalRaw : (totalRaw is num ? totalRaw.toInt() : screening + interviews);
                      final id = jobId is int ? jobId : (jobId is num ? jobId.toInt() : null);
                      Get.to(
                        () => PipelineScreen(
                          jobTitle: title,
                          location: location,
                          totalCandidates: total,
                          jobId: id,
                          jobData: jobData,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClosedJobCard({
    required String title,
    required String company,
    required String location,
    String? type,
    required String salary,
    required String schedule,
    String? additionalInfo,
    String? badge,
    Color? badgeColor,
    required int hires,
    required int archived,
    String? closedBy,
    int? filledDays,
    required String closedDate,
  }) {
    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$hires hire${hires != 1 ? 's' : ''} • $archived archived',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (filledDays != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Filled in $filledDays days',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else if (closedBy != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Closed by $closedBy',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '$company • $location${type != null ? ' • $type' : ''}',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Text(
                '$salary • $schedule',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
              if (additionalInfo != null) ...[
                Text(
                  ' • $additionalInfo',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          if (badge != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color:
                    badgeColor?.withOpacity(0.1) ??
                    Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: badgeColor ?? Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Closed • $closedDate',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'View summary',
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
    );
  }

  Widget _buildDraftJobCard({
    required String title,
    required String company,
    required String location,
    String? type,
    required String salary,
    required String schedule,
    required String lastEdited,
    required int completionPercent,
  }) {
    return Container(
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Draft',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '$company • $location${type != null ? ' • $type' : ''}',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 6.h),
          Text(
            '$salary • $schedule',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completionPercent% complete',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          lastEdited,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Stack(
                      children: [
                        Container(
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: completionPercent / 100,
                          child: Container(
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        'Continue editing',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red[400],
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
