import 'dart:async';
import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:data_center_job/view/candidate/auth/skill_expertise_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../constants/colors.dart';
import '../../../models/signup_data.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoadingLocation = false;
  bool _isPhoneEnabled = false; // Track if phone field should be enabled
  String _countryCode = '+1'; // Default country code
  static const String _googlePlacesApiKey = "AIzaSyBsOA0owjpxAXWhxPdD_kit9W9jHgPwDUI";
  List<Map<String, dynamic>> _placePredictions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_onLocationChanged);
    _fetchVerifiedPhoneNumber();
    _prefillUserData();
  }

  Future<void> _fetchVerifiedPhoneNumber() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        setState(() {
          _phoneController.text = user.phoneNumber!;
          _isPhoneEnabled = false; // Disable if phone is already verified
        });
        // Save phone to SignupData
        SignupData.instance.phone = user.phoneNumber!;
      } else {
        // No phone number from Firebase Auth (likely Google Sign-In)
        setState(() {
          _isPhoneEnabled = true; // Enable phone field for manual entry
        });
        print('ℹ️ No verified phone number found, enabling phone field for manual entry');
      }
    } catch (e) {
      print('Error fetching phone number: $e');
      // On error, enable phone field
      setState(() {
        _isPhoneEnabled = true;
      });
    }
  }

  void _prefillUserData() {
    // Pre-fill email and fullName from SignupData (for Google Sign-In flow)
    if (SignupData.instance.email != null && SignupData.instance.email!.isNotEmpty) {
      _emailController.text = SignupData.instance.email!;
    } else {
      // Fallback: try to get from Firebase user
      try {
        User? user = _auth.currentUser;
        if (user != null && user.email != null && user.email!.isNotEmpty) {
          _emailController.text = user.email!;
          SignupData.instance.email = user.email!;
        }
      } catch (e) {
        print('Error fetching email from Firebase: $e');
      }
    }

    if (SignupData.instance.fullName != null && SignupData.instance.fullName!.isNotEmpty) {
      _fullNameController.text = SignupData.instance.fullName!;
    } else {
      // Fallback: try to get from Firebase user
      try {
        User? user = _auth.currentUser;
        if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
          _fullNameController.text = user.displayName!;
          SignupData.instance.fullName = user.displayName!;
        }
      } catch (e) {
        print('Error fetching display name from Firebase: $e');
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.removeListener(_onLocationChanged);
    _locationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onLocationChanged() {
    _debounceTimer?.cancel();
    if (_locationController.text.length > 2) {
      _debounceTimer = Timer(Duration(milliseconds: 500), () {
        _searchPlaces(_locationController.text);
      });
    } else {
      _removeOverlay();
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      _removeOverlay();
      return;
    }

    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$_googlePlacesApiKey'
          '&language=en';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = List<Map<String, dynamic>>.from(data['predictions']);
          if (mounted) {
            setState(() {
              _placePredictions = predictions;
            });
            _showSuggestions();
          }
        } else if (data['status'] == 'ZERO_RESULTS') {
          if (mounted) {
            setState(() {
              _placePredictions = [];
            });
            _removeOverlay();
          }
        } else {
          _removeOverlay();
        }
      } else {
        _removeOverlay();
      }
    } catch (e) {
      print('Error searching places: $e');
      _removeOverlay();
    }
  }

  void _showSuggestions() {
    _removeOverlay();
    if (_placePredictions.isEmpty || !mounted) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 24,
        right: 24,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _placePredictions.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: _placePredictions.length > 5 ? 5 : _placePredictions.length,
                      separatorBuilder: (context, index) => Divider(height: 1, indent: 48),
                      itemBuilder: (context, index) {
                        Map<String, dynamic> prediction = _placePredictions[index];
                        String description = prediction['description'] ?? "";
                        return InkWell(
                          onTap: () {
                            _locationController.text = description;
                            _removeOverlay();
                            FocusScope.of(context).unfocus();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (mounted) {
      setState(() {
        _placePredictions = [];
      });
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
                          'Step 1 of 5',
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
                        'Complete your profile',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Description
                      Text(
                        'Fill in your basic details so we can match you with the right data center roles and employers.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 40.h),
                      // Full Name Field
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 15,vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              label: 'Full Name',
                              controller: _fullNameController,
                              hintText: 'Enter your full name',
                            ),
                            SizedBox(height: 10.h),
                            // Email Field
                            _buildTextField(
                              label: 'Email',
                              controller: _emailController,
                              hintText: 'Enter your email address',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: 10.h),
                            // Phone Number Field
                            _buildPhoneTextField(),
                            SizedBox(height: 10.h),
                            // Location Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                CompositedTransformTarget(
                                  link: _layerLink,
                                  child: TextFormField(
                                    controller: _locationController,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: 'Enter your city or region',
                                      hintStyle: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey[400],
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                        borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                        borderSide: BorderSide(
                                          color: Color(0xFF2563EB),
                                          width: 1.5,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                      prefixIcon: Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.grey[600],
                                        size: 20.sp,
                                      ),
                                    ),
                                    onTap: () {
                                      if (_placePredictions.isNotEmpty) {
                                        _showSuggestions();
                                      }
                                    },
                                    onChanged: (value) {
                                      // The listener will handle the search
                                    },
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                      Row(
                                        children: [
                                          Expanded(
                                      child: Text(
                                                  'Used to find nearby jobs and employers',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                          ),
                                          GestureDetector(
                                      onTap: _isLoadingLocation ? null : _getCurrentLocation,
                                      child: _isLoadingLocation
                                          ? SizedBox(
                                              width: 16.w,
                                              height: 16.h,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF2563EB),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              'Use current',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.w600,
                                              ),
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
                      // Update note
                      Center(
                        child: Text(
                          'You can update these details anytime from your profile settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Continue Button
                      GestureDetector(
                        onTap: () {
                          // Validate fields
                          if (_fullNameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your full name'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (_emailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your email'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (!_emailController.text.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter a valid email address'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (_locationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your location'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          // Validate phone number if field is enabled (Google Sign-In flow)
                          if (_isPhoneEnabled && _phoneController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter your phone number'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          // Save data to SignupData
                          final signupData = SignupData.instance;
                          signupData.fullName = _fullNameController.text.trim();
                          signupData.email = _emailController.text.trim();
                          signupData.location = _locationController.text.trim();
                          // Save phone number if entered (for Google Sign-In flow)
                          // Include country code with phone number
                          if (_isPhoneEnabled && _phoneController.text.trim().isNotEmpty) {
                            final phoneNumber = _countryCode + _phoneController.text.trim();
                            signupData.phone = phoneNumber;
                            print('   Phone with country code: $phoneNumber');
                          }
                          print('✅ Complete Profile data saved to SignupData:');
                          print('   Full Name: ${signupData.fullName}');
                          print('   Email: ${signupData.email}');
                          print('   Location: ${signupData.location}');
                          print('   Phone: ${signupData.phone ?? "Not set"}');
                          print('   Phone field enabled: $_isPhoneEnabled');
                          
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SkillExpertiseScreen(),));
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
                      // Terms and Privacy text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'By continuing, you agree to receive account-related messages and accept our Terms & Privacy Policy.',
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

  Widget _buildPhoneTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          enabled: _isPhoneEnabled,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: _isPhoneEnabled ? 'Enter phone number' : '+1 ••• ••• ••••',
            hintStyle: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[400],
            ),
            prefixIcon: _isPhoneEnabled
                ? CountryCodePicker(
                    onChanged: (country) {
                      setState(() {
                        _countryCode = country.dialCode ?? '+1';
                      });
                    },
                    initialSelection: 'US',
                    favorite: ['+1', 'US'],
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    alignLeft: false,
                    padding: EdgeInsets.zero,
                    textStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorDialog('Location services are disabled. Please enable location services in your device settings.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog('Location permissions are denied. Please enable location permissions in your device settings.');
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorDialog('Location permissions are permanently denied. Please enable location permissions in your device settings.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String location = '';
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          location = place.locality!;
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            location += ', ${place.administrativeArea!}';
          }
        } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          location = place.subAdministrativeArea!;
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            location += ', ${place.administrativeArea!}';
          }
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          location = place.administrativeArea!;
        } else {
          location = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }

        setState(() {
          _locationController.text = location;
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
        _showErrorDialog('Could not determine your location. Please try again or enter manually.');
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showErrorDialog('Error getting location: ${e.toString()}. Please try again or enter manually.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Location Error',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
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
  }
}
