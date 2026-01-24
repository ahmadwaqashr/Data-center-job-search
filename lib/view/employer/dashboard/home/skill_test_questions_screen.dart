import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/api_config.dart';
import 'job_posted_screen.dart';

class SkillTestQuestionsScreen extends StatefulWidget {
  final String jobTitle;
  final String company;
  final String location;
  final String minPay;
  final String maxPay;
  final String shiftType;
  final String workType;
  final String locationType;
  final String salaryType;
  final String jobDescription;
  final String requirements;
  final List<String> skills;
  final List<String> shifts;
  final List<String> benefits;

  const SkillTestQuestionsScreen({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.minPay,
    required this.maxPay,
    required this.shiftType,
    required this.workType,
    required this.locationType,
    required this.salaryType,
    required this.jobDescription,
    required this.requirements,
    required this.skills,
    required this.shifts,
    required this.benefits,
  });

  @override
  State<SkillTestQuestionsScreen> createState() =>
      _SkillTestQuestionsScreenState();
}

class _SkillTestQuestionsScreenState extends State<SkillTestQuestionsScreen> {
  int passingScore = 80;
  int correctAnswersNeeded = 4;
  int totalQuestions = 5;

  List<QuestionModel> questions = [];

  // Core Expertise
  final Dio _dio = Dio();
  final TextEditingController _coreExpertiseSearchController = TextEditingController();
  final FocusNode _coreExpertiseFocusNode = FocusNode();
  List<Map<String, dynamic>> _coreExpertiseList = [];
  List<Map<String, dynamic>> _filteredCoreExpertiseList = [];
  Map<String, dynamic>? _selectedCoreExpertise;
  bool _isLoadingCoreExpertise = false;
  bool _isLoadingQuestions = false;
  bool _showCoreExpertiseDropdown = false;
  Timer? _searchDebounceTimer;
  int _questionMode = 0; // 0 = All questions, 1 = Manual questions
  final Set<int> _selectedQuestionIds = {};
  bool _isPostingJob = false;

  int get _questionCountForScore =>
      _selectedQuestionIds.isNotEmpty ? _selectedQuestionIds.length : totalQuestions;

  int _calculateCorrectAnswersNeeded(int count) {
    if (count <= 0) return 0;
    return ((passingScore / 100) * count).ceil();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    if (authToken != null && authToken.isNotEmpty) {
      return authToken;
    }

    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      final token = userData['token']?.toString();
      if (token != null && token.isNotEmpty) {
        return token;
      }
    }

    return null;
  }

  Future<void> _postJobToServer() async {
    if (_isPostingJob) return;

    if (_selectedCoreExpertise == null) {
      Get.snackbar(
        'Error',
        'Please select a core expertise',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedQuestionIds.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one question',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final token = await _getAuthToken();
    if (token == null) {
      Get.snackbar(
        'Error',
        'No authentication token found. Please login again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final minPay = double.tryParse(widget.minPay.toString().trim());
    final maxPay = double.tryParse(widget.maxPay.toString().trim());
    if (minPay == null || maxPay == null || minPay <= 0 || maxPay <= 0) {
      Get.snackbar(
        'Error',
        'Invalid pay range',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (maxPay < minPay) {
      Get.snackbar(
        'Error',
        'Max pay must be greater than or equal to min pay',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isPostingJob = true;
    });

    try {
      final payload = {
        'jobTitle': widget.jobTitle.trim(),
        'companyName': widget.company.trim(),
        'location': widget.location.trim(),
        'workType': widget.workType,
        'locationType': widget.locationType,
        'salarytype': widget.salaryType,
        'minPay': minPay,
        'maxPay': maxPay,
        'jobDescription': widget.jobDescription.trim(),
        'requirements': widget.requirements.trim(),
        'banefit': widget.benefits,
        'skills': widget.skills,
        'shifts': widget.shifts,
        'coreExpertiseId': _selectedCoreExpertise!['id'],
        'passingScore': passingScore,
        'selectedQuestionIds': _selectedQuestionIds.toList(),
      };

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.jobPosted),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: jsonEncode(payload),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        Get.to(
          () => JobPostedScreen(
            jobTitle: widget.jobTitle,
            company: widget.company,
            location: widget.location,
            minPay: widget.minPay,
            maxPay: widget.maxPay,
            shiftType: widget.shiftType,
          ),
        );
      } else {
        String errorMessage =
            response.statusMessage ?? 'Failed to post job';
        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap['message'] != null) {
            errorMessage = dataMap['message'].toString();
          }
        } else if (response.data != null) {
          errorMessage = response.data.toString();
        }
        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to post job';
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (e.response?.data is Map<String, dynamic>) {
          final dataMap = e.response?.data as Map<String, dynamic>;
          if (dataMap['message'] != null) {
            errorMessage = dataMap['message'].toString();
          }
        } else if (e.response?.data != null) {
          errorMessage = e.response?.data.toString() ?? errorMessage;
        } else if (e.message != null) {
          errorMessage = e.message!;
        }

        if (statusCode != null) {
          errorMessage = 'Error $statusCode: $errorMessage';
        }
      } else {
        errorMessage = '${e.toString()}';
      }
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPostingJob = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCoreExpertise();
    _coreExpertiseSearchController.addListener(_onCoreExpertiseSearchChanged);
    _coreExpertiseFocusNode.addListener(() {
      if (!_coreExpertiseFocusNode.hasFocus) {
        // Close dropdown when TextField loses focus (with a small delay to allow item selection)
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted && !_coreExpertiseFocusNode.hasFocus) {
            setState(() {
              _showCoreExpertiseDropdown = false;
            });
          }
        });
      } else {
        // Show dropdown when TextField gains focus and has text
        if (_coreExpertiseSearchController.text.isNotEmpty) {
          setState(() {
            _showCoreExpertiseDropdown = _filteredCoreExpertiseList.isNotEmpty;
          });
        }
      }
    });
    // Start with empty questions list - questions will be loaded after selecting core expertise
    questions = [];
    totalQuestions = 0;
    correctAnswersNeeded = 0;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _coreExpertiseSearchController.removeListener(_onCoreExpertiseSearchChanged);
    _coreExpertiseSearchController.dispose();
    _coreExpertiseFocusNode.dispose();
    _dio.close();
    super.dispose();
  }

  void _onCoreExpertiseSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterCoreExpertise(_coreExpertiseSearchController.text);
    });
  }

  void _filterCoreExpertise(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredCoreExpertiseList = List.from(_coreExpertiseList);
        _showCoreExpertiseDropdown = false;
      });
      return;
    }

    final filtered = _coreExpertiseList.where((expertise) {
      final name = expertise['name']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredCoreExpertiseList = filtered;
      // Always show dropdown when there are filtered results (user is actively typing)
      _showCoreExpertiseDropdown = filtered.isNotEmpty;
    });
    
    print('🔍 Filtering core expertise: "$query"');
    print('   Total items: ${_coreExpertiseList.length}');
    print('   Found ${filtered.length} results');
    print('   Showing dropdown: $_showCoreExpertiseDropdown');
    if (filtered.isNotEmpty) {
      print('   Results: ${filtered.map((e) => e['name']).join(", ")}');
    }
  }

  Future<void> _fetchCoreExpertise() async {
    setState(() {
      _isLoadingCoreExpertise = true;
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
        print('✅ Core Expertise API Response:');
        print('   Success: ${responseData['success']}');
        print('   Data: ${responseData['data']}');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _coreExpertiseList = List<Map<String, dynamic>>.from(responseData['data']);
            _filteredCoreExpertiseList = List.from(_coreExpertiseList);
            _isLoadingCoreExpertise = false;
          });
          print('✅ Loaded ${_coreExpertiseList.length} core expertise items');
          print('   Items: ${_coreExpertiseList.map((e) => e['name']).join(", ")}');
        } else {
          print('⚠️ API response indicates failure or no data');
          setState(() {
            _isLoadingCoreExpertise = false;
          });
        }
      } else {
        print('❌ API returned status code: ${response.statusCode}');
        setState(() {
          _isLoadingCoreExpertise = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching core expertise: $e');
      setState(() {
        _isLoadingCoreExpertise = false;
      });
    }
  }

  void _selectCoreExpertise(Map<String, dynamic> expertise) {
    setState(() {
      _selectedCoreExpertise = expertise;
      _coreExpertiseSearchController.text = expertise['name']?.toString() ?? '';
      _showCoreExpertiseDropdown = false;
      _selectedQuestionIds.clear();
    });
    FocusScope.of(context).unfocus();
    
    // Fetch questions for the selected core expertise
    final coreId = expertise['id'];
    if (coreId != null && _questionMode == 0) {
      _fetchQuestionsByCoreId(coreId);
    }
  }

  void _setQuestionMode(int mode) {
    if (_questionMode == mode) return;
    setState(() {
      _questionMode = mode;
      questions = [];
      totalQuestions = 0;
      correctAnswersNeeded = 0;
      _selectedQuestionIds.clear();
    });

    if (mode == 0 && _selectedCoreExpertise != null) {
      final coreId = _selectedCoreExpertise!['id'];
      if (coreId != null) {
        _fetchQuestionsByCoreId(coreId);
      }
    }
  }

  Future<void> _fetchQuestionsByCoreId(int coreId) async {
    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      var headers = {
        'Content-Type': 'application/json'
      };
      var data = jsonEncode({
        "core_id": coreId
      });
      
      print('📥 Fetching questions for core_id: $coreId');
      
      var response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.fetchQuestionsByCoreId),
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('✅ Questions API Response:');
        print('   Success: ${responseData['success']}');
        print('   Message: ${responseData['message']}');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final questionsData = List<Map<String, dynamic>>.from(responseData['data']);
          print('   Found ${questionsData.length} questions');
          
          // Convert API response to QuestionModel list
          List<QuestionModel> fetchedQuestions = questionsData.map((q) {
            // Convert choices to OptionModel list
            List<OptionModel> options = [];
            if (q['choices'] != null) {
              final choices = List<Map<String, dynamic>>.from(q['choices']);
              // Sort by number to maintain order
              choices.sort((a, b) => (a['number'] ?? 0).compareTo(b['number'] ?? 0));
              options = choices.map((choice) {
                return OptionModel(
                  text: choice['text']?.toString() ?? '',
                  isCorrect: choice['isCorrect'] == true,
                );
              }).toList();
            }
            
            // Determine tag color based on tag name
            Color tagColor = Color(0xFF2563EB); // Default blue
            final tag = q['tag']?.toString() ?? 'Custom';
            if (tag.toLowerCase().contains('core')) {
              tagColor = Color(0xFF2563EB);
            } else if (tag.toLowerCase().contains('operation')) {
              tagColor = Color(0xFF10B981);
            }
            
            return QuestionModel(
              id: q['id'] ?? 0,
              questionText: q['questionTitle']?.toString() ?? '',
              tag: tag,
              tagColor: tagColor,
              isRequired: true,
              isDraft: false,
              options: options,
            );
          }).toList();
          
          setState(() {
            questions = fetchedQuestions;
            totalQuestions = questions.length;
            correctAnswersNeeded =
                _calculateCorrectAnswersNeeded(_questionCountForScore);
            _selectedQuestionIds.clear();
            _isLoadingQuestions = false;
          });
          
          print('✅ Loaded ${questions.length} questions');
          Get.snackbar(
            'Success',
            'Loaded ${questions.length} questions for ${_selectedCoreExpertise?['name']}',
            backgroundColor: Color(0xFF10B981),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 2),
          );
        } else {
          setState(() {
            _isLoadingQuestions = false;
          });
          Get.snackbar(
            'Info',
            'No questions found for this core expertise',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        print('❌ API returned status code: ${response.statusCode}');
        setState(() {
          _isLoadingQuestions = false;
        });
        Get.snackbar(
          'Error',
          'Failed to fetch questions',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ Error fetching questions: $e');
      setState(() {
        _isLoadingQuestions = false;
      });
      Get.snackbar(
        'Error',
        'Error loading questions: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
                                'Skill test questions',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Add multiple choice questions for this job post.',
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
                          // Skill test info card
                          Container(
                            padding: EdgeInsets.all(20),
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
                                  'Skill test for ${widget.jobTitle}',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'Candidates will answer these before submitting their application. Keep each question focused and objective.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  'Passing score',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                GestureDetector(
                                  onTap: () {
                                    _showPassingScoreDialog();
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
                                        Text(
                                          '$passingScore% recommended',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '$correctAnswersNeeded / ${_questionCountForScore} correct',
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 18.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'You can adjust this later from the job pipeline.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Core Expertise section
                          Container(
                            padding: EdgeInsets.all(20),
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
                                  'Core Expertise',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _coreExpertiseSearchController,
                                      focusNode: _coreExpertiseFocusNode,
                                      onTap: () {
                                        setState(() {
                                          if (_coreExpertiseSearchController.text.isEmpty) {
                                            _filteredCoreExpertiseList = List.from(_coreExpertiseList);
                                          }
                                          _showCoreExpertiseDropdown = _filteredCoreExpertiseList.isNotEmpty;
                                        });
                                      },
                                      onChanged: (value) {
                                        // Immediately filter and show dropdown when typing
                                        _filterCoreExpertise(value);
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Search or select core expertise...',
                                        hintStyle: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[400],
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color: Colors.grey[400],
                                          size: 20.sp,
                                        ),
                                        suffixIcon: _coreExpertiseSearchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.clear,
                                                  color: Colors.grey[400],
                                                  size: 20.sp,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _coreExpertiseSearchController.clear();
                                                    _selectedCoreExpertise = null;
                                                    _showCoreExpertiseDropdown = false;
                                                    _filteredCoreExpertiseList =
                                                        List.from(_coreExpertiseList);
                                                    questions = [];
                                                    totalQuestions = 0;
                                                    correctAnswersNeeded = 0;
                                                    _selectedQuestionIds.clear();
                                                  });
                                                },
                                              )
                                            : null,
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
                                    if (_showCoreExpertiseDropdown && _filteredCoreExpertiseList.isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(top: 4.h),
                                        constraints: BoxConstraints(
                                          maxHeight: 200.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10.r),
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
                                          itemCount: _filteredCoreExpertiseList.length,
                                          itemBuilder: (context, index) {
                                            final expertise = _filteredCoreExpertiseList[index];
                                            final name = expertise['name']?.toString() ?? '';
                                            final isSelected = _selectedCoreExpertise != null &&
                                                _selectedCoreExpertise!['id'] == expertise['id'];

                                            return GestureDetector(
                                              onTap: () => _selectCoreExpertise(expertise),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 12.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.primaryColor.withOpacity(0.1)
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8.r),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          color: Colors.black,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Icon(
                                                        Icons.check,
                                                        color: AppColors.primaryColor,
                                                        size: 18.sp,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'Question mode',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Radio<int>(
                                      value: 0,
                                      groupValue: _questionMode,
                                      activeColor: AppColors.primaryColor,
                                      onChanged: (value) {
                                        if (value != null) {
                                          _setQuestionMode(value);
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        'All questions (from API)',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio<int>(
                                      value: 1,
                                      groupValue: _questionMode,
                                      activeColor: AppColors.primaryColor,
                                      onChanged: (value) {
                                        if (value != null) {
                                          _setQuestionMode(value);
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Manual questions',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isLoadingCoreExpertise)
                                  Padding(
                                    padding: EdgeInsets.only(top: 12.h),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_selectedCoreExpertise != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 12.h),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _selectedCoreExpertise!['name']?.toString() ?? '',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedCoreExpertise = null;
                                                _coreExpertiseSearchController.clear();
                                                questions = [];
                                                totalQuestions = 0;
                                                correctAnswersNeeded = 0;
                                                _selectedQuestionIds.clear();
                                              });
                                            },
                                            child: Icon(
                                              Icons.close,
                                              size: 16.sp,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Questions section
                          Container(
                            padding: EdgeInsets.all(20),
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
                                  'Questions',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Use multiple choice with a single correct answer for faster auto-scoring.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                if (!_isLoadingQuestions && questions.isNotEmpty)
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _selectedQuestionIds.length ==
                                            questions.length,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedQuestionIds
                                                ..clear()
                                                ..addAll(
                                                  questions.map((q) => q.id),
                                                );
                                            } else {
                                              _selectedQuestionIds.clear();
                                            }
                                            correctAnswersNeeded =
                                                _calculateCorrectAnswersNeeded(
                                              _questionCountForScore,
                                            );
                                          });
                                        },
                                        activeColor: AppColors.primaryColor,
                                      ),
                                      Text(
                                        'Select all',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        '${_selectedQuestionIds.length} selected',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                // Loading indicator or Questions list
                                if (_isLoadingQuestions)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40.h),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryColor,
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          Text(
                                            'Loading questions...',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (questions.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40.h),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.quiz_outlined,
                                            size: 48.sp,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(height: 16.h),
                                          Text(
                                            'No questions available',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            _questionMode == 1
                                                ? 'Add questions manually using the button below'
                                                : 'Select a core expertise to load questions',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ...questions.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    QuestionModel question = entry.value;
                                    return Column(
                                      children: [
                                        _buildQuestionCard(
                                          question,
                                          index,
                                          isSelected: _selectedQuestionIds
                                              .contains(question.id),
                                          onToggleSelected: (selected) {
                                            setState(() {
                                              if (selected == true) {
                                                _selectedQuestionIds
                                                    .add(question.id);
                                              } else {
                                                _selectedQuestionIds
                                                    .remove(question.id);
                                              }
                                              correctAnswersNeeded =
                                                  _calculateCorrectAnswersNeeded(
                                                _questionCountForScore,
                                              );
                                            });
                                          },
                                        ),
                                        if (index < questions.length - 1)
                                          SizedBox(height: 16.h),
                                      ],
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          if (_selectedCoreExpertise != null) ...[
                            // Add another question button
                            GestureDetector(
                              onTap: () {
                                _showAddQuestionDialog();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.2,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: AppColors.primaryColor,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add another question',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          'Multiple choice, single correct answer',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                          ],
                          // Action buttons
                          if (_selectedCoreExpertise != null) ...[
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Column(
                                children: [
                                  GestureDetector(
                                  onTap: _isPostingJob ? null : _postJobToServer,
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
                                          _isPostingJob ? 'Posting...' : 'Save & continue',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  GestureDetector(
                                    onTap: () {
                                      Get.back();
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
                                          'Skip for now',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'You can refine questions and scoring anytime from the job\'s pipeline.',
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

  Widget _buildQuestionCard(
    QuestionModel question,
    int index, {
    required bool isSelected,
    required ValueChanged<bool?> onToggleSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (question.isDraft) {
          _showAddQuestionDialog(editQuestion: question, questionIndex: index);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: onToggleSelected,
                activeColor: AppColors.primaryColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${question.isDraft ? 'Add your own multiple choice question' : question.questionText}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 2.h,
                      children: [
                        Text(
                          'Single choice',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          question.isDraft ? 'Draft' : 'Required',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: question.tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    question.tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: question.tagColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (question.isDraft) ...[
            SizedBox(height: 16.h),
            Text(
              'Question text',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 1),
                Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type your question here...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                filled: true,
                fillColor: Colors.white,
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
              'Options',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          // Options
          ...question.options.asMap().entries.map((entry) {
            int optionIndex = entry.key;
            OptionModel option = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    width: 20.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            option.isCorrect
                                ? Color(0xFF10B981)
                                : Colors.grey[300]!,
                        width: 2,
                      ),
                      color:
                          option.isCorrect
                              ? Color(0xFF10B981)
                              : Colors.transparent,
                    ),
                    child:
                        option.isCorrect
                            ? Icon(
                              Icons.circle,
                              size: 10.sp,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(fontSize: 14.sp, color: Colors.black),
                    ),
                  ),
                  if (option.isCorrect)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'Correct',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }          ).toList(),
        ],
      ),
    ));
  }
  void _showPassingScoreDialog() {
    final TextEditingController scoreController = TextEditingController(
      text: passingScore.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Edit passing score',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set the percentage required to pass',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Passing score (%)',
                hintText: '80',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newScore = int.tryParse(scoreController.text);
              if (newScore != null && newScore >= 0 && newScore <= 100) {
                setState(() {
                  passingScore = newScore;
                  correctAnswersNeeded =
                      _calculateCorrectAnswersNeeded(_questionCountForScore);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog({
    QuestionModel? editQuestion,
    int? questionIndex,
  }) {
    final TextEditingController questionController = TextEditingController(
      text: editQuestion?.questionText ?? '',
    );
    final TextEditingController tagController = TextEditingController(
      text: editQuestion?.tag ?? '',
    );
    List<TextEditingController> optionControllers = [];
    List<bool> optionCorrectness = [];
    bool isRequired = editQuestion?.isRequired ?? true;
    bool isSubmitting = false;

    if (editQuestion != null) {
      for (var option in editQuestion.options) {
        optionControllers.add(TextEditingController(text: option.text));
        optionCorrectness.add(option.isCorrect);
      }
    } else {
      optionControllers = [
        TextEditingController(),
        TextEditingController(),
      ];
      optionCorrectness = [true, false];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editQuestion != null
                                ? 'Edit question'
                                : 'Add new question',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (_selectedCoreExpertise != null) ...[
                            SizedBox(height: 6.h),
                            Text(
                              'Core expertise: ${_selectedCoreExpertise!['name']?.toString() ?? ''}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          SizedBox(height: 20.h),
                          // Question text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question text',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          TextField(
                            controller: questionController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Type your question here...',
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
                          // Tag
                          Text(
                            'Category tag',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextField(
                            controller: tagController,
                            decoration: InputDecoration(
                              hintText: 'Type category tag...',
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
                                vertical: 12.h,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Options
                          Text(
                            'Options',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Select one correct answer',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ...List.generate(optionControllers.length, (index) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        for (int i = 0;
                                            i < optionCorrectness.length;
                                            i++) {
                                          optionCorrectness[i] = i == index;
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: 24.w,
                                      height: 24.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              optionCorrectness[index]
                                                  ? Color(0xFF10B981)
                                                  : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                        color:
                                            optionCorrectness[index]
                                                ? Color(0xFF10B981)
                                                : Colors.transparent,
                                      ),
                                      child:
                                          optionCorrectness[index]
                                              ? Icon(
                                                Icons.circle,
                                                size: 12.sp,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: TextField(
                                      controller: optionControllers[index],
                                      decoration: InputDecoration(
                                        hintText:
                                            'Option ${index + 1}${optionCorrectness[index] ? ' (Correct)' : ''}',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
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
                                          vertical: 12.h,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (optionControllers.length > 2)
                                    IconButton(
                                      onPressed: () {
                                        setModalState(() {
                                          optionControllers.removeAt(index);
                                          optionCorrectness.removeAt(index);
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        size: 20.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: () {
                              if (optionControllers.length >= 5) {
                                Get.snackbar(
                                  'Limit reached',
                                  'You can add up to 5 options only',
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              setModalState(() {
                                optionControllers.add(TextEditingController());
                                optionCorrectness.add(false);
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  color: optionControllers.length >= 5
                                      ? Colors.grey[400]
                                      : AppColors.primaryColor,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Add option',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: optionControllers.length >= 5
                                        ? Colors.grey[400]
                                        : AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
                          // Save button
                          GestureDetector(
                            onTap: isSubmitting
                                ? null
                                : () async {
                                    if (isSubmitting) {
                                      return;
                                    }
                                    if (_selectedCoreExpertise == null) {
                                      Get.snackbar(
                                        'Error',
                                        'Please select a core expertise first',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      return;
                                    }

                                    if (questionController.text.trim().isEmpty) {
                                      Get.snackbar(
                                        'Error',
                                        'Please enter a question',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      return;
                                    }

                                    if (tagController.text.trim().isEmpty) {
                                      Get.snackbar(
                                        'Error',
                                        'Please enter a category tag',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      return;
                                    }

                                    if (optionControllers.length < 4) {
                                      Get.snackbar(
                                        'Error',
                                        'Please add at least 4 options',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      return;
                                    }

                                    for (final controller in optionControllers) {
                                      if (controller.text.trim().isEmpty) {
                                        Get.snackbar(
                                          'Error',
                                          'Please fill all option fields',
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                        return;
                                      }
                                    }

                                    // Validate at least one correct answer
                                    if (!optionCorrectness.contains(true)) {
                                      Get.snackbar(
                                        'Error',
                                        'Please select a correct answer',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      return;
                                    }

                                    final correctIndex =
                                        optionCorrectness.indexOf(true);
                                    if (correctIndex < 0) {
                                      Get.snackbar(
                                        'Error',
                                        'Please select a correct answer',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      return;
                                    }

                                    final tagText = tagController.text.trim();
                                    final optionTexts = optionControllers
                                        .map((c) => c.text.trim())
                                        .toList();

                                    if (editQuestion != null &&
                                        questionIndex != null) {
                                      // Update locally for edits
                                      setState(() {
                                        questions[questionIndex] = QuestionModel(
                                          id: editQuestion.id,
                                          questionText:
                                              questionController.text.trim(),
                                          tag: tagText,
                                          tagColor: Color(0xFF2563EB),
                                          isRequired: isRequired,
                                          isDraft: false,
                                          options: optionTexts
                                              .asMap()
                                              .entries
                                              .map(
                                                (entry) => OptionModel(
                                                  text: entry.value,
                                                  isCorrect:
                                                      entry.key == correctIndex,
                                                ),
                                              )
                                              .toList(),
                                        );
                                      });

                                      Navigator.pop(context);
                                      Get.snackbar(
                                        'Success',
                                        'Question updated',
                                        backgroundColor: Color(0xFF10B981),
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      return;
                                    }

                                    setModalState(() {
                                      isSubmitting = true;
                                    });

                                    try {
                                      final headers = {
                                        'Content-Type': 'application/json',
                                      };
                                      final data = jsonEncode({
                                        'core_id': _selectedCoreExpertise!['id'],
                                        'question_title':
                                            questionController.text.trim(),
                                        'tag': tagText,
                                        'choice1':
                                            optionTexts.length > 0 ? optionTexts[0] : '',
                                        'choice2':
                                            optionTexts.length > 1 ? optionTexts[1] : '',
                                        'choice3':
                                            optionTexts.length > 2 ? optionTexts[2] : '',
                                        'choice4':
                                            optionTexts.length > 3 ? optionTexts[3] : '',
                                        'choice5':
                                            optionTexts.length > 4 ? optionTexts[4] : null,
                                        'correct_choice': correctIndex + 1,
                                      });

                                      final response = await _dio.request(
                                        ApiConfig.getUrl(
                                          ApiConfig.createTestQuestion,
                                        ),
                                        options: Options(
                                          method: 'POST',
                                          headers: headers,
                                        ),
                                        data: data,
                                      );

                                      final statusCode = response.statusCode ?? 0;
                                      if (statusCode >= 200 && statusCode < 300) {
                                        final responseData = response.data;

                                        final createdOptions = <OptionModel>[];
                                        for (int i = 1; i <= 5; i++) {
                                          final choiceValue =
                                              responseData['choice$i'];
                                          if (choiceValue != null &&
                                              choiceValue.toString().trim().isNotEmpty) {
                                            createdOptions.add(
                                              OptionModel(
                                                text: choiceValue.toString(),
                                                isCorrect:
                                                    responseData['correctChoice'] ==
                                                        i,
                                              ),
                                            );
                                          }
                                        }

                                        final createdQuestion = QuestionModel(
                                          id: responseData['id'] ?? 0,
                                          questionText:
                                              responseData['questionTitle']?.toString() ??
                                                  questionController.text.trim(),
                                          tag: responseData['tag']?.toString() ??
                                              tagText,
                                          tagColor: Color(0xFF2563EB),
                                          isRequired: true,
                                          isDraft: false,
                                          options: createdOptions.isNotEmpty
                                              ? createdOptions
                                              : optionTexts
                                                  .asMap()
                                                  .entries
                                                  .map(
                                                    (entry) => OptionModel(
                                                      text: entry.value,
                                                      isCorrect:
                                                          entry.key == correctIndex,
                                                    ),
                                                  )
                                                  .toList(),
                                        );

                                        setState(() {
                                          final existingIndex = questions.indexWhere(
                                            (q) => q.id == createdQuestion.id,
                                          );
                                          if (existingIndex >= 0) {
                                            questions[existingIndex] = createdQuestion;
                                          } else {
                                            questions.add(createdQuestion);
                                          }
                                          totalQuestions = questions.length;
                                          correctAnswersNeeded =
                                              _calculateCorrectAnswersNeeded(
                                                _questionCountForScore,
                                              );
                                          _selectedQuestionIds.add(
                                            createdQuestion.id,
                                          );
                                        });

                                        setModalState(() {
                                          isSubmitting = false;
                                        });
                                        Navigator.pop(context);
                                        Get.snackbar(
                                          'Success',
                                          'Question added',
                                          backgroundColor: Color(0xFF10B981),
                                          colorText: Colors.white,
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      } else {
                                        Get.snackbar(
                                          'Error',
                                          response.statusMessage ??
                                              'Failed to add question',
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                        setModalState(() {
                                          isSubmitting = false;
                                        });
                                      }
                                    } catch (e) {
                                      Get.snackbar(
                                        'Error',
                                        'Failed to add question: ${e.toString()}',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      setModalState(() {
                                        isSubmitting = false;
                                      });
                                    }
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
                                  editQuestion != null
                                      ? 'Update question'
                                      : isSubmitting
                                          ? 'Saving...'
                                          : 'Add question',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildActionChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color:
            isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          color: isSelected ? AppColors.primaryColor : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Models
class QuestionModel {
  final int id;
  final String questionText;
  final String tag;
  final Color tagColor;
  final bool isRequired;
  final bool isDraft;
  final List<OptionModel> options;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.tag,
    required this.tagColor,
    required this.isRequired,
    this.isDraft = false,
    required this.options,
  });
}

class OptionModel {
  final String text;
  final bool isCorrect;

  OptionModel({required this.text, required this.isCorrect});
}
