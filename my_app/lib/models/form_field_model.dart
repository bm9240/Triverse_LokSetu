class FormFieldModel {
  final String id;
  final String label;
  final String fieldType; // text, number, date, dropdown, etc.
  final String? value;
  final bool isRequired;
  final List<String>? options; // for dropdown
  final String? sourceDocument; // which document this field was extracted from
  final bool isAutoFilled;

  FormFieldModel({
    required this.id,
    required this.label,
    required this.fieldType,
    this.value,
    this.isRequired = false,
    this.options,
    this.sourceDocument,
    this.isAutoFilled = false,
  });

  FormFieldModel copyWith({
    String? id,
    String? label,
    String? fieldType,
    String? value,
    bool? isRequired,
    List<String>? options,
    String? sourceDocument,
    bool? isAutoFilled,
  }) {
    return FormFieldModel(
      id: id ?? this.id,
      label: label ?? this.label,
      fieldType: fieldType ?? this.fieldType,
      value: value ?? this.value,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
      sourceDocument: sourceDocument ?? this.sourceDocument,
      isAutoFilled: isAutoFilled ?? this.isAutoFilled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'fieldType': fieldType,
      'value': value,
      'isRequired': isRequired,
      'options': options,
      'sourceDocument': sourceDocument,
      'isAutoFilled': isAutoFilled,
    };
  }

  factory FormFieldModel.fromJson(Map<String, dynamic> json) {
    return FormFieldModel(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      fieldType: json['fieldType'] ?? 'text',
      value: json['value'],
      isRequired: json['isRequired'] ?? false,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      sourceDocument: json['sourceDocument'],
      isAutoFilled: json['isAutoFilled'] ?? false,
    );
  }
}

class FormModel {
  final String id;
  final String schemeId;
  final String formName;
  final List<FormFieldModel> fields;
  final DateTime createdAt;
  final String status; // draft, submitted, approved, rejected

  FormModel({
    required this.id,
    required this.schemeId,
    required this.formName,
    required this.fields,
    required this.createdAt,
    this.status = 'draft',
  });

  FormModel copyWith({
    String? id,
    String? schemeId,
    String? formName,
    List<FormFieldModel>? fields,
    DateTime? createdAt,
    String? status,
  }) {
    return FormModel(
      id: id ?? this.id,
      schemeId: schemeId ?? this.schemeId,
      formName: formName ?? this.formName,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schemeId': schemeId,
      'formName': formName,
      'fields': fields.map((f) => f.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      id: json['id'] ?? '',
      schemeId: json['schemeId'] ?? '',
      formName: json['formName'] ?? '',
      fields: (json['fields'] as List?)
              ?.map((f) => FormFieldModel.fromJson(f))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'draft',
    );
  }
}
