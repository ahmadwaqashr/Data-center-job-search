import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/colors.dart';
import '../../../constants/api_config.dart';
import '../dashboard/home/home_screen.dart';

class SkillTestResultScreen extends StatefulWidget {
  final String jobTitle;
  final String company;
  final int totalQuestions;
  final int correctAnswers;
  final int attemptedQuestions;
  final String timeUsed;
  final double scorePercentage;
  final int passingScore;
  final Map<String, dynamic>? jobData;
  final Map<int, int>? skillTestAnswers; // questionIndex: selectedOptionIndex
  final List<Map<String, dynamic>>? questions; // Questions with IDs
  final String? goodFitAnswer;
  final String? startDate;
  final bool? shareProfile;

  const SkillTestResultScreen({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.attemptedQuestions,
    required this.timeUsed,
    required this.scorePercentage,
    this.passingScore = 80,
    this.jobData,
    this.skillTestAnswers,
    this.questions,
    this.goodFitAnswer,
    this.startDate,
    this.shareProfile,
  });

  @override
  State<SkillTestResultScreen> createState() => _SkillTestResultScreenState();
}

class _SkillTestResultScreenState extends State<SkillTestResultScreen> {
  final Dio _dio = Dio();
  bool _isSubmitting = false;

  String get performanceLevel {
    if (widget.scorePercentage >= widget.passingScore) {
      return 'Passed';
    } else if (widget.scorePercentage >= widget.passingScore * 0.75) {
      return 'Good attempt';
    } else if (widget.scorePercentage >= widget.passingScore * 0.5) {
      return 'Needs improvement';
    }
    return 'Below passing';
  }

  Color get performanceColor {
    if (widget.scorePercentage >= widget.passingScore) {
      return Color(0xFF10B981); // Green
    } else if (widget.scorePercentage >= widget.passingScore * 0.75) {
      return Color(0xFF2563EB); // Blue
    } else if (widget.scorePercentage >= widget.passingScore * 0.5) {
      return Color(0xFFF59E0B); // Orange
    }
    return Color(0xFFEF4444); // Red
  }

  bool get hasPassed => widget.scorePercentage >= widget.passingScore;

  // Generate unique reference ID
  String _generateReferenceId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    // Format: DCT-{timestamp_last4}-{random4digits}
    final timestampStr = timestamp.toString().substring(timestamp.toString().length - 4);
    return 'DCT-$timestampStr-$randomNum';
  }

  String get pace {
    // Parse time used to determine pace
    try {
      final parts = widget.timeUsed.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        final totalSeconds = minutes * 60 + seconds;
        final avgTimePerQuestion = totalSeconds / widget.totalQuestions;
        
        if (avgTimePerQuestion < 30) {
          return 'Fast pace';
        } else if (avgTimePerQuestion < 60) {
          return 'Balanced pace';
        } else {
          return 'Thoughtful pace';
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 'Balanced pace';
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
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

  Future<void> _submitApplication() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        Get.snackbar(
          'Error',
          'Authentication required. Please login again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      Map<String, dynamic> userData = {};
      if (userDataString != null) {
        userData = jsonDecode(userDataString) as Map<String, dynamic>;
      }

      // Prepare skill test answers in format: [{questionId: 1, selectedOptionIndex: 0}, ...]
      List<Map<String, dynamic>> skillTestAnswersList = [];
      if (widget.skillTestAnswers != null && widget.questions != null) {
        widget.skillTestAnswers!.forEach((questionIndex, selectedOptionIndex) {
          if (questionIndex < widget.questions!.length) {
            final question = widget.questions![questionIndex];
            skillTestAnswersList.add({
              'questionId': question['id'],
              'selectedOptionIndex': selectedOptionIndex,
            });
          }
        });
      }

      // Generate reference ID
      final referenceId = _generateReferenceId();

      final rawJobId = widget.jobData?['id'] ?? widget.jobData?['jobId'];
      final rawCandidateId = userData['id'];
      final jobId = rawJobId is int ? rawJobId : (rawJobId is num ? rawJobId.toInt() : null);
      final candidateId = rawCandidateId is int ? rawCandidateId : (rawCandidateId is num ? rawCandidateId.toInt() : null);

      final payload = {
        'jobId': jobId,
        'candidateId': candidateId,
        'referenceId': referenceId,
        'goodFitAnswer': widget.goodFitAnswer ?? '',
        'startDate': widget.startDate ?? '',
        'shareProfile': widget.shareProfile ?? true,
        'skillTestScore': widget.scorePercentage,
        'skillTestPassed': hasPassed,
        'skillTestTimeUsed': widget.timeUsed,
        'skillTestAnswers': skillTestAnswersList,
        'totalQuestions': widget.totalQuestions,
        'correctAnswers': widget.correctAnswers,
        'attemptedQuestions': widget.attemptedQuestions,
      };

      final response = await _dio.request(
        ApiConfig.getUrl(ApiConfig.applyJob),
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        print('✅ Application submitted successfully:');
        print('   Response: ${jsonEncode(responseData)}');

        Get.snackbar(
          'Success',
          responseData['message'] ?? 'Application submitted successfully!',
          backgroundColor: Color(0xFF10B981),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );

        // Navigate to home screen after successful submission
        Future.delayed(Duration(seconds: 1), () {
          Get.offAll(() => HomeScreen());
        });
      } else {
        throw Exception('Failed to submit application: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting application: $e');
      String errorMessage = 'Failed to submit application';
      if (e is DioException) {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFE8EEFA),
        body: Column(
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
                          'Skill test complete',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Results shared with the employer',
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
                      'Completed',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 20.w,right: 20,bottom: 20.h),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Column(
                        children: [
                          // Score display
                          Column(
                            children: [
                              Container(
                                width: 120.w,
                                height: 120.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: performanceColor.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    '${widget.scorePercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.bold,
                                      color: performanceColor,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: performanceColor,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasPassed)
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 18.sp,
                                      ),
                                    if (hasPassed) SizedBox(width: 6.w),
                                    Text(
                                      performanceLevel,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!hasPassed) ...[
                                SizedBox(height: 8.h),
                                Text(
                                  'Passing score: ${widget.passingScore}%',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 24.h),
                          // Title
                          Text(
                            hasPassed
                                ? 'Congratulations!'
                                : 'Test Completed',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            hasPassed
                                ? 'You passed the skill test for ${widget.jobTitle} with a score of ${widget.scorePercentage.toStringAsFixed(1)}%.'
                                : 'You scored ${widget.scorePercentage.toStringAsFixed(1)}% on the skill test for ${widget.jobTitle}. The passing score is ${widget.passingScore}%.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Stats row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Questions completed',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      '${widget.attemptedQuestions} / ${widget.totalQuestions}',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Score: ${widget.scorePercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (!hasPassed) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Required: ${widget.passingScore}%',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(width: 20.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time used',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      widget.timeUsed,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      pace,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          Divider(color: Colors.grey[200], thickness: 1),
                          SizedBox(height: 24.h),
                          // Assessment focus
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assessment focus',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: [
                                    _buildTagChip('Incident response'),
                                    _buildTagChip('Rack & power'),
                                    _buildTagChip('Monitoring'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          // Shared with
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shared with',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Data center operations',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      widget.company,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          // Description
                          Text(
                            'Your answers help highlight your on-site decision making for this role. You can retake or update this test in future applications.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20.w),
                      color: Color(0xFFE8EEFA),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isSubmitting ? null : _submitApplication,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              decoration: BoxDecoration(
                                color: _isSubmitting
                                    ? Colors.grey[400]
                                    : AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSubmitting)
                                    Padding(
                                      padding: EdgeInsets.only(right: 8.w),
                                      child: SizedBox(
                                        width: 16.w,
                                        height: 16.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _isSubmitting
                                        ? 'Submitting...'
                                        : 'Submit application',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          GestureDetector(
                            onTap: (){},
                            child: Text(
                              'Skip for now and return to Applications',
                              style: TextStyle(
                                fontSize: 13.sp,
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
            ),
            // Bottom buttons

          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
