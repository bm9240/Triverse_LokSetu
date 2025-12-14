class SchemeModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> requiredDocuments;
  final List<String> optionalDocuments;
  final List<String> eligibilityCriteria;
  final String formType;

  SchemeModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.requiredDocuments,
    this.optionalDocuments = const [],
    required this.eligibilityCriteria,
    required this.formType,
  });

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      requiredDocuments: List<String>.from(json['requiredDocuments'] ?? []),
      optionalDocuments: List<String>.from(json['optionalDocuments'] ?? []),
      eligibilityCriteria: List<String>.from(json['eligibilityCriteria'] ?? []),
      formType: json['formType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'requiredDocuments': requiredDocuments,
      'optionalDocuments': optionalDocuments,
      'eligibilityCriteria': eligibilityCriteria,
      'formType': formType,
    };
  }

  // Comprehensive list of government schemes with intelligent document requirements
  static List<SchemeModel> getCommonSchemes() {
    return [
      // PENSION SCHEMES
      SchemeModel(
        id: 'widow_pension',
        name: 'Widow Pension Scheme',
        category: 'Pension',
        description: 'Financial assistance for widows',
        requiredDocuments: [
          'Aadhaar Card',
          'Bank Passbook',
          'Husband\'s Death Certificate',
        ],
        optionalDocuments: [
          'Address Proof',
          'Age Proof',
          'Income Certificate',
        ],
        eligibilityCriteria: [
          'Widow',
          'Age between 18-60 years',
          'Below Poverty Line',
        ],
        formType: 'Widow Pension Application Form',
      ),
      SchemeModel(
        id: 'disability_pension',
        name: 'Disability Pension Scheme',
        category: 'Pension',
        description: 'Financial assistance for disabled persons',
        requiredDocuments: [
          'Aadhaar Card',
          'Disability Certificate (40% or above)',
          'Bank Passbook',
        ],
        optionalDocuments: [
          'Address Proof',
          'Income Certificate',
        ],
        eligibilityCriteria: [
          'Disability 40% or above',
          'Age 18 years or above',
          'Below Poverty Line',
        ],
        formType: 'Disability Pension Application Form',
      ),
      SchemeModel(
        id: 'old_age_pension',
        name: 'Old Age Pension Scheme',
        category: 'Pension',
        description: 'Financial assistance for senior citizens',
        requiredDocuments: [
          'Aadhaar Card',
          'Age Proof (Birth Certificate or School Certificate)',
          'Bank Passbook',
        ],
        optionalDocuments: [
          'Address Proof',
          'Income Certificate',
        ],
        eligibilityCriteria: [
          'Age 60 years or above',
          'Below Poverty Line',
          'No regular income',
        ],
        formType: 'Old Age Pension Application Form',
      ),

      // IDENTITY & TAX DOCUMENTS
      SchemeModel(
        id: 'pan_card',
        name: 'PAN Card Application',
        category: 'Identity Card',
        description: 'Permanent Account Number for tax purposes',
        requiredDocuments: [
          'Aadhaar Card',
          'Date of Birth Proof',
        ],
        optionalDocuments: [
          'Address Proof',
          'Passport Size Photo',
        ],
        eligibilityCriteria: [
          'Indian Citizen or Foreign National',
          'Required for income tax filing',
        ],
        formType: 'PAN Card Application Form 49A',
      ),
      SchemeModel(
        id: 'aadhaar_card',
        name: 'Aadhaar Card Enrollment',
        category: 'Identity Card',
        description: 'Unique identification number for Indian residents',
        requiredDocuments: [
          'Date of Birth Proof',
          'Address Proof',
        ],
        optionalDocuments: [
          'Photo Identity Proof',
        ],
        eligibilityCriteria: [
          'Indian Resident',
          'All age groups',
        ],
        formType: 'Aadhaar Enrollment Form',
      ),
      SchemeModel(
        id: 'voter_id',
        name: 'Voter ID Card',
        category: 'Identity Card',
        description: 'Electoral photo identity card',
        requiredDocuments: [
          'Address Proof',
          'Age Proof',
          'Passport Size Photo',
        ],
        optionalDocuments: [
          'Aadhaar Card',
        ],
        eligibilityCriteria: [
          'Indian Citizen',
          'Age 18 years or above',
        ],
        formType: 'Form 6 - Voter Registration',
      ),
      SchemeModel(
        id: 'driving_license',
        name: 'Driving License',
        category: 'License',
        description: 'License to drive motor vehicles',
        requiredDocuments: [
          'Aadhaar Card',
          'Address Proof',
          'Age Proof',
          'Passport Size Photo',
          'Learner\'s License',
        ],
        optionalDocuments: [
          'Educational Certificate',
        ],
        eligibilityCriteria: [
          'Age 18 years or above (16 for two-wheeler)',
          'Passed driving test',
        ],
        formType: 'Form 4 - Driving License Application',
      ),

      // FOOD SECURITY & WELFARE
      SchemeModel(
        id: 'ration_card',
        name: 'Ration Card',
        category: 'Food Security',
        description: 'Access to subsidized food grains',
        requiredDocuments: [
          'Aadhaar Card',
          'Address Proof',
        ],
        optionalDocuments: [
          'Income Certificate',
          'Family Photo',
        ],
        eligibilityCriteria: [
          'Resident of the state',
          'No existing ration card',
        ],
        formType: 'Ration Card Application Form',
      ),

      // CERTIFICATES
      SchemeModel(
        id: 'birth_certificate',
        name: 'Birth Certificate',
        category: 'Certificate',
        description: 'Official record of birth',
        requiredDocuments: [
          'Hospital Discharge Summary',
          'Parent\'s Aadhaar Card',
        ],
        optionalDocuments: [
          'Parent\'s Marriage Certificate',
          'Address Proof',
        ],
        eligibilityCriteria: [
          'Birth occurred in India',
        ],
        formType: 'Birth Registration Form',
      ),
      SchemeModel(
        id: 'death_certificate',
        name: 'Death Certificate',
        category: 'Certificate',
        description: 'Official record of death',
        requiredDocuments: [
          'Hospital Death Summary or Cremation Certificate',
          'Deceased\'s Identity Proof',
          'Informant\'s Identity Proof',
        ],
        optionalDocuments: [
          'Address Proof',
        ],
        eligibilityCriteria: [
          'Death occurred in India',
          'Application within 21 days',
        ],
        formType: 'Death Registration Form',
      ),
      SchemeModel(
        id: 'income_certificate',
        name: 'Income Certificate',
        category: 'Certificate',
        description: 'Certificate showing annual family income',
        requiredDocuments: [
          'Aadhaar Card',
          'Salary Slips or Income Proof',
          'Address Proof',
        ],
        optionalDocuments: [
          'Bank Statement',
          'Property Documents',
        ],
        eligibilityCriteria: [
          'Resident of the state',
          'For scholarship or government schemes',
        ],
        formType: 'Income Certificate Application Form',
      ),
      SchemeModel(
        id: 'caste_certificate',
        name: 'Caste Certificate',
        category: 'Certificate',
        description: 'Certificate showing caste category (SC/ST/OBC)',
        requiredDocuments: [
          'Aadhaar Card',
          'Address Proof',
          'Parent\'s Caste Certificate (if available)',
        ],
        optionalDocuments: [
          'School Certificate',
          'Birth Certificate',
        ],
        eligibilityCriteria: [
          'Belongs to SC/ST/OBC category',
          'For reservations and benefits',
        ],
        formType: 'Caste Certificate Application Form',
      ),
      SchemeModel(
        id: 'domicile_certificate',
        name: 'Domicile Certificate',
        category: 'Certificate',
        description: 'Certificate of residence/domicile',
        requiredDocuments: [
          'Aadhaar Card',
          'Address Proof (minimum 3 years)',
        ],
        optionalDocuments: [
          'School Leaving Certificate',
          'Property Documents',
        ],
        eligibilityCriteria: [
          'Residing in the state for at least 3 years',
        ],
        formType: 'Domicile Certificate Application',
      ),

      // EDUCATION & SCHOLARSHIPS
      SchemeModel(
        id: 'scholarship',
        name: 'Education Scholarship',
        category: 'Education',
        description: 'Financial assistance for students',
        requiredDocuments: [
          'Aadhaar Card',
          'Income Certificate',
          'Educational Marksheets',
          'Bank Passbook',
        ],
        optionalDocuments: [
          'Caste Certificate',
          'Disability Certificate',
        ],
        eligibilityCriteria: [
          'Student',
          'Family income below threshold',
        ],
        formType: 'Scholarship Application Form',
      ),

      // BUSINESS & TRADE
      SchemeModel(
        id: 'gst_registration',
        name: 'GST Registration',
        category: 'Business',
        description: 'Goods and Services Tax registration',
        requiredDocuments: [
          'PAN Card',
          'Aadhaar Card',
          'Business Address Proof',
          'Bank Account Details',
        ],
        optionalDocuments: [
          'Business Registration Certificate',
          'Partnership Deed',
        ],
        eligibilityCriteria: [
          'Turnover exceeds threshold',
          'Business entity',
        ],
        formType: 'GST REG-01 Form',
      ),
      SchemeModel(
        id: 'shop_license',
        name: 'Shop and Establishment License',
        category: 'Business',
        description: 'License to operate shop or commercial establishment',
        requiredDocuments: [
          'Owner\'s Identity Proof',
          'Property Documents',
          'Address Proof',
        ],
        optionalDocuments: [
          'Partnership Deed',
          'NOC from Property Owner',
        ],
        eligibilityCriteria: [
          'Operating commercial establishment',
        ],
        formType: 'Shop License Application Form',
      ),

      // HOUSING & PROPERTY
      SchemeModel(
        id: 'property_tax',
        name: 'Property Tax Registration',
        category: 'Property',
        description: 'Registration for property tax payment',
        requiredDocuments: [
          'Property Documents',
          'Owner\'s Identity Proof',
          'Address Proof',
        ],
        optionalDocuments: [
          'Previous Tax Receipt',
        ],
        eligibilityCriteria: [
          'Property owner',
        ],
        formType: 'Property Tax Form',
      ),
    ];
  }
}
