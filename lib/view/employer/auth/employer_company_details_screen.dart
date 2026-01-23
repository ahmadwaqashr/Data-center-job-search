import 'dart:async';
import 'dart:convert';
import 'package:data_center_job/utils/custom_button.dart';
import 'package:data_center_job/view/employer/auth/employer_logo_screen.dart';
import 'package:data_center_job/view/employer/auth/employer_sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../constants/colors.dart';

class EmployerCompanyDetailsScreen extends StatefulWidget {
  final String? verifiedEmail;
  
  const EmployerCompanyDetailsScreen({super.key, this.verifiedEmail});

  @override
  State<EmployerCompanyDetailsScreen> createState() =>
      _EmployerCompanyDetailsScreenState();
}

class _EmployerCompanyDetailsScreenState
    extends State<EmployerCompanyDetailsScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  late final TextEditingController _workEmailController;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();

  String _selectedCompanySize = '1-20';
  String _selectedHiringVolume = '1-5 roles';
  bool _confirmTerms = false;
  bool _isEmailEditable = false;

  // Location autocomplete
  static const String _googlePlacesApiKey = "AIzaSyBsOA0owjpxAXWhxPdD_kit9W9jHgPwDUI";
  List<Map<String, dynamic>> _locationPredictions = [];
  Timer? _locationDebounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize email controller with verified email or empty
    _workEmailController = TextEditingController(
      text: widget.verifiedEmail ?? '',
    );
    // Add listener for location search
    _locationController.addListener(_onLocationSearchChanged);
  }

  @override
  void dispose() {
    _locationDebounceTimer?.cancel();
    _locationController.removeListener(_onLocationSearchChanged);
    _companyNameController.dispose();
    _workEmailController.dispose();
    _fullNameController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _linkedinController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  void _onLocationSearchChanged() {
    _locationDebounceTimer?.cancel();
    _locationDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(_locationController.text);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _locationPredictions = [];
        });
      }
      return;
    }

    print('🔍 Searching places for: $query');

    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$_googlePlacesApiKey'
          '&language=en';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📍 Places API response status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = List<Map<String, dynamic>>.from(data['predictions']);
          print('✅ Found ${predictions.length} location predictions');
          
          if (mounted) {
            setState(() {
              _locationPredictions = predictions;
            });
          }
        } else {
          print('⚠️ No predictions found. Status: ${data['status']}');
          if (mounted) {
            setState(() {
              _locationPredictions = [];
            });
          }
        }
      } else {
        print('❌ Places API error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _locationPredictions = [];
          });
        }
      }
    } catch (e) {
      print('❌ Error searching places: $e');
      if (mounted) {
        setState(() {
          _locationPredictions = [];
        });
      }
    }
  }

  void _selectLocation(Map<String, dynamic> prediction) {
    final locationName = prediction['description']?.toString() ?? '';
    if (locationName.isEmpty) {
      return;
    }

    print('✅ Selecting location: $locationName');
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    setState(() {
      _locationController.text = locationName;
      _locationPredictions = [];
    });
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
                        // Text(
                        //   'Recruiter',
                        //   style: TextStyle(
                        //     fontSize: 14.sp,
                        //     color: Colors.grey[700],
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
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
                          // Progress indicator
                          Row(
                            children: [
                              Text(
                                'Step 3 of 4',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '• Company details',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          // Progress bar
                          Stack(
                            children: [
                              Container(
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: 0.75,
                                child: Container(
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          // Title
                          Text(
                            'Set up your account',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Tell us about your company',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'These details help candidates recognize your brand and keep your hiring workspace organized.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Form container
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Company name
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Company name',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      child: Text(
                                        'Required',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.grey[700],
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
                                    controller: _companyNameController,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.business_outlined,
                                        color: Colors.grey[600],
                                        size: 20.sp,
                                      ),
                                      hintText:
                                          'Enter company or location name',
                                      hintStyle: TextStyle(
                                        fontSize: 14.sp,
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
                                SizedBox(height: 16.h),
                                // Work email
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Work email',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (widget.verifiedEmail != null)
                                      GestureDetector(
                                        onTap: () {
                                          print('👆 Edit email button tapped');
                                          // Navigate back to sign-in screen to restart email verification
                                          Get.offAll(() => EmployerSignInScreen());
                                        },
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        'Used for candidate updates',
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
                                    controller: _workEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: widget.verifiedEmail != null && !_isEmailEditable,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Colors.grey[600],
                                        size: 20.sp,
                                      ),
                                      suffixIcon: widget.verifiedEmail != null && !_isEmailEditable
                                          ? Padding(
                                              padding: EdgeInsets.only(right: 8.w),
                                              child: Icon(
                                                Icons.verified,
                                                color: Colors.green,
                                                size: 18.sp,
                                              ),
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 14.h,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Your full name
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Your full name',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Shown to candidates',
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
                                    controller: _fullNameController,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: Colors.grey[600],
                                        size: 20.sp,
                                      ),
                                      hintText: 'Enter your name',
                                      hintStyle: TextStyle(
                                        fontSize: 14.sp,
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
                                SizedBox(height: 16.h),
                                // Your role
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Your role',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Optional',
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
                                    controller: _roleController,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.work_outline,
                                        color: Colors.grey[600],
                                        size: 20.sp,
                                      ),
                                      hintText:
                                          'e.g. Hiring manager, Store owner',
                                      hintStyle: TextStyle(
                                        fontSize: 14.sp,
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
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Company size
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
                                      'Company size',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Choose one',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildChip('1-20', _selectedCompanySize, (
                                      value,
                                    ) {
                                      setState(
                                        () => _selectedCompanySize = value,
                                      );
                                    }),
                                    _buildChip('21-100', _selectedCompanySize, (
                                      value,
                                    ) {
                                      setState(
                                        () => _selectedCompanySize = value,
                                      );
                                    }),
                                    _buildChip(
                                      '101-500',
                                      _selectedCompanySize,
                                      (value) {
                                        setState(
                                          () => _selectedCompanySize = value,
                                        );
                                      },
                                    ),
                                    _buildChip('500+', _selectedCompanySize, (
                                      value,
                                    ) {
                                      setState(
                                        () => _selectedCompanySize = value,
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Monthly hiring volume
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
                                      'Monthly hiring volume',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Rough estimate',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildChip(
                                      '1-5 roles',
                                      _selectedHiringVolume,
                                      (value) {
                                        setState(
                                          () => _selectedHiringVolume = value,
                                        );
                                      },
                                    ),
                                    _buildChip(
                                      '6-20 roles',
                                      _selectedHiringVolume,
                                      (value) {
                                        setState(
                                          () => _selectedHiringVolume = value,
                                        );
                                      },
                                    ),
                                    _buildChip(
                                      '21-50 roles',
                                      _selectedHiringVolume,
                                      (value) {
                                        setState(
                                          () => _selectedHiringVolume = value,
                                        );
                                      },
                                    ),
                                    _buildChip(
                                      '50+ roles',
                                      _selectedHiringVolume,
                                      (value) {
                                        setState(
                                          () => _selectedHiringVolume = value,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Company location
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
                                      'Company location',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'City and state',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20.r),
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
                                        color: Colors.grey[600],
                                        size: 20.sp,
                                      ),
                                      hintText: 'e.g. Seattle, WA',
                                      hintStyle: TextStyle(
                                        fontSize: 14.sp,
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
                                // Autocomplete suggestions
                                if (_locationPredictions.isNotEmpty) ...[
                                  SizedBox(height: 8.h),
                                  Container(
                                    constraints: BoxConstraints(maxHeight: 200.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: Colors.grey[300]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: ClampingScrollPhysics(),
                                      primary: false,
                                      itemCount: _locationPredictions.length,
                                      itemBuilder: (context, index) {
                                        final prediction = _locationPredictions[index];
                                        final description = prediction['description']?.toString() ?? '';
                                        
                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              print('👆 Location tapped: $description');
                                              _selectLocation(prediction);
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16.w,
                                                vertical: 12.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey[200]!,
                                                    width: index < _locationPredictions.length - 1 ? 1 : 0,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 20.sp,
                                                    color: AppColors.primaryColor,
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Expanded(
                                                    child: Text(
                                                      description,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        color: Colors.black,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Social media links
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Heading
                                Text(
                                  'Social media links',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                // Website
                                _buildSocialLinkField(
                                  controller: _websiteController,
                                  label: 'Website',
                                  hint: 'https://www.example.com',
                                  icon: Icons.language,
                                ),
                                SizedBox(height: 12.h),
                                // Facebook
                                _buildSocialLinkField(
                                  controller: _facebookController,
                                  label: 'Facebook link',
                                  hint: 'https://www.facebook.com/yourpage',
                                  icon: Icons.facebook,
                                ),
                                SizedBox(height: 12.h),
                                // LinkedIn
                                _buildSocialLinkField(
                                  controller: _linkedinController,
                                  label: 'LinkedIn link',
                                  hint: 'https://www.linkedin.com/company/yourcompany',
                                  icon: Icons.business,
                                ),
                                SizedBox(height: 12.h),
                                // Instagram
                                _buildSocialLinkField(
                                  controller: _instagramController,
                                  label: 'Instagram link',
                                  hint: 'https://www.instagram.com/yourpage',
                                  icon: Icons.camera_alt_outlined,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Terms checkbox
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _confirmTerms = !_confirmTerms,
                                    );
                                  },
                                  child: Container(
                                    width: 20.w,
                                    height: 20.h,
                                    decoration: BoxDecoration(
                                      color:
                                          _confirmTerms
                                              ? AppColors.primaryColor
                                              : Colors.white,
                                      border: Border.all(
                                        color:
                                            _confirmTerms
                                                ? AppColors.primaryColor
                                                : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child:
                                        _confirmTerms
                                            ? Icon(
                                              Icons.check,
                                              size: 14.sp,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              'I confirm that I\'m creating this account to hire for a real company and agree to the ',
                                        ),
                                        TextSpan(
                                          text: 'Terms',
                                          style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Continue button
                          GestureDetector(
                            onTap: () {
                              if (_validateForm()) {
                                Get.to(() => EmployerLogoScreen(
                                  companyData: {
                                    'email': widget.verifiedEmail ?? '',
                                    'companyName': _companyNameController.text.trim(),
                                    'fullName': _fullNameController.text.trim(),
                                    'yourRole': _roleController.text.trim(),
                                    'companySize': _selectedCompanySize,
                                    'monthlyHiring': _selectedHiringVolume,
                                    'companyLocation': _locationController.text.trim(),
                                    'companyWebsite': _websiteController.text.trim(),
                                    'fbLink': _facebookController.text.trim(),
                                    'linkedinLink': _linkedinController.text.trim(),
                                    'instagramLink': _instagramController.text.trim(),
                                  },
                                ));
                              }
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
                                mainAxisAlignment:
                                MainAxisAlignment.center,
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

  bool _validateForm() {
    // Validate company name
    if (_companyNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Company name is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // Validate email
    if (widget.verifiedEmail == null || widget.verifiedEmail!.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Email is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // Validate full name
    if (_fullNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Your full name is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // Validate terms
    if (!_confirmTerms) {
      Get.snackbar(
        'Validation Error',
        'Please confirm the terms and conditions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  Widget _buildChip(
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

  Widget _buildSocialLinkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
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
            controller: controller,
            keyboardType: TextInputType.url,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14.sp,
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
      ],
    );
  }
}
