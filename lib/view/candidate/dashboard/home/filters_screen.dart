import 'package:data_center_job/utils/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  // Job type
  String _selectedJobType = '';

  // Work mode
  String _selectedWorkMode = '';

  // Experience level
  String _selectedExperienceLevel = '';

  // Compensation
  RangeValues _compensationRange = RangeValues(0, 100);

  // Shift
  String _selectedShift = '';

  // Location
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
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
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Clear all filters
                            setState(() {
                              _selectedJobType = '';
                              _selectedWorkMode = '';
                              _selectedExperienceLevel = '';
                              _compensationRange = RangeValues(0, 100);
                              _selectedShift = '';
                              _locationController.clear();
                            });
                          },
                          child: Text(
                            'Clear all',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primaryColor,
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
                          // Job type
                          Text(
                            'Job type',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _buildFilterChip('Full-time', _selectedJobType, (
                                value,
                              ) {
                                setState(() => _selectedJobType = value);
                              }),
                              _buildFilterChip('Part-time', _selectedJobType, (
                                value,
                              ) {
                                setState(() => _selectedJobType = value);
                              }),
                              _buildFilterChip('Contract', _selectedJobType, (
                                value,
                              ) {
                                setState(() => _selectedJobType = value);
                              }),
                              _buildFilterChip('Internship', _selectedJobType, (
                                value,
                              ) {
                                setState(() => _selectedJobType = value);
                              }),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          // Work mode
                          Text(
                            'Work mode',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _buildFilterChip('On-site', _selectedWorkMode, (
                                value,
                              ) {
                                setState(() => _selectedWorkMode = value);
                              }),
                              _buildFilterChip('Hybrid', _selectedWorkMode, (
                                value,
                              ) {
                                setState(() => _selectedWorkMode = value);
                              }),
                              _buildFilterChip('Remote', _selectedWorkMode, (
                                value,
                              ) {
                                setState(() => _selectedWorkMode = value);
                              }),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          // Experience level
                          Text(
                            'Experience level',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _buildFilterChip(
                                'Mid-level',
                                _selectedExperienceLevel,
                                (value) {
                                  setState(
                                    () => _selectedExperienceLevel = value,
                                  );
                                },
                              ),
                              _buildFilterChip(
                                'Entry',
                                _selectedExperienceLevel,
                                (value) {
                                  setState(
                                    () => _selectedExperienceLevel = value,
                                  );
                                },
                              ),
                              _buildFilterChip(
                                'Senior',
                                _selectedExperienceLevel,
                                (value) {
                                  setState(
                                    () => _selectedExperienceLevel = value,
                                  );
                                },
                              ),
                              _buildFilterChip(
                                'Lead',
                                _selectedExperienceLevel,
                                (value) {
                                  setState(
                                    () => _selectedExperienceLevel = value,
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          // Compensation
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
                                      'Compensation',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Hourly or annual',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Range',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'USD',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _compensationRange.start == 0 && _compensationRange.end == 100
                                      ? 'Any compensation'
                                      : '\$${_compensationRange.start.round()}/hr – \$${_compensationRange.end.round()}/hr',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: AppColors.primaryColor,
                                    inactiveTrackColor: Colors.grey[300],
                                    thumbColor: AppColors.primaryColor,
                                    overlayColor: AppColors.primaryColor
                                        .withOpacity(0.2),
                                    trackHeight: 4.h,
                                    thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 8.r,
                                    ),
                                  ),
                                  child: RangeSlider(
                                    values: _compensationRange,
                                    min: 0,
                                    max: 100,
                                    onChanged: (RangeValues values) {
                                      setState(() {
                                        _compensationRange = values;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Min \$${_compensationRange.start.round()}',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Max \$${_compensationRange.end.round()}',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Shift
                          Text(
                            'Shift',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _buildFilterChip('Day', _selectedShift, (value) {
                                setState(() => _selectedShift = value);
                              }),
                              _buildFilterChip('Night', _selectedShift, (
                                value,
                              ) {
                                setState(() => _selectedShift = value);
                              }),
                              _buildFilterChip('Rotational', _selectedShift, (
                                value,
                              ) {
                                setState(() => _selectedShift = value);
                              }),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          // Location
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
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Enter a city or ZIP code to see jobs nearby',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  height: 45.h,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  child: TextField(
                                    controller: _locationController,
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
                                      hintText: 'Enter location',
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
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Apply filters button
                          GestureDetector(
                            onTap: () {
                              // Return filter data
                              final filterData = <String, dynamic>{};
                              
                              if (_selectedJobType.isNotEmpty) {
                                filterData['workType'] = _selectedJobType;
                              }
                              if (_selectedWorkMode.isNotEmpty) {
                                filterData['locationType'] = _selectedWorkMode;
                              }
                              if (_selectedExperienceLevel.isNotEmpty) {
                                filterData['seniority'] = _selectedExperienceLevel;
                              }
                              // Only include compensation if not at default range
                              if (_compensationRange.start > 0 || _compensationRange.end < 100) {
                                filterData['minPay'] = _compensationRange.start.round();
                                filterData['maxPay'] = _compensationRange.end.round();
                              }
                              if (_selectedShift.isNotEmpty) {
                                filterData['shift'] = _selectedShift;
                              }
                              if (_locationController.text.trim().isNotEmpty) {
                                filterData['location'] = _locationController.text.trim();
                              }
                              
                              Get.back(result: filterData);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
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
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Apply filters',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    Function(String) onTap,
  ) {
    bool isSelected = selectedValue == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
