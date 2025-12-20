import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../constants/colors.dart';
import 'job_posted_screen.dart';

class SkillTestQuestionsScreen extends StatefulWidget {
  final String jobTitle;
  final String company;
  final String location;
  final String minPay;
  final String maxPay;
  final String shiftType;

  const SkillTestQuestionsScreen({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.minPay,
    required this.maxPay,
    required this.shiftType,
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

  @override
  void initState() {
    super.initState();
    // Initialize with sample questions
    questions = [
      QuestionModel(
        id: 1,
        questionText:
            'What is the safest first step before working inside a rack-mounted server?',
        tag: 'Core\nknowledge',
        tagColor: Color(0xFF2563EB),
        isRequired: true,
        options: [
          OptionModel(
            text:
                'Power down the server and verify all power sources are disconnected.',
            isCorrect: true,
          ),
          OptionModel(
            text: 'Disconnect all network cables from the switch.',
            isCorrect: false,
          ),
          OptionModel(
            text: 'Label the rack doors with a maintenance note.',
            isCorrect: false,
          ),
          OptionModel(
            text: 'Check that hot aisle temperature is within range.',
            isCorrect: false,
          ),
        ],
      ),
      QuestionModel(
        id: 2,
        questionText:
            'Which metric best indicates a data center cooling issue?',
        tag: 'Operations',
        tagColor: Color(0xFF2563EB),
        isRequired: true,
        options: [
          OptionModel(
            text: 'Increase in power usage effectiveness (PUE).',
            isCorrect: false,
          ),
          OptionModel(
            text: 'Rising inlet temperatures above vendor specifications.',
            isCorrect: true,
          ),
          OptionModel(
            text: 'Decrease in network throughput.',
            isCorrect: false,
          ),
          OptionModel(text: 'Higher UPS battery runtime.', isCorrect: false),
        ],
      ),
    ];
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
                                              '$correctAnswersNeeded / $totalQuestions correct',
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
                                // Questions list
                                ...questions.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  QuestionModel question = entry.value;
                                  return Column(
                                    children: [
                                      _buildQuestionCard(question, index),
                                      if (index < questions.length - 1)
                                        SizedBox(height: 16.h),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
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
                          // Action buttons
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to job posted screen
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
                                  },
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
                                        'Save & continue',
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

  Widget _buildQuestionCard(QuestionModel question, int index) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${question.isDraft ? 'Add your own multiple choice question' : question.questionText}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          'Single choice',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          ' • ',
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: question.tagColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  question.tag,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: question.tagColor,
                    fontWeight: FontWeight.w600,
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
          }).toList(),
          // Add option button
          GestureDetector(
            onTap: () {
              // Add option logic
            },
            child: Row(
              children: [
                Icon(Icons.add, color: AppColors.primaryColor, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Add option',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Action chips
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildActionChip('Multiple choice', true),
              _buildActionChip(
                question.isDraft ? 'Required' : 'Make optional',
                false,
              ),
              _buildActionChip('More', false),
            ],
          ),
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
                      ((passingScore / 100) * totalQuestions).ceil();
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
    List<TextEditingController> optionControllers = [];
    List<bool> optionCorrectness = [];
    String selectedType = 'Multiple choice';
    bool isRequired = editQuestion?.isRequired ?? true;

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
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              'Core\nknowledge',
                              'Operations',
                              'Custom',
                            ].map((tag) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
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
                              setModalState(() {
                                optionControllers.add(TextEditingController());
                                optionCorrectness.add(false);
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add,
                                  color: AppColors.primaryColor,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Add option',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Question type and settings
                          Text(
                            'Question settings',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedType = 'Multiple choice';
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selectedType == 'Multiple choice'
                                            ? AppColors.primaryColor
                                                .withOpacity(0.1)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color:
                                          selectedType == 'Multiple choice'
                                              ? AppColors.primaryColor
                                              : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    'Multiple choice',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color:
                                          selectedType == 'Multiple choice'
                                              ? AppColors.primaryColor
                                              : Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    isRequired = !isRequired;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        !isRequired
                                            ? AppColors.primaryColor
                                                .withOpacity(0.1)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color:
                                          !isRequired
                                              ? AppColors.primaryColor
                                              : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    isRequired ? 'Make optional' : 'Optional',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color:
                                          !isRequired
                                              ? AppColors.primaryColor
                                              : Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          // Save button
                          GestureDetector(
                            onTap: () {
                              if (questionController.text.isEmpty) {
                                Get.snackbar(
                                  'Error',
                                  'Please enter a question',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
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

                              // Create options list
                              List<OptionModel> newOptions = [];
                              for (int i = 0;
                                  i < optionControllers.length;
                                  i++) {
                                if (optionControllers[i].text.isNotEmpty) {
                                  newOptions.add(
                                    OptionModel(
                                      text: optionControllers[i].text,
                                      isCorrect: optionCorrectness[i],
                                    ),
                                  );
                                }
                              }

                              if (newOptions.length < 2) {
                                Get.snackbar(
                                  'Error',
                                  'Please add at least 2 options',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              setState(() {
                                if (editQuestion != null &&
                                    questionIndex != null) {
                                  // Edit existing question
                                  questions[questionIndex] = QuestionModel(
                                    id: editQuestion.id,
                                    questionText: questionController.text,
                                    tag: 'Custom',
                                    tagColor: Color(0xFF2563EB),
                                    isRequired: isRequired,
                                    isDraft: false,
                                    options: newOptions,
                                  );
                                } else {
                                  // Add new question
                                  questions.add(
                                    QuestionModel(
                                      id: questions.length + 1,
                                      questionText: questionController.text,
                                      tag: 'Custom',
                                      tagColor: Color(0xFF2563EB),
                                      isRequired: isRequired,
                                      options: newOptions,
                                    ),
                                  );
                                  totalQuestions = questions.length;
                                  correctAnswersNeeded =
                                      ((passingScore / 100) * totalQuestions)
                                          .ceil();
                                }
                              });

                              Navigator.pop(context);
                              Get.snackbar(
                                'Success',
                                editQuestion != null
                                    ? 'Question updated'
                                    : 'Question added',
                                backgroundColor: Color(0xFF10B981),
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
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
