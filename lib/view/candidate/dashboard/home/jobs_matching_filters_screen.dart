import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import 'filters_screen.dart';
import 'job_detail_screen.dart';

class JobsMatchingFiltersScreen extends StatefulWidget {
  const JobsMatchingFiltersScreen({super.key});

  @override
  State<JobsMatchingFiltersScreen> createState() =>
      _JobsMatchingFiltersScreenState();
}

class _JobsMatchingFiltersScreenState extends State<JobsMatchingFiltersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _appliedFilters = {};

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _fetchJobs({Map<String, dynamic>? filters}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (filters != null) {
        _appliedFilters = filters;
      }
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'No authentication token found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // Build filter payload
      final filterPayload = <String, dynamic>{};
      
      // Add search term if present
      if (_searchController.text.trim().isNotEmpty) {
        filterPayload['search'] = _searchController.text.trim();
      }
      
      // Add filters if present
      if (_appliedFilters != null) {
        if (_appliedFilters!['workType'] != null && _appliedFilters!['workType'].toString().isNotEmpty) {
          filterPayload['workType'] = _appliedFilters!['workType'];
        }
        if (_appliedFilters!['locationType'] != null && _appliedFilters!['locationType'].toString().isNotEmpty) {
          filterPayload['locationType'] = _appliedFilters!['locationType'];
        }
        if (_appliedFilters!['seniority'] != null && _appliedFilters!['seniority'].toString().isNotEmpty) {
          filterPayload['seniority'] = _appliedFilters!['seniority'];
        }
        if (_appliedFilters!['minPay'] != null) {
          filterPayload['minPay'] = _appliedFilters!['minPay'];
        }
        if (_appliedFilters!['maxPay'] != null) {
          filterPayload['maxPay'] = _appliedFilters!['maxPay'];
        }
        if (_appliedFilters!['shift'] != null && _appliedFilters!['shift'].toString().isNotEmpty) {
          filterPayload['shift'] = _appliedFilters!['shift'];
        }
        if (_appliedFilters!['location'] != null && _appliedFilters!['location'].toString().isNotEmpty) {
          filterPayload['location'] = _appliedFilters!['location'];
        }
      }

      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      print('📡 Fetching jobs with filters:');
      print('   Filters: $filterPayload');
      
      var response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchJob),
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: jsonEncode(filterPayload),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _jobs = List<Map<String, dynamic>>.from(responseData['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to load jobs';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.statusMessage ?? 'Failed to load jobs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading jobs: ${e.toString()}';
        _isLoading = false;
      });
      print('Error fetching jobs: $e');
    }
  }

  String _formatSalary(Map<String, dynamic> job) {
    final minPay = job['minPay']?.toDouble() ?? 0.0;
    final maxPay = job['maxPay']?.toDouble() ?? 0.0;
    final salaryType = job['salaryType']?.toString().toLowerCase() ?? 'monthly';
    
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
    if (createdAt == null) return 'Posted recently';
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

  String _getFilterSummary() {
    final parts = <String>[];
    if (_appliedFilters?['location'] != null) {
      parts.add(_appliedFilters!['location'].toString());
    }
    if (_appliedFilters?['workType'] != null) {
      parts.add(_appliedFilters!['workType'].toString());
    }
    if (_appliedFilters?['locationType'] != null) {
      parts.add(_appliedFilters!['locationType'].toString());
    }
    if (_appliedFilters?['minPay'] != null && _appliedFilters?['maxPay'] != null) {
      parts.add('\$${_appliedFilters!['minPay']}-\$${_appliedFilters!['maxPay']}/hr');
    }
    return parts.isEmpty ? 'No filters applied' : parts.join(' • ');
  }

  List<Widget> _getFilterChips() {
    final chips = <Widget>[];
    if (_appliedFilters?['location'] != null) {
      chips.add(_buildFilterChip(_appliedFilters!['location'].toString()));
    }
    if (_appliedFilters?['workType'] != null) {
      chips.add(_buildFilterChip(_appliedFilters!['workType'].toString()));
    }
    if (_appliedFilters?['locationType'] != null) {
      chips.add(_buildFilterChip(_appliedFilters!['locationType'].toString()));
    }
    if (_appliedFilters?['seniority'] != null) {
      chips.add(_buildFilterChip(_appliedFilters!['seniority'].toString()));
    }
    if (_appliedFilters?['minPay'] != null && _appliedFilters?['maxPay'] != null) {
      chips.add(_buildFilterChip('\$${_appliedFilters!['minPay']}-\$${_appliedFilters!['maxPay']}/hr'));
    }
    return chips;
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
                                'Jobs matching filters',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Showing roles near your chosen location.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search bar and filters button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                // Search will be triggered on submit or when filters are applied
                              },
                              onSubmitted: (value) {
                                // Trigger search when user presses enter
                                _fetchJobs();
                              },
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[500],
                                  size: 22.sp,
                                ),
                                hintText: 'Search roles, companies...',
                                hintStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[500],
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        GestureDetector(
                          onTap: () async {
                            final filterResult = await Get.to(() => const FiltersScreen());
                            if (filterResult != null) {
                              _fetchJobs(filters: filterResult as Map<String, dynamic>);
                            }
                          },
                          child: Container(
                            width: 90.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'Filters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filters applied section
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
                                    Text(
                                      'Filters applied',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${_jobs.length} jobs',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (_appliedFilters != null && _appliedFilters!.isNotEmpty)
                                          ...[
                                            SizedBox(width: 12.w),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _appliedFilters = {};
                                                  _searchController.clear();
                                                });
                                                _fetchJobs();
                                              },
                                              child: Text(
                                                'Clear',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  _getFilterSummary(),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                // Filter chips
                                if (_getFilterChips().isNotEmpty)
                                  Wrap(
                                    spacing: 8.w,
                                    runSpacing: 8.h,
                                    children: _getFilterChips(),
                                  )
                                else
                                  Text(
                                    'No filters applied',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Recommended for you section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recommended\nfor you',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Based on your skills\nand filters',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Search button (if search text exists)
                          if (_searchController.text.trim().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: GestureDetector(
                                onTap: () => _fetchJobs(),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Search "${_searchController.text.trim()}"',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Job cards
                          if (_isLoading)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.h),
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            )
                          else if (_errorMessage != null)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.h),
                                child: Column(
                                  children: [
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.red,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16.h),
                                    ElevatedButton(
                                      onPressed: () => _fetchJobs(),
                                      child: Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_jobs.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.h),
                                child: Text(
                                  'No jobs found matching your filters',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            ..._jobs.map((job) {
                              final shifts = (job['shifts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                              final tags = [
                                job['workType']?.toString() ?? 'Full-time',
                                if (job['seniority'] != null) job['seniority'].toString(),
                                if (shifts.isNotEmpty) shifts[0],
                              ].where((e) => e != null && e.isNotEmpty).toList();
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: _buildJobCard(
                                  {
                                    'title': job['jobTitle']?.toString() ?? 'Job Title',
                                    'company': job['companyName']?.toString() ?? 'Company',
                                    'type': job['workType']?.toString() ?? 'Full-time',
                                    'schedule': shifts.isNotEmpty ? shifts[0] : 'Shift-based',
                                    'workStyle': job['locationType']?.toString() ?? 'On-site',
                                    'hourlyRate': _formatSalary(job),
                                    'location': job['location']?.toString() ?? 'Location',
                                    'postedTime': _formatTimeAgo(job['createdAt']?.toString()),
                                    'matchLevel': 'New',
                                    'matchColor': Color(0xFF10B981),
                                    ...job, // Include full job data
                                  },
                                ),
                              );
                            }).toList(),
                          SizedBox(height: 16.h),
                          // Bottom text
                          Center(
                            child: Text(
                              'Refine your filters anytime to see more or fewer roles in this area.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
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

  Widget _buildFilterChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    // Use API field names with fallbacks
    final title = job['jobTitle'] ?? job['title'] ?? 'Job Title';
    final company = job['companyName'] ?? job['company'] ?? 'Company';
    final workType = job['workType'] ?? job['type'] ?? 'Full-time';
    final location = job['location'] ?? 'Location';
    final postedTime = job['postedTime'] ?? _formatTimeAgo(job['createdAt']?.toString()) ?? 'Posted recently';
    final shifts = (job['shifts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final schedule = shifts.isNotEmpty ? shifts[0] : (job['schedule'] ?? 'Shift-based');
    final workStyle = job['locationType'] ?? job['workStyle'] ?? 'On-site';
    final hourlyRate = job['hourlyRate'] ?? _formatSalary(job) ?? '\$0/hr';
    final matchLevel = job['matchLevel'] ?? 'New';
    final matchColor = job['matchColor'] ?? Color(0xFF10B981);
    
    return GestureDetector(
      onTap: () => Get.to(() => JobDetailScreen(jobData: job)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and match badge
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
                    color: matchColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Text(
                    matchLevel,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: matchColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // Company and type
            Text(
              '$company • $workType',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            // Tags
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildJobTag(schedule),
                _buildJobTag(workStyle),
                _buildJobTag(hourlyRate),
              ],
            ),
            SizedBox(height: 12.h),
            // Location, time and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        postedTime,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Quick apply',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.bookmark_border,
                      size: 24.sp,
                      color: Colors.grey[600],
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

  Widget _buildJobTag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
      ),
    );
  }
}
