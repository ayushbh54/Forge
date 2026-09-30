import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS — IEC 62443 / CERT-In CNI CYBERSECURITY
// ============================================================================

/// Purdue Model ICS Network Architecture Levels per IEC 62443-3-2
enum PurdueLevel {
  level0, // Level 0: Process Zone (Sensors, Actuators, ESDV Quick Exhausts, HART loops)
  level1, // Level 1: Basic Control (Safety PLCs, Moxa ioPAC, Schneider SCADAPack RTUs)
  level2, // Level 2: Supervisory SCADA (SCADA Masters, Local Historians, Operator HMIs, EWS)
  level3, // Level 3: Operations & IDMZ (Central PI Historian, Jump Host Bastion, Patch WSUS, IDS)
  level4, // Level 4: Enterprise Network (SAP ERP, Corporate Cloud, Office WAN)
}

/// Security Levels per IEC 62443 (SL-1 to SL-4)
enum IecSecurityLevel {
  sl1, // Protection against casual/coincidental violation
  sl2, // Protection against intentional violation using simple means
  sl3, // Protection against intentional violation using sophisticated means (ICS targeted)
  sl4, // Protection against intentional violation using state-sponsored/advanced means
}

/// Industrial Protocols Inspected by DPI Engine
enum IcsProtocol {
  modbusTcp,
  dnp3Sa,
  iec104,
  arpNetwork,
  dot1xPort,
}

/// Threat Severity Classification per CERT-In Incident Reporting
enum ThreatSeverity {
  critical, // Immediate physical safety / shutdown hazard (P1)
  high, // Conduit breach or active MitM probe (P2)
  medium, // Unauthorized configuration or protocol anomaly (P3)
  low, // Reconnaissance scan or policy advisory (P4)
  cleared, // Verified normal traffic
}

/// Uplink Communication Medium for Remote RTU Valve Stations
enum UplinkMedium {
  vsatSatellite,
  cellularPrivateApn,
  dualFailover,
}

/// Model for a Purdue Architecture Zone / Level
class PurdueZoneConfig {
  final PurdueLevel level;
  final String title;
  final String code;
  final String description;
  final IecSecurityLevel targetSl;
  final double achievedSl; // e.g. 3.4
  final List<String> primaryAssets;
  final String conduitSecurity;
  final String firewallPolicy;
  final int activeAssetCount;
  final int blockedAttacks24h;
  final bool isAirgapped;
  final bool hasDataDiode;

  const PurdueZoneConfig({
    required this.level,
    required this.title,
    required this.code,
    required this.description,
    required this.targetSl,
    required this.achievedSl,
    required this.primaryAssets,
    required this.conduitSecurity,
    required this.firewallPolicy,
    required this.activeAssetCount,
    required this.blockedAttacks24h,
    this.isAirgapped = false,
    this.hasDataDiode = false,
  });

  String get targetSlLabel => 'SL-${targetSl.index + 1}';
  Color get slColor {
    if (achievedSl >= 3.5) return const Color(0xFF10B981);
    if (achievedSl >= 3.0) return const Color(0xFF0284C7);
    if (achievedSl >= 2.0) return const Color(0xFFFFB95F);
    return const Color(0xFFFFB4AB);
  }
}

/// Model for Conduit between Zones
class ZoneConduit {
  final String id; // e.g. C-01, C-02
  final String name;
  final String sourceZone;
  final String targetZone;
  final String encryption; // TLS 1.3 / IPsec / Optical Diode
  final String firewallHardware;
  final bool isHardwareDiode;
  final bool isEnforcing;
  final double throughputKbps;
  final int packetDropCount;

  const ZoneConduit({
    required this.id,
    required this.name,
    required this.sourceZone,
    required this.targetZone,
    required this.encryption,
    required this.firewallHardware,
    this.isHardwareDiode = false,
    this.isEnforcing = true,
    required this.throughputKbps,
    required this.packetDropCount,
  });
}

/// Model for Protocol Deep Packet Inspection (DPI) Event
class DpiPacketLog {
  final String id;
  final DateTime timestamp;
  final IcsProtocol protocol;
  final String sourceIp;
  final int sourcePort;
  final String destinationIp;
  final int destinationPort;
  final String targetStationId; // e.g. VS-03
  final String functionCodeOrAsdu; // e.g. "0x05 (Force Single Coil)" or "ASDU 45"
  final String description;
  final ThreatSeverity severity;
  final bool isBlocked;
  final String ruleTriggered;
  final String hexPayloadPreview;
  final String forensicMitigation;

  DpiPacketLog({
    required this.id,
    required this.timestamp,
    required this.protocol,
    required this.sourceIp,
    required this.sourcePort,
    required this.destinationIp,
    required this.destinationPort,
    required this.targetStationId,
    required this.functionCodeOrAsdu,
    required this.description,
    required this.severity,
    required this.isBlocked,
    required this.ruleTriggered,
    required this.hexPayloadPreview,
    required this.forensicMitigation,
  });

  Color get severityColor {
    switch (severity) {
      case ThreatSeverity.critical:
        return const Color(0xFFFF5252);
      case ThreatSeverity.high:
        return const Color(0xFFFF7043);
      case ThreatSeverity.medium:
        return const Color(0xFFFFB95F);
      case ThreatSeverity.low:
        return const Color(0xFF38BDF8);
      case ThreatSeverity.cleared:
        return const Color(0xFF4EDEA3);
    }
  }

  String get severityLabel {
    switch (severity) {
      case ThreatSeverity.critical:
        return 'CRITICAL P1';
      case ThreatSeverity.high:
        return 'HIGH P2';
      case ThreatSeverity.medium:
        return 'MEDIUM P3';
      case ThreatSeverity.low:
        return 'LOW P4';
      case ThreatSeverity.cleared:
        return 'NORMAL';
    }
  }
}

/// Model for Remote RTU Valve Station Cyber Security Telemetry
class RtuStationCyberNode {
  final String id; // VS-01 to VS-08
  final String name;
  final String chainage;
  final String hardwareModel; // Moxa ioPAC 8600 / SCADAPack 357E
  final String rtuIp;
  final String macAddress;
  UplinkMedium activeUplink;

  // Telemetry metrics
  double satLatencyMs;
  double satSnrDb;
  bool satIpsecActive;
  double cellLatencyMs;
  double cellRsrpDbm;
  bool cellPrivateApnActive;

  // Threat detection engines
  bool imsiCatcherSuspected;
  bool gnssClockDriftAnomaly; // >500ns jump indicating spoofing
  bool arpPoisoningDetected;
  bool dot1xPortLockdown;
  bool cabinetDoorTamperTrip;
  bool dnp3KeyInSync;

  int blockedEventsCount;
  ThreatSeverity overallRisk;

  RtuStationCyberNode({
    required this.id,
    required this.name,
    required this.chainage,
    required this.hardwareModel,
    required this.rtuIp,
    required this.macAddress,
    this.activeUplink = UplinkMedium.vsatSatellite,
    required this.satLatencyMs,
    required this.satSnrDb,
    this.satIpsecActive = true,
    required this.cellLatencyMs,
    required this.cellRsrpDbm,
    this.cellPrivateApnActive = true,
    this.imsiCatcherSuspected = false,
    this.gnssClockDriftAnomaly = false,
    this.arpPoisoningDetected = false,
    this.dot1xPortLockdown = false,
    this.cabinetDoorTamperTrip = false,
    this.dnp3KeyInSync = true,
    required this.blockedEventsCount,
    required this.overallRisk,
  });

  bool get isCompromised =>
      imsiCatcherSuspected ||
      gnssClockDriftAnomaly ||
      arpPoisoningDetected ||
      dot1xPortLockdown ||
      cabinetDoorTamperTrip;
}

/// CERT-In Mandatory Incident Record
class CertInIncident {
  final String incidentId;
  final String title;
  final DateTime detectedAt;
  final DateTime reportingDeadline; // Strict 6-Hour window per Rule 20(5)
  final ThreatSeverity severity;
  final String impactedAsset;
  final String attackVector;
  final String technicalHash;
  final String certInAnnexureCategory;
  bool isAcknowledged;
  bool isDispatchedToCertIn;

  CertInIncident({
    required this.incidentId,
    required this.title,
    required this.detectedAt,
    required this.reportingDeadline,
    required this.severity,
    required this.impactedAsset,
    required this.attackVector,
    required this.technicalHash,
    required this.certInAnnexureCategory,
    this.isAcknowledged = false,
    this.isDispatchedToCertIn = false,
  });

  Duration get remainingReportingTime {
    final now = DateTime.now();
    if (now.isAfter(reportingDeadline)) return Duration.zero;
    return reportingDeadline.difference(now);
  }
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class ScadaCybersecurityScreen extends StatefulWidget {
  const ScadaCybersecurityScreen({super.key});

  @override
  State<ScadaCybersecurityScreen> createState() =>
      _ScadaCybersecurityScreenState();
}

class _ScadaCybersecurityScreenState extends State<ScadaCybersecurityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveTelemetryTimer;
  Timer? _countdownTimer;

  // Selected filters
  IcsProtocol? _selectedProtocolFilter;
  String _searchQuery = '';
  bool _isIslandModeActive = false;
  bool _isDnp3RekeyInProgress = false;
  bool _isDpiEnforceMode = true; // Enforce (Drop) vs Monitor (Alert only)

  // Simulation State
  bool _isSimulationRunning = false;
  String _activeSimScenario = 'IDLE';

  // Live counters
  int _totalPacketsInspected = 1482920;
  int _totalPacketsDropped = 48;
  int _modbusCoilBlocks = 21;
  int _dnp3ChallengesPassed = 18450;
  final int _iec104Anomalies = 9;

  // Active Purdue Zones
  late List<PurdueZoneConfig> _purdueZones;
  late List<ZoneConduit> _conduits;
  late List<RtuStationCyberNode> _rtuStations;
  late List<DpiPacketLog> _packetLogs;
  late List<CertInIncident> _certInIncidents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();

    // Live background packet & telemetry generator
    _liveTelemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      _onLiveTick();
    });

    // 1-second timer for CERT-In 6-hour countdown ticking
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveTelemetryTimer?.cancel();
    _countdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _purdueZones = [
      const PurdueZoneConfig(
        level: PurdueLevel.level0,
        title: 'Process Instrumentation Zone',
        code: 'LEVEL 0',
        description:
            'Air-gapped 4-20mA HART loops, solenoid ESDV dump valves, ultrasonic meters & optical cabinet tamper switches.',
        targetSl: IecSecurityLevel.sl4,
        achievedSl: 3.9,
        primaryAssets: [
          'HART 7 Transmitters',
          'Bettis G-Series Hydraulic ESDV',
          'Daniel Senior Sonic Ultrasonic Meter',
          'Pepperl+Fuchs Galvanic Barriers',
          'Cabinet Optical Tamper Micro-switches'
        ],
        conduitSecurity: 'Galvanically isolated physical wiring, zero IP endpoints',
        firewallPolicy: 'Direct physical interlock, hardware dry contact bypass',
        activeAssetCount: 164,
        blockedAttacks24h: 0,
        isAirgapped: true,
      ),
      const PurdueZoneConfig(
        level: PurdueLevel.level1,
        title: 'Basic Control & RTU Substation',
        code: 'LEVEL 1',
        description:
            'Safety PLCs, Moxa ioPAC 8600 RTUs, Schneider SCADAPack 357E logic solvers, dual-redundant ring switches.',
        targetSl: IecSecurityLevel.sl3,
        achievedSl: 3.5,
        primaryAssets: [
          '8x Moxa ioPAC 8600 Modular RTU',
          '8x Schneider SCADAPack 357E SIL-2',
          'Hirschmann RS20 Managed Switches',
          'IEEE 1588 PTP Grandmaster Clock',
          'FortiGate Rugged 60F Industrial FW'
        ],
        conduitSecurity: 'TLS 1.3 / IPsec DNP3 SAv5 Encrypted Tunnels',
        firewallPolicy: 'Strict whitelist: Only SCADA Master IP & port 20000/502',
        activeAssetCount: 48,
        blockedAttacks24h: 21,
      ),
      const PurdueZoneConfig(
        level: PurdueLevel.level2,
        title: 'Supervisory SCADA & Control Room',
        code: 'LEVEL 2',
        description:
            'Dual-redundant SCADA Master Servers, HMI Operator consoles, Local Operational Historian, EWS with FIDO2 MFA.',
        targetSl: IecSecurityLevel.sl3,
        achievedSl: 3.6,
        primaryAssets: [
          'SCADA Master Alpha (Active)',
          'SCADA Master Bravo (Hot Standby)',
          'AVEVA System Platform HMI',
          'Local FactoryTalk Historian',
          'EWS Engineering Station (Smartcard MFA)'
        ],
        conduitSecurity: 'Data Diode (Owl Cyber Defense) outbound to IDMZ',
        firewallPolicy: 'Micro-segmentation, Zero-Trust lateral containment',
        activeAssetCount: 22,
        blockedAttacks24h: 14,
        hasDataDiode: true,
      ),
      const PurdueZoneConfig(
        level: PurdueLevel.level3,
        title: 'Operations DMZ (IDMZ) & SOC',
        code: 'LEVEL 3',
        description:
            'Central Enterprise OSIsoft PI Historian, Patch Management WSUS, Apache Guacamole PAM Jump Host, Claroty IDS.',
        targetSl: IecSecurityLevel.sl3,
        achievedSl: 3.2,
        primaryAssets: [
          'OSIsoft PI Enterprise Server',
          'WSUS Air-Gap Patch Repository',
          'PAM Jump Host Bastion (MFA RDP/SSH)',
          'Claroty Continuous Threat Detection',
          'Suricata DPI Sensor Engine'
        ],
        conduitSecurity: 'Dual FortiGate Enterprise DMZ with SSL Inspection',
        firewallPolicy: 'Outbound SIEM syslog to SOC, inbound strictly PAM jump',
        activeAssetCount: 31,
        blockedAttacks24h: 38,
      ),
      const PurdueZoneConfig(
        level: PurdueLevel.level4,
        title: 'Enterprise / Corporate WAN',
        code: 'LEVEL 4',
        description:
            'Corporate SAP S/4HANA ERP, MS Exchange, Active Directory Domain, Office IT LAN and external cloud connectors.',
        targetSl: IecSecurityLevel.sl2,
        achievedSl: 2.8,
        primaryAssets: [
          'SAP S/4HANA Oil & Gas ERP',
          'Corporate Active Directory Kerberos',
          'Cloud BI / PowerBI Gateway',
          'Corporate Email & Web Gateway'
        ],
        conduitSecurity: 'IPsec VPN over MPLS WAN with Palo Alto NextGen FW',
        firewallPolicy: 'Complete isolation from OT Level 2/1, no direct route',
        activeAssetCount: 420,
        blockedAttacks24h: 112,
      ),
    ];

    _conduits = [
      const ZoneConduit(
        id: 'C-01',
        name: 'Process Fieldbus to RTU I/O',
        sourceZone: 'Level 0 (Process)',
        targetZone: 'Level 1 (RTUs)',
        encryption: 'Galvanic / HART Protocol FSK (Point-to-Point)',
        firewallHardware: 'Pepperl+Fuchs K-System Intrinsic Safety Isolators',
        throughputKbps: 9.6,
        packetDropCount: 0,
      ),
      const ZoneConduit(
        id: 'C-02',
        name: 'Remote RTU Telemetry Conduit',
        sourceZone: 'Level 1 (RTU Substation)',
        targetZone: 'Level 2 (SCADA Master)',
        encryption: 'TLS 1.3 / IPsec AES-256-GCM (DNP3 SAv5)',
        firewallHardware: 'FortiGate Rugged 60F OT Firewall',
        throughputKbps: 512.0,
        packetDropCount: 21,
      ),
      const ZoneConduit(
        id: 'C-03',
        name: 'SCADA to IDMZ Data Conduit',
        sourceZone: 'Level 2 (Supervisory)',
        targetZone: 'Level 3 (Operations IDMZ)',
        encryption: 'Hardware Optical Diode (Physical 1-Way Beam)',
        firewallHardware: 'Owl Cyber Defense DualDiode OPDS-100D',
        isHardwareDiode: true,
        throughputKbps: 1840.0,
        packetDropCount: 0,
      ),
      const ZoneConduit(
        id: 'C-04',
        name: 'IDMZ to Enterprise WAN Conduit',
        sourceZone: 'Level 3 (IDMZ)',
        targetZone: 'Level 4 (Enterprise)',
        encryption: 'IPsec IKEv2 / Mutual TLS Jump Bastion',
        firewallHardware: 'Palo Alto PA-3410 NextGen HA Pair',
        throughputKbps: 8400.0,
        packetDropCount: 18,
      ),
    ];

    _rtuStations = [
      RtuStationCyberNode(
        id: 'VS-01',
        name: 'Duliajan Dispatch Terminal',
        chainage: 'KP 0+000',
        hardwareModel: 'Moxa ioPAC 8600 Modular',
        rtuIp: '10.24.1.10',
        macAddress: '00:90:E8:22:A1:01',
        activeUplink: UplinkMedium.vsatSatellite,
        satLatencyMs: 564.0,
        satSnrDb: 15.2,
        cellLatencyMs: 44.0,
        cellRsrpDbm: -72.0,
        blockedEventsCount: 2,
        overallRisk: ThreatSeverity.cleared,
      ),
      RtuStationCyberNode(
        id: 'VS-02',
        name: 'Tingrai Sectionalizing',
        chainage: 'KP 14+200',
        hardwareModel: 'Schneider SCADAPack 357E',
        rtuIp: '10.24.1.20',
        macAddress: '00:80:F4:71:B2:02',
        activeUplink: UplinkMedium.vsatSatellite,
        satLatencyMs: 572.0,
        satSnrDb: 14.8,
        cellLatencyMs: 48.0,
        cellRsrpDbm: -76.0,
        blockedEventsCount: 5,
        overallRisk: ThreatSeverity.cleared,
      ),
      RtuStationCyberNode(
        id: 'VS-03',
        name: 'Burhi Dihing River North',
        chainage: 'KP 28+600',
        hardwareModel: 'Moxa ioPAC 8600 Modular',
        rtuIp: '10.24.1.30',
        macAddress: '00:90:E8:22:A1:03',
        activeUplink: UplinkMedium.vsatSatellite,
        satLatencyMs: 588.0,
        satSnrDb: 13.9,
        cellLatencyMs: 52.0,
        cellRsrpDbm: -82.0,
        blockedEventsCount: 14,
        overallRisk: ThreatSeverity.critical, // Active Modbus 0x05 injection target
      ),
      RtuStationCyberNode(
        id: 'VS-04',
        name: 'Burhi Dihing River South',
        chainage: 'KP 30+100',
        hardwareModel: 'Schneider SCADAPack 357E',
        rtuIp: '10.24.1.40',
        macAddress: '00:80:F4:71:B2:04',
        activeUplink: UplinkMedium.cellularPrivateApn,
        satLatencyMs: 590.0,
        satSnrDb: 13.5,
        cellLatencyMs: 49.0,
        cellRsrpDbm: -68.0,
        imsiCatcherSuspected: true, // Cellular MitM anomaly
        blockedEventsCount: 8,
        overallRisk: ThreatSeverity.high,
      ),
      RtuStationCyberNode(
        id: 'VS-05',
        name: 'Moran Junction Station',
        chainage: 'KP 45+800',
        hardwareModel: 'Moxa ioPAC 8600 Modular',
        rtuIp: '10.24.1.50',
        macAddress: '00:90:E8:22:A1:05',
        activeUplink: UplinkMedium.vsatSatellite,
        satLatencyMs: 576.0,
        satSnrDb: 14.9,
        cellLatencyMs: 42.0,
        cellRsrpDbm: -74.0,
        blockedEventsCount: 3,
        overallRisk: ThreatSeverity.cleared,
      ),
      RtuStationCyberNode(
        id: 'VS-06',
        name: 'Sepon Delivery Terminal',
        chainage: 'KP 62+400',
        hardwareModel: 'Schneider SCADAPack 357E',
        rtuIp: '10.24.1.60',
        macAddress: '00:80:F4:71:B2:06',
        activeUplink: UplinkMedium.vsatSatellite,
        satLatencyMs: 580.0,
        satSnrDb: 14.2,
        cellLatencyMs: 45.0,
        cellRsrpDbm: -78.0,
        gnssClockDriftAnomaly: true, // PTP Clock jump > 500ns
        blockedEventsCount: 6,
        overallRisk: ThreatSeverity.medium,
      ),
      RtuStationCyberNode(
        id: 'VS-07',
        name: 'Demow Intermediate Station',
        chainage: 'KP 78+900',
        hardwareModel: 'Moxa ioPAC 8600 Modular',
        rtuIp: '10.24.1.70',
        macAddress: '00:90:E8:22:A1:07',
        activeUplink: UplinkMedium.vsatSatellite,
        satLatencyMs: 569.0,
        satSnrDb: 15.1,
        cellLatencyMs: 41.0,
        cellRsrpDbm: -71.0,
        dot1xPortLockdown: true, // Rogue MAC on local switch
        cabinetDoorTamperTrip: true, // Optical cabinet door trip
        blockedEventsCount: 7,
        overallRisk: ThreatSeverity.high,
      ),
      RtuStationCyberNode(
        id: 'VS-08',
        name: 'Sibsagar Receiving Terminal',
        chainage: 'KP 94+300',
        hardwareModel: 'Schneider SCADAPack 357E',
        rtuIp: '10.24.1.80',
        macAddress: '00:80:F4:71:B2:08',
        activeUplink: UplinkMedium.vsatSatellite,
        satLatencyMs: 574.0,
        satSnrDb: 15.0,
        cellLatencyMs: 40.0,
        cellRsrpDbm: -70.0,
        blockedEventsCount: 3,
        overallRisk: ThreatSeverity.cleared,
      ),
    ];

    _packetLogs = [
      DpiPacketLog(
        id: 'PKT-10941',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        protocol: IcsProtocol.modbusTcp,
        sourceIp: '192.168.104.88',
        sourcePort: 49152,
        destinationIp: '10.24.1.30',
        destinationPort: 502,
        targetStationId: 'VS-03',
        functionCodeOrAsdu: '0x05 (Write Single Coil)',
        description:
            'BLOCKED: Unauthorized Coil Force 0x05 attempting to command ESDV-03 Trip from unwhitelisted IT rogue IP.',
        severity: ThreatSeverity.critical,
        isBlocked: true,
        ruleTriggered: 'SURICATA-ICS-MODBUS-0x05-ESDV-DROP',
        hexPayloadPreview:
            '00 01 00 00 00 06 01 05 00 14 FF 00 [Target Coil 0x0014 = ON]',
        forensicMitigation:
            'Packet quarantined, IP 192.168.104.88 blacklisted on FortiGate perimeter. CERT-In P1 alert generated.',
      ),
      DpiPacketLog(
        id: 'PKT-10938',
        timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
        protocol: IcsProtocol.modbusTcp,
        sourceIp: '10.24.4.15',
        sourcePort: 51200,
        destinationIp: '10.24.1.30',
        destinationPort: 502,
        targetStationId: 'VS-03',
        functionCodeOrAsdu: '0x0F (Force Multiple Coils)',
        description:
            'BLOCKED: Malicious mass coil overwrite 0x0F targeting Solenoid valves SV-01/02/03 simultaneously.',
        severity: ThreatSeverity.critical,
        isBlocked: true,
        ruleTriggered: 'SURICATA-ICS-MODBUS-0x0F-SOLENOID-FORCE',
        hexPayloadPreview:
            '00 02 00 00 00 08 01 0F 00 00 00 08 01 00 [All Coils Force OFF]',
        forensicMitigation:
            'Immediate RST frame injected to tear down TCP connection. Source MAC flagged for switch port shutdown.',
      ),
      DpiPacketLog(
        id: 'PKT-10931',
        timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
        protocol: IcsProtocol.dnp3Sa,
        sourceIp: '10.24.2.10',
        sourcePort: 20000,
        destinationIp: '10.24.1.40',
        destinationPort: 20000,
        targetStationId: 'VS-04',
        functionCodeOrAsdu: 'DNP3 SAv5 (Challenge HMAC-SHA256)',
        description:
            'PASSED: IEEE 1815.1 Secure Authentication challenge-response validated for Mainline Valve status polling.',
        severity: ThreatSeverity.cleared,
        isBlocked: false,
        ruleTriggered: 'DNP3-SAV5-MUTUAL-AUTH-VERIFIED',
        hexPayloadPreview:
            '05 64 12 C4 01 00 04 00 81 80 78 01 02 03 4A 9B 11 [HMAC Valid]',
        forensicMitigation:
            'Session key valid for next 3600 seconds. Aggressive mode enabled.',
      ),
      DpiPacketLog(
        id: 'PKT-10925',
        timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
        protocol: IcsProtocol.iec104,
        sourceIp: '172.16.8.99',
        sourcePort: 2404,
        destinationIp: '10.24.1.60',
        destinationPort: 2404,
        targetStationId: 'VS-06',
        functionCodeOrAsdu: 'ASDU 45 (Single Command C_SC_NA_1)',
        description:
            'ANOMALY ALERT: Spontaneous ASDU 45 Cot=6 (Activation) sequence number mismatch. Potential fuzzing attack.',
        severity: ThreatSeverity.high,
        isBlocked: true,
        ruleTriggered: 'IEC104-COT-UNEXPECTED-SEQUENCE-DROP',
        hexPayloadPreview:
            '68 0E 04 00 02 00 2D 01 06 00 01 00 01 00 00 01 [ASDU 45 Cot=6]',
        forensicMitigation:
            'Connection terminated due to out-of-order sequence counter (APDU Rx: 41, Expected: 12).',
      ),
      DpiPacketLog(
        id: 'PKT-10919',
        timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
        protocol: IcsProtocol.dot1xPort,
        sourceIp: '0.0.0.0',
        sourcePort: 0,
        destinationIp: '10.24.1.70',
        destinationPort: 0,
        targetStationId: 'VS-07',
        functionCodeOrAsdu: '802.1X Port Security Violation',
        description:
            'ROGUE DEVICE: Unauthorized MAC address C8:F7:50:AA:99:11 detected on Switch Port FE-04 in Demow Station cabinet.',
        severity: ThreatSeverity.high,
        isBlocked: true,
        ruleTriggered: 'HIRSCHMANN-MAC-PORT-LOCKDOWN',
        hexPayloadPreview:
            'EAPOL Start Frame from Rogue NIC [Vendor: Realtek Semi]',
        forensicMitigation:
            'Switch port FE-04 disabled automatically. Optical cabinet door trip confirmed intrusion event.',
      ),
      DpiPacketLog(
        id: 'PKT-10910',
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
        protocol: IcsProtocol.arpNetwork,
        sourceIp: '10.24.1.44',
        sourcePort: 0,
        destinationIp: '10.24.1.255',
        destinationPort: 0,
        targetStationId: 'VS-04',
        functionCodeOrAsdu: 'Gratuitous ARP Broadcast (MitM)',
        description:
            'MitM SUSPECT: Gratuitous ARP claiming Gateway IP 10.24.1.1 from duplicate MAC. Cellular APN proxy spoof attempt.',
        severity: ThreatSeverity.high,
        isBlocked: true,
        ruleTriggered: 'DAI-DYNAMIC-ARP-INSPECTION-DROP',
        hexPayloadPreview:
            'ARP Who-has 10.24.1.1 Tell 10.24.1.44 [MAC Conflict]',
        forensicMitigation:
            'Dynamic ARP Inspection dropped 42 poisoned frames. RTU-VS04 switched to primary VSAT satellite link.',
      ),
    ];

    // Mandatory CERT-In Incident (6-Hour reporting deadline)
    _certInIncidents = [
      CertInIncident(
        incidentId: 'INC-2026-OT-088',
        title: 'Unauthorized Modbus 0x05 Coil Force Targeting VS-03 Mainline ESDV',
        detectedAt: DateTime.now().subtract(const Duration(minutes: 24)),
        reportingDeadline:
            DateTime.now().add(const Duration(hours: 5, minutes: 36)),
        severity: ThreatSeverity.critical,
        impactedAsset: 'VS-03 Burhi Dihing North RTU (10.24.1.30:502)',
        attackVector:
            'Modbus TCP Function 0x05 injection via rogue pivot on SCADA DMZ bridge',
        technicalHash: 'sha256:7f9a2e88b9015c71d0e4a6bf9912c01994a32e18fa4310',
        certInAnnexureCategory:
            'Para 20(5)(i) - Unauthorized access to Critical Control Systems',
        isAcknowledged: true,
        isDispatchedToCertIn: false,
      ),
      CertInIncident(
        incidentId: 'INC-2026-OT-084',
        title: 'Cellular IMSI Catcher Cipher Downgrade & Cell Tower Spoof on VS-04',
        detectedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 12)),
        reportingDeadline:
            DateTime.now().add(const Duration(hours: 4, minutes: 48)),
        severity: ThreatSeverity.high,
        impactedAsset: 'VS-04 Burhi Dihing South 4G Private APN Modem',
        attackVector:
            'Rogue GSM/LTE Base Station emitting fake MCC 404 / MNC 45 with Null A5/0 Cipher',
        technicalHash: 'sha256:3a1b8c22f009d177e5c92849ab2170399ea118c7bc4539',
        certInAnnexureCategory:
            'Para 20(5)(iv) - Man-in-the-middle attacks on critical infrastructure telemetry',
        isAcknowledged: true,
        isDispatchedToCertIn: true,
      ),
    ];
  }

  void _onLiveTick() {
    setState(() {
      _totalPacketsInspected += math.Random().nextInt(40) + 15;
      _dnp3ChallengesPassed += math.Random().nextInt(3) + 1;

      // Small jitter on satellite and cellular telemetry
      for (var rtu in _rtuStations) {
        rtu.satLatencyMs = 560.0 + math.Random().nextDouble() * 30.0;
        rtu.cellLatencyMs = 40.0 + math.Random().nextDouble() * 15.0;
      }
    });
  }

  // ============================================================================
  // SIMULATION ACTIONS
  // ============================================================================

  void _simulateModbusCoilAttack() {
    setState(() {
      _isSimulationRunning = true;
      _activeSimScenario = 'Modbus 0x05 Coil Force Attack (ESDV-03)';
      _totalPacketsDropped += 1;
      _modbusCoilBlocks += 1;

      final newLog = DpiPacketLog(
        id: 'PKT-${11000 + math.Random().nextInt(900)}',
        timestamp: DateTime.now(),
        protocol: IcsProtocol.modbusTcp,
        sourceIp: '192.168.105.${math.Random().nextInt(200) + 10}',
        sourcePort: 54100 + math.Random().nextInt(1000),
        destinationIp: '10.24.1.30',
        destinationPort: 502,
        targetStationId: 'VS-03',
        functionCodeOrAsdu: '0x05 (Write Single Coil - TRIP)',
        description:
            'INTERCEPTED: Malicious Modbus 0x05 force coil command targeting ESDV-03. Dropped by DPI engine.',
        severity: ThreatSeverity.critical,
        isBlocked: true,
        ruleTriggered: 'SURICATA-ICS-MODBUS-0x05-ESDV-DROP',
        hexPayloadPreview:
            '00 12 00 00 00 06 01 05 00 14 FF 00 [ESDV-03 EMERGENCY TRIP INJECT]',
        forensicMitigation:
            'DPI Engine injected TCP RST and dropped packet at FortiGate Rugged 60F. Zero mechanical displacement.',
      );
      _packetLogs.insert(0, newLog);
    });

    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2E5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        content: Row(
          children: const [
            Icon(Icons.gpp_bad_rounded, color: Color(0xFFFF5252), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'DPI THREAT BLOCKED: Unauthorized Modbus 0x05 (Coil Force) targeting ESDV-03 intercepted & dropped!',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _simulateImsiCatcherAttack() {
    setState(() {
      _isSimulationRunning = true;
      _activeSimScenario = 'Cellular IMSI Catcher / Fake Base Station';
      final vs04 = _rtuStations.firstWhere((r) => r.id == 'VS-04');
      vs04.imsiCatcherSuspected = true;
      vs04.overallRisk = ThreatSeverity.critical;
      vs04.activeUplink = UplinkMedium.vsatSatellite; // Automatic failover

      final newLog = DpiPacketLog(
        id: 'PKT-${11000 + math.Random().nextInt(900)}',
        timestamp: DateTime.now(),
        protocol: IcsProtocol.arpNetwork,
        sourceIp: 'Cell-Tower-LAC-8801',
        sourcePort: 0,
        destinationIp: '10.24.1.40',
        destinationPort: 0,
        targetStationId: 'VS-04',
        functionCodeOrAsdu: 'IMSI Catcher RF Cipher Downgrade',
        description:
            'MitM ALERT: Rogue GSM BTS detected broadcasting A5/0 null cipher. RTU modem automatically severed cellular and engaged VSAT satellite.',
        severity: ThreatSeverity.critical,
        isBlocked: true,
        ruleTriggered: 'RF-IMSI-CATCHER-CIPHER-DOWNGRADE-FAILOVER',
        hexPayloadPreview:
            'RRC Connection Reject / Forced 2G Downgrade [Fake MNC: 404-99]',
        forensicMitigation:
            'Air-interface severed. Primary VSAT ISRO GSAT-11 transponder engaged with IPsec AES-256-GCM.',
      );
      _packetLogs.insert(0, newLog);
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2E5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFFB95F), width: 1.5),
        ),
        content: Row(
          children: const [
            Icon(Icons.cell_tower_rounded, color: Color(0xFFFFB95F), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'MitM CELLULAR DEFENSE: Rogue IMSI Catcher detected on VS-04. Automatically failed over to encrypted VSAT satellite link!',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _simulateCabinetTamper() {
    setState(() {
      _isSimulationRunning = true;
      _activeSimScenario = 'Substation Physical Tamper & Rogue 802.1X';
      final vs07 = _rtuStations.firstWhere((r) => r.id == 'VS-07');
      vs07.cabinetDoorTamperTrip = true;
      vs07.dot1xPortLockdown = true;
      vs07.overallRisk = ThreatSeverity.high;

      final newLog = DpiPacketLog(
        id: 'PKT-${11000 + math.Random().nextInt(900)}',
        timestamp: DateTime.now(),
        protocol: IcsProtocol.dot1xPort,
        sourceIp: 'MAC C8:F7:50:11:22:33',
        sourcePort: 0,
        destinationIp: '10.24.1.70',
        destinationPort: 0,
        targetStationId: 'VS-07',
        functionCodeOrAsdu: '802.1X Port Security Shutdown',
        description:
            'TAMPER TRIP: Optical cabinet door interlock opened. Unauthorized Ethernet cable attached to port FE-02. Port instantly killed.',
        severity: ThreatSeverity.high,
        isBlocked: true,
        ruleTriggered: 'PHYSICAL-TAMPER-802.1X-HARDWARE-LOCK',
        hexPayloadPreview:
            'Tamper Sensor Optical State: BROKEN (0V) -> Port FE-02 ADMIN_DOWN',
        forensicMitigation:
            'Physical tamper latch engaged. Field security dispatched to Demow station KP 78+900.',
      );
      _packetLogs.insert(0, newLog);
    });

    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2E5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        content: Row(
          children: const [
            Icon(Icons.door_sliding_rounded,
                color: Color(0xFFFF5252), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'PHYSICAL TAMPER: Optical door trip at VS-07 Demow! Substation switch 802.1X port locked down.',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _triggerEmergencyOtIsland() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111C38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF5252), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'EMERGENCY OT QUARANTINE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF1F5F9),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'This action will instantly sever all conduits between Purdue Level 3 (Operations IDMZ) and Level 2 (SCADA Master).',
              style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
            ),
            SizedBox(height: 12),
            Text(
              '• RTUs (VS-01 to VS-08) and SCADA Master will operate in autonomous deterministic island mode.\n• All external WAN and ERP telemetry connections will be forcefully terminated.\n• Physical hardwired Level 0 safety ESDV logic remains fully operational.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isIslandModeActive = !_isIslandModeActive;
              });
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF162347),
                  content: Text(
                    _isIslandModeActive
                        ? 'OT ISLAND ENGAGED: Conduits severed. SCADA & RTUs in autonomous air-gapped protection.'
                        : 'OT ISLAND RELEASED: Normal Purdue conduits restored.',
                    style: TextStyle(
                      color: _isIslandModeActive
                          ? const Color(0xFFFF5252)
                          : const Color(0xFF4EDEA3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
            icon: Icon(
              _isIslandModeActive
                  ? Icons.lock_open_rounded
                  : Icons.shield_rounded,
              size: 18,
            ),
            label: Text(
              _isIslandModeActive
                  ? 'RESTORE CONDUITS'
                  : 'ENGAGE OT AIR-GAP ISLAND',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerDnp3KeyRotation() {
    setState(() => _isDnp3RekeyInProgress = true);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isDnp3RekeyInProgress = false;
        _dnp3ChallengesPassed += 8;
        for (var r in _rtuStations) {
          r.dnp3KeyInSync = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF162347),
          content: Text(
            'DNP3 SAv5 KEYS ROTATED: 8/8 RTU outstations successfully negotiated fresh HMAC-SHA256 session keys.',
            style: TextStyle(
              color: Color(0xFF4EDEA3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  // ============================================================================
  // BUILD SCREEN
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildThreatStatusBanner(),
          if (_isSimulationRunning) _buildActiveSimulationBanner(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPurdueZonesTab(),
                _buildProtocolDpiTab(),
                _buildRtuLinksTab(),
                _buildCertInComplianceTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomStatusBar(),
    );
  }

  // ============================================================================
  // APP BAR & HEADER
  // ============================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0284C7).withValues(alpha: 0.3),
                  const Color(0xFF00E5FF).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'SCADA Cyber-Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Text(
                        'IEC 62443 SL-3',
                        style: TextStyle(
                          color: Color(0xFF4EDEA3),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Critical National Infrastructure (CNI) OT Defense Shield',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Simulate Threat Scenarios',
          icon: const Icon(Icons.science_outlined, color: Color(0xFFFFB95F)),
          onPressed: _showSimulationDialog,
        ),
        IconButton(
          tooltip: 'Emergency OT Quarantine',
          icon: Icon(
            _isIslandModeActive
                ? Icons.lock_rounded
                : Icons.electrical_services_rounded,
            color: _isIslandModeActive
                ? const Color(0xFFFF5252)
                : const Color(0xFF94A3B8),
          ),
          onPressed: _triggerEmergencyOtIsland,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================================
  // THREAT STATUS BANNER
  // ============================================================================

  Widget _buildThreatStatusBanner() {
    final hasActiveCritical = _packetLogs
        .any((p) => p.severity == ThreatSeverity.critical && p.isBlocked);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isIslandModeActive
            ? const Color(0xFF3F1316)
            : const Color(0xFF111C38),
        border: Border(
          bottom: BorderSide(
            color: _isIslandModeActive
                ? const Color(0xFFFF5252)
                : AppTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Flashing Indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isIslandModeActive
                  ? const Color(0xFFFF5252)
                  : (hasActiveCritical
                      ? const Color(0xFFFFB95F)
                      : const Color(0xFF10B981)),
              boxShadow: [
                BoxShadow(
                  color: (_isIslandModeActive
                          ? const Color(0xFFFF5252)
                          : (hasActiveCritical
                              ? const Color(0xFFFFB95F)
                              : const Color(0xFF10B981)))
                      .withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _isIslandModeActive
                          ? 'AIR-GAP OT ISLAND MODE ACTIVE'
                          : 'THREATCON: ELEVATED (DEFCON 2)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _isIslandModeActive
                            ? const Color(0xFFFFB4AB)
                            : const Color(0xFFFFB95F),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• CERT-In 6h Clock Active',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isIslandModeActive
                      ? 'Level 3/2 conduits disconnected. Zero remote lateral ingress possible.'
                      : 'DPI Engine filtering Modbus TCP (0x05 blocked), DNP3 SAv5 active on 8 RTUs.',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              side: BorderSide(
                color: _isIslandModeActive
                    ? const Color(0xFFFF5252)
                    : const Color(0xFF38BDF8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => _tabController.animateTo(3),
            child: Text(
              '6h Clock: ${_certInIncidents.first.remainingReportingTime.inHours}h ${_certInIncidents.first.remainingReportingTime.inMinutes % 60}m',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _isIslandModeActive
                    ? const Color(0xFFFF5252)
                    : const Color(0xFF38BDF8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSimulationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: const Color(0xFF1E2E5C),
      child: Row(
        children: [
          const Icon(Icons.science, size: 16, color: Color(0xFFFFB95F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ACTIVE SIMULATION: $_activeSimScenario',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFB95F),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              setState(() {
                _isSimulationRunning = false;
                _activeSimScenario = 'IDLE';
              });
            },
            child: const Text(
              'CLEAR SIM',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB BAR
  // ============================================================================

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 2.5,
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(
            icon: Icon(Icons.layers_rounded, size: 16),
            text: 'Zones & Conduits',
          ),
          Tab(
            icon: Icon(Icons.filter_alt_rounded, size: 16),
            text: 'Protocol DPI & Threat',
          ),
          Tab(
            icon: Icon(Icons.satellite_alt_rounded, size: 16),
            text: 'Remote RTUs & MitM',
          ),
          Tab(
            icon: Icon(Icons.policy_rounded, size: 16),
            text: 'CERT-In Compliance',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: PURDUE ZONES & CONDUITS (IEC 62443-3-2)
  // ============================================================================

  Widget _buildPurdueZonesTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildPurdueSummaryCard(),
        const SizedBox(height: 14),
        const Text(
          'PURDUE OT/ICS SEGMENTATION (LEVEL 0 TO 4)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ..._purdueZones.map((zone) => _buildZoneCard(zone)),
        const SizedBox(height: 16),
        const Text(
          'SECURED INTER-ZONE CONDUITS & DATA DIODES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ..._conduits.map((conduit) => _buildConduitCard(conduit)),
      ],
    );
  }

  Widget _buildPurdueSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded,
                  color: Color(0xFF38BDF8), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'IEC 62443-3-2 Zone & Conduit Architecture',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0284C7)),
                ),
                child: const Text(
                  'CNI COMPLIANT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Critical National Infrastructure boundary for Oil India pipeline control systems. Strict segmentation isolates field RTU networks from corporate IT networks via an Industrial DMZ and a physical one-way optical hardware data diode.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryPill(
                label: 'Overall SL-A',
                value: 'SL-3.6',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _buildSummaryPill(
                label: 'Conduits Monitored',
                value: '4/4 Active',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _buildSummaryPill(
                label: 'Hardware Diode',
                value: 'Owl Diode ON',
                color: const Color(0xFFFFB95F),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(PurdueZoneConfig zone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: zone.isAirgapped
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : AppTheme.border,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding:
            const EdgeInsets.only(left: 14, right: 14, bottom: 14, top: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: zone.slColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: zone.slColor.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            zone.code.replaceAll('LEVEL ', 'L'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: zone.slColor,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                zone.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (zone.isAirgapped)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AIR-GAPPED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4EDEA3),
                  ),
                ),
              ),
            if (zone.hasDataDiode)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB95F).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DATA DIODE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFB95F),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                'Target: ${zone.targetSlLabel}  |  Achieved: SL-${zone.achievedSl.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: zone.slColor,
                ),
              ),
              const Spacer(),
              Text(
                '${zone.activeAssetCount} Assets',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(color: AppTheme.border, height: 16),
          Text(
            zone.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          _buildZoneDetailRow(
              'Conduit Protection', zone.conduitSecurity, Icons.cable_rounded),
          const SizedBox(height: 6),
          _buildZoneDetailRow(
              'Firewall Policy', zone.firewallPolicy, Icons.shield_rounded),
          const SizedBox(height: 10),
          const Text(
            'Primary Certified OT Assets:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: zone.primaryAssets
                .map(
                  (asset) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.border.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      asset,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Blocked attacks in 24h: ${zone.blockedAttacks24h}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: zone.blockedAttacks24h > 0
                      ? const Color(0xFFFFB95F)
                      : const Color(0xFF4EDEA3),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showZoneDrilldown(zone),
                icon: const Icon(Icons.arrow_forward,
                    size: 14, color: Color(0xFF38BDF8)),
                label: const Text(
                  'Zone Assets & Rules',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConduitCard(ZoneConduit conduit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: conduit.isHardwareDiode
              ? const Color(0xFFFFB95F).withValues(alpha: 0.6)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  conduit.id,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conduit.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (conduit.isHardwareDiode)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB95F).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '1-WAY HARDWARE DIODE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFB95F),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${conduit.sourceZone} ➔ ${conduit.targetZone}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
              Text(
                '${conduit.throughputKbps.toStringAsFixed(1)} kbps',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Security: ${conduit.encryption}  |  Appliance: ${conduit.firewallHardware}',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: PROTOCOL DPI & THREAT MITIGATION (MODBUS / DNP3 / IEC-104)
  // ============================================================================

  Widget _buildProtocolDpiTab() {
    final filteredLogs = _packetLogs.where((log) {
      if (_selectedProtocolFilter != null &&
          log.protocol != _selectedProtocolFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return log.description.toLowerCase().contains(query) ||
            log.targetStationId.toLowerCase().contains(query) ||
            log.functionCodeOrAsdu.toLowerCase().contains(query) ||
            log.sourceIp.contains(query);
      }
      return true;
    }).toList();

    return Column(
      children: [
        _buildDpiStatRow(),
        _buildDpiThroughputChart(),
        _buildModbusCoilRuleBanner(),
        _buildDpiFilterBar(),
        Expanded(
          child: filteredLogs.isEmpty
              ? _buildEmptyLogsView()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) =>
                      _buildPacketLogTile(filteredLogs[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildDpiStatRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppTheme.surfaceCard,
      child: Row(
        children: [
          _buildDpiStatItem(
            label: 'Packets Inspected',
            value: NumberFormat('#,###').format(_totalPacketsInspected),
            color: const Color(0xFF38BDF8),
          ),
          _buildDpiStatItem(
            label: 'Malicious Dropped',
            value: '$_totalPacketsDropped Blocked',
            color: const Color(0xFFFF5252),
          ),
          _buildDpiStatItem(
            label: 'Modbus 0x05',
            value: '$_modbusCoilBlocks Coils',
            color: const Color(0xFFFFB95F),
          ),
          _buildDpiStatItem(
            label: 'DNP3 SAv5',
            value: NumberFormat('#,###').format(_dnp3ChallengesPassed),
            color: const Color(0xFF10B981),
          ),
          _buildDpiStatItem(
            label: 'IEC-104 Alerts',
            value: '$_iec104Anomalies Quarantined',
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildDpiThroughputChart() {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '24H PACKET INSPECTION & BLOCKED ATTACKS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Cyan: Throughput (kpps)  |  Red: Blocked Threats',
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 110),
                      FlSpot(4, 125),
                      FlSpot(8, 140),
                      FlSpot(12, 160),
                      FlSpot(16, 145),
                      FlSpot(20, 130),
                      FlSpot(24, 150),
                    ],
                    isCurved: true,
                    color: const Color(0xFF00E5FF),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(4, 1),
                      FlSpot(8, 5),
                      FlSpot(12, 14),
                      FlSpot(16, 8),
                      FlSpot(20, 3),
                      FlSpot(24, 6),
                    ],
                    isCurved: true,
                    color: const Color(0xFFFF5252),
                    barWidth: 1.8,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDpiStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModbusCoilRuleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162347),
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_update_warning_rounded,
              color: Color(0xFFFFB95F), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Modbus TCP Function Code Enforcement Active',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF1F5F9),
                  ),
                ),
                Text(
                  'Whitelisted: 0x01/0x02/0x03/0x04 | FORBIDDEN & BLOCKED: 0x05 (Coil Force) & 0x0F (Multiple Force)',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDpiEnforceMode,
            activeThumbColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.4),
            onChanged: (val) {
              setState(() => _isDpiEnforceMode = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isDpiEnforceMode
                        ? 'DPI MODE: STRICT ENFORCE (All unauthorized Modbus 0x05/0x0F commands dropped)'
                        : 'DPI MODE: MONITOR ONLY (Audit logs generated, packets permitted)',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDpiFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search IP, RTU, Function Code, Rule...',
                      hintStyle:
                          const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: AppTheme.textMuted),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: Color(0xFF0284C7)),
                ),
                onPressed: _simulateModbusCoilAttack,
                icon: const Icon(Icons.bolt,
                    size: 14, color: Color(0xFFFF5252)),
                label: const Text(
                  'Test 0x05 Force',
                  style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildProtocolFilterChip(null, 'ALL PROTOCOLS'),
                const SizedBox(width: 6),
                _buildProtocolFilterChip(
                    IcsProtocol.modbusTcp, 'MODBUS TCP (0x05/0x0F)'),
                const SizedBox(width: 6),
                _buildProtocolFilterChip(IcsProtocol.dnp3Sa, 'DNP3 SAv5'),
                const SizedBox(width: 6),
                _buildProtocolFilterChip(IcsProtocol.iec104, 'IEC 60870-5-104'),
                const SizedBox(width: 6),
                _buildProtocolFilterChip(
                    IcsProtocol.arpNetwork, 'ARP & MitM'),
                const SizedBox(width: 6),
                _buildProtocolFilterChip(
                    IcsProtocol.dot1xPort, '802.1X Port Tamper'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolFilterChip(IcsProtocol? proto, String label) {
    final isSelected = _selectedProtocolFilter == proto;
    return GestureDetector(
      onTap: () => setState(() => _selectedProtocolFilter = proto),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7)
              : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPacketLogTile(DpiPacketLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: log.isBlocked
              ? log.severityColor.withValues(alpha: 0.5)
              : AppTheme.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showPacketDissectorModal(log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: log.severityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: log.severityColor.withValues(alpha: 0.8)),
                    ),
                    child: Text(
                      log.severityLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: log.severityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.targetStationId,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm:ss').format(log.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log.description,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Src: ${log.sourceIp}:${log.sourcePort} ➔ Dst: ${log.destinationIp}:${log.destinationPort}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: log.isBlocked
                          ? const Color(0xFFFF5252).withValues(alpha: 0.2)
                          : const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.isBlocked ? 'ACTION: QUARANTINE_DROP' : 'ACTION: FORWARD',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: log.isBlocked
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF4EDEA3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1326),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Payload: ${log.hexPayloadPreview}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF38BDF8),
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLogsView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 40),
          SizedBox(height: 12),
          Text(
            'No matching DPI packets found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'All SCADA conduits clear of matching threat signatures.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: REMOTE RTU LINKS & MITM DEFENSE (SATELLITE & CELLULAR)
  // ============================================================================

  Widget _buildRtuLinksTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildMitmOverviewBanner(),
        const SizedBox(height: 14),
        const Text(
          'VALVE STATION SATELLITE / CELLULAR RTU NODES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ..._rtuStations.map((rtu) => _buildRtuNodeCard(rtu)),
      ],
    );
  }

  Widget _buildMitmOverviewBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.satellite_alt_rounded,
                  color: Color(0xFF00E5FF), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Remote Link Perimeter & MitM Detection Engine',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cell_tower,
                    color: Color(0xFFFFB95F), size: 20),
                tooltip: 'Simulate Cellular MitM / IMSI Catcher',
                onPressed: _simulateImsiCatcherAttack,
              ),
              IconButton(
                icon: const Icon(Icons.door_sliding_outlined,
                    color: Color(0xFFFF5252), size: 20),
                tooltip: 'Simulate Cabinet Optical Tamper',
                onPressed: _simulateCabinetTamper,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Valve stations VS-01 through VS-08 traverse remote Upper Assam terrain via dual redundant uplinks: Primary ISRO GSAT-11 VSAT Satellite (Ku-band SCPC, IPsec encrypted) and Secondary 4G/5G Private APN. Active heuristics detect Rogue Base Stations (IMSI Catchers), GNSS spoofing (>500ns PTP drift), ARP poisoning, and cabinet optical tamper.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryPill(
                label: 'Sat Links (ISRO GSAT)',
                value: '8/8 Online',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _buildSummaryPill(
                label: 'Private 4G APN',
                value: '7 Online, 1 MitM',
                color: const Color(0xFFFFB95F),
              ),
              const SizedBox(width: 8),
              _buildSummaryPill(
                label: 'DNP3 SAv5 Rekey',
                value: _isDnp3RekeyInProgress ? 'SYNCING...' : '8/8 Keys OK',
                color: const Color(0xFF0284C7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRtuNodeCard(RtuStationCyberNode rtu) {
    Color statusColor;
    String statusText;
    if (rtu.overallRisk == ThreatSeverity.critical) {
      statusColor = const Color(0xFFFF5252);
      statusText = 'CRITICAL MITM / COIL THREAT';
    } else if (rtu.overallRisk == ThreatSeverity.high) {
      statusColor = const Color(0xFFFF7043);
      statusText = 'HIGH RISK (TAMPER / IMSI)';
    } else if (rtu.overallRisk == ThreatSeverity.medium) {
      statusColor = const Color(0xFFFFB95F);
      statusText = 'CLOCK DRIFT ANOMALY';
    } else {
      statusColor = const Color(0xFF10B981);
      statusText = 'HARDENED & SECURE';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: rtu.isCompromised
              ? statusColor.withValues(alpha: 0.6)
              : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF0284C7)),
                  ),
                  child: Text(
                    rtu.id,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rtu.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${rtu.chainage} • ${rtu.hardwareModel}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.border, height: 16),
            // Telemetry Links
            Row(
              children: [
                Expanded(
                  child: _buildUplinkStatusBox(
                    name: 'VSAT Satellite',
                    active: rtu.activeUplink == UplinkMedium.vsatSatellite,
                    metric:
                        '${rtu.satLatencyMs.toStringAsFixed(0)}ms  |  SNR ${rtu.satSnrDb.toStringAsFixed(1)}dB',
                    subtext: 'IPsec AES-256-GCM',
                    icon: Icons.satellite_alt_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildUplinkStatusBox(
                    name: '4G Private APN',
                    active: rtu.activeUplink == UplinkMedium.cellularPrivateApn,
                    metric:
                        '${rtu.cellLatencyMs.toStringAsFixed(0)}ms  |  RSRP ${rtu.cellRsrpDbm.toStringAsFixed(0)}dBm',
                    subtext: rtu.imsiCatcherSuspected
                        ? 'IMSI Catcher Warning'
                        : 'Airtel IoT Private',
                    icon: Icons.cell_tower_rounded,
                    isWarning: rtu.imsiCatcherSuspected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Active Defense Vectors
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildVectorChip(
                  label: 'IMSI Catcher',
                  state: !rtu.imsiCatcherSuspected,
                  failText: 'Rogue Tower Detected',
                ),
                _buildVectorChip(
                  label: 'GNSS PTP Clock',
                  state: !rtu.gnssClockDriftAnomaly,
                  failText: 'Clock Spoofing (>500ns)',
                ),
                _buildVectorChip(
                  label: 'ARP Integrity',
                  state: !rtu.arpPoisoningDetected,
                  failText: 'ARP Poisoned',
                ),
                _buildVectorChip(
                  label: '802.1X Port Guard',
                  state: !rtu.dot1xPortLockdown,
                  failText: 'Port Locked / Rogue MAC',
                ),
                _buildVectorChip(
                  label: 'Cabinet Optical Tamper',
                  state: !rtu.cabinetDoorTamperTrip,
                  failText: 'DOOR INTRUSION',
                ),
                _buildVectorChip(
                  label: 'DNP3 SAv5 Key',
                  state: rtu.dnp3KeyInSync,
                  failText: 'Key Expired',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RTU IP: ${rtu.rtuIp}  |  MAC: ${rtu.macAddress}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppTheme.textMuted,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _toggleUplink(rtu),
                      child: Text(
                        rtu.activeUplink == UplinkMedium.vsatSatellite
                            ? 'Switch to 4G'
                            : 'Force VSAT Link',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF38BDF8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: const Color(0xFF1E2E5C),
                      ),
                      onPressed: () => _showRtuControlSheet(rtu),
                      child: const Text('Isolate / Reset',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUplinkStatusBox({
    required String name,
    required bool active,
    required String metric,
    required String subtext,
    required IconData icon,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: active
            ? (isWarning
                ? const Color(0xFFFFB95F).withValues(alpha: 0.15)
                : const Color(0xFF0284C7).withValues(alpha: 0.15))
            : AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? (isWarning
                  ? const Color(0xFFFFB95F)
                  : const Color(0xFF38BDF8))
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 13,
                  color: active
                      ? (isWarning
                          ? const Color(0xFFFFB95F)
                          : const Color(0xFF38BDF8))
                      : AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? AppTheme.textPrimary : AppTheme.textMuted,
                  ),
                ),
              ),
              if (active)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isWarning
                        ? const Color(0xFFFFB95F).withValues(alpha: 0.2)
                        : const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    isWarning ? 'ALERT' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: isWarning
                          ? const Color(0xFFFFB95F)
                          : const Color(0xFF4EDEA3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            metric,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9.5,
              color: isWarning ? const Color(0xFFFF7043) : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorChip({
    required String label,
    required bool state,
    required String failText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: state
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : const Color(0xFFFF5252).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: state
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFFF5252),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state ? Icons.check_circle_outline : Icons.warning_rounded,
            size: 11,
            color: state ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
          ),
          const SizedBox(width: 4),
          Text(
            state ? '$label: SAFE' : failText,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: state ? const Color(0xFF4EDEA3) : const Color(0xFFFF5252),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleUplink(RtuStationCyberNode rtu) {
    setState(() {
      rtu.activeUplink = rtu.activeUplink == UplinkMedium.vsatSatellite
          ? UplinkMedium.cellularPrivateApn
          : UplinkMedium.vsatSatellite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${rtu.id} (${rtu.name}) telemetry forced to ${rtu.activeUplink == UplinkMedium.vsatSatellite ? 'VSAT ISRO Satellite' : '4G Private APN'}',
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 4: CERT-IN COMPLIANCE & INCIDENT WORKBENCH
  // ============================================================================

  Widget _buildCertInComplianceTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildCertInMandateHeader(),
        const SizedBox(height: 14),
        const Text(
          'CERT-IN 6-HOUR MANDATORY NOTIFICATION WORKBENCH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ..._certInIncidents.map((inc) => _buildCertInIncidentCard(inc)),
        const SizedBox(height: 16),
        _buildIec62443Scorecard(),
        const SizedBox(height: 16),
        _buildEmergencyPlaybooksCard(),
      ],
    );
  }

  Widget _buildCertInMandateHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.policy_rounded,
                    color: Color(0xFF38BDF8), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CERT-In Cyber Security Directions (Rule 20(5))',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Information Technology (The Indian Computer Emergency Response Team) Rules',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Mandatory notification requirement: Any cyber security incident involving Critical National Infrastructure (CNI) SCADA/OT networks MUST be reported to CERT-In within six (6) hours of noticing or being brought to notice. Real-time logging of all OT telemetry and perimeter firewalls maintained for 180 consecutive days per statutory directives.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertInIncidentCard(CertInIncident inc) {
    final remaining = inc.remainingReportingTime;
    final isUrgent = remaining.inHours < 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: inc.isDispatchedToCertIn
              ? const Color(0xFF10B981)
              : (isUrgent ? const Color(0xFFFF5252) : const Color(0xFFFFB95F)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFF5252)),
                  ),
                  child: Text(
                    inc.incidentId,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF5252),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inc.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1326),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: Color(0xFFFFB95F)),
                  const SizedBox(width: 6),
                  const Text(
                    '6-Hour Reporting Window Remaining: ',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${remaining.inHours}h ${remaining.inMinutes % 60}m ${remaining.inSeconds % 60}s',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isUrgent
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFFFB95F),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: inc.isDispatchedToCertIn
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFFFF7043).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      inc.isDispatchedToCertIn
                          ? 'DISPATCHED TO CERT-IN'
                          : 'PENDING TRANSMISSION',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: inc.isDispatchedToCertIn
                            ? const Color(0xFF4EDEA3)
                            : const Color(0xFFFF7043),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impacted Asset: ${inc.impactedAsset}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
            ),
            Text(
              'Attack Vector: ${inc.attackVector}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            Text(
              'Statutory Category: ${inc.certInAnnexureCategory}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hash: ${inc.technicalHash.substring(0, 24)}...',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontFamily: 'monospace',
                    color: AppTheme.textMuted,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inc.isDispatchedToCertIn
                        ? const Color(0xFF162347)
                        : const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => _showCertInReportDialog(inc),
                  icon: Icon(
                    inc.isDispatchedToCertIn
                        ? Icons.receipt_long
                        : Icons.send_rounded,
                    size: 14,
                  ),
                  label: Text(
                    inc.isDispatchedToCertIn
                        ? 'View CERT-In Form'
                        : 'Generate CERT-In Notice',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIec62443Scorecard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.fact_check_outlined,
                  color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'IEC 62443 Foundational Requirements (FR 1 to FR 7)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildScorecardItem('FR 1: Identification & Authentication Control',
              3.5, 'FIDO2 MFA + Smartcard EWS'),
          _buildScorecardItem('FR 2: Use Control & Least Privilege', 3.3,
              'Role-based SCADA operator profiles'),
          _buildScorecardItem('FR 3: System Integrity & Firmware Signatures',
              3.8, 'Moxa/SCADAPack signed firmware'),
          _buildScorecardItem('FR 4: Data Confidentiality & Encryption', 3.7,
              'TLS 1.3 / IPsec AES-256 links'),
          _buildScorecardItem('FR 5: Restricted Data Flow (Conduits)', 4.0,
              'Owl Hardware Diode + Micro-seg'),
          _buildScorecardItem('FR 6: Timely Response to Events (SOC)', 3.6,
              'Continuous Suricata & DPI logging'),
          _buildScorecardItem('FR 7: Resource Availability & Redundancy', 3.9,
              'Dual SCADA Masters & Dual Uplinks'),
        ],
      ),
    );
  }

  Widget _buildScorecardItem(String requirement, double score, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  requirement,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                'SL-$score / 4.0',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: score / 4.0,
            backgroundColor: AppTheme.surfaceContainerHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyPlaybooksCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CRITICAL INFRASTRUCTURE DEFENSE PLAYBOOKS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          _buildPlaybookTile(
            title: 'Playbook 01: Emergency OT Air-Gap Isolation',
            description:
                'Instantly sever Level 3 to Level 2 conduits. SCADA Master & RTUs operate in autonomous standalone safety loop.',
            actionLabel: _isIslandModeActive ? 'RESTORE CONDUITS' : 'ENGAGE AIR-GAP',
            actionColor: const Color(0xFFFF5252),
            onTap: _triggerEmergencyOtIsland,
          ),
          const SizedBox(height: 8),
          _buildPlaybookTile(
            title: 'Playbook 02: Global DNP3 SAv5 Master Key Rekey',
            description:
                'Broadcast emergency IEEE 1815.1 key renegotiation across all 8 RTU stations to invalidate compromised session keys.',
            actionLabel: _isDnp3RekeyInProgress ? 'REKEYING...' : 'FORCE REKEY',
            actionColor: const Color(0xFF0284C7),
            onTap: _triggerDnp3KeyRotation,
          ),
          const SizedBox(height: 8),
          _buildPlaybookTile(
            title: 'Playbook 03: Cellular APN Sever & VSAT Lock',
            description:
                'Shutdown cellular 4G modems across pipeline route in case of coordinated rogue IMSI Catcher activity.',
            actionLabel: 'LOCK TO VSAT',
            actionColor: const Color(0xFFFFB95F),
            onTap: () {
              setState(() {
                for (var r in _rtuStations) {
                  r.activeUplink = UplinkMedium.vsatSatellite;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'All 8 RTU stations forced exclusively to encrypted VSAT satellite links.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybookTile({
    required String title,
    required String description,
    required String actionLabel,
    required Color actionColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              side: BorderSide(color: actionColor),
              foregroundColor: actionColor,
            ),
            onPressed: onTap,
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTTOM STATUS BAR
  // ============================================================================

  Widget _buildBottomStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.hub_rounded, size: 14, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            const Text(
              '8/8 RTU Nodes Healthy',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4EDEA3),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '•',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'DPI Filter: 0x05/0x0F Drops Active',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _showSimulationDialog,
              icon: const Icon(Icons.bolt, size: 14, color: Color(0xFFFFB95F)),
              label: const Text(
                'Simulate Attack',
                style: TextStyle(fontSize: 11, color: Color(0xFFFFB95F)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MODALS & DIALOGS
  // ============================================================================

  void _showSimulationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.science_rounded,
                    color: Color(0xFFFFB95F), size: 22),
                SizedBox(width: 10),
                Text(
                  'ICS Cyber Attack & Defense Simulator',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Test DPI interception, MitM cellular defense, and optical tamper triggers against IEC 62443 rules.',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.power_settings_new_rounded,
                    color: Color(0xFFFF5252), size: 20),
              ),
              title: const Text('Inject Modbus 0x05 Coil Force (ESDV Trip)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              subtitle: const Text(
                  'Simulates attacker sending 0x05 packet to trip Burhi Dihing ESDV-03.',
                  style:
                      TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _simulateModbusCoilAttack();
              },
            ),
            const Divider(color: AppTheme.border),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB95F).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cell_tower_rounded,
                    color: Color(0xFFFFB95F), size: 20),
              ),
              title: const Text('Simulate Rogue IMSI Catcher (Fake BTS)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              subtitle: const Text(
                  'Simulates cellular tower downgrade and triggers automatic VSAT failover.',
                  style:
                      TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _simulateImsiCatcherAttack();
              },
            ),
            const Divider(color: AppTheme.border),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.door_sliding_rounded,
                    color: Color(0xFF38BDF8), size: 20),
              ),
              title: const Text('Trigger Substation Cabinet Tamper & 802.1X',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              subtitle: const Text(
                  'Simulates optical door trip and rogue MAC plugged into maintenance port.',
                  style:
                      TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _simulateCabinetTamper();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showPacketDissectorModal(DpiPacketLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111C38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: log.severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: log.severityColor),
                  ),
                  child: Text(
                    log.id,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: log.severityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DPI Deep Packet Dissector',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rule Triggered: ${log.ruleTriggered}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFB95F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'NETWORK LAYER 3 / 4 HEADER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1326),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Source IP: ${log.sourceIp} (Port ${log.sourcePort})',
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF38BDF8))),
                  Text(
                      'Destination IP: ${log.destinationIp} (Port ${log.destinationPort})',
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF38BDF8))),
                  Text('Target Valve Station: ${log.targetStationId}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary)),
                  Text('Protocol: ${log.protocol.name.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'APPLICATION LAYER / SCADA PAYLOAD HEX DUMP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1326),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                log.hexPayloadPreview,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF4EDEA3),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'FORENSIC MITIGATION & ISOLATION ACTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                log.forensicMitigation,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCertInReportDialog(CertInIncident inc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111C38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF0284C7)),
        ),
        title: Row(
          children: const [
            Icon(Icons.policy_rounded, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'CERT-In Annexure-I Notice',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Form for Reporting Cyber Security Incidents to CERT-In (Section 70B, IT Act)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(height: 10),
                _buildReportField('Incident Ref', inc.incidentId),
                _buildReportField('Organization',
                    'Oil India Limited / Nirmaan Pipeline SCADA CNI'),
                _buildReportField('Critical Sector', 'Petroleum & Natural Gas'),
                _buildReportField('Incident Title', inc.title),
                _buildReportField('Impacted Asset', inc.impactedAsset),
                _buildReportField('Attack Vector', inc.attackVector),
                _buildReportField('Statutory Direction',
                    inc.certInAnnexureCategory),
                _buildReportField('Forensic SHA-256', inc.technicalHash),
                _buildReportField(
                    'Detection Timestamp',
                    DateFormat('yyyy-MM-dd HH:mm:ss IST')
                        .format(inc.detectedAt)),
                _buildReportField(
                    'Mandatory Deadline',
                    DateFormat('yyyy-MM-dd HH:mm:ss IST')
                        .format(inc.reportingDeadline)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => inc.isDispatchedToCertIn = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF162347),
                  content: Text(
                    'CERT-In incident notice ${inc.incidentId} officially dispatched to incident@cert-in.org.in via encrypted S/MIME.',
                    style: const TextStyle(
                      color: Color(0xFF4EDEA3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('TRANSMIT TO CERT-IN'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _showZoneDrilldown(PurdueZoneConfig zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: zone.slColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: zone.slColor),
                  ),
                  child: Text(
                    zone.code,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: zone.slColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    zone.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Security Target: ${zone.targetSlLabel}  •  Achieved SL: ${zone.achievedSl}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: zone.slColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              zone.description,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text(
              'Firewall & Conduit Rules:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• ${zone.firewallPolicy}\n• ${zone.conduitSecurity}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRtuControlSheet(RtuStationCyberNode rtu) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Containment Controls: ${rtu.id} (${rtu.name})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'RTU IP: ${rtu.rtuIp}  |  MAC: ${rtu.macAddress}',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF10B981)),
              title: const Text('Reset 802.1X Port Security & Clear Alarms',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              subtitle: const Text(
                  'Clears port shutdown on local switch after technician physical inspection.',
                  style:
                      TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  rtu.dot1xPortLockdown = false;
                  rtu.cabinetDoorTamperTrip = false;
                  rtu.overallRisk = ThreatSeverity.cleared;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${rtu.id} 802.1X port re-enabled and optical alarms cleared.'),
                  ),
                );
              },
            ),
            const Divider(color: AppTheme.border),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.satellite_alt_rounded,
                  color: Color(0xFF00E5FF)),
              title: const Text('Lock RTU to VSAT Satellite Uplink Only',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              subtitle: const Text(
                  'Drops 4G modem connection to isolate from rogue IMSI catcher towers.',
                  style:
                      TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  rtu.activeUplink = UplinkMedium.vsatSatellite;
                  rtu.imsiCatcherSuspected = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${rtu.id} cellular severed. Uplink locked to ISRO GSAT-11 satellite.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
