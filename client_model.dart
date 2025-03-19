// lib/models/client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Información personal básica
class PersonalInfo {
  final String firstName;
  final String lastName;
  final String idNumber; // cédula
  final String occupation;
  final String gender;
  final DateTime birthDate;

  PersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.idNumber,
    required this.occupation,
    required this.gender,
    required this.birthDate,
  });

  factory PersonalInfo.fromMap(Map<String, dynamic> data) {
    return PersonalInfo(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      idNumber: data['idNumber'] ?? '',
      occupation: data['occupation'] ?? '',
      gender: data['gender'] ?? '',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'idNumber': idNumber,
      'occupation': occupation,
      'gender': gender,
      'birthDate': Timestamp.fromDate(birthDate),
    };
  }
}

// Información de contacto
class ContactInfo {
  final String email;
  final String phone;
  final String address;

  ContactInfo({
    required this.email,
    required this.phone,
    required this.address,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> data) {
    return ContactInfo(
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'address': address,
    };
  }
}

// Historial médico
class MedicalInfo {
  final bool allergies;
  final bool respiratory;
  final bool nervousSystem;
  final bool diabetes;
  final bool kidney;
  final bool digestive;
  final bool cardiac;
  final bool thyroid;
  final bool previousSurgeries;
  final String otherConditions;

  MedicalInfo({
    this.allergies = false,
    this.respiratory = false,
    this.nervousSystem = false,
    this.diabetes = false,
    this.kidney = false,
    this.digestive = false,
    this.cardiac = false,
    this.thyroid = false,
    this.previousSurgeries = false,
    this.otherConditions = '',
  });

  factory MedicalInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return MedicalInfo();
    }

    return MedicalInfo(
      allergies: data['allergies'] ?? false,
      respiratory: data['respiratory'] ?? false,
      nervousSystem: data['nervousSystem'] ?? false,
      diabetes: data['diabetes'] ?? false,
      kidney: data['kidney'] ?? false,
      digestive: data['digestive'] ?? false,
      cardiac: data['cardiac'] ?? false,
      thyroid: data['thyroid'] ?? false,
      previousSurgeries: data['previousSurgeries'] ?? false,
      otherConditions: data['otherConditions'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allergies': allergies,
      'respiratory': respiratory,
      'nervousSystem': nervousSystem,
      'diabetes': diabetes,
      'kidney': kidney,
      'digestive': digestive,
      'cardiac': cardiac,
      'thyroid': thyroid,
      'previousSurgeries': previousSurgeries,
      'otherConditions': otherConditions,
    };
  }
}

// Historial estético
class AestheticInfo {
  final List<String> productsUsed;
  final List<String> currentTreatments;
  final String other;

  AestheticInfo({
    this.productsUsed = const [],
    this.currentTreatments = const [],
    this.other = '',
  });

  factory AestheticInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return AestheticInfo();
    }

    return AestheticInfo(
      productsUsed: List<String>.from(data['productsUsed'] ?? []),
      currentTreatments: List<String>.from(data['currentTreatments'] ?? []),
      other: data['other'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productsUsed': productsUsed,
      'currentTreatments': currentTreatments,
      'other': other,
    };
  }
}

// Hábitos de vida
class LifestyleInfo {
  final bool smoker;
  final bool alcohol;
  final bool regularPhysicalActivity;
  final bool sleepProblems;

  LifestyleInfo({
    this.smoker = false,
    this.alcohol = false,
    this.regularPhysicalActivity = false,
    this.sleepProblems = false,
  });

  factory LifestyleInfo.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return LifestyleInfo();
    }

    return LifestyleInfo(
      smoker: data['smoker'] ?? false,
      alcohol: data['alcohol'] ?? false,
      regularPhysicalActivity: data['regularPhysicalActivity'] ?? false,
      sleepProblems: data['sleepProblems'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'smoker': smoker,
      'alcohol': alcohol,
      'regularPhysicalActivity': regularPhysicalActivity,
      'sleepProblems': sleepProblems,
    };
  }
}

// Marcas faciales para el diagrama
class FacialMark {
  final String id;
  final String type; // 'mark', 'erythema', 'spot', 'injury', 'other'
  final Offset position;
  final String comment;

  FacialMark({
    required this.id,
    required this.type,
    required this.position,
    this.comment = '',
  });

  factory FacialMark.fromMap(Map<String, dynamic> data) {
    return FacialMark(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: data['type'] ?? 'mark',
      position:
          Offset(data['position']['dx'] ?? 0.0, data['position']['dy'] ?? 0.0),
      comment: data['comment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'comment': comment,
    };
  }
}

// Tratamiento facial
class FacialTreatment {
  final String skinType;
  final String skinCondition;
  final int flaccidityDegree;
  final List<FacialMark> facialMarks;

  FacialTreatment({
    this.skinType = '',
    this.skinCondition = '',
    this.flaccidityDegree = 0,
    this.facialMarks = const [],
  });

  factory FacialTreatment.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return FacialTreatment();
    }

    return FacialTreatment(
      skinType: data['skinType'] ?? '',
      skinCondition: data['skinCondition'] ?? '',
      flaccidityDegree: data['flaccidityDegree'] ?? 0,
      facialMarks: (data['facialMarks'] as List?)
              ?.map((mark) => FacialMark.fromMap(mark))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skinType': skinType,
      'skinCondition': skinCondition,
      'flaccidityDegree': flaccidityDegree,
      'facialMarks': facialMarks.map((mark) => mark.toMap()).toList(),
    };
  }
}

// Celulitis para tratamiento corporal
class Cellulite {
  final int grade; // 1, 2, 3, 4
  final String location;

  Cellulite({
    this.grade = 1,
    this.location = '',
  });

  factory Cellulite.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return Cellulite();
    }

    return Cellulite(
      grade: data['grade'] ?? 1,
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'grade': grade,
      'location': location,
    };
  }
}

// Estrías para tratamiento corporal
class Stretch {
  final String color;
  final String duration;

  Stretch({
    this.color = '',
    this.duration = '',
  });

  factory Stretch.fromMap(Map<String, dynamic> data) {
    return Stretch(
      color: data['color'] ?? '',
      duration: data['duration'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'duration': duration,
    };
  }
}

// Tratamiento corporal
class BodyTreatment {
  final double highAbdomen;
  final double lowAbdomen;
  final double waist;
  final double back;
  final double leftArm;
  final double rightArm;
  final double weight;
  final double height;
  final double bmi;
  final Cellulite cellulite;
  final List<Stretch> stretches;

  BodyTreatment({
    this.highAbdomen = 0,
    this.lowAbdomen = 0,
    this.waist = 0,
    this.back = 0,
    this.leftArm = 0,
    this.rightArm = 0,
    this.weight = 0,
    this.height = 0,
    this.bmi = 0,
    Cellulite? cellulite,
    this.stretches = const [],
  }) : cellulite = cellulite ?? Cellulite();

  factory BodyTreatment.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return BodyTreatment();
    }

    return BodyTreatment(
      highAbdomen: (data['highAbdomen'] ?? 0).toDouble(),
      lowAbdomen: (data['lowAbdomen'] ?? 0).toDouble(),
      waist: (data['waist'] ?? 0).toDouble(),
      back: (data['back'] ?? 0).toDouble(),
      leftArm: (data['leftArm'] ?? 0).toDouble(),
      rightArm: (data['rightArm'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      bmi: (data['bmi'] ?? 0).toDouble(),
      cellulite: Cellulite.fromMap(data['cellulite']),
      stretches: (data['stretches'] as List?)
              ?.map((stretch) => Stretch.fromMap(stretch))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'highAbdomen': highAbdomen,
      'lowAbdomen': lowAbdomen,
      'waist': waist,
      'back': back,
      'leftArm': leftArm,
      'rightArm': rightArm,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'cellulite': cellulite.toMap(),
      'stretches': stretches.map((stretch) => stretch.toMap()).toList(),
    };
  }

  // Método para calcular IMC
  double calculateBMI() {
    if (height <= 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }
}

// Tratamiento de bronceado
class TanningTreatment {
  final int glasgowScale;
  final int fitzpatrickScale;

  TanningTreatment({
    this.glasgowScale = 0,
    this.fitzpatrickScale = 0,
  });

  factory TanningTreatment.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return TanningTreatment();
    }

    return TanningTreatment(
      glasgowScale: data['glasgowScale'] ?? 0,
      fitzpatrickScale: data['fitzpatrickScale'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'glasgowScale': glasgowScale,
      'fitzpatrickScale': fitzpatrickScale,
    };
  }
}

// Notas de tratamiento
class TreatmentNote {
  final String id;
  final DateTime date;
  final String note;
  final String therapistId;
  final String therapistName;

  TreatmentNote({
    required this.id,
    required this.date,
    required this.note,
    required this.therapistId,
    required this.therapistName,
  });

  factory TreatmentNote.fromMap(Map<String, dynamic> data) {
    return TreatmentNote(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] ?? '',
      therapistId: data['therapistId'] ?? '',
      therapistName: data['therapistName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'note': note,
      'therapistId': therapistId,
      'therapistName': therapistName,
    };
  }
}

// Modelo completo de cliente
class ClientModel {
  final String id;
  final String userId;
  final PersonalInfo personalInfo;
  final ContactInfo contactInfo;
  final MedicalInfo medicalInfo;
  final AestheticInfo aestheticInfo;
  final LifestyleInfo lifestyleInfo;
  final String consultationReason;
  final FacialTreatment facialTreatment;
  final BodyTreatment bodyTreatment;
  final TanningTreatment tanningTreatment;
  final List<String> preferredTreatments;
  final DateTime lastVisit;
  final int visitCount;
  final String? referredBy;
  final List<TreatmentNote> treatmentNotes;

  ClientModel({
    required this.id,
    required this.userId,
    required this.personalInfo,
    required this.contactInfo,
    required this.medicalInfo,
    required this.aestheticInfo,
    required this.lifestyleInfo,
    this.consultationReason = '',
    required this.facialTreatment,
    required this.bodyTreatment,
    required this.tanningTreatment,
    this.preferredTreatments = const [],
    required this.lastVisit,
    this.visitCount = 0,
    this.referredBy,
    this.treatmentNotes = const [],
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      personalInfo: PersonalInfo.fromMap(data['personalInfo'] ?? {}),
      contactInfo: ContactInfo.fromMap(data['contactInfo'] ?? {}),
      medicalInfo: MedicalInfo.fromMap(data['medicalInfo']),
      aestheticInfo: AestheticInfo.fromMap(data['aestheticInfo']),
      lifestyleInfo: LifestyleInfo.fromMap(data['lifestyleInfo']),
      consultationReason: data['consultationReason'] ?? '',
      facialTreatment: FacialTreatment.fromMap(data['facialTreatment']),
      bodyTreatment: BodyTreatment.fromMap(data['bodyTreatment']),
      tanningTreatment: TanningTreatment.fromMap(data['tanningTreatment']),
      preferredTreatments: List<String>.from(data['preferredTreatments'] ?? []),
      lastVisit: data['lastVisit'] != null
          ? (data['lastVisit'] as Timestamp).toDate()
          : DateTime.now(),
      visitCount: data['visitCount'] ?? 0,
      referredBy: data['referredBy'],
      treatmentNotes: (data['treatmentNotes'] as List?)
              ?.map((note) => TreatmentNote.fromMap(note))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'personalInfo': personalInfo.toMap(),
      'contactInfo': contactInfo.toMap(),
      'medicalInfo': medicalInfo.toMap(),
      'aestheticInfo': aestheticInfo.toMap(),
      'lifestyleInfo': lifestyleInfo.toMap(),
      'consultationReason': consultationReason,
      'facialTreatment': facialTreatment.toMap(),
      'bodyTreatment': bodyTreatment.toMap(),
      'tanningTreatment': tanningTreatment.toMap(),
      'preferredTreatments': preferredTreatments,
      'lastVisit': Timestamp.fromDate(lastVisit),
      'visitCount': visitCount,
      'referredBy': referredBy,
      'treatmentNotes': treatmentNotes.map((note) => note.toMap()).toList(),
    };
  }

  // Método para obtener el nombre completo
  String get fullName => '${personalInfo.firstName} ${personalInfo.lastName}';
}
