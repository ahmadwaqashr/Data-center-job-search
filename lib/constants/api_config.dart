class ApiConfig {
  // Base URL for API endpoints
  static const String baseUrl = 'http://192.168.100.193:5000';

  // API Endpoints
  static const String fetchCoreExpertise = '/api/coreexpertise/fetch_coreExpertise';
  static const String fetchExperienceLevel = '/api/experiencelevel/fetch_experienceLevel';
  static const String fetchAvatar = '/api/avatar/fetch_avatar';
  static const String candidateSignup = '/api/auth/signup';
  static const String candidateLogin = '/api/auth/login';
  static const String editMyProfile = '/api/auth/edit_myprofile';
  static const String addExperience = '/api/experience/add_experience';
  static const String fetchExperiences = '/api/experience/fetch_experience';
  static const String fetchPreferredRoles = '/api/preferredrole/fetch_preferred';
  static const String addSkills = '/api/skills/add_skills';
  static const String fetchSkillsPreferences = '/api/skills/fetch_skills_prefrences';
  static const String sendEmailOTP = '/api/auth/send-email-otp';
  static const String verifyEmailOTP = '/api/auth/verify-email-otp';
  
  // Helper method to get edit skills URL with ID
  static String getEditSkillsUrl(int id) {
    return '$baseUrl/api/skills/edit_skills/$id';
  }

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Helper method to get image URL
  static String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return '$baseUrl$imagePath';
  }
}
