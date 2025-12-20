import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../constants/colors.dart';
import 'application_detail_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _allApplications = [
    {
      'title': 'Data Center Technician',
      'company': 'EdgeCore Systems • Seattle, WA',
      'applied': 'Applied 3 days ago',
      'details': 'Full-time • On-site',
      'updated': 'Updated 2h ago',
      'stage': 'Stage 2 of 4 • Hiring manager review',
      'status': 'In review',
      'statusColor': Color(0xFF2563EB),
      'progress': 2,
    },
    {
      'title': 'Operations Engineer',
      'company': 'Nimbus Cloud • Austin, TX',
      'applied': 'Applied 1 week ago',
      'details': 'Hybrid • Mid-level',
      'updated': 'Interview tomorrow',
      'stage': 'Stage 3 of 4 • On-site interview',
      'status': 'Interview',
      'statusColor': Color(0xFF10B981),
      'progress': 3,
    },
    {
      'title': 'Facilities Specialist',
      'company': 'CoreRack Data Centers • Remote',
      'applied': 'Applied 3 weeks ago',
      'details': 'Remote • Full-time',
      'updated': 'Offer received',
      'stage': 'Stage 4 of 4 • Offer negotiation',
      'status': 'Offer',
      'statusColor': Color(0xFFF59E0B),
      'progress': 4,
    },
    {
      'title': 'Junior Data Technician',
      'company': 'SkyStack Hosting • Denver, CO',
      'applied': 'Applied 1 month ago',
      'details': 'Entry • On-site',
      'updated': 'Closed 4d ago',
      'stage': 'Application closed by auth',
      'status': 'Closed',
      'statusColor': Color(0xFFEF4444),
      'progress': 0,
    },
  ];

  List<Map<String, dynamic>> get _filteredApplications {
    if (_selectedFilter == 'All') {
      return _allApplications;
    }
    return _allApplications
        .where((app) => app['status'] == _selectedFilter)
        .toList();
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
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Applications',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          CircleAvatar(
                            radius: 20.r,
                            backgroundImage: AssetImage(
                              'assets/images/avatar1.png',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Search bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.grey[400],
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search by role or company...',
                                        hintStyle: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[400],
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.4),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            SizedBox(width: 8.w),
                            _buildFilterChip('In review'),
                            SizedBox(width: 8.w),
                            _buildFilterChip('Interview'),
                            SizedBox(width: 8.w),
                            _buildFilterChip('Offer'),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Application cards
                      ..._filteredApplications.map(
                        (app) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildApplicationCard(
                            applicationData: app,
                            title: app['title'],
                            company: app['company'],
                            applied: app['applied'],
                            details: app['details'],
                            updated: app['updated'],
                            stage: app['stage'],
                            status: app['status'],
                            statusColor: app['statusColor'],
                            progress: app['progress'],
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
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard({
    required Map<String, dynamic> applicationData,
    required String title,
    required String company,
    required String applied,
    required String details,
    required String updated,
    required String stage,
    required String status,
    required Color statusColor,
    required int progress,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Company logo placeholder
              Container(
                width: 37.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: Color(0xFFE8E9F3),
                  borderRadius: BorderRadius.circular(10.r),
                  image: DecorationImage(
                    image: AssetImage('assets/images/avatar2.png'),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      company,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '$applied • $details',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 4.h),
          Text(
            updated,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          // Progress indicator
          if (progress > 0)
            Row(
              children: [
                Row(
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 8.w,
                      height: 8.h,
                      margin: EdgeInsets.only(right: 4.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            index < progress
                                ? AppColors.primaryColor
                                : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10..w),
                Expanded(
                  child: Text(
                    stage,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ApplicationDetailScreen(
                              applicationData: applicationData,
                            ),
                      ),
                    );
                  },
                  child: Text(
                    'View',
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
}
