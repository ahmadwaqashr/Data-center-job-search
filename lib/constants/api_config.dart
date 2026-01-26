class ApiConfig {
  // Base URL for API endpoints
  //static const String baseUrl = 'https://datacenterjobs.onrender.com';
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
  static const String fetchQuestionsByCoreId = '/api/testquestion/fetch_questionbycoreid';
  static const String createTestQuestion = '/api/testquestion';
  static const String jobPosted = '/api/jobposted';
  static const String fetchJob = '/api/fetchjob';
  static const String applyJob = '/api/appliedjob';
  static const String fetchEmployerApplications = '/api/appliedjob/fetch_employer_applications';
  static const String fetchEmployerOverview = '/api/appliedjob/fetch_employer_overview';
  static const String fetchCandidatesByJob = '/api/appliedjob/fetch_candidates_by_job';
  static const String fetchCandidateDetails = '/api/appliedjob/fetch_candidate_details';
  static const String updateCandidateStage = '/api/appliedjob/update_candidate_stage';
  
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
