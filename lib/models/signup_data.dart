import 'dart:io';

/// Model to collect signup data across all screens
class SignupData {
  // Singleton instance
  static final SignupData instance = SignupData._();
  SignupData._();
  
  // From phone auth
  String? phone;
  
  // From complete profile screen
  String? fullName;
  String? email;
  String? location;
  
  // From skill expertise screen
  List<String> selectedCoreSkills = [];
  String? selectedExperienceLevel;
  
  // From upload CV screen
  File? cvFile;
  
  // From add profile photo screen
  File? profilePicFile;
  int? selectedAvatarIndex;
  String? selectedAvatarUrl; // For avatar selection
  
  // From face scanning screen
  File? faceImageFile;
  
  // Clear all data
  void clear() {
    phone = null;
    fullName = null;
    email = null;
    location = null;
    selectedCoreSkills.clear();
    selectedExperienceLevel = null;
    cvFile = null;
    profilePicFile = null;
    selectedAvatarIndex = null;
    selectedAvatarUrl = null;
    faceImageFile = null;
  }
  
  // Validation methods
  bool isCompleteProfileValid() {
    return fullName != null && 
           fullName!.trim().isNotEmpty &&
           email != null && 
           email!.trim().isNotEmpty &&
           location != null && 
           location!.trim().isNotEmpty &&
           phone != null && 
           phone!.trim().isNotEmpty;
  }
  
  bool isSkillExpertiseValid() {
    return selectedCoreSkills.isNotEmpty && 
           selectedExperienceLevel != null && 
           selectedExperienceLevel!.trim().isNotEmpty;
  }
  
  bool isProfilePhotoValid() {
    return profilePicFile != null || selectedAvatarIndex != null;
  }
  
  bool isFaceImageValid() {
    return faceImageFile != null;
  }
  
  bool isCvValid() {
    return cvFile != null;
  }
  
  bool isAllDataValid() {
    return isCompleteProfileValid() && 
           isSkillExpertiseValid() && 
           isProfilePhotoValid() && 
           isFaceImageValid() &&
           isCvValid();
  }
  
  // Get expertise as comma-separated string
  String getExpertiseString() {
    return selectedCoreSkills.join(', ');
  }
  
  // Get validation errors
  List<String> getValidationErrors() {
    List<String> errors = [];
    if (!isCompleteProfileValid()) {
      if (fullName == null || fullName!.trim().isEmpty) errors.add('Full name is required');
      if (email == null || email!.trim().isEmpty) errors.add('Email is required');
      if (location == null || location!.trim().isEmpty) errors.add('Location is required');
      if (phone == null || phone!.trim().isEmpty) errors.add('Phone number is required');
    }
    if (!isSkillExpertiseValid()) {
      if (selectedCoreSkills.isEmpty) errors.add('Please select at least one core expertise');
      if (selectedExperienceLevel == null || selectedExperienceLevel!.trim().isEmpty) {
        errors.add('Please select experience level');
      }
    }
    if (!isProfilePhotoValid()) {
      errors.add('Please select a profile photo or avatar');
    }
    if (!isCvValid()) {
      errors.add('Please upload your CV');
    }
    if (!isFaceImageValid()) {
      errors.add('Face recognition is required');
    }
    return errors;
  }
}
