import 'dart:io';
import 'package:data_center_job/view/candidate/auth/face_recognition_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';
import '../../../models/signup_data.dart';

class AddProfilePhotoScreen extends StatefulWidget {
  const AddProfilePhotoScreen({super.key});

  @override
  State<AddProfilePhotoScreen> createState() => _AddProfilePhotoScreenState();
}

class _AddProfilePhotoScreenState extends State<AddProfilePhotoScreen> {
  final Dio _dio = Dio();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Selected avatar index (null means no avatar selected yet)
  int? selectedAvatarIndex;

  // Uploaded image file
  File? _uploadedImage;
  
  // List of avatars from API
  List<Map<String, dynamic>> avatars = [];
  bool _isLoadingAvatars = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAvatars();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchAvatars() async {
    setState(() {
      _isLoadingAvatars = true;
      _errorMessage = null;
    });

    try {
      var data = '';
      var response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchAvatar),
        options: Options(
          method: 'POST',
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            avatars = List<Map<String, dynamic>>.from(responseData['data']);
            _isLoadingAvatars = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load avatars';
            _isLoadingAvatars = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.statusMessage ?? 'Failed to load avatars';
          _isLoadingAvatars = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading avatars: ${e.toString()}';
        _isLoadingAvatars = false;
      });
      print('Error fetching avatars: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _uploadedImage = File(image.path);
          selectedAvatarIndex = null; // Clear avatar selection when uploading
          // Save profile pic to SignupData
          SignupData.instance.profilePicFile = _uploadedImage;
          SignupData.instance.selectedAvatarIndex = null;
          SignupData.instance.selectedAvatarUrl = null;
          print('✅ Profile Pic File saved to SignupData:');
          print('   Path: ${_uploadedImage!.path}');
          print('   Source: Uploaded from ${source == ImageSource.camera ? "Camera" : "Gallery"}');
          // Verify file exists and is saved
          _uploadedImage!.exists().then((exists) {
            print('   File exists check: $exists');
            if (exists) {
              _uploadedImage!.length().then((size) {
                print('   File size on disk: $size bytes');
              });
            }
          });
          // Verify SignupData has the file
          print('   SignupData.profilePicFile path: ${SignupData.instance.profilePicFile?.path ?? "NULL"}');
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryColor),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'Step 4 of 5',
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
                        'Add a profile photo',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Description
                      Text(
                        'Choose an avatar or upload your own photo so employers can easily recognize you.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Selected photo preview
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 15,vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 120.w,
                                    height: 120.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Color(0xFF2563EB),
                                        width: 3,
                                      ),
                                      color: Colors.grey[300],
                                    ),
                                    child: ClipOval(
                                      child: _uploadedImage != null
                                          ? Image.file(
                                              _uploadedImage!,
                                        fit: BoxFit.cover,
                                      )
                                          : selectedAvatarIndex != null && avatars.isNotEmpty
                                              ? Image.network(
                                                  ApiConfig.getImageUrl(avatars[selectedAvatarIndex!]['imageUrl']),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.person,
                                                      size: 60.sp,
                                                      color: Colors.grey[500],
                                                    );
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                                    );
                                                  },
                                                )
                                              : Icon(
                                      Icons.person,
                                      size: 60.sp,
                                      color: Colors.grey[500],
                                                ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'This is how your photo will appear on applications and messages.',
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
                            // Choose an avatar label
                            Text(
                              'Choose an avatar',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            // Avatar Grid
                            _isLoadingAvatars
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
                                            onTap: _fetchAvatars,
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
                                    : avatars.isEmpty
                                        ? Padding(
                                            padding: EdgeInsets.symmetric(vertical: 20.h),
                                            child: Text(
                                              'No avatars available',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          )
                                        : GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 16.w,
                                mainAxisSpacing: 16.h,
                              ),
                                            itemCount: avatars.length,
                              itemBuilder: (context, index) {
                                final isSelected = selectedAvatarIndex == index;
                                              final avatarUrl = ApiConfig.getImageUrl(avatars[index]['imageUrl']);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedAvatarIndex = index;
                                                    _uploadedImage = null; // Clear uploaded image when selecting avatar
                                                    // Save avatar selection to SignupData
                                                    SignupData.instance.selectedAvatarIndex = index;
                                                    SignupData.instance.selectedAvatarUrl = avatarUrl;
                                                    SignupData.instance.profilePicFile = null;
                                                    print('✅ Avatar selected and saved to SignupData:');
                                                    print('   Avatar Index: $index');
                                                    print('   Avatar URL: $avatarUrl');
                                                    print('   Full URL: ${ApiConfig.getImageUrl(avatarUrl)}');
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                                      color: isSelected
                                            ? Color(0xFF2563EB)
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                                  child: ClipOval(
                                                    child: Image.network(
                                                      avatarUrl,
                                          fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: Colors.grey[300],
                                                          child: Icon(
                                                            Icons.person,
                                                            color: Colors.grey[500],
                                                          ),
                                                        );
                                                      },
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Container(
                                                          color: Colors.grey[200],
                                                          child: Center(
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              value: loadingProgress.expectedTotalBytes != null
                                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                                      loadingProgress.expectedTotalBytes!
                                                                  : null,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 20.h),
                            // Or upload your own photo
                            Text(
                              'Or upload your own photo',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            // Upload section
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Upload from device',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'JPG or PNG · Max 5 MB',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _showImageSourceDialog,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 10.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Text(
                                        'Upload image',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),
                      // Save and continue Button
                      GestureDetector(
                        onTap: () {
                          // Validate profile photo
                          if (_uploadedImage == null && selectedAvatarIndex == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select a profile photo or avatar'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FaceRecognitionScreen(),));
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
                                'Save and Continue',
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
                          'You can change your profile photo anytime from settings.',
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
