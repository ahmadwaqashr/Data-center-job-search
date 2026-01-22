import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';
import '../../../models/signup_data.dart';
import 'registration_success_screen.dart';

class FaceScanningScreen extends StatefulWidget {
  const FaceScanningScreen({super.key});

  @override
  State<FaceScanningScreen> createState() => _FaceScanningScreenState();
}

class _FaceScanningScreenState extends State<FaceScanningScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _progress = 0;
  Timer? _timer;
  Timer? _faceDetectionTimer;
  late AnimationController _animationController;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFaceDetected = false;
  bool _isScanningComplete = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: true,
      minFaceSize: 0.1,
    ),
  );
  bool _isProcessingFrame = false;
  bool _isSubmitting = false;
  bool _isPermissionDenied = false;
  final Dio _dio = Dio();
  File? _capturedFaceImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _faceDetectionTimer?.cancel();
    _animationController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    _dio.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 App lifecycle state changed: $state');
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // Recheck permission and reinitialize camera when app resumes
      // This handles the case when user grants permission from settings
      print('🔄 App resumed, rechecking camera permission...');
      // Add a small delay to ensure the app is fully resumed
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _initializeCamera();
        }
      });
    }
  }

  Future<void> _initializeCamera() async {
    // Check current camera permission status
    PermissionStatus status = await Permission.camera.status;
    
    print('📷 Camera permission status: $status');
    print('   isGranted: ${status.isGranted}');
    print('   isDenied: ${status.isDenied}');
    print('   isPermanentlyDenied: ${status.isPermanentlyDenied}');
    print('   isRestricted: ${status.isRestricted}');
    
    // If permission is not granted, request it
    if (!status.isGranted) {
      // Check if permanently denied first
      if (status.isPermanentlyDenied) {
        // Permission is permanently denied, user must enable in settings
        print('❌ Camera permission permanently denied - must open settings');
        if (mounted) {
          setState(() {
            _isPermissionDenied = true;
            _isCameraInitialized = false;
          });
          // Show dialog after a short delay to ensure UI is updated
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _showPermissionDialog(
                title: 'Camera Permission Required',
                message: 'Camera permission is required for face recognition. Please enable it in your device settings.\n\nGo to Settings > Data Center Job > Camera and enable access.',
                onSettingsTap: () async {
                  print('📱 Opening app settings...');
                  final opened = await openAppSettings();
                  print('   Settings opened: $opened');
                },
              );
            }
          });
        }
        return;
      }
      
      // If not permanently denied, try to request permission
      if (status.isDenied || status.isRestricted) {
        print('📷 Requesting camera permission...');
        try {
          status = await Permission.camera.request();
          print('📷 Permission request result: $status');
          print('   isGranted: ${status.isGranted}');
          print('   isDenied: ${status.isDenied}');
          print('   isPermanentlyDenied: ${status.isPermanentlyDenied}');
        } catch (e) {
          print('❌ Error requesting permission: $e');
          if (mounted) {
            setState(() {
              _isPermissionDenied = true;
            });
          }
          return;
        }
      }
      
      // Check status after request
      if (status.isPermanentlyDenied) {
        print('❌ Camera permission permanently denied after request');
        if (mounted) {
          setState(() {
            _isPermissionDenied = true;
            _isCameraInitialized = false;
          });
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _showPermissionDialog(
                title: 'Camera Permission Required',
                message: 'Camera permission is required for face recognition. Please enable it in your device settings.\n\nGo to Settings > Data Center Job > Camera and enable access.',
                onSettingsTap: () async {
                  print('📱 Opening app settings...');
                  await openAppSettings();
                },
              );
            }
          });
        }
        return;
      }
      
      if (!status.isGranted) {
        // Permission was denied (but not permanently)
        print('❌ Camera permission denied (not permanent)');
        if (mounted) {
          setState(() {
            _isPermissionDenied = true;
            _isCameraInitialized = false;
          });
          Get.snackbar(
            'Camera Permission',
            'Camera permission is required for face recognition. Please grant permission when prompted.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: Duration(seconds: 4),
            mainButton: TextButton(
              onPressed: () async {
                // Retry permission request
                await _retryPermission();
              },
              child: Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return;
      }
    }
    
    // Permission is granted, reset permission denied state
    if (mounted) {
      setState(() {
        _isPermissionDenied = false;
      });
    }
    
    print('✅ Camera permission granted');

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        Get.snackbar(
          'Error',
          'No cameras available',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Find front camera
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Use front camera if available, otherwise use first camera
      final selectedCamera = frontCamera ?? _cameras![0];

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startFaceDetection();
        _startScanning();
      }
    } catch (e) {
      print('Error initializing camera: $e');
      Get.snackbar(
        'Camera Error',
        'Failed to initialize camera: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _startFaceDetection() {
    _faceDetectionTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessingFrame || _isScanningComplete) {
        return;
      }

      try {
        _isProcessingFrame = true;
        final XFile image = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);
        
        final List<Face> faces = await _faceDetector.processImage(inputImage);
        
        if (mounted) {
          setState(() {
            _isFaceDetected = faces.isNotEmpty;
            
            // If face is detected, increase progress faster
            if (_isFaceDetected && _progress < 100) {
              _progress = (_progress + 2).clamp(0, 100);
            }
            
            // Complete scanning when face detected for sufficient time
            if (_isFaceDetected && _progress >= 100 && !_isScanningComplete) {
              _isScanningComplete = true;
              timer.cancel();
              _timer?.cancel();
              _animationController.stop();
              // Capture face image
              _captureFaceImage();
            }
          });
        }
        
        // Don't delete the image file - we need it for face capture
        // The file will be used when scanning completes
      } catch (e) {
        print('Face detection error: $e');
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  Future<void> _captureFaceImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('Camera not initialized, cannot capture face image');
      return;
    }

    try {
      print('Capturing face image...');
      final XFile image = await _cameraController!.takePicture();
      final file = File(image.path);
      
      print('📸 Face image captured at: ${file.path}');
      
      if (await file.exists()) {
        final fileSize = await file.length();
        print('✅ Face image file exists, size: $fileSize bytes');
        setState(() {
          _capturedFaceImage = file;
        });
        
        // Save face image to SignupData
        SignupData.instance.faceImageFile = file;
        print('✅ Face image saved to SignupData:');
        print('   Path: ${SignupData.instance.faceImageFile?.path}');
        print('   Size: $fileSize bytes');
        
        // Verify SignupData has the file
        print('   SignupData.faceImageFile path: ${SignupData.instance.faceImageFile?.path ?? "NULL"}');
        print('   SignupData.faceImageFile is null: ${SignupData.instance.faceImageFile == null}');
        
        // Wait a bit to ensure file is fully written
        await Future.delayed(Duration(milliseconds: 500));
        
        // Verify file still exists before submission
        if (await file.exists()) {
          final verifySize = await file.length();
          print('✅ Face image verified before submission, size: $verifySize bytes');
          
          // Double-check SignupData still has the file
          if (SignupData.instance.faceImageFile == null) {
            print('❌ ERROR: Face image was lost from SignupData! Re-saving...');
            SignupData.instance.faceImageFile = file;
          }
          print('   Final check - SignupData.faceImageFile: ${SignupData.instance.faceImageFile?.path ?? "NULL"}');
          
          // Submit signup data
          _submitSignup();
        } else {
          throw Exception('Face image file was deleted before submission: ${file.path}');
        }
      } else {
        throw Exception('Captured face image file does not exist at: ${file.path}');
      }
    } catch (e) {
      print('Error capturing face image: $e');
      Get.snackbar(
        'Error',
        'Failed to capture face image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<File?> _downloadAvatarImage(String url) async {
    try {
      final fullUrl = url.startsWith('http') ? url : ApiConfig.getImageUrl(url);
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        // Create temporary file
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print('Error downloading avatar: $e');
    }
    return null;
  }

  Future<void> _submitSignup() async {
    if (_isSubmitting) return;
    
    final signupData = SignupData.instance;
    
    // Debug: Print current SignupData state
    print('=== SignupData State ===');
    print('Phone: ${signupData.phone}');
    print('Full Name: ${signupData.fullName}');
    print('Email: ${signupData.email}');
    print('Location: ${signupData.location}');
    print('Core Skills: ${signupData.selectedCoreSkills}');
    print('Experience Level: ${signupData.selectedExperienceLevel}');
    print('Profile Pic File: ${signupData.profilePicFile?.path ?? "NULL"}');
    print('   Profile Pic exists: ${signupData.profilePicFile != null ? await signupData.profilePicFile!.exists() : false}');
    print('Selected Avatar Index: ${signupData.selectedAvatarIndex ?? "NULL"}');
    print('Selected Avatar URL: ${signupData.selectedAvatarUrl ?? "NULL"}');
    print('Face Image File: ${signupData.faceImageFile?.path ?? "NULL"}');
    print('   Face Image exists: ${signupData.faceImageFile != null ? await signupData.faceImageFile!.exists() : false}');
    print('CV File: ${signupData.cvFile?.path ?? "NULL"}');
    print('   CV File exists: ${signupData.cvFile != null ? await signupData.cvFile!.exists() : false}');
    print('========================');
    
    // Validate all data
    if (!signupData.isAllDataValid()) {
      final errors = signupData.getValidationErrors();
      print('Validation errors: $errors');
      Get.snackbar(
        'Validation Error',
        errors.join('\n'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare FormData with specific field names as shown in Postman
      // API expects: profilePic, faceImage, cv (not a generic 'files' array)
      print('📝 Preparing FormData with specific field names...');
      
      final formData = FormData();
      
      // Add profile pic with field name 'profilePic'
      if (signupData.profilePicFile != null) {
        final profileFile = signupData.profilePicFile!;
        print('Adding profilePic file: ${profileFile.path}');
        if (await profileFile.exists()) {
          final fileSize = await profileFile.length();
          print('   Profile pic file exists, size: $fileSize bytes');
          formData.files.add(MapEntry(
            'profilePic',
            await MultipartFile.fromFile(
              profileFile.path,
              filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          ));
          print('✅ profilePic added to FormData');
        } else {
          throw Exception('Profile pic file does not exist: ${profileFile.path}');
        }
      } else if (signupData.selectedAvatarUrl != null && signupData.selectedAvatarUrl!.isNotEmpty) {
        // Download avatar image
        print('Downloading avatar for profilePic from: ${signupData.selectedAvatarUrl}');
        final avatarFile = await _downloadAvatarImage(signupData.selectedAvatarUrl!);
        if (avatarFile != null && await avatarFile.exists()) {
          final fileSize = await avatarFile.length();
          print('   Avatar file downloaded, size: $fileSize bytes');
          formData.files.add(MapEntry(
            'profilePic',
            await MultipartFile.fromFile(
              avatarFile.path,
              filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          ));
          print('✅ profilePic (avatar) added to FormData');
        } else {
          throw Exception('Failed to download avatar image or file does not exist');
        }
      } else {
        throw Exception('Profile photo is required. ProfilePicFile: ${signupData.profilePicFile?.path}, AvatarURL: ${signupData.selectedAvatarUrl}');
      }
      
      // Add face image with field name 'faceImage'
      if (signupData.faceImageFile != null) {
        final faceFile = signupData.faceImageFile!;
        print('Adding faceImage file: ${faceFile.path}');
        if (await faceFile.exists()) {
          final fileSize = await faceFile.length();
          print('   Face image file exists, size: $fileSize bytes');
          formData.files.add(MapEntry(
            'faceImage',
            await MultipartFile.fromFile(
              faceFile.path,
              filename: 'face_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          ));
          print('✅ faceImage added to FormData');
        } else {
          throw Exception('Face image file does not exist: ${faceFile.path}');
        }
      } else {
        throw Exception('Face image is required. FaceImageFile: ${signupData.faceImageFile?.path}');
      }
      
      // Add CV file with field name 'cv'
      if (signupData.cvFile != null) {
        final cvFile = signupData.cvFile!;
        print('Adding cv file: ${cvFile.path}');
        if (await cvFile.exists()) {
          final fileSize = await cvFile.length();
          final cvExtension = cvFile.path.split('.').last;
          print('   CV file exists, size: $fileSize bytes, extension: $cvExtension');
          formData.files.add(MapEntry(
            'cv',
            await MultipartFile.fromFile(
              cvFile.path,
              filename: 'cv_${DateTime.now().millisecondsSinceEpoch}.$cvExtension',
            ),
          ));
          print('✅ cv added to FormData');
        } else {
          throw Exception('CV file does not exist: ${cvFile.path}');
        }
      } else {
        throw Exception('CV file is required. CVFile: ${signupData.cvFile?.path}');
      }
      
      // Add other form fields
      formData.fields.addAll([
        MapEntry('role', 'candidate'),
        MapEntry('phone', signupData.phone ?? ''),
        MapEntry('fullName', signupData.fullName ?? ''),
        MapEntry('email', signupData.email ?? ''),
        MapEntry('location', signupData.location ?? ''),
        MapEntry('experties', signupData.getExpertiseString()),
        MapEntry('experienced', signupData.selectedExperienceLevel ?? ''),
      ]);
      
      print('📦 FormData Summary:');
      print('   Total files: ${formData.files.length}');
      print('   Total fields: ${formData.fields.length}');
      print('   FormData file entries:');
      for (var entry in formData.files) {
        print('     - Field: ${entry.key}, Filename: ${entry.value.filename}, Size: ${entry.value.length} bytes');
      }
      print('   FormData field entries:');
      for (var entry in formData.fields) {
        print('     - ${entry.key}: ${entry.value}');
      }
      
      print('📤 FormData prepared:');
      print('   Role: candidate');
      print('   Phone: ${signupData.phone ?? "NULL"}');
      print('   Full Name: ${signupData.fullName ?? "NULL"}');
      print('   Email: ${signupData.email ?? "NULL"}');
      print('   Location: ${signupData.location ?? "NULL"}');
      print('   Expertise: ${signupData.getExpertiseString()}');
      print('   Experience: ${signupData.selectedExperienceLevel ?? "NULL"}');
      print('   Files count: ${formData.files.length}');

      print('🌐 Making API call to: ${ApiConfig.getUrl(ApiConfig.candidateSignup)}');
      
      // Make API call
      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.candidateSignup),
        options: Options(
          method: 'POST',
        ),
        data: formData,
      );
      
      print('✅ API Response received:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Data: ${jsonEncode(response.data)}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('✅ Signup successful!');
        print('📊 Response data:');
        print('   ID: ${responseData['id']}');
        print('   Email: ${responseData['email']}');
        print('   Full Name: ${responseData['fullName']}');
        print('   Profile Pic: ${responseData['profilePic']}');
        print('   Face Image: ${responseData['faceImagePath']}');
        print('   CV File: ${responseData['cvFilePath']}');
        print('   Token: ${responseData['token']?.substring(0, 20) ?? "NULL"}...');
        
        // Save to SharedPreferences
        print('💾 Saving user data to SharedPreferences...');
        await _saveUserData(responseData);
        print('✅ User data saved to SharedPreferences');
        
        // Clear signup data
        signupData.clear();
        print('🧹 SignupData cleared');
        
        if (mounted) {
          // Navigate to success screen
          print('🚀 Navigating to success screen...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrationSuccessScreen(),
            ),
          );
        }
      } else {
        print('❌ Signup failed with status: ${response.statusCode}');
        print('   Message: ${response.statusMessage}');
        throw Exception('Signup failed: ${response.statusMessage}');
      }
    } catch (e, stackTrace) {
      print('❌ Error submitting signup:');
      print('   Error: $e');
      print('   Stack Trace: $stackTrace');
      Get.snackbar(
        'Signup Failed',
        'Failed to complete registration: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        print('🔄 Submission state reset');
      }
    }
  }

  Future<void> _retryPermission() async {
    print('🔄 Retrying camera permission request...');
    setState(() {
      _isPermissionDenied = false;
    });
    
    // Check if permission is permanently denied
    PermissionStatus status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      // If permanently denied, open settings
      print('📱 Opening app settings...');
      await openAppSettings();
      // Don't reinitialize camera here - wait for app to resume
      return;
    }
    
    // Otherwise, try to request permission again
    await _initializeCamera();
  }

  void _showPermissionDialog({
    required String title,
    required String message,
    required VoidCallback onSettingsTap,
  }) {
    // Don't show dialog if already showing
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: AppColors.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[700],
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Can\'t find Camera in Settings?',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '1. Scroll down in Settings > Data Center Job\n2. Look for "Camera" below other permissions\n3. If still not visible, uninstall and reinstall the app',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'After enabling camera access, return to the app and the camera will work automatically.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSettingsTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      print('💾 Saving user data to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      
      // Save all user data as JSON
      await prefs.setString('user_data', jsonEncode(userData));
      print('   ✅ user_data saved');
      
      // Save individual important fields for easy access
      if (userData['token'] != null) {
        await prefs.setString('auth_token', userData['token']);
        print('   ✅ auth_token saved');
      }
      if (userData['id'] != null) {
        await prefs.setString('user_id', userData['id'].toString());
        print('   ✅ user_id saved: ${userData['id']}');
      }
      if (userData['email'] != null) {
        await prefs.setString('user_email', userData['email']);
        print('   ✅ user_email saved: ${userData['email']}');
      }
      if (userData['fullName'] != null) {
        await prefs.setString('user_name', userData['fullName']);
        print('   ✅ user_name saved: ${userData['fullName']}');
      }
      if (userData['role'] != null) {
        await prefs.setString('user_role', userData['role']);
        print('   ✅ user_role saved: ${userData['role']}');
      }
      
      print('✅ All user data saved to SharedPreferences successfully');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  void _startScanning() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted && !_isScanningComplete) {
        setState(() {
          if (_progress < 100 && !_isFaceDetected) {
            _progress += 1;
          }
          
          if (_progress >= 100 && _isFaceDetected && !_isScanningComplete) {
            _isScanningComplete = true;
            timer.cancel();
            _faceDetectionTimer?.cancel();
            _animationController.stop();
            // Capture face image
            _captureFaceImage();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isComplete = _isScanningComplete && _progress >= 100;

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
                          'Step 5 of 5',
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
                        'Scanning your face',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Description
                      Text(
                        'Hold your phone steady and keep your face inside the frame while we complete the scan.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      // Scanning container
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Camera preview or placeholder
                            Center(
                              child: Container(
                                width: 240.w,
                                height: 240.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1A1F3D),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _isPermissionDenied
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.camera_alt_outlined,
                                                color: Colors.white.withOpacity(0.5),
                                                size: 48.sp,
                                              ),
                                              SizedBox(height: 16.h),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                                child: Text(
                                                  'Camera permission required',
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              SizedBox(height: 12.h),
                                              GestureDetector(
                                                onTap: _retryPermission,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                    vertical: 8.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryColor,
                                                    borderRadius: BorderRadius.circular(20.r),
                                                  ),
                                                  child: Text(
                                                    'Grant Permission',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _isCameraInitialized && _cameraController != null
                                      ? Stack(
                                  alignment: Alignment.center,
                                          children: [
                                            // Camera preview
                                            SizedBox(
                                              width: 240.w,
                                              height: 240.h,
                                              child: ClipOval(
                                                child: AspectRatio(
                                                  aspectRatio: _cameraController!.value.aspectRatio,
                                                  child: CameraPreview(_cameraController!),
                                                ),
                                              ),
                                            ),
                                            // Overlay with scanning indicators
                                            Stack(
                                  children: [
                                    // Animated scanning ring
                                    if (!isComplete)
                                      AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          return Container(
                                            width: 220.w,
                                            height: 220.h,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                            color: _isFaceDetected
                                                                ? Colors.green
                                                                : Color(0xFF2563EB).withOpacity(0.5),
                                                width: 3,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                                // Outer circle
                                    Container(
                                      width: 220.w,
                                      height: 220.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                    ),
                                                // Face detection indicator
                                                if (_isFaceDetected && !isComplete)
                                                  Positioned(
                                                    bottom: 20.h,
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 12.w,
                                                        vertical: 4.h,
                                                      ),
                                      decoration: BoxDecoration(
                                                        color: Colors.green.withOpacity(0.8),
                                                        borderRadius: BorderRadius.circular(12.r),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.check_circle,
                                                            color: Colors.white,
                                                            size: 14.sp,
                                                          ),
                                                          SizedBox(width: 4.w),
                                                          Text(
                                                            'Face detected',
                                                            style: TextStyle(
                                                              fontSize: 12.sp,
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                        ),
                                      ),
                                    ),
                                    // Verifying text
                                                if (!_isFaceDetected && !isComplete)
                                      Positioned(
                                        bottom: 20.h,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                                        color: Colors.black.withOpacity(0.7),
                                                        borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Text(
                                                        'Position your face',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                                // Success indicator
                                                if (isComplete)
                                                  Positioned(
                                                    bottom: 20.h,
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 12.w,
                                                        vertical: 4.h,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.withOpacity(0.9),
                                                        borderRadius: BorderRadius.circular(12.r),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.check_circle,
                                                            color: Colors.white,
                                                            size: 16.sp,
                                                          ),
                                                          SizedBox(width: 6.w),
                                                          Text(
                                                            'Verification complete',
                                                            style: TextStyle(
                                                              fontSize: 12.sp,
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                    // Corner brackets
                                    Positioned(
                                      top: 30.h,
                                      left: 30.w,
                                      child: Icon(
                                        Icons.crop_free,
                                                    color: _isFaceDetected
                                                        ? Colors.green
                                                        : Colors.white.withOpacity(0.5),
                                        size: 24.sp,
                                      ),
                                    ),
                                    Positioned(
                                      top: 30.h,
                                      right: 30.w,
                                      child: Icon(
                                        Icons.crop_free,
                                                    color: _isFaceDetected
                                                        ? Colors.green
                                                        : Colors.white.withOpacity(0.5),
                                        size: 24.sp,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 30.h,
                                      left: 30.w,
                                      child: Icon(
                                        Icons.crop_free,
                                                    color: _isFaceDetected
                                                        ? Colors.green
                                                        : Colors.white.withOpacity(0.5),
                                        size: 24.sp,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 30.h,
                                      right: 30.w,
                                      child: Icon(
                                        Icons.crop_free,
                                                    color: _isFaceDetected
                                                        ? Colors.green
                                                        : Colors.white.withOpacity(0.5),
                                        size: 24.sp,
                                      ),
                                    ),
                                  ],
                                            ),
                                          ],
                                        )
                                      : Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: 30.h),
                            // Status text
                            Text(
                              'Face recognition in progress',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'This usually takes just a few seconds.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 20.h),
                            // Progress bar
                            Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 50),
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.85 *
                                          (_progress / 100),
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_progress% complete',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Stay still',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Continue Button (appears when complete)
                      GestureDetector(
                        onTap:
                            isComplete && !_isSubmitting
                                ? () {
                                  // Submission is handled automatically after face capture
                                  if (_isSubmitting) {
                                    Get.snackbar(
                                      'Please wait',
                                      'Submitting your registration...',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.blue,
                                      colorText: Colors.white,
                                  );
                                  }
                                }
                                : null,
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color:
                                isComplete
                                    ? AppColors.primaryColor
                                    : Colors.grey[400],
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          alignment: Alignment.center,
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                      isComplete ? (_isSubmitting ? 'Submitting...' : 'Continue') : 'Scanning...',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (isComplete) ...[
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
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Bottom note
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Your biometric data is encrypted and used only to verify your identity.',
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
