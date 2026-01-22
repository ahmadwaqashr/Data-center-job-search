import 'dart:convert';
import 'package:data_center_job/constants/api_config.dart';
import 'package:data_center_job/utils/custom_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide FormData;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/colors.dart';

class EditExperienceScreen extends StatefulWidget {
  const EditExperienceScreen({super.key});

  @override
  State<EditExperienceScreen> createState() => _EditExperienceScreenState();
}

class _EditExperienceScreenState extends State<EditExperienceScreen> {
  List<Map<String, dynamic>> _experiences = [];
  bool _isLoadingExperiences = true;

  final Dio _dio = Dio();
  bool _experienceAdded = false;
  String? _profilePicUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchExperiences();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile picture every time screen comes into focus to get latest data
    if (mounted) {
      _loadUserData();
    }
  }

  Future<void> _fetchExperiences() async {
    try {
      setState(() {
        _isLoadingExperiences = true;
      });

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      String? token;

      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        token = userData['token']?.toString();
      }

      if (token == null || token.isEmpty) {
        print('⚠️ No authentication token found');
        setState(() {
          _isLoadingExperiences = false;
        });
        return;
      }

      print('📥 Fetching experiences from API...');

      // Make API call
      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchExperiences),
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: '', // Empty string as per API requirement
      );

      if (response.statusCode == 200) {
        print('✅ Experiences fetched successfully');
        print('   Response: ${jsonEncode(response.data)}');

        final responseData = response.data as Map<String, dynamic>;
        List<Map<String, dynamic>> experiences = [];

        if (responseData['success'] == true && responseData['data'] != null) {
          final dataList = responseData['data'] as List;
          
          for (var item in dataList) {
            final exp = item as Map<String, dynamic>;
            
            // Parse dates
            DateTime? startDateObj;
            DateTime? endDateObj;
            bool isPresent = false;

            if (exp['startDate'] != null) {
              try {
                startDateObj = DateTime.parse(exp['startDate'].toString());
              } catch (e) {
                print('⚠️ Error parsing startDate: $e');
              }
            }

            if (exp['endDate'] != null) {
              final endDateStr = exp['endDate'].toString().toLowerCase();
              if (endDateStr == 'present') {
                isPresent = true;
              } else {
                try {
                  endDateObj = DateTime.parse(exp['endDate'].toString());
                } catch (e) {
                  print('⚠️ Error parsing endDate: $e');
                }
              }
            } else {
              isPresent = exp['isPresent'] ?? false;
            }

            if (startDateObj != null) {
              // Get job type from API response and format it
              String jobType = exp['jobType']?.toString() ?? 'Full-time';
              // Capitalize first letter of each word
              jobType = jobType.split(' ').map((word) {
                if (word.isEmpty) return word;
                return word[0].toUpperCase() + word.substring(1).toLowerCase();
              }).join(' ');
              
              experiences.add({
                'title': exp['title']?.toString() ?? '',
                'company': exp['company']?.toString() ?? '',
                'type': jobType,
                'location': exp['location']?.toString() ?? '',
      'workStyle': '',
                'startDay': startDateObj.day.toString(),
                'startMonth': _getMonthName(startDateObj.month),
                'startYear': startDateObj.year.toString(),
                'endDay': endDateObj != null ? endDateObj.day.toString() : '',
                'endMonth': endDateObj != null
                    ? _getMonthName(endDateObj.month)
                    : 'Present',
                'endYear': endDateObj != null ? endDateObj.year.toString() : '',
                'isCurrent': isPresent,
              });
            }
          }

          // Sort by start date (most recent first)
          experiences.sort((a, b) {
            final aYear = int.tryParse(a['startYear'] ?? '0') ?? 0;
            final bYear = int.tryParse(b['startYear'] ?? '0') ?? 0;
            if (aYear != bYear) return bYear.compareTo(aYear);
            
            final aMonth = _getMonthIndex(a['startMonth'] ?? '');
            final bMonth = _getMonthIndex(b['startMonth'] ?? '');
            return bMonth.compareTo(aMonth);
          });

          setState(() {
            _experiences = experiences;
            _isLoadingExperiences = false;
          });
        } else {
          setState(() {
            _experiences = [];
            _isLoadingExperiences = false;
          });
        }
      } else {
        throw Exception('Failed to fetch experiences: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Error fetching experiences: $e');
      setState(() {
        _experiences = [];
        _isLoadingExperiences = false;
      });
    }
  }

  int _getMonthIndex(String monthName) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months.indexOf(monthName);
  }

  Future<void> _loadUserData() async {
    try {
      print('📥 Loading profile picture from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        final profilePicPath = userData['profilePic']?.toString();
        
        String? newProfilePicUrl;
        if (profilePicPath != null && profilePicPath.isNotEmpty) {
          newProfilePicUrl = ApiConfig.getImageUrl(profilePicPath);
          print('✅ Profile picture loaded: $newProfilePicUrl');
        } else {
          print('⚠️ No profile picture found in user data');
        }
        
        // Only update state if profile picture changed
        if (mounted && _profilePicUrl != newProfilePicUrl) {
          setState(() {
            _profilePicUrl = newProfilePicUrl;
            _isLoadingProfile = false;
          });
        } else if (mounted && _isLoadingProfile) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      } else {
        print('⚠️ No user data found in SharedPreferences');
        if (mounted) {
          setState(() {
            _profilePicUrl = null;
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _showAddExperienceDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController companyController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    bool isPresent = false;
    bool isSaving = false; // Track saving state to prevent multiple clicks
    String? selectedJobType; // Job type: Full-time, Contract, Remote, Hybrid, etc.
    
    final List<String> jobTypes = [
      'Full-time',
      'Part-time',
      'Contract',
      'Temporary',
      'Remote',
      'Hybrid',
      'On-site',
      'Shift-based',
      'Freelance',
      'Internship',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add Experience',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Data Center Technician',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Company name field
                      Text(
                        'Company name',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: companyController,
                        decoration: InputDecoration(
                          hintText: 'e.g., EdgeCore Systems',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Location field
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Seattle, WA',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Job type field
                      Text(
                        'Job type',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedJobType,
                          decoration: InputDecoration(
                            hintText: 'Select job type',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                          ),
                          items: jobTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              selectedJobType = newValue;
                            });
                          },
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                            size: 24.sp,
                          ),
                          iconSize: 24.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Start date field
                      Text(
                        'Start date',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                startDate != null
                                    ? '${startDate!.day} ${_getMonthName(startDate!.month)} ${startDate!.year}'
                                    : 'Select start date',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: startDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                              Icon(Icons.calendar_today, size: 20.sp),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Present checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: isPresent,
                            onChanged: (value) {
                              setDialogState(() {
                                isPresent = value ?? false;
                                if (isPresent) {
                                  endDate = null;
                                }
                              });
                            },
                          ),
                          Text(
                            'Present',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      // End date field (only if not present)
                      if (!isPresent) ...[
                        Text(
                          'End date',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                endDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  endDate != null
                                      ? '${endDate!.day} ${_getMonthName(endDate!.month)} ${endDate!.year}'
                                      : 'Select end date',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: endDate != null
                                        ? Colors.black
                                        : Colors.grey[600],
                                  ),
                                ),
                                Icon(Icons.calendar_today, size: 20.sp),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSaving ? null : () async {
                    // Prevent multiple clicks
                    if (isSaving) return;
                    
                    setDialogState(() {
                      isSaving = true;
                    });

                    if (titleController.text.trim().isEmpty ||
                        companyController.text.trim().isEmpty ||
                        locationController.text.trim().isEmpty ||
                        selectedJobType == null ||
                        startDate == null ||
                        (!isPresent && endDate == null)) {
                      setDialogState(() {
                        isSaving = false;
                      });
                      Get.snackbar(
                        'Validation Error',
                        'Please fill all required fields',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    try {
                      // Get token from SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      final userDataString = prefs.getString('user_data');
                      String? token;

                      if (userDataString != null) {
                        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
                        token = userData['token']?.toString();
                      }

                      if (token == null || token.isEmpty) {
                        setDialogState(() {
                          isSaving = false;
                        });
                        Get.snackbar(
                          'Error',
                          'No authentication token found. Please login again.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      // Format start date as YYYY-MM-DD
                      final formattedStartDate = 
                          '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}';

                      // Format end date or send 'present'
                      final formattedEndDate = isPresent 
                          ? 'present' 
                          : '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';

                      // Format job type to lowercase with space (e.g., "full time")
                      final formattedJobType = selectedJobType!.toLowerCase();

                      print('📤 Adding experience via API...');
                      print('   Title: ${titleController.text.trim()}');
                      print('   Company: ${companyController.text.trim()}');
                      print('   Location: ${locationController.text.trim()}');
                      print('   Job Type: $formattedJobType');
                      print('   Start Date: $formattedStartDate');
                      print('   End Date: $formattedEndDate');

                      // Prepare FormData
                      final formData = FormData.fromMap({
                        'title': titleController.text.trim(),
                        'company': companyController.text.trim(),
                        'location': locationController.text.trim(),
                        'startDate': formattedStartDate,
                        'endDate': formattedEndDate,
                        'jobType': formattedJobType,
                      });

                      // Make API call
                      final response = await _dio.request(
                        ApiConfig.getUrl(ApiConfig.addExperience),
                        options: Options(
                          method: 'POST',
                          headers: {
                            'Authorization': 'Bearer $token',
                          },
                        ),
                        data: formData,
                      );

                      if (response.statusCode == 200) {
                        print('✅ Experience added successfully');
                        print('   Response: ${jsonEncode(response.data)}');

                        Navigator.of(context).pop(); // Close dialog
                        
                        // Mark that experience was added (will be used when screen closes)
                        _experienceAdded = true;
                        
                        // Reload experiences from API to get the latest data
                        await _fetchExperiences();
                        
                        Get.snackbar(
                          'Success',
                          'Experience added successfully',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      } else {
                        throw Exception('Failed to add experience: ${response.statusMessage}');
                      }
                    } catch (e) {
                      print('❌ Error adding experience: $e');
                      setDialogState(() {
                        isSaving = false;
                      });
                      Get.snackbar(
                        'Error',
                        'Failed to add experience: ${e.toString()}',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: isSaving
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14.sp,
                              height: 14.sp,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
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
                          onTap: () {
                            Navigator.pop(context, _experienceAdded);
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
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit experience',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Update your recent roles and timelines.',
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
                          backgroundImage: _profilePicUrl != null
                              ? NetworkImage(_profilePicUrl!)
                              : AssetImage('assets/images/avatar1.png') as ImageProvider,
                          onBackgroundImageError: (exception, stackTrace) {
                            // Fallback to default avatar if network image fails
                            setState(() {
                              _profilePicUrl = null;
                            });
                          },
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
                          // Experience section
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
                                      'Experience',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Add or adjust your past roles. Most recent first.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Experience list
                                _isLoadingExperiences
                                    ? Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 40.h),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : _experiences.isEmpty
                                        ? Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(vertical: 40.h),
                                              child: Text(
                                                'No experiences yet. Add your first experience!',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          )
                                        : Column(
                                            children: [
                                ..._experiences.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, dynamic> exp = entry.value;
                                  return Column(
                                    children: [
                                      if (index > 0) SizedBox(height: 16.h),
                                      _buildExperienceItem(exp),
                                      if (index < _experiences.length - 1)
                                        Divider(height: 10.h),
                                    ],
                                  );
                                }).toList(),
                                            ],
                                          ),
                                SizedBox(height: 16.h),
                                // Add another experience button
                                GestureDetector(
                                  onTap: () => _showAddExperienceDialog(),
                                  child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: AppColors.primaryColor,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'Add another experience',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppColors.primaryColor,
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
                          SizedBox(height: 10.h),
                          // Save changes button
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context, _experienceAdded);
                            },
                            child: CustomButton(text: 'Save Changes'),
                          ),
                          SizedBox(height: 10.h),
                          // Help text
                          Center(
                            child: Text(
                              'Changes will update how employers see your profile immediately.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
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

  Widget _buildExperienceItem(Map<String, dynamic> experience) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                experience['title'],
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color:
                    experience['isCurrent']
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Text(
                experience['isCurrent'] ? 'Current role' : 'Previous',
                style: TextStyle(
                  fontSize: 12.sp,
                  color:
                      experience['isCurrent']
                          ? AppColors.primaryColor
                          : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Company & type
        Text(
          'Company & type',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 6.h),
        Text(
          '${experience['company']} • ${experience['type']}',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        // Location
        Text(
          'Location',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 6.h),
        Text(
          experience['location'],
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        // Start and End dates
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    experience['startDay'] != null && experience['startDay'].toString().isNotEmpty
                        ? '${experience['startDay']} ${experience['startMonth']} ${experience['startYear']}'
                        : '${experience['startMonth']} ${experience['startYear']}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    experience['isCurrent']
                        ? 'Present'
                        : (experience['endDay'] != null && experience['endDay'].toString().isNotEmpty
                            ? '${experience['endDay']} ${experience['endMonth']} ${experience['endYear']}'
                            : '${experience['endMonth']} ${experience['endYear']}'),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color:
                          experience['isCurrent']
                              ? Colors.grey[500]
                              : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
