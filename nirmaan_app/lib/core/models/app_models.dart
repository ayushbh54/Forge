import 'dart:convert';

class ProjectModel {
  final String id;
  final String code;
  final String name;
  final String client;
  final String contractorJV;
  final String contractType;
  final String location;
  final double totalBudget;
  final double spentBudget;
  final String currency;
  final DateTime startDate;
  final DateTime originalFinishDate;
  DateTime forecastFinishDate;
  final Map<String, String> keyPersonnel;
  final double spi;
  final double cpi;
  final double evidenceCoverage;
  final String status;

  ProjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.client,
    required this.contractorJV,
    required this.contractType,
    required this.location,
    required this.totalBudget,
    required this.spentBudget,
    required this.currency,
    required this.startDate,
    required this.originalFinishDate,
    required this.forecastFinishDate,
    required this.keyPersonnel,
    this.spi = 0.94,
    this.cpi = 0.98,
    this.evidenceCoverage = 88.5,
    this.status = 'ON_TRACK',
  });

  double get remainingBudget => totalBudget - spentBudget;
  double get budgetUtilizationPercentage => (spentBudget / totalBudget) * 100;
  double get budget => totalBudget;
  String get plannedFinishDate => originalFinishDate.toIso8601String();

  // Duration in months
  int get originalDurationMonths {
    return ((originalFinishDate.year - startDate.year) * 12) + (originalFinishDate.month - startDate.month);
  }

  int get forecastDurationMonths {
    return ((forecastFinishDate.year - startDate.year) * 12) + (forecastFinishDate.month - startDate.month);
  }

  int get delaySlippageMonths {
    final diff = forecastDurationMonths - originalDurationMonths;
    return diff > 0 ? diff : 0;
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseKeyPersonnel(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {
        'Project Director': 'Marcus Vance, P.E. (FIDIC 3.1)',
        'Site Piping Supervisor': 'Vikram Joshi (Field Operations)',
        'Lead Planning Engineer': 'Ananya Sen (Primavera Controls)',
        'QA/QC Lead Inspector': 'R. K. Sharma (Materials Lab)',
        'Safety & HSE Officer': 'Subhash Roy (Permit to Work)',
      };
    }

    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      return DateTime.tryParse(val.toString()) ?? fallback;
    }

    return ProjectModel(
      id: json['id']?.toString() ?? 'PRJ-OIL-2026',
      code: json['code']?.toString() ?? json['id']?.toString() ?? 'OIL-PL-024',
      name: json['name']?.toString() ?? 'Trunk Crude Oil Pipeline Expansion',
      client: json['client']?.toString() ?? 'Oil India Limited (OIL)',
      contractorJV: json['contractorJV']?.toString() ?? json['contractor_jv']?.toString() ?? 'Consortium JV',
      contractType: json['contractType']?.toString() ?? json['contract_type']?.toString() ?? 'FIDIC Red Book Cl. 8.4',
      location: json['location']?.toString() ?? 'Duliajan, Assam',
      totalBudget: parseDouble(json['budget'] ?? json['totalBudget'], 2450000000.0),
      spentBudget: parseDouble(json['spentBudget'] ?? json['spent_budget'], 1720000000.0),
      currency: json['currency']?.toString() ?? 'INR (₹)',
      startDate: parseDate(json['startDate'] ?? json['start_date'], DateTime(2026, 1, 15)),
      originalFinishDate: parseDate(json['plannedFinishDate'] ?? json['planned_finish_date'], DateTime(2028, 1, 15)),
      forecastFinishDate: parseDate(json['forecastFinishDate'] ?? json['forecast_finish_date'], DateTime(2028, 7, 15)),
      keyPersonnel: parseKeyPersonnel(json['keyPersonnel']),
      spi: parseDouble(json['spi'], 0.94),
      cpi: parseDouble(json['cpi'], 0.98),
      evidenceCoverage: parseDouble(json['evidenceCoverage'] ?? json['evidence_coverage'], 88.5),
      status: json['status']?.toString() ?? 'ON_TRACK',
    );
  }
}

class ActivityModel {
  final String id;
  final String code;
  final String uwid;
  final String wbsCode;
  final String name;
  final String discipline;
  final DateTime plannedStart;
  final DateTime plannedFinish;
  final int durationDays;
  final int totalFloatDays;
  final bool isCriticalPath;
  final double plannedProgress;
  double contractorReportedProgress;
  final double quantitySurveyProgress;
  final double qcPassedProgress;
  final double droneLidarProgress;
  double validatedConsensusProgress;
  final double plannedQuantity;
  double installedQuantity;
  final String unit;
  final String supervisor;

  ActivityModel({
    required this.id,
    required this.code,
    required this.uwid,
    required this.wbsCode,
    required this.name,
    required this.discipline,
    required this.plannedStart,
    required this.plannedFinish,
    required this.durationDays,
    required this.totalFloatDays,
    required this.isCriticalPath,
    required this.plannedProgress,
    required this.contractorReportedProgress,
    required this.quantitySurveyProgress,
    required this.qcPassedProgress,
    required this.droneLidarProgress,
    required this.validatedConsensusProgress,
    required this.plannedQuantity,
    required this.installedQuantity,
    required this.unit,
    required this.supervisor,
  });

  /// Standard contractual tolerance limit under FIDIC Cl. 14.3 / 8.4 (±5.0%)
  static const double varianceToleranceLimit = 5.0;

  /// Calculates consensus progress from independent field verification sources.
  /// Standard FIDIC weights: Drone LiDAR (30%), Quantity Surveyor (35%), QA/QC (35%).
  double calculateConsensus({
    double droneWeight = 0.30,
    double qsWeight = 0.35,
    double qcWeight = 0.35,
  }) {
    final totalWeight = droneWeight + qsWeight + qcWeight;
    if (totalWeight <= 0) return 0.0;
    final weighted = (droneLidarProgress * droneWeight) +
        (quantitySurveyProgress * qsWeight) +
        (qcPassedProgress * qcWeight);
    final raw = weighted / totalWeight;
    return (raw * 10).roundToDouble() / 10.0;
  }

  /// Calculates 5-factor consensus with customizable weights across all 5 progress factors
  double calculate5FactorConsensus({
    double plannedWeight = 0.0,
    double contractorWeight = 0.0,
    double qsWeight = 0.35,
    double qcWeight = 0.35,
    double droneWeight = 0.30,
  }) {
    final totalWeight = plannedWeight + contractorWeight + qsWeight + qcWeight + droneWeight;
    if (totalWeight <= 0) return 0.0;
    final weighted = (plannedProgress * plannedWeight) +
        (contractorReportedProgress * contractorWeight) +
        (quantitySurveyProgress * qsWeight) +
        (qcPassedProgress * qcWeight) +
        (droneLidarProgress * droneWeight);
    final raw = weighted / totalWeight;
    return (raw * 10).roundToDouble() / 10.0;
  }

  /// Effective reconciled consensus progress (validated consensus from API or calculated from factors)
  double get effectiveConsensus =>
      validatedConsensusProgress > 0 ? validatedConsensusProgress : calculateConsensus();

  /// Variance delta between contractor claim and validated consensus (Claim - Consensus)
  double get varianceDelta =>
      double.parse((contractorReportedProgress - effectiveConsensus).toStringAsFixed(1));

  /// Highlights if contractor claim deviates by more than the ±5.0% contract tolerance limit
  bool get isVarianceToleranceBreached => varianceDelta.abs() > varianceToleranceLimit;

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      return DateTime.tryParse(val.toString()) ?? fallback;
    }

    final isCrit = json['isCriticalPath'] == 1 ||
        json['isCriticalPath'] == true ||
        json['is_critical_path'] == 1 ||
        json['is_critical_path'] == true;

    return ActivityModel(
      id: json['id']?.toString() ?? 'ACT-01',
      code: json['activityCode']?.toString() ?? json['code']?.toString() ?? json['activity_code']?.toString() ?? 'PIP-L5-024',
      uwid: json['uwid']?.toString() ?? 'UWID-EXP-2026-03088',
      wbsCode: json['wbsCode']?.toString() ?? json['wbs_code']?.toString() ?? '03.02.04',
      name: json['name']?.toString() ?? 'Pipe Lower-in & Downhill Welding',
      discipline: json['discipline']?.toString() ?? 'PIPING',
      plannedStart: parseDate(json['plannedStart'] ?? json['planned_start'], DateTime(2026, 2, 1)),
      plannedFinish: parseDate(json['plannedFinish'] ?? json['planned_finish'], DateTime(2026, 4, 15)),
      durationDays: parseInt(json['durationDays'] ?? json['duration_days'], 74),
      totalFloatDays: parseInt(json['totalFloatDays'] ?? json['total_float_days'], 2),
      isCriticalPath: isCrit,
      plannedProgress: parseDouble(json['plannedProgress'] ?? json['planned_progress'], 65.0),
      contractorReportedProgress: parseDouble(json['contractorReportedProgress'] ?? json['contractor_reported_progress'], 80.0),
      quantitySurveyProgress: parseDouble(json['quantitySurveyProgress'] ?? json['quantity_survey_progress'], 74.5),
      qcPassedProgress: parseDouble(json['qcPassedProgress'] ?? json['qc_passed_progress'], 70.0),
      droneLidarProgress: parseDouble(json['droneLidarProgress'] ?? json['drone_lidar_progress'], 68.2),
      validatedConsensusProgress: parseDouble(
        json['validatedConsensusProgress'] ?? json['validated_consensus_progress'],
        ((((parseDouble(json['droneLidarProgress'] ?? json['drone_lidar_progress'], 68.2) * 0.30) +
            (parseDouble(json['quantitySurveyProgress'] ?? json['quantity_survey_progress'], 74.5) * 0.35) +
            (parseDouble(json['qcPassedProgress'] ?? json['qc_passed_progress'], 70.0) * 0.35)) * 10).roundToDouble() / 10.0),
      ),
      plannedQuantity: parseDouble(json['plannedQuantity'] ?? json['planned_quantity'], 1200.0),
      installedQuantity: parseDouble(json['installedQuantity'] ?? json['installed_quantity'], 868.0),
      unit: json['unit']?.toString() ?? 'meters',
      supervisor: json['assignedSupervisor']?.toString() ?? json['assigned_supervisor']?.toString() ?? json['supervisor']?.toString() ?? 'Vikram Joshi',
    );
  }
}

class WorkerModel {
  final String id;
  final String badgeNumber;
  final String name;
  final String trade;
  final List<String> skills;
  final String gang;
  final String safetyCertExpiry;
  String attendanceStatus; // 'ABSENT', 'VERIFIED_PRESENT'
  String verificationMethod; // 'NOT_VERIFIED', 'GEOFENCE_BIOMETRIC'
  double confidenceScore;
  String lastClockIn;
  double geofenceDistanceMeters;
  bool isAiSpoofProtected;

  WorkerModel({
    required this.id,
    required this.badgeNumber,
    required this.name,
    required this.trade,
    required this.skills,
    required this.gang,
    required this.safetyCertExpiry,
    this.attendanceStatus = 'ABSENT',
    this.verificationMethod = 'NOT_VERIFIED',
    this.confidenceScore = 0.0,
    this.lastClockIn = 'Not clocked in today',
    this.geofenceDistanceMeters = 0.0,
    this.isAiSpoofProtected = true,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = ['General Trade'];
    final rawSkills = json['skills'];
    if (rawSkills is List) {
      parsedSkills = rawSkills.map((s) => s?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      if (parsedSkills.isEmpty) parsedSkills = ['General Trade'];
    } else if (rawSkills is String && rawSkills.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSkills);
        if (decoded is List) {
          parsedSkills = decoded.map((s) => s?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        }
      } catch (_) {
        parsedSkills = [rawSkills];
      }
    }

    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    return WorkerModel(
      id: json['id']?.toString() ?? 'WRK-01',
      badgeNumber: json['badgeNumber']?.toString() ?? json['badge_number']?.toString() ?? 'LAB-01',
      name: json['name']?.toString() ?? 'Worker Name',
      trade: json['trade']?.toString() ?? 'WELDER',
      skills: parsedSkills,
      gang: json['contractor']?.toString() ?? json['gang']?.toString() ?? 'Site Gang A',
      safetyCertExpiry: json['safetyCertValidTill']?.toString() ?? json['safety_cert_valid_till']?.toString() ?? '2027-12-31',
      attendanceStatus: json['attendanceStatus']?.toString() ?? json['attendance_status']?.toString() ?? 'ABSENT',
      verificationMethod: json['verificationMethod']?.toString() ?? json['verification_method']?.toString() ?? 'NOT_VERIFIED',
      confidenceScore: parseDouble(json['confidenceScore'] ?? json['confidence_score'], 0.0),
      lastClockIn: json['lastClockIn']?.toString() ?? json['last_clock_in']?.toString() ?? 'Pending Clock-in',
      geofenceDistanceMeters: parseDouble(json['geofenceDistanceMeters'], 8.5),
      isAiSpoofProtected: json['isAiSpoofProtected'] != false,
    );
  }
}

class SupervisorVisitModel {
  final String id;
  final String supervisorName;
  final String supervisorRole;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final bool siteGeofenceVerified;
  final double distanceToSiteBoundaryMeters;
  final bool aiSpoofCheckPassed;
  final String photoWatermarkHash;
  final String inspectionRemarks;
  final String activityCode;

  SupervisorVisitModel({
    required this.id,
    required this.supervisorName,
    required this.supervisorRole,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.siteGeofenceVerified,
    required this.distanceToSiteBoundaryMeters,
    required this.aiSpoofCheckPassed,
    required this.photoWatermarkHash,
    required this.inspectionRemarks,
    required this.activityCode,
  });
}

class TenderPdfInsight {
  final String tenderId;
  final String title;
  final int totalPages;
  final String clientAgency;
  final double estimatedValue;
  final String currency;
  final List<String> keyMilestones;
  final List<String> penaltyClauses;
  final List<String> technicalSpecifications;
  final List<String> paymentTerms;
  final String fidicConditions;
  final int translatedPagesCount;
  final bool isStructuralLayoutPreserved;

  TenderPdfInsight({
    required this.tenderId,
    required this.title,
    required this.totalPages,
    required this.clientAgency,
    required this.estimatedValue,
    required this.currency,
    required this.keyMilestones,
    required this.penaltyClauses,
    required this.technicalSpecifications,
    required this.paymentTerms,
    required this.fidicConditions,
    required this.translatedPagesCount,
    this.isStructuralLayoutPreserved = true,
  });
}

class ContractorScorecardModel {
  final String id;
  final String name;
  final String code;
  final String category;
  final String scopeDescription;
  final double rating;
  final double maxRating;
  final double spi;
  final String spiStatus;
  final double safetyScore;
  final int workersCount;
  final bool hasVarianceAlert;
  final String? varianceAlertReason;
  final double plannedProductivity;
  final double actualProductivity;
  final String productivityUnit;
  final double reworkRate;
  final double qcBenchmarkRate;
  final double qcPassedInspectionRate;
  final String safetyRecord;
  final int safeDaysCount;
  final int safeManHours;
  final int safetyIncidentsCount;
  final double certifiedMilestonesCr;
  final double paidMilestonesCr;
  final double withheldOrRetentionCr;
  final String contractClause;
  final String institutionalMemoryTag;
  final double tenderQualificationScore;
  final double tenderScoreDelta;
  final String tenderRecommendation;
  final Map<String, int> gangTrades;
  final String lastAuditDate;

  const ContractorScorecardModel({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.scopeDescription,
    required this.rating,
    this.maxRating = 5.0,
    required this.spi,
    required this.spiStatus,
    required this.safetyScore,
    required this.workersCount,
    this.hasVarianceAlert = false,
    this.varianceAlertReason,
    required this.plannedProductivity,
    required this.actualProductivity,
    this.productivityUnit = 'm/day',
    required this.reworkRate,
    this.qcBenchmarkRate = 3.0,
    this.qcPassedInspectionRate = 98.6,
    this.safetyRecord = 'Zero LTI',
    required this.safeDaysCount,
    required this.safeManHours,
    this.safetyIncidentsCount = 0,
    required this.certifiedMilestonesCr,
    required this.paidMilestonesCr,
    required this.withheldOrRetentionCr,
    required this.contractClause,
    this.institutionalMemoryTag = 'Performance record will feed future tender qualification scoring',
    required this.tenderQualificationScore,
    required this.tenderScoreDelta,
    required this.tenderRecommendation,
    required this.gangTrades,
    required this.lastAuditDate,
  });

  double get productivityEfficiency =>
      plannedProductivity > 0 ? (actualProductivity / plannedProductivity) * 100 : 0.0;

  double get paymentFulfillmentPercentage =>
      certifiedMilestonesCr > 0 ? (paidMilestonesCr / certifiedMilestonesCr) * 100 : 0.0;
}

enum EquipmentStatus {
  running,
  idle,
  standby,
  maintenance,
  breakdown;

  String get label {
    switch (this) {
      case EquipmentStatus.running:
        return 'RUNNING';
      case EquipmentStatus.idle:
        return 'IDLE';
      case EquipmentStatus.standby:
        return 'STANDBY';
      case EquipmentStatus.maintenance:
        return 'MAINTENANCE';
      case EquipmentStatus.breakdown:
        return 'BREAKDOWN';
    }
  }
}

class EquipmentModel {
  final String id;
  final String tag;
  final String name;
  final String category;
  final String task;
  final String location;
  final EquipmentStatus status;
  final double fuelLevel; // 0 to 100 percentage
  final double engineHours;
  final double fuelBurnRate; // Litres per hour
  final String operatorName;
  final String maintenanceDue;
  final int maintenanceDueDays;
  final String? blockedActivityId;
  final bool isCriticalPathBlocker;
  final String? alertMessage;
  final Map<String, String> telemetryMetrics;

  const EquipmentModel({
    required this.id,
    required this.tag,
    required this.name,
    required this.category,
    required this.task,
    required this.location,
    required this.status,
    required this.fuelLevel,
    required this.engineHours,
    required this.fuelBurnRate,
    required this.operatorName,
    required this.maintenanceDue,
    this.maintenanceDueDays = 30,
    this.blockedActivityId,
    this.isCriticalPathBlocker = false,
    this.alertMessage,
    this.telemetryMetrics = const {},
  });

  bool get isRunning => status == EquipmentStatus.running;
  bool get isIdle => status == EquipmentStatus.idle;
  bool get isBreakdown => status == EquipmentStatus.breakdown;
}

enum VariationWorkflowStage {
  initiated,
  engineerReviewed,
  clientSanctioned;

  String get label {
    switch (this) {
      case VariationWorkflowStage.initiated:
        return 'Initiated';
      case VariationWorkflowStage.engineerReviewed:
        return 'Engineer Reviewed';
      case VariationWorkflowStage.clientSanctioned:
        return 'Client Sanctioned';
    }
  }

  int get stepIndex {
    switch (this) {
      case VariationWorkflowStage.initiated:
        return 0;
      case VariationWorkflowStage.engineerReviewed:
        return 1;
      case VariationWorkflowStage.clientSanctioned:
        return 2;
    }
  }
}

class VariationOrderModel {
  final String id;
  final String title;
  final String clauseReference;
  final double costImpactCr;
  final int scheduleImpactDays;
  final VariationWorkflowStage workflowStage;
  final String reason;
  final String scopeDescription;
  final String workPackage;
  final String submittedDate;
  final String? engineerReviewedDate;
  final String? clientSanctionedDate;
  final String contractorOriginator;
  final String engineerSignatory;
  final String? clientSignatory;
  final String? sanctionReferenceNumber;
  final Map<String, double> boqCostBreakdown;
  final List<String> technicalJustifications;
  final bool hasCriticalPathImpact;

  const VariationOrderModel({
    required this.id,
    required this.title,
    required this.clauseReference,
    required this.costImpactCr,
    required this.scheduleImpactDays,
    required this.workflowStage,
    required this.reason,
    required this.scopeDescription,
    required this.workPackage,
    required this.submittedDate,
    this.engineerReviewedDate,
    this.clientSanctionedDate,
    required this.contractorOriginator,
    this.engineerSignatory = 'Marcus Vance, P.E. (FIDIC Cl. 3.1 Engineer)',
    this.clientSignatory,
    this.sanctionReferenceNumber,
    this.boqCostBreakdown = const {},
    this.technicalJustifications = const [],
    this.hasCriticalPathImpact = true,
  });

  String get formattedCost => '+₹${costImpactCr.toStringAsFixed(2)} Cr';
  String get formattedSchedule =>
      scheduleImpactDays > 0 ? '+$scheduleImpactDays Days EOT' : '0 Days (Nil CPM)';
  bool get isSanctioned => workflowStage == VariationWorkflowStage.clientSanctioned;
  bool get isReviewed => workflowStage == VariationWorkflowStage.engineerReviewed;
  bool get isInitiated => workflowStage == VariationWorkflowStage.initiated;

  VariationOrderModel copyWith({
    String? id,
    String? title,
    String? clauseReference,
    double? costImpactCr,
    int? scheduleImpactDays,
    VariationWorkflowStage? workflowStage,
    String? reason,
    String? scopeDescription,
    String? workPackage,
    String? submittedDate,
    String? engineerReviewedDate,
    String? clientSanctionedDate,
    String? contractorOriginator,
    String? engineerSignatory,
    String? clientSignatory,
    String? sanctionReferenceNumber,
    Map<String, double>? boqCostBreakdown,
    List<String>? technicalJustifications,
    bool? hasCriticalPathImpact,
  }) {
    return VariationOrderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      clauseReference: clauseReference ?? this.clauseReference,
      costImpactCr: costImpactCr ?? this.costImpactCr,
      scheduleImpactDays: scheduleImpactDays ?? this.scheduleImpactDays,
      workflowStage: workflowStage ?? this.workflowStage,
      reason: reason ?? this.reason,
      scopeDescription: scopeDescription ?? this.scopeDescription,
      workPackage: workPackage ?? this.workPackage,
      submittedDate: submittedDate ?? this.submittedDate,
      engineerReviewedDate: engineerReviewedDate ?? this.engineerReviewedDate,
      clientSanctionedDate: clientSanctionedDate ?? this.clientSanctionedDate,
      contractorOriginator: contractorOriginator ?? this.contractorOriginator,
      engineerSignatory: engineerSignatory ?? this.engineerSignatory,
      clientSignatory: clientSignatory ?? this.clientSignatory,
      sanctionReferenceNumber: sanctionReferenceNumber ?? this.sanctionReferenceNumber,
      boqCostBreakdown: boqCostBreakdown ?? this.boqCostBreakdown,
      technicalJustifications: technicalJustifications ?? this.technicalJustifications,
      hasCriticalPathImpact: hasCriticalPathImpact ?? this.hasCriticalPathImpact,
    );
  }
}

/// Origin of critical path delay event
enum DelayOrigin {
  employer,
  contractor,
}

/// FIDIC Sub-Clause 8.7 Milestone-specific Liquidated Damages Model
class MilestoneLdModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final double contractValueWeight; // e.g. 0.30 (30%)
  final double allocatedValueCr; // e.g. 55.20 Cr
  final DateTime baselineDueDate;
  final DateTime certifiedDate;
  final int grossDelayDays;
  final int concurrentEmployerOffsetDays;
  final double weeklyLdRatePct; // e.g. 0.5%
  final double maxCapPct; // e.g. 10.0%
  final String status; // 'COMPLETED_LD', 'CRITICAL_DELAY', 'PROJECTED_DELAY', 'ON_SCHEDULE'
  final List<String> scopeKeyDeliverables;

  const MilestoneLdModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.contractValueWeight,
    required this.allocatedValueCr,
    required this.baselineDueDate,
    required this.certifiedDate,
    required this.grossDelayDays,
    required this.concurrentEmployerOffsetDays,
    this.weeklyLdRatePct = 0.50,
    this.maxCapPct = 10.00,
    required this.status,
    this.scopeKeyDeliverables = const [],
  });

  int get netCulpableDelayDays {
    final net = grossDelayDays - concurrentEmployerOffsetDays;
    return net < 0 ? 0 : net;
  }

  double get grossDelayWeeks => grossDelayDays / 7.0;
  double get netDelayWeeks => netCulpableDelayDays / 7.0;
  double get weeklyRateCr => allocatedValueCr * (weeklyLdRatePct / 100.0);
  double get dailyRateCr => weeklyRateCr / 7.0;
  double get maxCapCr => allocatedValueCr * (maxCapPct / 100.0);
  double get uncappedLdCr => netDelayWeeks * weeklyRateCr;
  double get calculatedLdCr => uncappedLdCr > maxCapCr ? maxCapCr : uncappedLdCr;
  bool get isCapped => uncappedLdCr >= maxCapCr;
  double get capUtilizationPct => maxCapCr > 0 ? (calculatedLdCr / maxCapCr) * 100.0 : 0.0;

  MilestoneLdModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    double? contractValueWeight,
    double? allocatedValueCr,
    DateTime? baselineDueDate,
    DateTime? certifiedDate,
    int? grossDelayDays,
    int? concurrentEmployerOffsetDays,
    double? weeklyLdRatePct,
    double? maxCapPct,
    String? status,
    List<String>? scopeKeyDeliverables,
  }) {
    return MilestoneLdModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      contractValueWeight: contractValueWeight ?? this.contractValueWeight,
      allocatedValueCr: allocatedValueCr ?? this.allocatedValueCr,
      baselineDueDate: baselineDueDate ?? this.baselineDueDate,
      certifiedDate: certifiedDate ?? this.certifiedDate,
      grossDelayDays: grossDelayDays ?? this.grossDelayDays,
      concurrentEmployerOffsetDays: concurrentEmployerOffsetDays ?? this.concurrentEmployerOffsetDays,
      weeklyLdRatePct: weeklyLdRatePct ?? this.weeklyLdRatePct,
      maxCapPct: maxCapPct ?? this.maxCapPct,
      status: status ?? this.status,
      scopeKeyDeliverables: scopeKeyDeliverables ?? this.scopeKeyDeliverables,
    );
  }
}

/// SCL Delay and Disruption Protocol Concurrent Delay Event Model
class ConcurrentDelayEventModel {
  final String id;
  final String code;
  final String title;
  final DelayOrigin origin;
  final String description;
  final String fidicSubclause;
  final DateTime startDate;
  final DateTime endDate;
  final int impactDays;
  final bool isCriticalPath;
  final String evidenceReference;
  final bool isApprovedForOffset;

  const ConcurrentDelayEventModel({
    required this.id,
    required this.code,
    required this.title,
    required this.origin,
    required this.description,
    required this.fidicSubclause,
    required this.startDate,
    required this.endDate,
    required this.impactDays,
    required this.isCriticalPath,
    required this.evidenceReference,
    this.isApprovedForOffset = true,
  });

  bool get isEmployerDelay => origin == DelayOrigin.employer;
  bool get isContractorDelay => origin == DelayOrigin.contractor;

  ConcurrentDelayEventModel copyWith({
    String? id,
    String? code,
    String? title,
    DelayOrigin? origin,
    String? description,
    String? fidicSubclause,
    DateTime? startDate,
    DateTime? endDate,
    int? impactDays,
    bool? isCriticalPath,
    String? evidenceReference,
    bool? isApprovedForOffset,
  }) {
    return ConcurrentDelayEventModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      origin: origin ?? this.origin,
      description: description ?? this.description,
      fidicSubclause: fidicSubclause ?? this.fidicSubclause,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      impactDays: impactDays ?? this.impactDays,
      isCriticalPath: isCriticalPath ?? this.isCriticalPath,
      evidenceReference: evidenceReference ?? this.evidenceReference,
      isApprovedForOffset: isApprovedForOffset ?? this.isApprovedForOffset,
    );
  }
}

/// Legal Citation / Case Precedent Model
class LegalCitationModel {
  final String title;
  final String citation;
  final String court;
  final String year;
  final String principle;
  final String relevanceToLd;

  const LegalCitationModel({
    required this.title,
    required this.citation,
    required this.court,
    required this.year,
    required this.principle,
    required this.relevanceToLd,
  });
}

