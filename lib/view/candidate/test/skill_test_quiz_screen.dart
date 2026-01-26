import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';
import 'skill_test_result_screen.dart';

class SkillTestQuizScreen extends StatefulWidget {
  final String jobTitle;
  final String company;
  final Map<String, dynamic>? jobData;
  final String? goodFitAnswer;
  final String? startDate;
  final bool? shareProfile;

  const SkillTestQuizScreen({
    super.key,
    required this.jobTitle,
    required this.company,
    this.jobData,
    this.goodFitAnswer,
    this.startDate,
    this.shareProfile,
  });

  @override
  State<SkillTestQuizScreen> createState() => _SkillTestQuizScreenState();
}

class _SkillTestQuizScreenState extends State<SkillTestQuizScreen> {
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {}; // questionIndex: optionIndex
  Timer? _timer;
  int remainingSeconds = 600; // 10 minutes = 600 seconds
  final Dio _dio = Dio();

  List<Map<String, dynamic>> questions = [];
  bool _isLoadingQuestions = true;
  String? _errorMessage;
  int? _passingScore;
  int? _coreExpertiseId;
  List<int>? _selectedQuestionIds;
  // Fallback questions if API fails
  final List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'question':
          'In a data center, which metric best indicates a cooling efficiency?',
      'options': [
        'Power Usage Effectiveness (PUE)',
        'Rack Units (U) per cabinet',
        'Network throughput',
        'Number of raised floor tiles',
      ],
      'correctAnswer': 0,
    },
    {
      'question':
          'What is the safest first step before working inside a rack-mounted server?',
      'options': [
        'Power down the server and verify all power sources are disconnected.',
        'Disconnect all network cables from the switch.',
        'Label the rack doors with a maintenance note.',
        'Check that hot aisle temperature is within range.',
      ],
      'correctAnswer': 0,
    },
    {
      'question':
          'Which of the following is the primary purpose of a data center\'s UPS system?',
      'options': [
        'Provide backup power during outages',
        'Monitor temperature and humidity',
        'Increase network bandwidth',
        'Reduce cooling costs',
      ],
      'correctAnswer': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadJobData();
    _fetchQuestions();
  }

  void _loadJobData() {
    if (widget.jobData != null) {
      _passingScore = widget.jobData!['passingScore'] as int?;
      _coreExpertiseId = widget.jobData!['coreExpertiseId'] as int?;
      if (widget.jobData!['selectedQuestionIds'] != null) {
        _selectedQuestionIds = List<int>.from(widget.jobData!['selectedQuestionIds']);
      }
    }
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

  Future<void> _fetchQuestions() async {
    if (_coreExpertiseId == null) {
      // Use fallback questions if no core expertise ID
      setState(() {
        questions = _fallbackQuestions;
        _isLoadingQuestions = false;
      });
      startTimer();
      return;
    }

    setState(() {
      _isLoadingQuestions = true;
      _errorMessage = null;
    });

    try {
      final token = await _getAuthToken();
      var headers = {
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      var data = jsonEncode({
        "core_id": _coreExpertiseId,
      });

      print('📥 Fetching questions for core_id: $_coreExpertiseId');

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

        if (responseData['success'] == true && responseData['data'] != null) {
          final questionsData = List<Map<String, dynamic>>.from(responseData['data']);

          // Filter by selectedQuestionIds if available
          List<Map<String, dynamic>> filteredQuestions = questionsData;
          if (_selectedQuestionIds != null && _selectedQuestionIds!.isNotEmpty) {
            filteredQuestions = questionsData.where((q) {
              final qId = q['id'] as int?;
              return qId != null && _selectedQuestionIds!.contains(qId);
            }).toList();
          }

          // Convert API response to our question format
          questions = filteredQuestions.map((q) {
            List<String> options = [];
            int correctAnswerIndex = 0;

            if (q['choices'] != null) {
              final choices = List<Map<String, dynamic>>.from(q['choices']);
              // Sort by number to maintain order
              choices.sort((a, b) => (a['number'] ?? 0).compareTo(b['number'] ?? 0));
              
              options = choices.map((choice) {
                return choice['text']?.toString() ?? '';
              }).toList();

              // Find correct answer index
              for (int i = 0; i < choices.length; i++) {
                if (choices[i]['isCorrect'] == true) {
                  correctAnswerIndex = i;
                  break;
                }
              }
            }

            return {
              'id': q['id'],
              'question': q['questionTitle']?.toString() ?? q['question']?.toString() ?? '',
              'options': options,
              'correctAnswer': correctAnswerIndex,
              'tag': q['tag']?.toString() ?? '',
            };
          }).toList();

          if (questions.isEmpty) {
            // Use fallback if no questions found
            questions = _fallbackQuestions;
          }

          setState(() {
            _isLoadingQuestions = false;
          });
          startTimer();
        } else {
          // Use fallback questions
          setState(() {
            questions = _fallbackQuestions;
            _isLoadingQuestions = false;
          });
          startTimer();
        }
      } else {
        throw Exception('Failed to fetch questions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching questions: $e');
      setState(() {
        _errorMessage = 'Failed to load questions. Using sample questions.';
        questions = _fallbackQuestions;
        _isLoadingQuestions = false;
      });
      startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dio.close();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          timer.cancel();
          // Auto submit when time runs out
          submitTest();
        }
      });
    });
  }

  String getFormattedTime() {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double getTimeProgress() {
    return remainingSeconds / 600;
  }

  void submitTest() {
    _timer?.cancel();

    // Calculate score and time used
    int correctAnswers = 0;
    selectedAnswers.forEach((questionIndex, selectedOption) {
      if (questionIndex < questions.length &&
          questions[questionIndex]['correctAnswer'] == selectedOption) {
        correctAnswers++;
      }
    });

    // Calculate time used (10 minutes - remaining time)
    int timeUsedInSeconds = 600 - remainingSeconds;
    int minutes = timeUsedInSeconds ~/ 60;
    int seconds = timeUsedInSeconds % 60;
    String timeUsed =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Calculate score percentage
    double scorePercentage = questions.isNotEmpty
        ? (correctAnswers / questions.length) * 100
        : 0.0;

    Get.off(
      () => SkillTestResultScreen(
        jobTitle: widget.jobTitle,
        company: widget.company,
        totalQuestions: questions.length,
        correctAnswers: correctAnswers,
        attemptedQuestions: selectedAnswers.length,
        timeUsed: timeUsed,
        scorePercentage: scorePercentage,
        passingScore: _passingScore ?? 80,
        jobData: widget.jobData,
        skillTestAnswers: selectedAnswers,
        questions: questions,
        goodFitAnswer: widget.goodFitAnswer,
        startDate: widget.startDate,
        shareProfile: widget.shareProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xFFE8EEFA),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'Loading questions...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xFFE8EEFA),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.sp,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _errorMessage ?? 'No questions available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == questions.length - 1;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFE8EEFA),
        body: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                              title: Text('Exit Test?'),
                              content: Text(
                                'Are you sure you want to exit? Your progress will be lost.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Get.back();
                                  },
                                  child: Text(
                                    'Exit',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
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
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Skill test',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Optional assessment for this role',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'MCQ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Timer
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18.sp,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Time left',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            Spacer(),
                            Text(
                              getFormattedTime(),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        LinearProgressIndicator(
                          value: getTimeProgress(),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563EB),
                          ),
                          // minHeight: 4.h,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 20.w,right: 20.w,bottom: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Boost section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Boost your chances',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Showcase your hands-on data center skills with a short multiple-choice test tailored to this job.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _buildInfoChip('${questions.length} questions'),
                              _buildInfoChip('~10 minutes'),
                              _buildInfoChip('No negative marking'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    // Question card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${currentQuestionIndex + 1}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${currentQuestionIndex + 1}/${questions.length}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            currentQuestion['question'],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Select the most appropriate option.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Options
                          ...List.generate(
                            currentQuestion['options'].length,
                            (index) {
                              final isSelected =
                                  selectedAnswers[currentQuestionIndex] ==
                                  index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedAnswers[currentQuestionIndex] =
                                        index;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Color(
                                              0xFF2563EB,
                                            ).withOpacity(0.1)
                                            : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Color(0xFF2563EB)
                                              : Colors.grey[200]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22.w,
                                        height: 22.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? Color(0xFF2563EB)
                                                    : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          color:
                                              isSelected
                                                  ? Color(0xFF2563EB)
                                                  : Colors.transparent,
                                        ),
                                        child:
                                            isSelected
                                                ? Icon(
                                                  Icons.circle,
                                                  size: 12.sp,
                                                  color: Colors.white,
                                                )
                                                : null,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          currentQuestion['options'][index],
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color:
                                                isSelected
                                                    ? Color(0xFF2563EB)
                                                    : Colors.black,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'You can change your answer before\nsubmitting the test.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Time left •\n${getFormattedTime()}',
                                textAlign: TextAlign.right,
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
                    SizedBox(height: 20.h),
                    // Next button
                    GestureDetector(
                      onTap: () {
                        // Validate that an answer is selected for current question
                        if (!selectedAnswers.containsKey(currentQuestionIndex)) {
                          Get.snackbar(
                            'Answer Required',
                            'Please select an answer before proceeding.',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: Duration(seconds: 2),
                          );
                          return;
                        }

                        if (isLastQuestion) {
                          // Check result
                          submitTest();
                        } else {
                          // Go to next question
                          setState(() {
                            currentQuestionIndex++;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastQuestion
                                  ? 'Check result'
                                  : 'Next question',
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isLastQuestion) ...[
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Skill tests earn a strong score can improve your match for this role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
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
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
