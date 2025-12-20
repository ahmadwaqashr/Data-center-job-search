import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import '../pipeline/pipeline_screen.dart';

class EmployerJobsScreen extends StatefulWidget {
  const EmployerJobsScreen({super.key});

  @override
  State<EmployerJobsScreen> createState() => _EmployerJobsScreenState();
}

class _EmployerJobsScreenState extends State<EmployerJobsScreen> {
  int _selectedTab = 0; // 0: Open, 1: Closed, 2: Drafts

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
              SingleChildScrollView(
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
                                ? '3 open'
                                : _selectedTab == 1
                                ? '3 archived'
                                : '2 drafts',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Job listings based on selected tab
                      if (_selectedTab == 0) ..._buildOpenJobs(),
                      if (_selectedTab == 1) ..._buildClosedJobs(),
                      if (_selectedTab == 2) ..._buildDraftJobs(),
                      SizedBox(height: 30.h),
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
    return [
      _buildOpenJobCard(
        title: 'Data Center Technician',
        company: 'EdgeCore Systems',
        location: 'Seattle, WA',
        type: 'On-site',
        salary: '\$38-45/hr',
        schedule: 'Shift-based',
        badge: 'High match',
        badgeColor: Color(0xFF10B981),
        candidates: '12 candidates',
        screening: 4,
        interviews: 2,
        isOpen: true,
        postedTime: 'Posted 2h ago',
      ),
      SizedBox(height: 12.h),
      _buildOpenJobCard(
        title: 'Network Specialist',
        company: 'EdgeCore Systems',
        location: 'Remote (US)',
        salary: '\$80k-95k',
        schedule: 'Full-time',
        additionalInfo: 'Day shifts',
        candidates: '7 candidates',
        screening: 3,
        interviews: 1,
        isOpen: true,
        postedTime: 'Posted yesterday',
      ),
      SizedBox(height: 12.h),
      _buildOpenJobCard(
        title: 'Facilities Technician',
        company: 'EdgeCore Systems',
        location: 'Tacoma, WA',
        type: 'On-site',
        salary: '\$32-38/hr',
        schedule: 'Shift-based',
        badge: 'Priority',
        badgeColor: Color(0xFFEF4444),
        candidates: '5 candidates',
        screening: 2,
        interviews: 0,
        isOpen: true,
        postedTime: 'Posted 3 days ago',
      ),
    ];
  }

  List<Widget> _buildClosedJobs() {
    return [
      _buildClosedJobCard(
        title: 'Data Center Technician',
        company: 'EdgeCore Systems',
        location: 'Seattle, WA',
        type: 'On-site',
        salary: '\$38-45/hr',
        schedule: 'Shift-based',
        badge: 'High match',
        badgeColor: Color(0xFF10B981),
        hires: 1,
        archived: 11,
        filledDays: 18,
        closedDate: 'Filled on Mar 12',
      ),
      SizedBox(height: 12.h),
      _buildClosedJobCard(
        title: 'Network Operations Specialist',
        company: 'EdgeCore Systems',
        location: 'Remote (US)',
        salary: '\$80k-95k',
        schedule: 'Full-time',
        additionalInfo: 'Day shifts',
        hires: 2,
        archived: 9,
        closedBy: 'recruiter',
        closedDate: 'Filled on Feb 28',
      ),
      SizedBox(height: 12.h),
      _buildClosedJobCard(
        title: 'Facilities Technician (Night shift)',
        company: 'EdgeCore Systems',
        location: 'Tacoma, WA',
        type: 'On-site',
        salary: '\$32-38/hr',
        schedule: 'Shift-based',
        badge: 'Priority role',
        badgeColor: Color(0xFFEF4444),
        hires: 0,
        archived: 5,
        closedBy: 'without hire',
        closedDate: 'Archived on Jan 19',
      ),
    ];
  }

  List<Widget> _buildDraftJobs() {
    return [
      _buildDraftJobCard(
        title: 'Senior Data Engineer',
        company: 'EdgeCore Systems',
        location: 'Remote (US)',
        salary: '\$120k-150k',
        schedule: 'Full-time',
        lastEdited: 'Edited 2 days ago',
        completionPercent: 85,
      ),
      SizedBox(height: 12.h),
      _buildDraftJobCard(
        title: 'DevOps Engineer',
        company: 'EdgeCore Systems',
        location: 'Seattle, WA',
        type: 'Hybrid',
        salary: '\$100k-130k',
        schedule: 'Full-time',
        lastEdited: 'Edited 1 week ago',
        completionPercent: 60,
      ),
    ];
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
                      Get.to(
                        () => PipelineScreen(
                          jobTitle: title,
                          location: location,
                          totalCandidates: screening + interviews,
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
