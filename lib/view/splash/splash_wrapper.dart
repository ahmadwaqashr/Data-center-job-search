import 'package:data_center_job/utils/custom_button.dart';
import 'package:data_center_job/view/splash/splash4.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> splashData = [
    {
      'image': 'assets/images/splash1.png',
      'title': 'Find Your Dream Job or Hire Top Talent!',
      'description':
          'Join thousands of professionals and employers connecting for the perfect job match.',
      'buttonText': 'Continue',
    },
    {
      'image': 'assets/images/splash2.png',
      'title': 'Personalize your job matches',
      'description':
          'Get personalized job recommendations based on your preferences.',
      'buttonText': 'Continue',
    },
    {
      'image': 'assets/images/splash3.png',
      'title': 'Smart hiring for employers',
      'description':
          'Post jobs, review applications, and assess candidates effortlessly.',
      'buttonText': 'Get Started',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < splashData.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to splash4
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Splash4()),
      );
    }
  }

  void _skipToEnd() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Splash4()),
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
              // PageView Content
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: splashData.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      SizedBox(height: 30.h),
                      // Card Image
                      Container(
                        height: 390.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: Image.asset(
                            splashData[index]['image']!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        'Data Center Job Search',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          splashData[index]['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          splashData[index]['description']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Spacer(),
                      // Continue/Get Started Button
                      GestureDetector(
                        onTap: _goToNextPage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: CustomButton(
                            text: splashData[index]['buttonText']!,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // Skip for now
                      GestureDetector(
                        onTap: _skipToEnd,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          splashData.length,
                          (dotIndex) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            width: 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _currentPage == dotIndex
                                      ? Color(0xFF2563EB)
                                      : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
