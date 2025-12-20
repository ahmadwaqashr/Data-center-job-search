import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';

class SkillsPreferencesScreen extends StatefulWidget {
  const SkillsPreferencesScreen({super.key});

  @override
  State<SkillsPreferencesScreen> createState() =>
      _SkillsPreferencesScreenState();
}

class _SkillsPreferencesScreenState extends State<SkillsPreferencesScreen> {
  List<Map<String, dynamic>> _coreSkills = [
    {'name': 'Data center operations', 'isPrimary': true},
    {'name': 'Hardware troubleshooting', 'isPrimary': false},
    {'name': 'Network monitoring', 'isPrimary': false},
  ];

  String _selectedRoleFocus = 'Technician / Specialist';
  String _selectedWorkStyle = 'On-site';
  String _selectedAvailability = 'Full-time';

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
                                  'Skills & preferences',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Tune your matches based on your strengths.',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
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
                  ),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),
                          // Core skills section
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
                                  'Core skills',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Update the skills you want recruiters to see first.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Search and add skills header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Search and add skills',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Container(
                                      width: 8.w,
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Search field
                                Container(
                                  height: 45.h,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  child: TextField(
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
                                      hintText: 'Start typing to find skills',
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
                                SizedBox(height: 16.h),
                                // Skills list
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children:
                                      _coreSkills.map((skill) {
                                        return _buildSkillChip(
                                          skill['name'],
                                          isPrimary: skill['isPrimary'],
                                          onDelete: () {
                                            setState(() {
                                              _coreSkills.remove(skill);
                                            });
                                          },
                                        );
                                      }).toList(),
                                ),
                                SizedBox(height: 12.h),
                                // Add skill button (disabled)
                                Opacity(
                                  opacity: 0.5,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: AppColors.primaryColor,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Add skill',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Preferred roles section
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
                                  'Preferred roles',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Help us prioritize roles that match how you want to work.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Role focus
                                Text(
                                  'Role focus',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildSelectableChip(
                                      'Technician / Specialist',
                                      _selectedRoleFocus ==
                                          'Technician / Specialist',
                                      () {
                                        setState(() {
                                          _selectedRoleFocus =
                                              'Technician / Specialist';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Engineer',
                                      _selectedRoleFocus == 'Engineer',
                                      () {
                                        setState(() {
                                          _selectedRoleFocus = 'Engineer';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Supervisor',
                                      _selectedRoleFocus == 'Supervisor',
                                      () {
                                        setState(() {
                                          _selectedRoleFocus = 'Supervisor';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                // Work style
                                Text(
                                  'Work style',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildSelectableChip(
                                      'On-site',
                                      _selectedWorkStyle == 'On-site',
                                      () {
                                        setState(() {
                                          _selectedWorkStyle = 'On-site';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Hybrid',
                                      _selectedWorkStyle == 'Hybrid',
                                      () {
                                        setState(() {
                                          _selectedWorkStyle = 'Hybrid';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Remote',
                                      _selectedWorkStyle == 'Remote',
                                      () {
                                        setState(() {
                                          _selectedWorkStyle = 'Remote';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'You can always adjust this per-application.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Location & schedule section
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
                                  'Location & schedule',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Set where and when you\'re available to work.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Preferred locations
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Preferred locations',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Container(
                                      width: 8.w,
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Add cities or regions field
                                Container(
                                  height: 45.h,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  child: TextField(
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.grey[500],
                                        size: 22.sp,
                                      ),
                                      hintText: 'Add cities or regions',
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
                                SizedBox(height: 12.h),
                                // Location chip
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Seattle, WA',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '25 mi radius',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(width: 6.w),
                                          Icon(
                                            Icons.close,
                                            size: 16.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.add,
                                          color: AppColors.primaryColor,
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Add location',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                // Availability
                                Text(
                                  'Availability',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildSelectableChip(
                                      'Full-time',
                                      _selectedAvailability == 'Full-time',
                                      () {
                                        setState(() {
                                          _selectedAvailability = 'Full-time';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Part-time',
                                      _selectedAvailability == 'Part-time',
                                      () {
                                        setState(() {
                                          _selectedAvailability = 'Part-time';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Weekends',
                                      _selectedAvailability == 'Weekends',
                                      () {
                                        setState(() {
                                          _selectedAvailability = 'Weekends';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Save changes button
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: () {
                                Get.back();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Save changes',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
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

  Widget _buildSkillChip(
    String label, {
    bool isPrimary = false,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isPrimary) ...[
            SizedBox(width: 6.w),
            Text(
              'Primary',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isSelected ? AppColors.primaryColor : Colors.black,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
