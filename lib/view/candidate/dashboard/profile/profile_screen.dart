import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide FormData;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import 'edit_profile_screen.dart';
import 'skills_preferences_screen.dart';
import 'edit_experience_screen.dart';
import 'upload_cv_screen.dart';
import 'upload_id_screen.dart';
import '../../test/skill_test_screen.dart';
import '../../../splash/splash0.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _experiences = [];
  bool _isLoadingExperiences = true;
  Map<String, dynamic>? _skillsPreferences;
  bool _isLoadingSkillsPreferences = true;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserData(),
      _fetchExperiences(),
      _fetchSkillsPreferences(),
    ]);
  }

  // Method to reload all data (called when returning from child screens)
  void _reloadAllData() {
    if (mounted) {
      _loadAllData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      print('📥 Loading user data from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        print('✅ User data loaded:');
        print('   Full Name: ${userData['fullName']}');
        print('   Email: ${userData['email']}');
        print('   Phone: ${userData['phone']}');
        print('   Location: ${userData['location']}');
        print('   Profile Pic: ${userData['profilePic']}');
        print('   Percentage: ${userData['percentage']}');
        print('   Experties: ${userData['experties']}');
        print('   Experienced: ${userData['experienced']}');
        
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        print('⚠️ No user data found in SharedPreferences');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
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
          _experiences = [];
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
                'jobType': jobType,
                'location': exp['location']?.toString() ?? '',
                'startDate': startDateObj,
                'endDate': endDateObj,
                'isPresent': isPresent,
              });
            }
          }

          // Sort by start date (most recent first)
          experiences.sort((a, b) {
            final aDate = a['startDate'] as DateTime;
            final bDate = b['startDate'] as DateTime;
            return bDate.compareTo(aDate);
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

  Future<void> _fetchSkillsPreferences() async {
    try {
      setState(() {
        _isLoadingSkillsPreferences = true;
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
          _skillsPreferences = null;
          _isLoadingSkillsPreferences = false;
        });
        return;
      }

      print('📥 Fetching skills preferences from API...');

      // Make API call
      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchSkillsPreferences),
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: '', // Empty string as per API requirement
      );

      if (response.statusCode == 200) {
        print('✅ Skills preferences fetched successfully');
        print('   Response: ${jsonEncode(response.data)}');

        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          final dataList = responseData['data'] as List;
          if (dataList.isNotEmpty) {
            // Get the first (most recent) skills preferences
            final skillsData = dataList[0] as Map<String, dynamic>;
            setState(() {
              _skillsPreferences = skillsData;
              _isLoadingSkillsPreferences = false;
            });
          } else {
            setState(() {
              _skillsPreferences = null;
              _isLoadingSkillsPreferences = false;
            });
          }
        } else {
          setState(() {
            _skillsPreferences = null;
            _isLoadingSkillsPreferences = false;
          });
        }
      } else {
        throw Exception('Failed to fetch skills preferences: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Error fetching skills preferences: $e');
      setState(() {
        _skillsPreferences = null;
        _isLoadingSkillsPreferences = false;
      });
    }
  }

  String _formatWorkPreferences(Map<String, dynamic> skillsData) {
    List<String> parts = [];
    
    // Add availability
    if (skillsData['availability'] != null) {
      parts.add(skillsData['availability'].toString());
    }
    
    // Add preferred name (role focus)
    if (skillsData['preferredName'] != null) {
      parts.add(skillsData['preferredName'].toString());
    }
    
    // Add work style
    if (skillsData['workStyle'] != null) {
      parts.add(skillsData['workStyle'].toString());
    }
    
    // Add locations if available
    if (skillsData['location'] != null && skillsData['location'] is List) {
      final locations = skillsData['location'] as List;
      if (locations.isNotEmpty) {
        final locationStr = locations.join(', ');
        parts.add(locationStr);
      }
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'Not set';
  }

  String _formatCoreSkills(dynamic coreName) {
    if (coreName == null) return 'Not set';
    
    if (coreName is List) {
      if (coreName.isEmpty) return 'Not set';
      return coreName.map((item) => item.toString()).join(', ');
    }
    
    return coreName.toString();
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

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Log Out',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      print('🚪 Logging out user...');
      
      // Sign out from Firebase Auth
      try {
        await FirebaseAuth.instance.signOut();
        print('✅ Signed out from Firebase Auth');
      } catch (e) {
        print('⚠️ Firebase sign out error: $e');
      }

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all user-related data
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      
      print('✅ Cleared all SharedPreferences data');
      print('✅ Logout successful');

      // Navigate to splash screen (which will check auth and route accordingly)
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Splash0()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xFFF9FAFB),
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        ),
      );
    }

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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _userData?['fullName'] ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 45.w,
                                height: 45.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  size: 24.sp,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              CircleAvatar(
                                radius: 24.r,
                                backgroundImage: _userData?['profilePic'] != null
                                    ? NetworkImage(
                                        ApiConfig.getImageUrl(_userData!['profilePic']),
                                      ) as ImageProvider
                                    : AssetImage('assets/images/avatar1.png') as ImageProvider,
                                onBackgroundImageError: (exception, stackTrace) {
                                  // Fallback handled by CircleAvatar
                                },
                                child: _userData?['profilePic'] == null
                                    ? null
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Profile completion card
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
                            stops: [0.04, 0.92],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Candidate profile',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                              '${_userData?['percentage'] ?? 0}% complete',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Finish your skills and preferences to get better job matches.',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.white.withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '+18% visibility when profile is complete',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Container(
                                          width: 4.w,
                                          height: 4.h,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Contact & basics
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Contact & basics',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    // Navigate to edit screen and wait for result
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EditProfileScreen(),
                                      ),
                                    );
                                    // Reload all data when returning (real-time update)
                                    if (result == true) {
                                      _loadAllData();
                                    }
                                  },
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Keep your info up to date so employers can reach you.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildContactItem(
                              icon: Icons.person_outline,
                              label: 'Full name',
                              value: _userData?['fullName'] ?? 'Not set',
                            ),
                            SizedBox(height: 12.h),
                            _buildContactItem(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: _userData?['email'] ?? 'Not set',
                            ),
                            SizedBox(height: 12.h),
                            _buildContactItem(
                              icon: Icons.phone_outlined,
                              label: 'Phone number',
                              value: _userData?['phone'] ?? 'Not set',
                            ),
                            SizedBox(height: 12.h),
                            _buildContactItem(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: _userData?['location'] ?? 'Not set',
                              subtitle: 'Open to roles within 25 miles radius',
                              showBadge: true,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Career snapshot
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
                              'Career snapshot',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Quick view of your applications and activity.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Recommended jobs',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 8.h),
                                        Row(
                                          children: [
                                            Text(
                                              '14',
                                              style: TextStyle(
                                                fontSize: 28.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Flexible(
                                              child: Text(
                                                'New today',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Color(0xFF10B981),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Active applications',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 8.h),
                                        Row(
                                          children: [
                                            Text(
                                              '3',
                                              style: TextStyle(
                                                fontSize: 28.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            Flexible(
                                              child: Text(
                                                'In review',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Experience
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Experience',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    // Navigate to edit experience screen and wait for result
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EditExperienceScreen(),
                                      ),
                                    );
                                    // Reload all data when returning (real-time update)
                                    if (result == true) {
                                      _loadAllData();
                                    }
                                  },
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Showcase your recent roles and responsibilities.',
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
                                      padding: EdgeInsets.symmetric(vertical: 20.h),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _experiences.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20.h),
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
                                            final exp = entry.value;
                                            final startDate = exp['startDate'] as DateTime;
                                            final endDate = exp['endDate'] as DateTime?;
                                            final isPresent = exp['isPresent'] as bool;
                                            
                                            String startDateStr = '${_getMonthName(startDate.month)} ${startDate.year}';
                                            String endDateStr = isPresent
                                                ? 'Present'
                                                : (endDate != null
                                                    ? '${_getMonthName(endDate.month)} ${endDate.year}'
                                                    : 'Present');
                                            String duration = '$startDateStr – $endDateStr • ${exp['location']}';
                                            
                                            return Column(
                                              children: [
                                                if (entry.key > 0) SizedBox(height: 16.h),
                                                _buildExperienceItem(
                                                  icon: isPresent
                                                      ? Icons.business_outlined
                                                      : Icons.work_outline,
                                                  title: exp['title'] ?? '',
                                                  company: '${exp['company']} • ${exp['jobType']}',
                                                  duration: duration,
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ],
                                      ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Skills & preferences
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Skills & preferences',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    // Navigate to skills preferences screen and wait for result
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SkillsPreferencesScreen(),
                                      ),
                                    );
                                    // Reload all data when returning (real-time update)
                                    if (result == true) {
                                      _loadAllData();
                                    }
                                  },
                                  child: Text(
                                    'Manage',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Tune what you\'re great at and what you want next.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildSkillItem(
                              icon: Icons.build_outlined,
                              label: 'Key skills',
                              value: _isLoadingSkillsPreferences
                                  ? 'Loading...'
                                  : _skillsPreferences != null && _skillsPreferences!['coreName'] != null
                                      ? _formatCoreSkills(_skillsPreferences!['coreName'])
                                      : (_userData?['experties'] != null && _userData!['experties'].toString().isNotEmpty
                                          ? _userData!['experties'].toString()
                                          : 'Not set'),
                            ),
                            SizedBox(height: 12.h),
                            _buildSkillItem(
                              icon: Icons.business_outlined,
                              label: 'Experience level',
                              value: _isLoadingSkillsPreferences
                                  ? 'Loading...'
                                  : _skillsPreferences != null && _skillsPreferences!['preferredName'] != null
                                      ? _skillsPreferences!['preferredName'].toString()
                                      : (_userData?['experienced'] != null && _userData!['experienced'].toString().isNotEmpty
                                          ? _userData!['experienced'].toString()
                                          : 'Not set'),
                            ),
                            SizedBox(height: 12.h),
                            _buildSkillItem(
                              icon: Icons.schedule_outlined,
                              label: 'Work preferences',
                              value: _isLoadingSkillsPreferences
                                  ? 'Loading...'
                                  : _skillsPreferences != null
                                      ? _formatWorkPreferences(_skillsPreferences!)
                                      : 'Not set',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Account & settings
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
                              'Account & settings',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Control notifications, security, and app preferences.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildSettingsItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              subtitle: 'New matches, application updates',
                            ),
                            SizedBox(height: 10..h),
                            _buildSettingsItem(
                              icon: Icons.security_outlined,
                              title: 'Security',
                              subtitle: 'Phone login, connected accounts',
                            ),
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () {
                                Get.to(() => const UploadCvScreen());
                              },
                              child: _buildSettingsItem(
                                icon: Icons.description_outlined,
                                title: 'Upload CV',
                                subtitle: 'Resume for job applications',
                              ),
                            ),
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () {
                                Get.to(() => const UploadIdScreen());
                              },
                              child: _buildSettingsItem(
                                icon: Icons.badge_outlined,
                                title: 'Upload ID',
                                subtitle: 'Verification document',
                              ),
                            ),
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () {
                                _handleLogout(context);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(.1),
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                                child: Text(
                                  'Log out',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'You can log back in anytime with your phone number.',
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
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    bool showBadge = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24.sp, color: Colors.grey[600]),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              if (subtitle != null) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
        if (showBadge)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'Required',
              style: TextStyle(
                fontSize: 11.sp,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExperienceItem({
    required IconData icon,
    required String title,
    required String company,
    required String duration,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24.sp, color: Colors.grey[600]),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: 4.h),
              Text(
                company,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: 2.h),
              Text(
                duration,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24.sp, color: Colors.grey[600]),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24.sp, color: Colors.grey[600]),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, size: 24.sp, color: Colors.grey[400]),
      ],
    );
  }
}
