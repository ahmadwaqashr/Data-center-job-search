import 'package:data_center_job/utils/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import 'quick_apply_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> jobData;

  const JobDetailScreen({super.key, required this.jobData});

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
                                'Job details',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                jobData['jobTitle'] ?? jobData['title'] ?? 'Data Center Technician',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
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
                                  children: [
                                    Container(
                                      width: 50.w,
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: jobData['logoPath'] != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12.r),
                                              child: Image.network(
                                                ApiConfig.getImageUrl(jobData['logoPath'].toString()),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Center(
                                                    child: Icon(
                                                      Icons.business,
                                                      size: 28.sp,
                                                      color: AppColors.primaryColor,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.business,
                                                size: 28.sp,
                                                color: AppColors.primaryColor,
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
                                            jobData['jobTitle'] ?? jobData['title'] ?? 'Data Center Technician',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            '${jobData['companyName'] ?? jobData['company'] ?? 'EdgeCore Systems'} • ${jobData['location'] ?? 'Seattle, WA'}',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatTimeAgo(jobData['createdAt']?.toString()) ?? jobData['postedTime'] ?? 'Posted 2h ago',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildInfoChip(
                                      jobData['workType'] ?? jobData['type'] ?? 'Full-time',
                                    ),
                                    if (jobData['shifts'] != null && (jobData['shifts'] as List).isNotEmpty)
                                      _buildInfoChip(
                                        (jobData['shifts'] as List)[0].toString(),
                                      )
                                    else if (jobData['schedule'] != null)
                                      _buildInfoChip(
                                        jobData['schedule'].toString(),
                                      ),
                                    _buildInfoChip(
                                      jobData['locationType'] ?? jobData['workStyle'] ?? 'On-site',
                                    ),
                                    if (jobData['seniority'] != null)
                                      _buildInfoChip(
                                        jobData['seniority'].toString(),
                                      ),
                                  ],
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
                                          _formatSalary(jobData) ?? jobData['hourlyRate'] ?? '\$38 – 45/hr',
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Estimated hourly rate • Based on experience',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16.sp,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${jobData['location'] ?? 'Seattle, WA'} •',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // About the role
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
                                  'About the role',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                if (jobData['jobDescription'] != null && jobData['jobDescription'].toString().isNotEmpty)
                                  Text(
                                    jobData['jobDescription'].toString(),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[700],
                                      height: 1.5,
                                    ),
                                  )
                                else
                                  Text(
                                    'Join ${jobData['companyName'] ?? jobData['company'] ?? 'EdgeCore Systems'} and help operate a high-availability data center environment, supporting mission-critical infrastructure for global customers.',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[700],
                                      height: 1.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Requirements
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
                                  'Requirements',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                if (jobData['requirements'] != null && jobData['requirements'].toString().isNotEmpty)
                                  _buildBulletPoint(
                                    jobData['requirements'].toString(),
                                  )
                                else
                                  ...[
                                    _buildBulletPoint(
                                      '2+ years in data center operations, IT support, or related field.',
                                    ),
                                    _buildBulletPoint(
                                      'Hands-on experience with server hardware, cabling, and basic networking.',
                                    ),
                                    _buildBulletPoint(
                                      'Comfortable working shift-based schedules, including nights or weekends.',
                                    ),
                                    _buildBulletPoint(
                                      'Ability to lift and move equipment up to 50 lbs safely.',
                                    ),
                                  ],
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Benefits & perks
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
                                  'Benefits & perks',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                if (jobData['banefit'] != null && (jobData['banefit'] as List).isNotEmpty)
                                  ...(jobData['banefit'] as List).map((benefit) => 
                                    _buildBulletPoint(benefit.toString())
                                  ).toList()
                                else if (jobData['benefits'] != null && (jobData['benefits'] as List).isNotEmpty)
                                  ...(jobData['benefits'] as List).map((benefit) => 
                                    _buildBulletPoint(benefit.toString())
                                  ).toList()
                                else
                                  ...[
                                    _buildBulletPoint(
                                      'Competitive hourly pay with overtime eligibility.',
                                    ),
                                    _buildBulletPoint(
                                      'Health, dental, and vision coverage from day one.',
                                    ),
                                    _buildBulletPoint(
                                      'Training budget and certification support for data center and cloud skills.',
                                    ),
                                  ],
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Job details
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
                                      'Job details',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          15.r,
                                        ),
                                      ),
                                      child: Text(
                                        'Quick apply',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      width: 140.w,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Schedule',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            jobData['shifts'] != null && (jobData['shifts'] as List).isNotEmpty
                                                ? (jobData['shifts'] as List)[0].toString()
                                                : jobData['schedule']?.toString() ?? 'Shift-based',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      width: 140.w,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Seniority',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            jobData['seniority']?.toString() ?? 'Mid-level',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      width: 140.w,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Employment type',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            jobData['workType'] ?? jobData['type'] ?? 'Full-time',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      width: 140.w,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'On-site / remote',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            jobData['locationType'] == 'On-site'
                                                ? 'On-site only'
                                                : jobData['locationType'] == 'Remote'
                                                    ? 'Remote only'
                                                    : jobData['locationType']?.toString() ?? 'On-site only',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Quick apply button
                          Builder(
                            builder: (context) {
                              final isApplied = jobData['applied'] == true || 
                                               jobData['applicationStatus'] == 'applied';
                              
                              return GestureDetector(
                                onTap: isApplied
                                    ? null // Disable tap if already applied
                                    : () {
                                      Get.to(() => QuickApplyScreen(jobData: jobData));
                                    },
                                child: Opacity(
                                  opacity: isApplied ? 0.6 : 1.0,
                                  child: CustomButton(
                                    text: isApplied ? 'Applied' : 'Quick apply',
                                    icon: isApplied ? Icons.check_circle : Icons.send_outlined,
                                  ),
                                ),
                              );
                            },
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatSalary(Map<String, dynamic> jobData) {
    final minPay = jobData['minPay']?.toDouble();
    final maxPay = jobData['maxPay']?.toDouble();
    final salaryType = jobData['salaryType']?.toString().toLowerCase() ?? 'monthly';
    
    if (minPay == null || maxPay == null) return null;
    
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

  String? _formatTimeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return null;
    // Simple time formatting - you can enhance this with a proper date package
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
