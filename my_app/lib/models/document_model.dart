class DocumentModel {
  final String id;
  final String name;
  final String type; // aadhaar, passbook, certificate, etc.
  final String? imagePath;
  final Map<String, dynamic> extractedData;
  final bool isVerified;

  DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    this.imagePath,
    this.extractedData = const {},
    this.isVerified = false,
  });

  DocumentModel copyWith({
    String? id,
    String? name,
    String? type,
    String? imagePath,
    Map<String, dynamic>? extractedData,
    bool? isVerified,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      extractedData: extractedData ?? this.extractedData,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'imagePath': imagePath,
      'extractedData': extractedData,
      'isVerified': isVerified,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      imagePath: json['imagePath'],
      extractedData: json['extractedData'] ?? {},
      isVerified: json['isVerified'] ?? false,
    );
  }
}
