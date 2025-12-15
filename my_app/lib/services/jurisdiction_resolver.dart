import '../models/autogov_complaint.dart';

/// Jurisdiction Resolver
/// Maps location (city, ward) to local governing office
class JurisdictionResolver {
  static final JurisdictionResolver _instance = JurisdictionResolver._internal();
  factory JurisdictionResolver() => _instance;
  JurisdictionResolver._internal();

  // Jurisdiction database: city -> ward -> office mapping
  final Map<String, Map<String, GoverningOffice>> _jurisdictionMap = {};

  /// Initialize with default jurisdiction data
  JurisdictionResolver initialize() {
    _initializeDefaultJurisdictions();
    return this;
  }

  /// Resolve governing office for given location
  GoverningOffice? resolveJurisdiction(LocationInfo location) {
    final cityMap = _jurisdictionMap[location.city.toLowerCase()];
    if (cityMap == null) {
      // Try to find closest match or return default
      return _getDefaultOffice(location.city);
    }

    final office = cityMap[location.ward.toLowerCase()];
    if (office == null) {
      // Ward not found, return city-level office
      return _getCityLevelOffice(location.city);
    }

    return office;
  }

  /// Register a new jurisdiction mapping
  void registerJurisdiction(
    String city,
    String ward,
    GoverningOffice office,
  ) {
    final cityLower = city.toLowerCase();
    final wardLower = ward.toLowerCase();

    _jurisdictionMap.putIfAbsent(cityLower, () => {});
    _jurisdictionMap[cityLower]![wardLower] = office;
  }

  /// Get all wards for a city
  List<String> getWardsForCity(String city) {
    final cityMap = _jurisdictionMap[city.toLowerCase()];
    if (cityMap == null) return [];
    return cityMap.keys.toList();
  }

  /// Get office for specific ward
  GoverningOffice? getOfficeForWard(String city, String ward) {
    return _jurisdictionMap[city.toLowerCase()]?[ward.toLowerCase()];
  }

  /// Check if location is registered
  bool isJurisdictionRegistered(String city, String ward) {
    return _jurisdictionMap[city.toLowerCase()]?.containsKey(ward.toLowerCase()) ?? false;
  }

  /// Initialize default jurisdiction mappings
  void _initializeDefaultJurisdictions() {
    // Mumbai example
    _registerMumbaiJurisdictions();
    
    // Delhi example
    _registerDelhiJurisdictions();
    
    // Bangalore example
    _registerBangaloreJurisdictions();
    
    // Add more cities as needed
  }

  void _registerMumbaiJurisdictions() {
    const city = 'Mumbai';
    
    registerJurisdiction(
      city,
      'Ward A',
      GoverningOffice(
        id: 'MUM_A',
        name: 'Mumbai Ward A Office',
        city: city,
        ward: 'Ward A',
        officeType: OfficeType.wardOffice,
        address: 'Colaba Municipal Office, South Mumbai',
        contactPhone: '+91-22-2200-0001',
        contactEmail: 'warda@mcgm.gov.in',
      ),
    );

    registerJurisdiction(
      city,
      'Ward B',
      GoverningOffice(
        id: 'MUM_B',
        name: 'Mumbai Ward B Office',
        city: city,
        ward: 'Ward B',
        officeType: OfficeType.wardOffice,
        address: 'Dockyard Road Municipal Office',
        contactPhone: '+91-22-2200-0002',
        contactEmail: 'wardb@mcgm.gov.in',
      ),
    );

    // Add more Mumbai wards as needed
  }

  void _registerDelhiJurisdictions() {
    const city = 'Delhi';
    
    registerJurisdiction(
      city,
      'Central Delhi',
      GoverningOffice(
        id: 'DEL_CENTRAL',
        name: 'Central Delhi Municipal Office',
        city: city,
        ward: 'Central Delhi',
        officeType: OfficeType.districtOffice,
        address: 'Town Hall, Chandni Chowk',
        contactPhone: '+91-11-2300-0001',
        contactEmail: 'central@dmc.gov.in',
      ),
    );

    registerJurisdiction(
      city,
      'South Delhi',
      GoverningOffice(
        id: 'DEL_SOUTH',
        name: 'South Delhi Municipal Office',
        city: city,
        ward: 'South Delhi',
        officeType: OfficeType.districtOffice,
        address: 'Defence Colony Municipal Office',
        contactPhone: '+91-11-2300-0002',
        contactEmail: 'south@dmc.gov.in',
      ),
    );
  }

  void _registerBangaloreJurisdictions() {
    const city = 'Bangalore';
    
    registerJurisdiction(
      city,
      'Zone 1',
      GoverningOffice(
        id: 'BLR_Z1',
        name: 'BBMP Zone 1 Office',
        city: city,
        ward: 'Zone 1',
        officeType: OfficeType.zoneOffice,
        address: 'Shantinagar BBMP Office',
        contactPhone: '+91-80-2200-0001',
        contactEmail: 'zone1@bbmp.gov.in',
      ),
    );

    registerJurisdiction(
      city,
      'Zone 2',
      GoverningOffice(
        id: 'BLR_Z2',
        name: 'BBMP Zone 2 Office',
        city: city,
        ward: 'Zone 2',
        officeType: OfficeType.zoneOffice,
        address: 'Jayanagar BBMP Office',
        contactPhone: '+91-80-2200-0002',
        contactEmail: 'zone2@bbmp.gov.in',
      ),
    );
  }

  /// Get default office when exact match not found
  GoverningOffice _getDefaultOffice(String city) {
    return GoverningOffice(
      id: '${city.toUpperCase()}_DEFAULT',
      name: '$city Municipal Corporation',
      city: city,
      ward: 'Central',
      officeType: OfficeType.cityOffice,
      address: '$city Municipal Headquarters',
      contactPhone: 'N/A',
      contactEmail: 'info@${city.toLowerCase()}.gov.in',
    );
  }

  /// Get city-level office
  GoverningOffice _getCityLevelOffice(String city) {
    return GoverningOffice(
      id: '${city.toUpperCase()}_CITY',
      name: '$city City Office',
      city: city,
      ward: 'City Wide',
      officeType: OfficeType.cityOffice,
      address: '$city Municipal Headquarters',
      contactPhone: 'N/A',
      contactEmail: 'city@${city.toLowerCase()}.gov.in',
    );
  }

  /// Get all registered cities
  List<String> getAllCities() {
    return _jurisdictionMap.keys.toList();
  }

  /// Clear all jurisdictions (for testing)
  void clearJurisdictions() {
    _jurisdictionMap.clear();
  }
}

/// Governing Office information
class GoverningOffice {
  final String id;
  final String name;
  final String city;
  final String ward;
  final OfficeType officeType;
  final String address;
  final String contactPhone;
  final String contactEmail;

  GoverningOffice({
    required this.id,
    required this.name,
    required this.city,
    required this.ward,
    required this.officeType,
    required this.address,
    required this.contactPhone,
    required this.contactEmail,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'ward': ward,
        'officeType': officeType.toString(),
        'address': address,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
      };

  factory GoverningOffice.fromJson(Map<String, dynamic> json) =>
      GoverningOffice(
        id: json['id'],
        name: json['name'],
        city: json['city'],
        ward: json['ward'],
        officeType: OfficeType.values.firstWhere(
          (e) => e.toString() == json['officeType'],
        ),
        address: json['address'],
        contactPhone: json['contactPhone'],
        contactEmail: json['contactEmail'],
      );

  @override
  String toString() => '$name ($ward, $city)';
}

/// Types of governing offices
enum OfficeType {
  wardOffice,    // Smallest administrative unit
  zoneOffice,    // Multiple wards
  districtOffice, // District level
  cityOffice,    // City-wide
}

extension OfficeTypeExtension on OfficeType {
  String get displayName {
    switch (this) {
      case OfficeType.wardOffice:
        return 'Ward Office';
      case OfficeType.zoneOffice:
        return 'Zone Office';
      case OfficeType.districtOffice:
        return 'District Office';
      case OfficeType.cityOffice:
        return 'City Office';
    }
  }
}
