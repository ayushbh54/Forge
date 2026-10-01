import 'package:flutter/material.dart';

class AppConstants {
  static const String defaultApiBaseUrl = 'http://10.0.2.2:3000';
  
  // Oil India Duliajan Central Operational Area Parameters
  static const String oilIndiaSiteName = 'Oil India Duliajan Central Operational Area';
  static const double oilIndiaSiteLatitude = 27.4825; // 27.4825° N
  static const double oilIndiaSiteLongitude = 95.3225; // 95.3225° E
  static const double oilIndiaGeofenceRadiusMeters = 100.0; // 100m boundary

  // Global Geofence Defaults (bound to Oil India Duliajan Operational Area)
  static const double geofenceRadiusMeters = 100.0;
  static const double defaultSiteLatitude = 27.4825; // Oil India Duliajan Central Operational Area
  static const double defaultSiteLongitude = 95.3225;
  static const String appVersion = '1.0.0';
  static const int maxPhotoSizeMB = 5;

  // Roles
  static const String roleProjectManager = 'PROJECT_MANAGER';
  static const String roleSiteEngineer = 'SITE_ENGINEER';
  static const String roleSupervisor = 'SUPERVISOR';
  static const String roleLabour = 'LABOUR';
  static const String roleQaQc = 'QA_QC';
  static const String roleHseOfficer = 'HSE_OFFICER';
  static const String roleMaterialsController = 'MATERIALS_CONTROLLER';
  static const String rolePlanningEngineer = 'PLANNING_ENGINEER';

  // Departments
  static const String deptCivil = 'CIVIL';
  static const String deptPiping = 'PIPING';
  static const String deptElectrical = 'ELECTRICAL';
  static const String deptInstrumentation = 'INSTRUMENTATION';
  static const String deptMechanical = 'MECHANICAL';
  static const String deptHse = 'HSE';

  // Status Colors (Example Mapping)
  static const Map<String, Color> statusColors = {
    'PENDING': Colors.orange,
    'IN_PROGRESS': Colors.blue,
    'COMPLETED': Colors.green,
    'DELAYED': Colors.red,
  };
}
