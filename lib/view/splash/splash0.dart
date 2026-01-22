import 'dart:async';
import 'dart:convert';
import 'package:data_center_job/view/splash/splash_wrapper.dart';
import 'package:data_center_job/view/candidate/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash0 extends StatefulWidget {
  const Splash0({super.key});

  @override
  State<Splash0> createState() => _Splash0State();
}

class _Splash0State extends State<Splash0> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash screen duration
    await Future.delayed(Duration(seconds: 3));
    
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user data exists
      final userDataString = prefs.getString('user_data');
      final userRole = prefs.getString('user_role');
      final authToken = prefs.getString('auth_token');
      
      print('🔍 Checking authentication status...');
      print('   User data exists: ${userDataString != null}');
      print('   User role: ${userRole ?? "NULL"}');
      print('   Auth token exists: ${authToken != null}');
      
      // If user exists and role is candidate, navigate to dashboard
      if (userDataString != null && 
          userRole == 'candidate' && 
          authToken != null && 
          authToken.isNotEmpty) {
        print('✅ User is authenticated as candidate, navigating to dashboard');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        }
        return;
      }
      
      // Otherwise, navigate to splash wrapper (onboarding/auth flow)
      print('ℹ️ No authenticated user found, navigating to onboarding');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SplashWrapper()),
        );
      }
    } catch (e) {
      print('❌ Error checking authentication: $e');
      // On error, navigate to splash wrapper
      if (mounted) {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SplashWrapper()),
    );
      }
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Image.asset(
                    'assets/images/splash0.png',
                    fit: BoxFit.contain,
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
