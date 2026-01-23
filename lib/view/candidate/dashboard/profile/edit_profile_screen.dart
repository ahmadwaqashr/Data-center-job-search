import 'dart:convert';
import 'dart:io';
import 'package:data_center_job/constants/api_config.dart';
import 'package:data_center_job/utils/custom_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;
  String? _userRole; // Store user role
  String? _profilePicUrl;
  File? _selectedImageFile;
  final ImagePicker _imagePicker = ImagePicker();
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickImage() async {
    try {
      // Show bottom sheet to choose between camera and gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) => Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue),
                title: Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              SizedBox(height: 10.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 800,
          maxHeight: 800,
        );

        if (image != null) {
          setState(() {
            _selectedImageFile = File(image.path);
            _profilePicUrl = null; // Clear network image when new image is selected
          });
          print('✅ Profile picture selected: ${_selectedImageFile?.path}');
        }
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() {
        _isSaving = true;
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
        throw Exception('No authentication token found. Please login again.');
      }

      print('📤 Preparing to save profile changes...');
      print('   Full Name: ${_fullNameController.text}');
      print('   Location: ${_locationController.text}');
      print('   Profile Pic Selected: ${_selectedImageFile != null}');

      // Prepare data map for FormData
      final Map<String, dynamic> dataMap = {};

      // Add profile picture file if selected (optional)
      if (_selectedImageFile != null) {
        print('   Adding profile picture file: ${_selectedImageFile!.path}');
        final fileName = _selectedImageFile!.path.split('/').last;
        dataMap['profile_pic'] = await MultipartFile.fromFile(
          _selectedImageFile!.path,
          filename: fileName,
        );
      }

      // Add fullname if changed (optional)
      final currentFullName = _userData?['fullName']?.toString() ?? '';
      final newFullName = _fullNameController.text.trim();
      if (newFullName.isNotEmpty && newFullName != currentFullName) {
        dataMap['fullname'] = newFullName;
        print('   Adding fullname: $newFullName');
      }

      // Add location if changed (optional) - use appropriate field based on role
      final currentLocation = _userRole == 'employer' 
          ? (_userData?['companyLocation']?.toString() ?? '')
          : (_userData?['location']?.toString() ?? '');
      final newLocation = _locationController.text.trim();
      if (newLocation.isNotEmpty && newLocation != currentLocation) {
        if (_userRole == 'employer') {
          dataMap['companyLocation'] = newLocation;
        } else {
          dataMap['location'] = newLocation;
        }
        print('   Adding location: $newLocation (field: ${_userRole == 'employer' ? 'companyLocation' : 'location'})');
      }

      // Add email if changed and role is employer (optional)
      if (_userRole == 'employer') {
        final currentEmail = _userData?['email']?.toString() ?? '';
        final newEmail = _emailController.text.trim();
        if (newEmail.isNotEmpty && newEmail != currentEmail) {
          dataMap['email'] = newEmail;
          print('   Adding email: $newEmail');
        }
      }

      // Add phone if changed and role is employer (optional)
      if (_userRole == 'employer') {
        final currentPhone = _userData?['phone']?.toString() ?? '';
        final newPhone = _phoneController.text.trim();
        if (newPhone.isNotEmpty && newPhone != currentPhone) {
          dataMap['phone'] = newPhone;
          print('   Adding phone: $newPhone');
        }
      }

      // Always include role for employers (even if only location is being updated)
      if (_userRole == 'employer') {
        dataMap['role'] = 'employer';
        print('   Adding role: employer');
      }

      // Check if there are any changes (excluding role)
      final hasChanges = dataMap.keys.any((key) => key != 'role');
      if (!hasChanges) {
        Get.snackbar(
          'Info',
          'No changes to save',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Create FormData from map (matches API structure)
      final formData = FormData.fromMap(dataMap);

      print('🌐 Making API call to: ${ApiConfig.getUrl(ApiConfig.editMyProfile)}');
      print('   User Role: ${_userRole ?? "NULL"}');
      print('   Data map keys: ${dataMap.keys.toList()}');
      print('   FormData structure:');
      print('     - profile_pic: ${dataMap['profile_pic'] != null ? 'Present (file)' : 'Not included'}');
      print('     - fullname: ${dataMap['fullname'] ?? 'Not included'}');
      if (_userRole == 'employer') {
        print('     - companyLocation: ${dataMap['companyLocation'] ?? 'Not included'}');
        print('     - email: ${dataMap['email'] ?? 'Not included'}');
        print('     - phone: ${dataMap['phone'] ?? 'Not included'}');
        print('     - role: ${dataMap['role'] ?? 'Not included'}');
      } else {
        print('     - location: ${dataMap['location'] ?? 'Not included'}');
      }
      if (_selectedImageFile != null) {
        print('     - Profile pic file path: ${_selectedImageFile!.path}');
        print('     - Profile pic file name: ${_selectedImageFile!.path.split('/').last}');
      }

      // Make API call
      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.editMyProfile),
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: formData,
      );

      if (response.statusCode == 200) {
        print('✅ Profile updated successfully');
        print('   Response: ${jsonEncode(response.data)}');

        // Update SharedPreferences with new data
        final updatedUserData = response.data as Map<String, dynamic>;
        await prefs.setString('user_data', jsonEncode(updatedUserData));

        // Ensure role is preserved in SharedPreferences
        if (_userRole != null) {
          await prefs.setString('user_role', _userRole!);
          print('   ✅ user_role preserved: $_userRole');
        }

        // Update local state
        setState(() {
          _userData = updatedUserData;
          _profilePicUrl = updatedUserData['profilePic'] != null
              ? ApiConfig.getImageUrl(updatedUserData['profilePic'].toString())
              : null;
          _selectedImageFile = null; // Clear selected file after successful upload
        });

        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate back after a short delay with result indicating success
        Future.delayed(Duration(milliseconds: 500), () {
          Navigator.pop(context, true); // Return true to indicate profile was updated
        });
      } else {
        throw Exception('Failed to update profile: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      print('📥 Loading user data from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();

      // Get user role
      _userRole = prefs.getString('user_role');
      print('   User Role: ${_userRole ?? "NULL"}');

      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        print('✅ User data loaded:');
        print('   Full Name: ${userData['fullName']}');
        print('   Email: ${userData['email']}');
        print('   Phone: ${userData['phone']}');
        print('   Location: ${userData['location']}');
        print('   Company Location: ${userData['companyLocation']}');
        print('   Profile Pic: ${userData['profilePic']}');

        setState(() {
          _userData = userData;
          _fullNameController.text = userData['fullName']?.toString() ?? '';
          _emailController.text = userData['email']?.toString() ?? '';
          
          // Set phone number
          _phoneController.text = userData['phone']?.toString() ?? '';
          
          // Set location based on role
          if (_userRole == 'employer') {
            _locationController.text = userData['companyLocation']?.toString() ?? '';
          } else {
            _locationController.text = userData['location']?.toString() ?? '';
          }
          
          // Set profile picture URL
          if (userData['profilePic'] != null && userData['profilePic'].toString().isNotEmpty) {
            _profilePicUrl = ApiConfig.getImageUrl(userData['profilePic'].toString());
          }
          
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit profile',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Update how employers see your details.',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                        CircleAvatar(
                          radius: 20.r,
                                backgroundImage: _selectedImageFile != null
                                    ? FileImage(_selectedImageFile!)
                                    : (_profilePicUrl != null
                                        ? NetworkImage(_profilePicUrl!)
                                        : AssetImage('assets/images/avatar1.png') as ImageProvider),
                                onBackgroundImageError: (exception, stackTrace) {
                                  // Fallback to default avatar if network image fails
                                  setState(() {
                                    _profilePicUrl = null;
                                  });
                                },
                              ),
                              // Plus icon overlay
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 16.w,
                                  height: 16.h,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 12.sp,
                                    color: Colors.white,
                                  ),
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
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15,vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contact & basics section
                            Text(
                              'Contact & basics',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Full name field
                            Text(
                              'Full name',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: TextField(
                                controller: _fullNameController,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: Colors.grey[600],
                                    size: 22.sp,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Email field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Used for important updates',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                readOnly: _userRole != 'employer' || (_userData?['email']?.toString().isNotEmpty ?? false),
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: (_userRole == 'employer' && (_userData?['email']?.toString().isEmpty ?? true))
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.grey[600],
                                    size: 22.sp,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Phone number field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Phone number',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Primary login method',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                readOnly: _userRole != 'employer' || (_userData?['phone']?.toString().isNotEmpty ?? false),
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: (_userRole == 'employer' && (_userData?['phone']?.toString().isEmpty ?? true))
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                        Icons.phone_outlined,
                                        color: Colors.grey[600],
                                        size: 22.sp,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Location field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _userRole == 'employer' ? 'Company location' : 'Location',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                if (_userRole == 'candidate')
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
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
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: TextField(
                                controller: _locationController,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey[600],
                                    size: 22.sp,
                                  ),
                                  hintText: _userRole == 'employer' ? 'e.g. Seattle, WA' : null,
                                  hintStyle: TextStyle(
                                    fontSize: 15.sp,
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                ),
                              ),
                            ),
                            if (_userRole == 'candidate') ...[
                              SizedBox(height: 8.h),
                              Padding(
                                padding: EdgeInsets.only(left: 12.w),
                                child: Text(
                                  'Open to roles within 25 miles radius',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 10.h),
                            // Save changes button
                            GestureDetector(
                              onTap: _isSaving ? null : _saveChanges,
                              child: Opacity(
                                opacity: _isSaving ? 0.6 : 1.0,
                                child: CustomButton(
                                  text: _isSaving ? 'Saving...' : 'Save Changes',
                                ),
                              ),
                            ),
                            // Cancel button
                            Center(
                              child: TextButton(
                                onPressed: () => Get.back(),
                                child: Text(
                                  'Cancel and go back',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            // Help text
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Text(
                                'Your contact info helps employers reach you quickly and powers location-based matches.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                          ],
                        ),
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
}
