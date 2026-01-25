import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import 'skill_test_questions_screen.dart';

class NewJobPostScreen extends StatefulWidget {
  const NewJobPostScreen({super.key});

  @override
  State<NewJobPostScreen> createState() => _NewJobPostScreenState();
}

class _NewJobPostScreenState extends State<NewJobPostScreen> {
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPayController = TextEditingController();
  final TextEditingController _maxPayController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _skillSearchController = TextEditingController();
  final TextEditingController _shiftSearchController = TextEditingController();
  final TextEditingController _benefitSearchController = TextEditingController();

  String selectedWorkType = 'Full-time';
  String selectedLocationType = 'On-site';
  String selectedSalaryType = 'Monthly';

  List<String> shifts = [
    'Night shifts',
    '12-hour shifts',
    'Day shifts',
    'Weekend shifts',
  ];
  String? selectedShift;
  String _shiftSearchQuery = '';

  List<String> skills = [];
  List<String> selectedSkills = [];
  String _skillSearchQuery = '';

  List<String> benefits = [];
  String _benefitSearchQuery = '';
  List<String> selectedBenefits = [];

  List<String> seniorityOptions = ['Expert', 'Mid-level', 'Entry-level', 'Senior', 'Junior'];
  String? selectedSeniority;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _minPayController.dispose();
    _maxPayController.dispose();
    _jobDescriptionController.dispose();
    _requirementsController.dispose();
    _skillSearchController.dispose();
    _shiftSearchController.dispose();
    _benefitSearchController.dispose();
    super.dispose();
  }

  void _addShiftFromSearch() {
    final value = _shiftSearchController.text.trim();
    if (value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a shift to add',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final exists =
        shifts.any((shift) => shift.toLowerCase() == value.toLowerCase());
    setState(() {
      if (!exists) {
        shifts.add(value);
      }
      selectedShift = value;
      _shiftSearchController.clear();
      _shiftSearchQuery = '';
    });
  }

  void _addSkillFromSearch() {
    final value = _skillSearchController.text.trim();
    if (value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a skill to add',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final exists =
        skills.any((skill) => skill.toLowerCase() == value.toLowerCase());
    setState(() {
      if (!exists) {
        skills.add(value);
      }
      if (!selectedSkills.contains(value)) {
        selectedSkills.add(value);
      }
      _skillSearchController.clear();
      _skillSearchQuery = '';
    });
  }

  void _addBenefitFromSearch() {
    final value = _benefitSearchController.text.trim();
    if (value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a benefit to add',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final exists =
        benefits.any((benefit) => benefit.toLowerCase() == value.toLowerCase());
    setState(() {
      if (!exists) {
        benefits.add(value);
      }
      if (!selectedBenefits.contains(value)) {
        selectedBenefits.add(value);
      }
      _benefitSearchController.clear();
      _benefitSearchQuery = '';
    });
  }

  bool get isJobTitleFilled => _jobTitleController.text.isNotEmpty;
  bool get isCompanyFilled => _companyController.text.isNotEmpty;
  bool get isPayRangeFilled =>
      _minPayController.text.isNotEmpty && _maxPayController.text.isNotEmpty;
  bool get isJobDescriptionFilled => _jobDescriptionController.text.isNotEmpty;

  bool _validateJobPost() {
    final title = _jobTitleController.text.trim();
    final company = _companyController.text.trim();
    final location = _locationController.text.trim();
    final description = _jobDescriptionController.text.trim();
    final requirements = _requirementsController.text.trim();
    final minPay = double.tryParse(_minPayController.text.trim());
    final maxPay = double.tryParse(_maxPayController.text.trim());

    if (title.isEmpty || title.length < 3) {
      Get.snackbar(
        'Error',
        'Job title is required (min 3 characters)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (company.isEmpty) {
      Get.snackbar(
        'Error',
        'Company name is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (location.isEmpty) {
      Get.snackbar(
        'Error',
        'Location is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (minPay == null || minPay <= 0) {
      Get.snackbar(
        'Error',
        'Minimum pay must be a valid number',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (maxPay == null || maxPay <= 0) {
      Get.snackbar(
        'Error',
        'Maximum pay must be a valid number',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (maxPay < minPay) {
      Get.snackbar(
        'Error',
        'Max pay must be greater than or equal to min pay',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (description.length < 30) {
      Get.snackbar(
        'Error',
        'Job description must be at least 30 characters',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (requirements.isEmpty || requirements.length < 10) {
      Get.snackbar(
        'Error',
        'Requirements are required (min 10 characters)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (selectedSkills.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add at least one skill',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (selectedShift == null || selectedShift!.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a shift',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (selectedSeniority == null || selectedSeniority!.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a seniority level',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
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
                                'New job post',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Add role details before you post.',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
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
                                Text(
                                  'Job details',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Define the core information candidates will see first.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Job title
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Job title',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Required',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color:
                                            isJobTitleFilled
                                                ? Colors.grey[500]
                                                : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                TextField(
                                  controller: _jobTitleController,
                                  onChanged: (value) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Data Center Technician',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14.sp,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Company & location
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Company & location',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Required',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color:
                                            isCompanyFilled
                                                ? Colors.grey[500]
                                                : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder:
                                          (context) =>
                                              _buildCompanyLocationBottomSheet(),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _companyController.text,
                                                style: TextStyle(
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                _locationController.text,
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 20.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Work type
                                Row(
                                  children: [
                                    Text(
                                      'Work type',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Required',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'On-site / remote',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            builder:
                                                (context) =>
                                                    _buildWorkTypeBottomSheet(),
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 14.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                selectedWorkType,
                                                style: TextStyle(
                                                  fontSize: 15.sp,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Icon(
                                                Icons.keyboard_arrow_down,
                                                size: 20.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            builder:
                                                (context) =>
                                                    _buildLocationTypeBottomSheet(),
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 14.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                selectedLocationType,
                                                style: TextStyle(
                                                  fontSize: 15.sp,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Icon(
                                                Icons.keyboard_arrow_down,
                                                size: 20.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                // Salary type
                                Row(
                                  children: [
                                    Text(
                                      'Salary type',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Required',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedSalaryType = 'Monthly';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 12.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selectedSalaryType == 'Monthly'
                                                ? AppColors.primaryColor.withOpacity(0.1)
                                                : Colors.grey[50],
                                            borderRadius: BorderRadius.circular(10.r),
                                            border: Border.all(
                                              color: selectedSalaryType == 'Monthly'
                                                  ? AppColors.primaryColor
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Monthly',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: selectedSalaryType == 'Monthly'
                                                    ? AppColors.primaryColor
                                                    : Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedSalaryType = 'Hr';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 12.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selectedSalaryType == 'Hr'
                                                ? AppColors.primaryColor.withOpacity(0.1)
                                                : Colors.grey[50],
                                            borderRadius: BorderRadius.circular(10.r),
                                            border: Border.all(
                                              color: selectedSalaryType == 'Hr'
                                                  ? AppColors.primaryColor
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Hr',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: selectedSalaryType == 'Hr'
                                                    ? AppColors.primaryColor
                                                    : Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                // Seniority
                                Text(
                                  'Seniority',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    ...seniorityOptions.map((seniority) {
                                      final isSelected = selectedSeniority == seniority;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedSeniority = isSelected ? null : seniority;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.w,
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryColor.withOpacity(0.1)
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(16.r),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primaryColor
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Text(
                                            seniority,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: isSelected
                                                  ? AppColors.primaryColor
                                                  : Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                // Pay range
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pay range',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Required',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color:
                                            isPayRangeFilled
                                                ? Colors.grey[500]
                                                : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _minPayController,
                                        onChanged: (value) => setState(() {}),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          prefixText: '\$ ',
                                          hintText: '38000',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 14.sp,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 14.h,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: TextField(
                                        controller: _maxPayController,
                                        onChanged: (value) => setState(() {}),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          prefixText: '\$ ',
                                          hintText: '45000',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 14.sp,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 14.h,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Displayed as a range on the job card.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Shifts & schedule
                                Text(
                                  'Shifts & schedule',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add shift patterns, nights, weekends...',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _shiftSearchController,
                                              onChanged: (value) {
                                                setState(() {
                                                  _shiftSearchQuery = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Search or type a shift...',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 13.sp,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.search,
                                                  color: Colors.grey[400],
                                                  size: 18.sp,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10.r),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 12.h,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          GestureDetector(
                                            onTap: _addShiftFromSearch,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 14.w,
                                                vertical: 12.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                              ),
                                              child: Text(
                                                'Add',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 8.h,
                                        children: [
                                          ...shifts
                                              .where((shift) {
                                                if (_shiftSearchQuery.trim().isEmpty) {
                                                  return true;
                                                }
                                                return shift
                                                    .toLowerCase()
                                                    .contains(_shiftSearchQuery.toLowerCase());
                                              })
                                              .map((shift) => _buildShiftChip(shift)),
                                          _buildAddChip(
                                            '+ Add shift',
                                            onTap: _addShiftFromSearch,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Description & requirements card
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
                                  'Description & requirements',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Job description
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Job description',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Required',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color:
                                            isJobDescriptionFilled
                                                ? Colors.grey[500]
                                                : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                TextField(
                                  controller: _jobDescriptionController,
                                  onChanged: (value) => setState(() {}),
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Briefly describe responsibilities, environment, and tools used...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14.sp,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Aim for 3–6 short paragraphs, or bullet points.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Requirements
                                Text(
                                  'Requirements',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                TextField(
                                  controller: _requirementsController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText:
                                        'List minimum skills, certifications, and experience...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14.sp,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Benefits
                                Text(
                                  'Benefits',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add benefits for this role',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _benefitSearchController,
                                              onChanged: (value) {
                                                setState(() {
                                                  _benefitSearchQuery = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Search or type a benefit...',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 13.sp,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.search,
                                                  color: Colors.grey[400],
                                                  size: 18.sp,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10.r),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 12.h,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          GestureDetector(
                                            onTap: _addBenefitFromSearch,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 14.w,
                                                vertical: 12.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                              ),
                                              child: Text(
                                                'Add',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 8.h,
                                        children: [
                                          ...benefits
                                              .where((benefit) {
                                                if (_benefitSearchQuery
                                                    .trim()
                                                    .isEmpty) {
                                                  return true;
                                                }
                                                return benefit
                                                    .toLowerCase()
                                                    .contains(_benefitSearchQuery
                                                        .toLowerCase());
                                              })
                                              .map((benefit) => _buildBenefitChip(benefit)),
                                          _buildAddChip(
                                            '+ Add benefit',
                                            onTap: _addBenefitFromSearch,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                // Key skills
                                Text(
                                  'Key skills',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Search and add skills that matter for this role',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _skillSearchController,
                                              onChanged: (value) {
                                                setState(() {
                                                  _skillSearchQuery = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Search or type a skill...',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 13.sp,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.search,
                                                  color: Colors.grey[400],
                                                  size: 18.sp,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10.r),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 12.h,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          GestureDetector(
                                            onTap: _addSkillFromSearch,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 14.w,
                                                vertical: 12.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor,
                                                borderRadius: BorderRadius.circular(10.r),
                                              ),
                                              child: Text(
                                                'Add',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 8.h,
                                        children: [
                                          ...skills
                                              .where((skill) {
                                                if (_skillSearchQuery.trim().isEmpty) {
                                                  return true;
                                                }
                                                return skill
                                                    .toLowerCase()
                                                    .contains(_skillSearchQuery.toLowerCase());
                                              })
                                              .map((skill) => _buildSkillChip(skill)),
                                          _buildAddChip(
                                            '+ Add skill',
                                            onTap: _addSkillFromSearch,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'Used to power candidate matching and skill tests.',
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
                          SizedBox(height: 20.h),
                          // Action buttons
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_validateJobPost()) {
                                      // Navigate to skill test questions
                                      Get.to(
                                        () => SkillTestQuestionsScreen(
                                          jobTitle:
                                              _jobTitleController.text.isEmpty
                                                  ? 'Data Center Technician'
                                                  : _jobTitleController.text,
                                          company: _companyController.text,
                                          location: _locationController.text,
                                          minPay: _minPayController.text,
                                          maxPay: _maxPayController.text,
                                          shiftType:
                                              selectedShift ?? 'Shift-based',
                                          workType: selectedWorkType,
                                          locationType: selectedLocationType,
                                          salaryType: selectedSalaryType.toLowerCase(),
                                          seniority: selectedSeniority!,
                                          jobDescription:
                                              _jobDescriptionController.text,
                                          requirements:
                                              _requirementsController.text,
                                          skills: List<String>.from(
                                            selectedSkills,
                                          ),
                                          shifts: selectedShift == null
                                              ? []
                                              : [selectedShift!],
                                          benefits: List<String>.from(
                                            selectedBenefits,
                                          ),
                                        ),
                                      );
                                    } else {
                                      return;
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Post job',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                GestureDetector(
                                  onTap: () {
                                    Get.snackbar(
                                      'Saved',
                                      'Job saved as draft',
                                      backgroundColor: Colors.grey[700],
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    Get.back();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Save as draft',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'You can edit details anytime from the job pipeline.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
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

  Widget _buildShiftChip(String shift) {
    final isSelected = selectedShift == shift;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedShift = isSelected ? null : shift;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              shift,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected ? AppColors.primaryColor : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Positioned(
          top: -6.h,
          right: -6.w,
          child: GestureDetector(
            onTap: () {
              setState(() {
                shifts.remove(shift);
                if (selectedShift == shift) {
                  selectedShift = null;
                }
              });
            },
            child: Container(
              width: 16.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 12.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    final isSelected = selectedSkills.contains(skill);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedSkills.remove(skill);
              } else {
                selectedSkills.add(skill);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              skill,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected ? AppColors.primaryColor : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Positioned(
          top: -6.h,
          right: -6.w,
          child: GestureDetector(
            onTap: () {
              setState(() {
                skills.remove(skill);
                selectedSkills.remove(skill);
              });
            },
            child: Container(
              width: 16.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 12.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitChip(String benefit) {
    final isSelected = selectedBenefits.contains(benefit);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedBenefits.remove(benefit);
              } else {
                selectedBenefits.add(benefit);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected ? AppColors.primaryColor : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Positioned(
          top: -6.h,
          right: -6.w,
          child: GestureDetector(
            onTap: () {
              setState(() {
                benefits.remove(benefit);
                selectedBenefits.remove(benefit);
              });
            },
            child: Container(
              width: 16.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 12.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddChip(String label, {VoidCallback? onTap}) {
    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    if (onTap == null) {
      return chip;
    }

    return GestureDetector(
      onTap: onTap,
      child: chip,
    );
  }

  Widget _buildWorkTypeBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select work type',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.h),
                ...['Full-time', 'Part-time', 'Contract'].map((type) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedWorkType = type;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color:
                                  selectedWorkType == type
                                      ? AppColors.primaryColor
                                      : Colors.black,
                              fontWeight:
                                  selectedWorkType == type
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                          if (selectedWorkType == type)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primaryColor,
                              size: 22.sp,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTypeBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select location type',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.h),
                ...['On-site', 'Remote', 'Hybrid'].map((type) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedLocationType = type;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color:
                                  selectedLocationType == type
                                      ? AppColors.primaryColor
                                      : Colors.black,
                              fontWeight:
                                  selectedLocationType == type
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                          if (selectedLocationType == type)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primaryColor,
                              size: 22.sp,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLocationBottomSheet() {
    final TextEditingController tempCompanyController = TextEditingController(
      text: _companyController.text,
    );
    final TextEditingController tempLocationController = TextEditingController(
      text: _locationController.text,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit company & location',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Company name',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: tempCompanyController,
                    decoration: InputDecoration(
                      hintText: 'e.g. EdgeCore Systems',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: tempLocationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Seattle, WA • On-site',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _companyController.text = tempCompanyController.text;
                        _locationController.text = tempLocationController.text;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child: Center(
                        child: Text(
                          'Save changes',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
