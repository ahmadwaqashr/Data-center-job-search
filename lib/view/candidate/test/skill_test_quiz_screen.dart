import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../constants/colors.dart';
import 'skill_test_result_screen.dart';

class SkillTestQuizScreen extends StatefulWidget {
  final String jobTitle;
  final String company;

  const SkillTestQuizScreen({
    super.key,
    this.jobTitle = 'Data Center Technician',
    this.company = 'EdgeCore Systems',
  });

  @override
  State<SkillTestQuizScreen> createState() => _SkillTestQuizScreenState();
}

class _SkillTestQuizScreenState extends State<SkillTestQuizScreen> {
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {}; // questionIndex: optionIndex
  Timer? _timer;
  int remainingSeconds = 600; // 10 minutes = 600 seconds

  final List<Map<String, dynamic>> questions = [
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
    {
      'question': 'What does DCIM stand for in data center operations?',
      'options': [
        'Data Center Infrastructure Management',
        'Direct Current Integration Module',
        'Distributed Computing Information Model',
        'Digital Cable Installation Method',
      ],
      'correctAnswer': 0,
    },
    {
      'question':
          'What is the recommended hot aisle temperature range for most data centers?',
      'options': [
        '18-27°C (64-80°F)',
        '10-15°C (50-59°F)',
        '30-35°C (86-95°F)',
        '5-10°C (41-50°F)',
      ],
      'correctAnswer': 0,
    },
    {
      'question':
          'Which cable type is most commonly used for high-speed data center networking?',
      'options': ['Fiber optic', 'Coaxial', 'USB-C', 'HDMI'],
      'correctAnswer': 0,
    },
    {
      'question': 'What is the standard rack unit (U) height in data centers?',
      'options': [
        '1.75 inches (44.45 mm)',
        '2.5 inches (63.5 mm)',
        '1 inch (25.4 mm)',
        '3 inches (76.2 mm)',
      ],
      'correctAnswer': 0,
    },
    {
      'question':
          'Which protocol is commonly used for remote server management in data centers?',
      'options': [
        'IPMI (Intelligent Platform Management Interface)',
        'FTP (File Transfer Protocol)',
        'SMTP (Simple Mail Transfer Protocol)',
        'HTTP (Hypertext Transfer Protocol)',
      ],
      'correctAnswer': 0,
    },
    {
      'question':
          'What is the primary benefit of using hot aisle/cold aisle containment?',
      'options': [
        'Improved cooling efficiency',
        'Increased server speed',
        'Better network performance',
        'Reduced cable clutter',
      ],
      'correctAnswer': 0,
    },
    {
      'question':
          'Which tier classification represents the highest level of data center redundancy?',
      'options': ['Tier IV', 'Tier I', 'Tier II', 'Tier III'],
      'correctAnswer': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      if (questions[questionIndex]['correctAnswer'] == selectedOption) {
        correctAnswers++;
      }
    });

    // Calculate time used (10 minutes - remaining time)
    int timeUsedInSeconds = 600 - remainingSeconds;
    int minutes = timeUsedInSeconds ~/ 60;
    int seconds = timeUsedInSeconds % 60;
    String timeUsed =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Get.off(
      () => SkillTestResultScreen(
        jobTitle: widget.jobTitle,
        company: widget.company,
        totalQuestions: questions.length,
        correctAnswers: correctAnswers,
        attemptedQuestions: selectedAnswers.length,
        timeUsed: timeUsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
