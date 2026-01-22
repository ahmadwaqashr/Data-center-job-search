import 'dart:convert';
import 'package:data_center_job/view/candidate/auth/upload_cv_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';
import '../../../models/signup_data.dart';

class SkillExpertiseScreen extends StatefulWidget {
  const SkillExpertiseScreen({super.key});

  @override
  State<SkillExpertiseScreen> createState() => _SkillExpertiseScreenState();
}

class _SkillExpertiseScreenState extends State<SkillExpertiseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();

  // Selected skills
  List<String> selectedCoreSkills = [];
  String selectedExperienceLevel = '';

  // Available skills from API
  List<Map<String, dynamic>> coreSkills = [];
  bool _isLoadingSkills = true;
  String? _errorMessage;

  // Experience levels from API
  List<Map<String, dynamic>> experienceLevels = [];
  bool _isLoadingExperienceLevels = true;
  String? _errorMessageExperienceLevels;

  @override
  void initState() {
    super.initState();
    _fetchCoreExpertise();
    _fetchExperienceLevels();
    _searchController.addListener(_filterSkills);
  }

  void _filterSkills() {
    setState(() {
      // Filtering is handled in the build method
    });
  }

  List<Map<String, dynamic>> get _filteredSkills {
    if (_searchController.text.isEmpty) {
      return coreSkills;
    }
    final query = _searchController.text.toLowerCase();
    return coreSkills.where((skill) {
      final name = (skill['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSkills);
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchCoreExpertise() async {
    setState(() {
      _isLoadingSkills = true;
      _errorMessage = null;
    });

    try {
      var data = '';
      var response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchCoreExpertise),
        options: Options(
          method: 'POST',
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            coreSkills = List<Map<String, dynamic>>.from(responseData['data']);
            _isLoadingSkills = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load skills';
            _isLoadingSkills = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.statusMessage ?? 'Failed to load skills';
          _isLoadingSkills = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading skills: ${e.toString()}';
        _isLoadingSkills = false;
      });
      print('Error fetching core expertise: $e');
    }
  }

  Future<void> _fetchExperienceLevels() async {
    setState(() {
      _isLoadingExperienceLevels = true;
      _errorMessageExperienceLevels = null;
    });

    try {
      var data = '';
      var response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchExperienceLevel),
        options: Options(
          method: 'POST',
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            experienceLevels = List<Map<String, dynamic>>.from(responseData['data']);
            _isLoadingExperienceLevels = false;
          });
        } else {
          setState(() {
            _errorMessageExperienceLevels = 'Failed to load experience levels';
            _isLoadingExperienceLevels = false;
          });
        }
      } else {
        setState(() {
          _errorMessageExperienceLevels = response.statusMessage ?? 'Failed to load experience levels';
          _isLoadingExperienceLevels = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessageExperienceLevels = 'Error loading experience levels: ${e.toString()}';
        _isLoadingExperienceLevels = false;
      });
      print('Error fetching experience levels: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      // Back Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
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
                      SizedBox(height: 20.h),
                      // Step indicator
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15)
                        ),
                        child: Text(
                          'Step 2 of 5',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Subtitle
                      Text(
                        'Data Center Job Search',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Title
                      Text(
                        'Choose your skill expertise',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Description
                      Text(
                        'Select the areas you\'re strongest in so we can surface the most relevant data center roles for you.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      // White Container with skills
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Field
                            TextFormField(
                              controller: _searchController,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                hintText: 'Search or type a skill',
                                hintStyle: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.grey[400],
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[400],
                                  size: 20.sp,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                  borderSide: BorderSide.none
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            // Core expertise label
                            Text(
                              'Core expertise',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(.5),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            // Core Skills Chips
                            _isLoadingSkills
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20.h),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : _errorMessage != null
                                    ? Column(
                                        children: [
                                          Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.red,
                                            ),
                                          ),
                                          SizedBox(height: 10.h),
                                          GestureDetector(
                                            onTap: _fetchCoreExpertise,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16.w,
                                                vertical: 10.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor,
                                                borderRadius: BorderRadius.circular(20.r),
                                              ),
                                              child: Text(
                                                'Retry',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                        : _filteredSkills.isEmpty
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(vertical: 20.h),
                                            child: Text(
                                              _searchController.text.isNotEmpty
                                                  ? 'No skills found matching "${_searchController.text}"'
                                                  : 'No skills available',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          )
                                        : Wrap(
                              spacing: 10.w,
                              runSpacing: 10.h,
                                            children: _filteredSkills.map((skillData) {
                                              final skillName = skillData['name'] ?? '';
                                              final isSelected = selectedCoreSkills.contains(skillName);
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                                      selectedCoreSkills.remove(skillName);
                                          } else {
                                                      selectedCoreSkills.add(skillName);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                                    color: isSelected
                                                  ? Color(0xFF2563EB)
                                                  : Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: Text(
                                                    skillName,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                                      color: isSelected
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            SizedBox(height: 24.h),
                            // Experience level label
                            Text(
                              'Experience level',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(.5),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            // Experience Level Chips
                            _isLoadingExperienceLevels
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20.h),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : _errorMessageExperienceLevels != null
                                    ? Column(
                                        children: [
                                          Text(
                                            _errorMessageExperienceLevels!,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.red,
                                            ),
                                          ),
                                          SizedBox(height: 10.h),
                                          GestureDetector(
                                            onTap: _fetchExperienceLevels,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16.w,
                                                vertical: 10.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor,
                                                borderRadius: BorderRadius.circular(20.r),
                                              ),
                                              child: Text(
                                                'Retry',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : experienceLevels.isEmpty
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(vertical: 20.h),
                                            child: Text(
                                              'No experience levels available',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          )
                                        : Wrap(
                              spacing: 10.w,
                              runSpacing: 10.h,
                                            children: experienceLevels.map((levelData) {
                                              final levelName = levelData['name'] ?? '';
                                              final isSelected = selectedExperienceLevel == levelName;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                                    selectedExperienceLevel = levelName;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                                    color: isSelected
                                                  ? Color(0xFF2563EB)
                                                  : Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: Text(
                                                    levelName,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                                      color: isSelected
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            SizedBox(height: 16.h),
                            // Update note
                            Text(
                              'You can always update or add more skills later from your profile.',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Continue Button
                      GestureDetector(
                        onTap: () {
                          // Validate selections
                          if (selectedCoreSkills.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select at least one core expertise'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (selectedExperienceLevel.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select your experience level'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          // Save data to SignupData
                          final signupData = SignupData.instance;
                          signupData.selectedCoreSkills = List.from(selectedCoreSkills);
                          signupData.selectedExperienceLevel = selectedExperienceLevel;
                          print('✅ Skill Expertise data saved to SignupData:');
                          print('   Core Skills: ${signupData.selectedCoreSkills}');
                          print('   Experience Level: ${signupData.selectedExperienceLevel}');
                          print('   Expertise String: ${signupData.getExpertiseString()}');
                          
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UploadCvScreen(),));
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Container(
                                height: 18.h,
                                width: 18.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF2052C1),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_sharp,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Bottom note
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'We\'ll use your skills to recommend the best-matching jobs and employers.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
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
        ),
      ),
    );
  }
}
