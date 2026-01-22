import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/api_config.dart';
import '../../../../constants/colors.dart';

class SkillsPreferencesScreen extends StatefulWidget {
  const SkillsPreferencesScreen({super.key});

  @override
  State<SkillsPreferencesScreen> createState() =>
      _SkillsPreferencesScreenState();
}

class _SkillsPreferencesScreenState extends State<SkillsPreferencesScreen> {
  List<Map<String, dynamic>> _coreSkills = [];
  List<Map<String, dynamic>> _availableSkills = [];
  List<Map<String, dynamic>> _filteredSkills = [];
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  bool _isLoadingSkills = true;

  List<String> _preferredRoles = [];
  bool _isLoadingRoles = true;
  String? _selectedRoleFocus;
  String _selectedWorkStyle = 'On-site';
  String _selectedAvailability = 'Full-time';
  bool _isSaving = false;
  int? _skillsPreferencesId; // Store ID if data already exists
  String? _profilePicUrl;
  bool _isLoadingProfile = true;

  // Location-related state
  static const String _googlePlacesApiKey = "AIzaSyBsOA0owjpxAXWhxPdD_kit9W9jHgPwDUI";
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _locationPredictions = [];
  List<Map<String, dynamic>> _selectedLocations = [];
  Timer? _locationDebounceTimer;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchSkills();
    _fetchPreferredRoles();
    _fetchSkillsPreferences();
    _searchController.addListener(_onSearchChanged);
    _locationController.addListener(_onLocationSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile picture every time screen comes into focus to get latest data
    if (mounted) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _locationDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _locationController.removeListener(_onLocationSearchChanged);
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      final query = _searchController.text.toLowerCase().trim();
      if (query.isEmpty) {
        setState(() {
          _filteredSkills = [];
        });
      } else {
        setState(() {
          // Filter skills that match the query and are not already added (case-insensitive)
          _filteredSkills = _availableSkills
              .where((skill) {
                final skillName = skill['name'].toString().trim().toLowerCase();
                final isAlreadyAdded = _coreSkills.any((s) => 
                    s['name'].toString().trim().toLowerCase() == skillName);
                final matchesQuery = skillName.contains(query);
                return matchesQuery && !isAlreadyAdded;
              })
              .toList();
        });
        print('🔍 Search query: "$query"');
        print('   Available skills: ${_availableSkills.length}');
        print('   Current skills: ${_coreSkills.length}');
        print('   Filtered results: ${_filteredSkills.length}');
      }
    });
  }

  Future<void> _fetchSkills() async {
    try {
      setState(() {
        _isLoadingSkills = true;
      });

      print('📥 Fetching core expertise from API...');

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchCoreExpertise),
        options: Options(
          method: 'POST',
        ),
        data: '',
      );

      if (response.statusCode == 200) {
        print('✅ Core expertise fetched successfully');
        print('   Response: ${jsonEncode(response.data)}');

        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          final dataList = responseData['data'] as List;
          setState(() {
            _availableSkills = dataList.map((item) {
              return {
                'id': item['id'],
                'name': item['name']?.toString() ?? '',
              };
            }).toList();
            _isLoadingSkills = false;
          });
        } else {
          setState(() {
            _availableSkills = [];
            _isLoadingSkills = false;
          });
        }
      } else {
        throw Exception('Failed to fetch skills: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Error fetching skills: $e');
      setState(() {
        _availableSkills = [];
        _isLoadingSkills = false;
      });
    }
  }

  Future<void> _fetchPreferredRoles() async {
    try {
      setState(() {
        _isLoadingRoles = true;
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
          _preferredRoles = [];
          _isLoadingRoles = false;
        });
        return;
      }

      print('📥 Fetching preferred roles from API...');

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchPreferredRoles),
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: '',
      );

      if (response.statusCode == 200) {
        print('✅ Preferred roles fetched successfully');
        print('   Response: ${jsonEncode(response.data)}');

        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          final dataList = responseData['data'] as List;
          final roles = dataList.map((item) {
            return item['name']?.toString() ?? '';
          }).where((name) => name.isNotEmpty).toList();

          setState(() {
            _preferredRoles = roles;
            // Set first role as selected if none selected
            if (_selectedRoleFocus == null && roles.isNotEmpty) {
              _selectedRoleFocus = roles.first;
            }
            _isLoadingRoles = false;
          });
        } else {
          setState(() {
            _preferredRoles = [];
            _isLoadingRoles = false;
          });
        }
      } else {
        throw Exception('Failed to fetch preferred roles: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Error fetching preferred roles: $e');
      setState(() {
        _preferredRoles = [];
        _isLoadingRoles = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      print('📥 Loading profile picture from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        String? newProfilePicUrl;
        
        if (userData['profilePic'] != null && userData['profilePic'].toString().isNotEmpty) {
          newProfilePicUrl = ApiConfig.getImageUrl(userData['profilePic'].toString());
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
      print('❌ Error loading profile picture: $e');
      if (mounted) {
        setState(() {
          _profilePicUrl = null;
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _fetchSkillsPreferences() async {
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
        print('⚠️ No authentication token found');
        return;
      }

      print('📥 Fetching existing skills preferences from API...');

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchSkillsPreferences),
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: '',
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
            
            // Store the ID for editing
            _skillsPreferencesId = skillsData['id'] != null 
                ? int.tryParse(skillsData['id'].toString()) 
                : null;
            
            setState(() {
              // Populate core skills
              if (skillsData['coreName'] != null && skillsData['coreName'] is List) {
                final coreNames = skillsData['coreName'] as List;
                _coreSkills = coreNames.asMap().entries.map<Map<String, dynamic>>((entry) {
                  final index = entry.key;
                  final skillName = entry.value.toString();
                  return <String, dynamic>{
                    'name': skillName,
                    'isPrimary': index == 0, // First skill is primary
                  };
                }).toList();
              }

              // Populate preferred role focus
              if (skillsData['preferredName'] != null) {
                _selectedRoleFocus = skillsData['preferredName'].toString();
              }

              // Populate work style
              if (skillsData['workStyle'] != null) {
                _selectedWorkStyle = skillsData['workStyle'].toString();
              }

              // Populate availability
              if (skillsData['availability'] != null) {
                _selectedAvailability = skillsData['availability'].toString();
              }

              // Populate locations
              if (skillsData['location'] != null && skillsData['location'] is List) {
                final locations = skillsData['location'] as List;
                _selectedLocations = locations.map<Map<String, dynamic>>((loc) {
                  return <String, dynamic>{
                    'name': loc.toString(),
                    'radius': '25 mi radius', // Default radius
                  };
                }).toList();
              }
            });

            print('✅ Skills preferences populated:');
            print('   Core Skills: ${_coreSkills.map((s) => s['name']).toList()}');
            print('   Role Focus: $_selectedRoleFocus');
            print('   Work Style: $_selectedWorkStyle');
            print('   Availability: $_selectedAvailability');
            print('   Locations: ${_selectedLocations.map((l) => l['name']).toList()}');
          }
        }
      } else {
        throw Exception('Failed to fetch skills preferences: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Error fetching skills preferences: $e');
      // Don't show error to user, just log it - it's okay if no preferences exist yet
    }
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
            print('✅ Location predictions updated in UI');
          } else {
            print('⚠️ Widget not mounted, cannot update predictions');
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

  void _addLocation(Map<String, dynamic> prediction) {
    final locationName = prediction['description']?.toString() ?? '';
    if (locationName.isEmpty) {
      print('⚠️ Empty location name');
      return;
    }

    print('🔍 Checking if location exists: $locationName');
    print('   Current locations: ${_selectedLocations.map((l) => l['name']).toList()}');

    // Check if location already exists (case-insensitive)
    final exists = _selectedLocations.any((loc) => 
        loc['name'].toString().toLowerCase().trim() == locationName.toLowerCase().trim());
    
    if (exists) {
      print('⚠️ Location already exists: $locationName');
      Get.snackbar(
        'Info',
        'Location already added',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    // Cancel any pending location search debounce
    _locationDebounceTimer?.cancel();

    print('✅ Adding location: $locationName');
    
    if (!mounted) {
      print('⚠️ Widget not mounted, cannot add location');
      return;
    }
    
    setState(() {
      final newLocation = Map<String, dynamic>.from({
        'name': locationName.toString(),
        'radius': '25 mi radius', // Default radius
      });
      _selectedLocations.add(newLocation);
      // Clear predictions immediately
      _locationPredictions = [];
    });
    
    // Clear search controller after state update
    _locationController.clear();
    
    print('✅ Location added successfully. Total locations: ${_selectedLocations.length}');
    print('   Updated locations: ${_selectedLocations.map((l) => l['name']).toList()}');
  }

  void _removeLocation(int index) {
    setState(() {
      _selectedLocations.removeAt(index);
    });
  }

  Future<void> _saveSkillsPreferences() async {
    if (_isSaving) return; // Prevent multiple clicks

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
        setState(() {
          _isSaving = false;
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

      // Check if editing existing data or adding new
      final isEditing = _skillsPreferencesId != null;
      
      print('📤 ${isEditing ? "Updating" : "Saving"} skills preferences...');
      if (isEditing) {
        print('   Editing ID: $_skillsPreferencesId');
      }

      // Prepare FormData - all parameters are optional for edit
      final Map<String, dynamic> formDataMap = {};

      // Add core_name (send all skills as JSON array for both add and edit)
      if (_coreSkills.isNotEmpty) {
        final coreNames = _coreSkills.map((skill) => skill['name'].toString()).toList();
        formDataMap['core_name'] = jsonEncode(coreNames);
      }

      // Add preferred_name (optional)
      if (_selectedRoleFocus != null && _selectedRoleFocus!.isNotEmpty) {
        formDataMap['preferred_name'] = _selectedRoleFocus;
      }

      // Add work_style (optional)
      if (_selectedWorkStyle.isNotEmpty) {
        formDataMap['work_style'] = _selectedWorkStyle;
      }

      // Add availability (optional)
      if (_selectedAvailability.isNotEmpty) {
        formDataMap['availability'] = _selectedAvailability;
      }

      // Add location (send all locations as JSON array for both add and edit)
      if (_selectedLocations.isNotEmpty) {
        final locations = _selectedLocations.map((loc) => loc['name'].toString()).toList();
        formDataMap['location'] = jsonEncode(locations);
      }

      // Validate required fields only for add (not for edit)
      if (!isEditing) {
        if (_selectedRoleFocus == null || _selectedRoleFocus!.isEmpty) {
          setState(() {
            _isSaving = false;
          });
          Get.snackbar(
            'Validation Error',
            'Please select a role focus',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      print('   FormData: ${formDataMap.keys.toList()}');
      print('   Core Skills: ${formDataMap['core_name']}');
      print('   Locations: ${formDataMap['location']}');

      final formData = FormData.fromMap(formDataMap);

      // Determine API endpoint
      final String apiUrl = isEditing
          ? ApiConfig.getEditSkillsUrl(_skillsPreferencesId!)
          : ApiConfig.getUrl(ApiConfig.addSkills);

      // Make API call
      final response = await _dio.request(
        apiUrl,
        options: Options(
          method: 'POST',
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: formData,
      );

      if (response.statusCode == 200) {
        print('✅ Skills preferences ${isEditing ? "updated" : "saved"} successfully');
        print('   Response: ${jsonEncode(response.data)}');

        // Store the ID if it's a new record
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data['id'] != null) {
            setState(() {
              _skillsPreferencesId = int.tryParse(data['id'].toString());
            });
          }
        }

        Get.snackbar(
          'Success',
          'Skills preferences ${isEditing ? "updated" : "saved"} successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate back after a short delay and return true to indicate success
        Future.delayed(Duration(milliseconds: 500), () {
          Navigator.of(context).pop(true);
        });
      } else {
        throw Exception('Failed to ${isEditing ? "update" : "save"} skills preferences: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ Error saving skills preferences: $e');
      setState(() {
        _isSaving = false;
      });
      Get.snackbar(
        'Error',
        'Failed to save skills preferences: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _addSkill(Map<String, dynamic> skill) {
    // Check if skill already exists (case-insensitive comparison)
    final skillName = skill['name'].toString().trim();
    final exists = _coreSkills.any((s) => 
        s['name'].toString().trim().toLowerCase() == skillName.toLowerCase());
    
    print('🔍 Adding skill: $skillName');
    print('   Current skills: ${_coreSkills.map((s) => s['name']).toList()}');
    print('   Already exists: $exists');
    
    if (!exists) {
      // Cancel any pending search debounce
      _searchDebounceTimer?.cancel();
      
      if (!mounted) {
        print('⚠️ Widget not mounted, cannot add skill');
        return;
      }
      
      setState(() {
        // Add as non-primary by default (first skill becomes primary if list is empty)
        final newSkill = Map<String, dynamic>.from({
          'name': skillName.toString(),
          'isPrimary': _coreSkills.isEmpty,
        });
        _coreSkills.add(newSkill);
        // Clear filtered skills and search immediately
        _filteredSkills = [];
      });
      // Clear search controller (this will trigger listener but we've already cleared filtered list)
      _searchController.clear();
      
      print('✅ Skill added successfully. Total skills: ${_coreSkills.length}');
      print('   Updated skills: ${_coreSkills.map((s) => s['name']).toList()}');
    } else {
      print('⚠️ Skill already exists: $skillName');
      Get.snackbar(
        'Info',
        'Skill already added',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }

  void _togglePrimarySkill(int index) {
    setState(() {
      // Set all to false first
      for (var skill in _coreSkills) {
        skill['isPrimary'] = false;
      }
      // Set selected one to true
      _coreSkills[index]['isPrimary'] = true;
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
                          onTap: () => Navigator.of(context).pop(false),
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
                                  'Skills & preferences',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Tune your matches based on your strengths.',
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
                          // Core skills section
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
                                  'Core skills',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Update the skills you want recruiters to see first.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Search and add skills header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Search and add skills',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Container(
                                      width: 8.w,
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Search field
                                Container(
                                  height: 45.h,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Colors.grey[500],
                                        size: 22.sp,
                                      ),
                                      hintText: 'Start typing to find skills',
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
                                // Search results dropdown
                                if (_filteredSkills.isNotEmpty) ...[
                                  SizedBox(height: 12.h),
                                  Container(
                                    constraints: BoxConstraints(maxHeight: 200.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredSkills.length,
                                      itemBuilder: (context, index) {
                                        final skill = _filteredSkills[index];
                                        final skillName = skill['name'].toString();
                                        final isAlreadyAdded = _coreSkills.any(
                                            (s) => s['name'] == skillName);
                                        
                                        return InkWell(
                                          onTap: isAlreadyAdded
                                              ? null
                                              : () {
                                                  print('👆 Skill tapped: $skillName');
                                                  // Dismiss keyboard first
                                                  FocusScope.of(context).unfocus();
                                                  // Small delay to ensure keyboard is dismissed
                                                  Future.delayed(Duration(milliseconds: 100), () {
                                                    if (mounted) {
                                                      _addSkill(skill);
                                                    }
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 12.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isAlreadyAdded
                                                  ? Colors.grey[100]
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                  child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                                  skillName,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                                      color: isAlreadyAdded
                                                          ? Colors.grey[400]
                                                          : Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                                if (isAlreadyAdded)
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 20.sp,
                                                    color: Colors.green,
                                                  )
                                                else
                                                  Icon(
                                                    Icons.add_circle_outline,
                                                    size: 20.sp,
                                                    color: AppColors.primaryColor,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                SizedBox(height: 16.h),
                                // Skills list
                                _coreSkills.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20.h),
                                          child: Text(
                                            'No skills added yet. Search and add skills above.',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8.w,
                                        runSpacing: 8.h,
                                        children: _coreSkills.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final skill = entry.value;
                                          return _buildSkillChip(
                                            skill['name'],
                                            isPrimary: skill['isPrimary'],
                                            onDelete: () {
                                              setState(() {
                                                _coreSkills.removeAt(index);
                                                // If deleted skill was primary and list is not empty, make first one primary
                                                if (_coreSkills.isNotEmpty &&
                                                    skill['isPrimary'] == true) {
                                                  _coreSkills[0]['isPrimary'] = true;
                                                }
                                              });
                                            },
                                            onPrimaryTap: () {
                                              _togglePrimarySkill(index);
                                            },
                                          );
                                        }).toList(),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Preferred roles section
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
                                  'Preferred roles',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Help us prioritize roles that match how you want to work.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Role focus
                                Text(
                                  'Role focus',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _isLoadingRoles
                                    ? Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20.h),
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                AppColors.primaryColor),
                                          ),
                                        ),
                                      )
                                    : _preferredRoles.isEmpty
                                        ? Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(vertical: 20.h),
                                              child: Text(
                                                'No roles available',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          )
                                        : Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                            children: _preferredRoles.map((role) {
                                              return _buildSelectableChip(
                                                role,
                                                _selectedRoleFocus == role,
                                      () {
                                        setState(() {
                                                    _selectedRoleFocus = role;
                                        });
                                      },
                                              );
                                            }).toList(),
                                ),
                                SizedBox(height: 16.h),
                                // Work style
                                Text(
                                  'Work style',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildSelectableChip(
                                      'On-site',
                                      _selectedWorkStyle == 'On-site',
                                      () {
                                        setState(() {
                                          _selectedWorkStyle = 'On-site';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Hybrid',
                                      _selectedWorkStyle == 'Hybrid',
                                      () {
                                        setState(() {
                                          _selectedWorkStyle = 'Hybrid';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Remote',
                                      _selectedWorkStyle == 'Remote',
                                      () {
                                        setState(() {
                                          _selectedWorkStyle = 'Remote';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'You can always adjust this per-application.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Location & schedule section
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
                                  'Location & schedule',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Set where and when you\'re available to work.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                // Preferred locations
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Preferred locations',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Container(
                                      width: 8.w,
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Add cities or regions field
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
                                      hintText: 'Add cities or regions',
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
                                              // Dismiss keyboard first
                                              FocusScope.of(context).unfocus();
                                              // Small delay to ensure keyboard is dismissed
                                              Future.delayed(Duration(milliseconds: 100), () {
                                                if (mounted) {
                                                  _addLocation(prediction);
                                                }
                                              });
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
                                SizedBox(height: 12.h),
                                // Selected locations chips
                                if (_selectedLocations.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 8.w,
                                    runSpacing: 8.h,
                                    children: _selectedLocations.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final location = entry.value;
                                      return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              location['name'],
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            location['radius'],
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(width: 6.w),
                                            GestureDetector(
                                              onTap: () => _removeLocation(index),
                                              child: Icon(
                                            Icons.close,
                                            size: 16.sp,
                                            color: Colors.grey[600],
                                              ),
                                          ),
                                        ],
                                      ),
                                      );
                                    }).toList(),
                                    ),
                                  SizedBox(height: 12.h),
                                ],
                                // Add location button
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.add,
                                          color: AppColors.primaryColor,
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Add location',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                // Availability
                                Text(
                                  'Availability',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    _buildSelectableChip(
                                      'Full-time',
                                      _selectedAvailability == 'Full-time',
                                      () {
                                        setState(() {
                                          _selectedAvailability = 'Full-time';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Part-time',
                                      _selectedAvailability == 'Part-time',
                                      () {
                                        setState(() {
                                          _selectedAvailability = 'Part-time';
                                        });
                                      },
                                    ),
                                    _buildSelectableChip(
                                      'Weekends',
                                      _selectedAvailability == 'Weekends',
                                      () {
                                        setState(() {
                                          _selectedAvailability = 'Weekends';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Save changes button
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveSkillsPreferences,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.6),
                              ),
                              child: _isSaving
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                'Save changes',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
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

  Widget _buildSkillChip(
    String label, {
    bool isPrimary = false,
    required VoidCallback onDelete,
    VoidCallback? onPrimaryTap,
  }) {
    return GestureDetector(
      onTap: onPrimaryTap,
      child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
        borderRadius: BorderRadius.circular(20.r),
          border: isPrimary
              ? Border.all(color: AppColors.primaryColor, width: 1)
              : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPrimary) ...[
            SizedBox(width: 6.w),
            Text(
              'Primary',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
            ),
          ],
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 16.sp, color: Colors.grey[600]),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSelectableChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isSelected ? AppColors.primaryColor : Colors.black,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
