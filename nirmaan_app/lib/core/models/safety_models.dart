enum PermitStatus {
  approved,
  pendingGasTest,
  underReview,
  closed,
}

enum PermitType {
  hotWork,
  workingAtHeight,
  confinedSpace,
  electricalIsolation,
  excavation,
  heavyLifting,
  coldWork,
}

class SafetyPermitModel {
  final String id;
  final String title;
  final String permitType;
  final String location;
  final String issuedTo;
  final String validTill;
  PermitStatus status;
  final String hazardLevel;
  final List<String> safetyChecklist;
  final Map<String, String>? gasTestReadings;
  final String authorizedOfficer;
  final DateTime issuedAt;
  final String workOrderRef;

  SafetyPermitModel({
    required this.id,
    required this.title,
    required this.permitType,
    required this.location,
    required this.issuedTo,
    required this.validTill,
    required this.status,
    required this.hazardLevel,
    required this.safetyChecklist,
    this.gasTestReadings,
    required this.authorizedOfficer,
    required this.issuedAt,
    required this.workOrderRef,
  });

  String get statusDisplay {
    switch (status) {
      case PermitStatus.approved:
        return 'APPROVED';
      case PermitStatus.pendingGasTest:
        return 'PENDING GAS TEST';
      case PermitStatus.underReview:
        return 'UNDER REVIEW';
      case PermitStatus.closed:
        return 'CLOSED';
    }
  }

  factory SafetyPermitModel.fromJson(Map<String, dynamic> json) {
    PermitStatus parsedStatus = PermitStatus.approved;
    final s = json['status']?.toString().toUpperCase() ?? '';
    if (s.contains('PENDING') || s.contains('GAS')) {
      parsedStatus = PermitStatus.pendingGasTest;
    } else if (s.contains('REVIEW')) {
      parsedStatus = PermitStatus.underReview;
    } else if (s.contains('CLOSED')) {
      parsedStatus = PermitStatus.closed;
    }

    return SafetyPermitModel(
      id: json['id'] ?? 'PTW-2026-001',
      title: json['title'] ?? 'General Work Permit',
      permitType: json['permitType'] ?? 'General',
      location: json['location'] ?? 'Site Corridor',
      issuedTo: json['issuedTo'] ?? 'Site Gang',
      validTill: json['validTill'] ?? '18:00',
      status: parsedStatus,
      hazardLevel: json['hazardLevel'] ?? 'HIGH',
      safetyChecklist: List<String>.from(json['safetyChecklist'] ?? []),
      gasTestReadings: json['gasTestReadings'] != null
          ? Map<String, String>.from(json['gasTestReadings'])
          : null,
      authorizedOfficer: json['authorizedOfficer'] ?? 'Subhash Roy (HSE)',
      issuedAt: DateTime.tryParse(json['issuedAt'] ?? '') ?? DateTime.now(),
      workOrderRef: json['workOrderRef'] ?? 'WO-OIL-2026',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'permitType': permitType,
      'location': location,
      'issuedTo': issuedTo,
      'validTill': validTill,
      'status': statusDisplay,
      'hazardLevel': hazardLevel,
      'safetyChecklist': safetyChecklist,
      'gasTestReadings': gasTestReadings,
      'authorizedOfficer': authorizedOfficer,
      'issuedAt': issuedAt.toIso8601String(),
      'workOrderRef': workOrderRef,
    };
  }
}

class NearMissReportModel {
  final String id;
  final String hazardCategory;
  final String location;
  final String description;
  final String immediateActionTaken;
  final String? photoPath;
  final String severity;
  final String reporterName;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  String status;

  NearMissReportModel({
    required this.id,
    required this.hazardCategory,
    required this.location,
    required this.description,
    required this.immediateActionTaken,
    this.photoPath,
    required this.severity,
    required this.reporterName,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.status = 'OPEN',
  });
}

class SafetyAuditModel {
  final String id;
  final String title;
  final String standardCode;
  final String location;
  final String auditorName;
  final DateTime date;
  final String status; // 'PASS', 'PASS_WITH_OBSERVATION', 'ACTION_REQUIRED'
  final double complianceScore;
  final List<String> findings;

  SafetyAuditModel({
    required this.id,
    required this.title,
    required this.standardCode,
    required this.location,
    required this.auditorName,
    required this.date,
    required this.status,
    required this.complianceScore,
    required this.findings,
  });
}

class WorkerSafetyProfile {
  final String badgeNumber;
  final String name;
  final String trade;
  final String contractor;
  final String clearanceStatus;
  final String photoUrl;
  final List<SafetyCertification> certifications;
  final String medicalFitnessDate;
  final String audiometryClass;
  final bool authorizedForHighRisk;

  WorkerSafetyProfile({
    required this.badgeNumber,
    required this.name,
    required this.trade,
    required this.contractor,
    required this.clearanceStatus,
    required this.photoUrl,
    required this.certifications,
    required this.medicalFitnessDate,
    required this.audiometryClass,
    required this.authorizedForHighRisk,
  });
}

class SafetyCertification {
  final String title;
  final String standard;
  final String validTill;
  final bool isValid;

  SafetyCertification({
    required this.title,
    required this.standard,
    required this.validTill,
    required this.isValid,
  });
}

class MusterPointModel {
  final String id;
  final String code;
  final String name;
  final String locationDescription;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final String walkingTime;
  final String bearing;
  final int capacity;
  final int currentHeadcount;
  final String status; // 'SAFE', 'STANDBY', 'DOWNWIND_WARNING'
  final String evacuationRoute;
  final List<String> emergencyEquipment;

  MusterPointModel({
    required this.id,
    required this.code,
    required this.name,
    required this.locationDescription,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.walkingTime,
    required this.bearing,
    required this.capacity,
    required this.currentHeadcount,
    required this.status,
    required this.evacuationRoute,
    required this.emergencyEquipment,
  });
}

class SiteClinicModel {
  final String name;
  final String location;
  final String emergencyHotline;
  final String speedDial;
  final String medicalOfficer;
  final String paramedicOnDuty;
  final String ambulanceStatus;
  final String responseTimeSla;
  final List<String> standbyEquipment;
  final List<FirstAiderModel> firstAiders;

  SiteClinicModel({
    required this.name,
    required this.location,
    required this.emergencyHotline,
    required this.speedDial,
    required this.medicalOfficer,
    required this.paramedicOnDuty,
    required this.ambulanceStatus,
    required this.responseTimeSla,
    required this.standbyEquipment,
    required this.firstAiders,
  });
}

class FirstAiderModel {
  final String name;
  final String badgeNumber;
  final String trade;
  final String location;
  final String contactExtension;
  final String certification;

  FirstAiderModel({
    required this.name,
    required this.badgeNumber,
    required this.trade,
    required this.location,
    required this.contactExtension,
    required this.certification,
  });
}

class PtwChecklistItem {
  final String id;
  final String title;
  final String standardRef;
  final bool isMandatory;
  bool isVerified;
  String? verifiedBy;
  DateTime? verifiedAt;

  PtwChecklistItem({
    required this.id,
    required this.title,
    required this.standardRef,
    this.isMandatory = true,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
  });
}

class GasTelemetrySensor {
  final String id;
  final String zone;
  final String associatedPermitType;
  double h2sPpm; // Safe < 10.0 ppm, alarm >= 10.0 ppm
  double lelPercent; // Safe < 10.0 %, alarm >= 10.0 %
  double o2Percent; // Safe 19.5% - 23.5%, alarm < 19.5% or > 23.5%
  double coPpm; // Safe < 25.0 ppm
  final String atexClassification;
  final String detectorModel;
  int batteryLevel;
  DateTime lastBumpTest;
  bool isMuted;

  GasTelemetrySensor({
    required this.id,
    required this.zone,
    required this.associatedPermitType,
    required this.h2sPpm,
    required this.lelPercent,
    required this.o2Percent,
    required this.coPpm,
    required this.atexClassification,
    required this.detectorModel,
    this.batteryLevel = 94,
    required this.lastBumpTest,
    this.isMuted = false,
  });

  bool get isH2sAlarm => h2sPpm >= 10.0;
  bool get isLelAlarm => lelPercent >= 10.0;
  bool get isO2Alarm => o2Percent < 19.5 || o2Percent > 23.5;
  bool get isCoAlarm => coPpm >= 25.0;
  bool get hasAnyAlarm => isH2sAlarm || isLelAlarm || isO2Alarm || isCoAlarm;

  String get overallStatus {
    if (hasAnyAlarm) return 'CRITICAL ALARM';
    if (h2sPpm >= 5.0 || lelPercent >= 5.0) return 'WARNING';
    return 'SAFE & NORMAL';
  }
}

class HseGoldenRuleModel {
  final int ruleNumber;
  final String title;
  final String lifeSavingStandard;
  final String mandatoryAction;
  final String standardCode;
  bool isCompliant;
  String remarks;
  String? auditorName;
  DateTime? auditTimestamp;

  HseGoldenRuleModel({
    required this.ruleNumber,
    required this.title,
    required this.lifeSavingStandard,
    required this.mandatoryAction,
    required this.standardCode,
    this.isCompliant = true,
    this.remarks = 'Verified on field by HSE Inspector. Fully compliant with site controls.',
    this.auditorName,
    this.auditTimestamp,
  });
}

class HseOfficerSignOff {
  final String officerName;
  final String badgeId;
  final String shift;
  final DateTime timestamp;
  final String digitalSignatureHash;
  final double compliancePercentage;
  final double? latitude;
  final double? longitude;
  final bool isRatified;

  HseOfficerSignOff({
    required this.officerName,
    required this.badgeId,
    required this.shift,
    required this.timestamp,
    required this.digitalSignatureHash,
    required this.compliancePercentage,
    this.latitude,
    this.longitude,
    this.isRatified = true,
  });
}

