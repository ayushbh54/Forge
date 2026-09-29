import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

// ============================================================================
// MULTI-DISCIPLINE DATA MODELS
// ============================================================================

enum DisciplineType { civil, piping, electrical, instrumentation, hse }

class DisciplineTrade {
  final String title;
  final int count;
  final String description;
  const DisciplineTrade(this.title, this.count, this.description);
}

class DisciplineWorkItem {
  final String code;
  final String name;
  final String unit;
  final double todayActual;
  final double todayTarget;
  final double cumulative;
  final double totalScope;
  final String location;
  final String status;
  final String rfiCode;

  const DisciplineWorkItem({
    required this.code,
    required this.name,
    required this.unit,
    required this.todayActual,
    required this.todayTarget,
    required this.cumulative,
    required this.totalScope,
    required this.location,
    required this.status,
    required this.rfiCode,
  });

  double get progressPct => (cumulative / totalScope).clamp(0.0, 1.0) * 100;
}

class DisciplineMachinery {
  final String name;
  final String count;
  final String hours;
  final String status;
  final IconData icon;

  const DisciplineMachinery(this.name, this.count, this.hours, this.status, this.icon);
}

class DisciplineMaterialItem {
  final String name;
  final String qty;
  final String grnRef;
  final String qcStatus;

  const DisciplineMaterialItem(this.name, this.qty, this.grnRef, this.qcStatus);
}

class DisciplineInspectionItem {
  final String code;
  final String title;
  final String standard;
  final String result;
  final bool passed;

  const DisciplineInspectionItem(this.code, this.title, this.standard, this.result, {this.passed = true});
}

class DisciplineRecord {
  final DisciplineType type;
  final String title;
  final IconData icon;
  final Color color;
  final int totalMen;
  final int manHours;
  final double progressPct;
  final String superintendent;
  final String shiftHours;
  final String weatherImpact;
  final List<DisciplineTrade> trades;
  final List<DisciplineWorkItem> workItems;
  final List<DisciplineMachinery> machinery;
  final List<DisciplineMaterialItem> materials;
  final List<DisciplineInspectionItem> inspections;
  final String supervisorNotes;

  const DisciplineRecord({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    required this.totalMen,
    required this.manHours,
    required this.progressPct,
    required this.superintendent,
    required this.shiftHours,
    required this.weatherImpact,
    required this.trades,
    required this.workItems,
    required this.machinery,
    required this.materials,
    required this.inspections,
    required this.supervisorNotes,
  });
}

class DisciplineRepository {
  static List<DisciplineRecord> getDisciplines() {
    return [
      const DisciplineRecord(
        type: DisciplineType.civil,
        title: 'Civil & Structural',
        icon: Icons.foundation,
        color: Color(0xFF38BDF8),
        totalMen: 140,
        manHours: 1120,
        progressPct: 68.8,
        superintendent: 'Rajesh Gogoi (Civil Lead Superintendent)',
        shiftHours: '07:00 – 17:30 (Outdoor stoppage: 2.5 hrs dewatering)',
        weatherImpact: 'Trench flooding in Sector 4; 4 dewatering pumps mobilized. Concreting paused 14:00-16:30.',
        trades: [
          DisciplineTrade('Carpenters & Shuttering', 30, 'Formwork erection for Substation Pad B'),
          DisciplineTrade('Steel Fixers & Bar Benders', 45, 'Rebar cage fabrication in covered yard'),
          DisciplineTrade('Concrete Masons', 25, 'Substation footing casting & screed finishing'),
          DisciplineTrade('Civil Helpers & Riggers', 35, 'Trench dewatering, earth handling & barricades'),
          DisciplineTrade('Supervisors & QC Inspectors', 5, 'Slump checks, level survey & cube sampling'),
        ],
        workItems: [
          DisciplineWorkItem(
            code: 'CIV-F4-012',
            name: 'Substation Foundation Pour & Trenching',
            unit: 'm³',
            todayActual: 45.0,
            todayTarget: 50.0,
            cumulative: 310.0,
            totalScope: 450.0,
            location: 'Substation Yard B (Grid 12)',
            status: 'ON TRACK',
            rfiCode: 'RFI-CIV-2026-112',
          ),
          DisciplineWorkItem(
            code: 'CIV-E1-004',
            name: 'Pipeline Trench Excavation Sector 4',
            unit: 'm',
            todayActual: 85.0,
            todayTarget: 120.0,
            cumulative: 1450.0,
            totalScope: 2000.0,
            location: 'Ch 14+200 to Ch 14+285',
            status: 'DELAYED (RAIN)',
            rfiCode: 'RFI-CIV-2026-114',
          ),
          DisciplineWorkItem(
            code: 'CIV-B2-019',
            name: 'Dewatering Sump Construction & Pump Well Setup',
            unit: 'nos',
            todayActual: 2.0,
            todayTarget: 2.0,
            cumulative: 8.0,
            totalScope: 8.0,
            location: 'Sector 4 Lowlands',
            status: 'COMPLETED',
            rfiCode: 'RFI-CIV-2026-115',
          ),
          DisciplineWorkItem(
            code: 'CIV-R3-007',
            name: 'Rebar Cage Assembly for Valve Pit 3',
            unit: 'MT',
            todayActual: 4.2,
            todayTarget: 5.0,
            cumulative: 21.0,
            totalScope: 25.0,
            location: 'Central Bar Bending Shed',
            status: 'ON TRACK',
            rfiCode: 'RFI-CIV-2026-116',
          ),
        ],
        machinery: [
          DisciplineMachinery('CAT 320D Hydraulic Excavator', '4 Units', '5.5 hrs running (2.5 hrs rain idle)', 'Operational', Icons.agriculture),
          DisciplineMachinery('Dynapac CA250 Trench Roller', '2 Units', '4.0 hrs bedding compaction', 'Operational', Icons.car_repair),
          DisciplineMachinery('Tata Signa 6m³ Transit Mixer', '3 Units', '4.5 hrs foundation batching', 'Operational', Icons.local_shipping),
          DisciplineMachinery('Kirloskar 15HP Dewatering Pumps', '4 Units', '6.0 hrs active pumping', 'Operational', Icons.water_drop),
        ],
        materials: [
          DisciplineMaterialItem('M30 Grade RMC Concrete', '45 m³', 'Batch #BM-419 (ReadyMix India)', 'QC Approved (125mm Slump)'),
          DisciplineMaterialItem('Fe-550D TMT Steel Rebar', '8.4 MT', 'GRN-2026-08 (Tata Steel)', 'MTC Lab Verified'),
          DisciplineMaterialItem('Coarse Aggregate 20mm', '32 MT', 'Stockpile Yard 3', 'Gradation Passed'),
        ],
        inspections: [
          DisciplineInspectionItem('RFI-CIV-2026-112', 'Substation footing pre-pour inspection & clear cover block verification', 'IS 456:2000', 'APPROVED', passed: true),
          DisciplineInspectionItem('QC-CUBE-0928', '7-Day compressive strength test on Foundation Pad Footing B', 'IS 516', '24.8 MPa (TARGET > 20 MPa)', passed: true),
        ],
        supervisorNotes: 'Substation footing concreting finished before rain onset. 4 dewatering pumps successfully prevented trench wall collapse in Sector 4.',
      ),

      const DisciplineRecord(
        type: DisciplineType.piping,
        title: 'Piping & Mechanical',
        icon: Icons.plumbing,
        color: Color(0xFFFFB95F),
        totalMen: 180,
        manHours: 1440,
        progressPct: 72.3,
        superintendent: 'Vikram Joshi (Lead Site Piping Supervisor)',
        shiftHours: '07:00 – 17:30 (Outdoor stoppage: 2.5 hrs; shop pre-fab continued)',
        weatherImpact: 'Mainline lower-in halted 14:00-16:30; 55 welders safely transferred to covered prefabrication spool shop.',
        trades: [
          DisciplineTrade('6G / GTAW Pipeline Welders', 55, 'Downhill welding & spool tie-ins'),
          DisciplineTrade('Pipe Fitters & Fabricators', 40, 'Spool alignment, beveling & fit-up'),
          DisciplineTrade('Riggers & Crane Signals', 30, 'Pipe handling, stringing & lower-in'),
          DisciplineTrade('Grinders & Welder Helpers', 45, 'Root pass cleaning & preheating'),
          DisciplineTrade('Welding QC & NDT Technicians', 10, 'Radiographic & ultrasonic weld testing'),
        ],
        workItems: [
          DisciplineWorkItem(
            code: 'PIP-L5-024',
            name: 'Pipe Lower-in & Downhill Mainline Welding',
            unit: 'm',
            todayActual: 68.0,
            todayTarget: 80.0,
            cumulative: 868.0,
            totalScope: 1200.0,
            location: 'Pipeline Sector 3 (Ch 12+100 to 12+168)',
            status: 'ON TRACK',
            rfiCode: 'RFI-PIP-2026-088',
          ),
          DisciplineWorkItem(
            code: 'PIP-F2-015',
            name: 'Spool Prefabrication 24" Mainline Section',
            unit: 'spools',
            todayActual: 16.0,
            todayTarget: 14.0,
            cumulative: 132.0,
            totalScope: 150.0,
            location: 'Covered Pipe Fabrication Shop',
            status: 'AHEAD OF TARGET',
            rfiCode: 'RFI-PIP-2026-085',
          ),
          DisciplineWorkItem(
            code: 'PIP-T3-019',
            name: 'NDT Hydrotest Section A Welds',
            unit: 'joints',
            todayActual: 18.0,
            todayTarget: 18.0,
            cumulative: 124.0,
            totalScope: 124.0,
            location: 'Section A Tie-in Bay',
            status: 'COMPLETED',
            rfiCode: 'RFI-PIP-2026-089',
          ),
          DisciplineWorkItem(
            code: 'PIP-B1-008',
            name: 'Cold Field Pipe Bending (24" OD x 14.3mm WT)',
            unit: 'bends',
            todayActual: 6.0,
            todayTarget: 8.0,
            cumulative: 42.0,
            totalScope: 70.0,
            location: 'Bending Yard Station 2',
            status: 'ON TRACK',
            rfiCode: 'RFI-PIP-2026-091',
          ),
        ],
        machinery: [
          DisciplineMachinery('Lincoln Electric 400A Diesel Welder', '6 Units', '7.0 hrs spool welding & joint prep', 'Operational', Icons.power),
          DisciplineMachinery('Kobelco 7055 50T Crawler Crane', '2 Units', '5.0 hrs pipe laying & trench placement', 'Operational', Icons.precision_manufacturing),
          DisciplineMachinery('Internal Pneumatic Line-up Clamp 24"', '1 Unit', '6.0 hrs joint alignment', 'Operational', Icons.build),
          DisciplineMachinery('Induction Pipe Pre-heating Rig', '2 Units', '5.5 hrs weld preheating (150°C)', 'Operational', Icons.local_fire_department),
        ],
        materials: [
          DisciplineMaterialItem('API 5L Grade X65 24" PSL2 Line Pipe', '68 m', 'Mill: Jindal SAW / PO-OIL-881', 'MTR Cleared (Heat #4912)'),
          DisciplineMaterialItem('E6010 / E8018-G Low-H2 Electrodes', '120 kg', 'Lincoln Fleetweld (Batch #EL-901)', 'Moisture Conditioned 350°C'),
          DisciplineMaterialItem('3LPE Heat Shrink Joint Sleeves', '18 nos', 'Canusa-CPS (Batch #SL-304)', 'Inspection Passed'),
        ],
        inspections: [
          DisciplineInspectionItem('RFI-PIP-2026-088', 'Radiographic & Ultrasonic Testing on Butt Welds #W-104 to #W-121', 'API 1104 / ASME B31.4', '100% ACCEPTED (0 REPAIRS)', passed: true),
          DisciplineInspectionItem('RFI-PIP-2026-089', 'Field joint coating Holiday detection test at 15 kV spark potential', 'NACE SP0188', 'PASSED (0 PINHOLES)', passed: true),
        ],
        supervisorNotes: 'Shop welding delivered 16 spools during the afternoon rain stoppage, fully offsetting outdoor lower-in downtime. 100% NDT clearance achieved on Section A.',
      ),

      const DisciplineRecord(
        type: DisciplineType.electrical,
        title: 'Electrical Systems',
        icon: Icons.bolt,
        color: Color(0xFF4EDEA3),
        totalMen: 80,
        manHours: 640,
        progressPct: 54.6,
        superintendent: 'Amit Buragohain (Electrical Project Engineer)',
        shiftHours: '07:00 – 17:30 (Indoor substation unaffected by rain)',
        weatherImpact: 'Outdoor cable tray pulling paused during rain; indoor switchgear room and transformer pad works prioritized.',
        trades: [
          DisciplineTrade('High-Voltage Electricians', 25, '33kV switchgear cable termination & glanding'),
          DisciplineTrade('Cable Pullers & Jointers', 20, '11kV feeder cable pulling in main trench'),
          DisciplineTrade('Substation Technicians', 15, 'Transformer auxiliary wiring & protection relay checks'),
          DisciplineTrade('Electrical Helpers', 15, 'Earthing flat fabrication & trench clearing'),
          DisciplineTrade('QA/QC Electrical Engineers', 5, 'Insulation resistance & earth loop testing'),
        ],
        workItems: [
          DisciplineWorkItem(
            code: 'ELE-C2-008',
            name: 'Cable Tray Laying & Earthing Grid Installation',
            unit: 'm',
            todayActual: 140.0,
            todayTarget: 160.0,
            cumulative: 820.0,
            totalScope: 1500.0,
            location: 'Central Substation to Pump House',
            status: 'ON TRACK',
            rfiCode: 'RFI-ELE-2026-049',
          ),
          DisciplineWorkItem(
            code: 'ELE-T1-003',
            name: '33kV Substation Transformer Pad Conduit Termination',
            unit: 'conduits',
            todayActual: 8.0,
            todayTarget: 8.0,
            cumulative: 24.0,
            totalScope: 24.0,
            location: 'Transformer Yard Bay 1 & 2',
            status: 'COMPLETED',
            rfiCode: 'RFI-ELE-2026-050',
          ),
          DisciplineWorkItem(
            code: 'ELE-E3-021',
            name: 'Earth Pit Resistance & Grid Continuity Testing',
            unit: 'pits',
            todayActual: 14.0,
            todayTarget: 16.0,
            cumulative: 48.0,
            totalScope: 60.0,
            location: 'Substation Earthing Perimeter',
            status: 'ON TRACK',
            rfiCode: 'RFI-ELE-2026-051',
          ),
          DisciplineWorkItem(
            code: 'ELE-P4-011',
            name: '415V Motor Control Center (MCC) Panel Glanding',
            unit: 'feeders',
            todayActual: 24.0,
            todayTarget: 25.0,
            cumulative: 96.0,
            totalScope: 140.0,
            location: 'Main Electrical Control Building',
            status: 'ON TRACK',
            rfiCode: 'RFI-ELE-2026-052',
          ),
        ],
        machinery: [
          DisciplineMachinery('Megger MIT515 5kV Insulation Tester', '2 Units', '4.0 hrs cable hi-pot testing', 'Operational', Icons.speed),
          DisciplineMachinery('Electric Cable Winch 5T Puller', '1 Unit', '4.5 hrs mainline cable pulling', 'Operational', Icons.hardware),
          DisciplineMachinery('Hydraulic Cable Crimper 400 sq.mm', '3 Units', '6.0 hrs lug crimping & termination', 'Operational', Icons.handyman),
          DisciplineMachinery('Fluke 1587 FC Insulation Multimeter', '4 Units', '6.5 hrs continuity verification', 'Operational', Icons.electrical_services),
        ],
        materials: [
          DisciplineMaterialItem('11kV 3C x 300 sq.mm XLPE Cable', '140 m', 'Polycab India (Lot #PC-8812)', 'Factory Test Cert Cleared'),
          DisciplineMaterialItem('50x6mm Galvanized Iron Earthing Flat', '210 m', 'TISCO (Batch #GI-442)', 'Zinc Coating 610 g/m² Verified'),
          DisciplineMaterialItem('Heavy Duty GI Perforated Tray 300mm', '60 m', 'Profab Engineering', 'Hot Dip Galvanized Passed'),
        ],
        inspections: [
          DisciplineInspectionItem('RFI-ELE-2026-049', 'High Potential (Hi-Pot) DC withstand testing on 11kV Feeder Section 2', 'IEEE 400.1 / IS 7098', 'PASSED (< 0.15 mA LEAKAGE)', passed: true),
          DisciplineInspectionItem('RFI-ELE-2026-050', 'Earthing grid individual pit resistance measurement', 'IEEE 80 / IS 3043', '0.74 OHMS (SPEC < 1.0 OHM)', passed: true),
        ],
        supervisorNotes: 'Earthing grid values showed excellent conductivity post-rainfall (0.74 Ω). Indoor MCC terminations are 3 days ahead of P6 baseline.',
      ),

      const DisciplineRecord(
        type: DisciplineType.instrumentation,
        title: 'Instrumentation & Automation',
        icon: Icons.memory,
        color: Color(0xFFA855F7),
        totalMen: 45,
        manHours: 360,
        progressPct: 68.5,
        superintendent: 'S. N. Kulkarni (Lead Instrumentation Specialist)',
        shiftHours: '07:00 – 17:30 (DCS control room work fully sheltered)',
        weatherImpact: 'Zero rain stoppage. Technicians conducted bench calibration of transmitters and DCS marshalling continuity tests.',
        trades: [
          DisciplineTrade('Instrumentation Technicians', 15, 'Transmitter hook-ups, manifolds & cabling'),
          DisciplineTrade('SS Impulse Tubing Fitters', 12, '1/2" 316L SS tubing bending & Swagelok fittings'),
          DisciplineTrade('Calibration & Loop Test Specialists', 10, 'HART transmitter calibration & DCS loop checks'),
          DisciplineTrade('Automation & Panel Helpers', 8, 'Tagging, ferruling, tray routing & clean-up'),
        ],
        workItems: [
          DisciplineWorkItem(
            code: 'INS-D1-009',
            name: 'Pressure & Differential Pressure Transmitter Hook-ups',
            unit: 'units',
            todayActual: 12.0,
            todayTarget: 14.0,
            cumulative: 78.0,
            totalScope: 110.0,
            location: 'Main Pipeline Manifold & Pig Launcher',
            status: 'ON TRACK',
            rfiCode: 'RFI-INS-2026-031',
          ),
          DisciplineWorkItem(
            code: 'INS-L2-014',
            name: 'DCS Marshalling Cabinet Loop Continuity & Cold Testing',
            unit: 'loops',
            todayActual: 38.0,
            todayTarget: 40.0,
            cumulative: 240.0,
            totalScope: 350.0,
            location: 'Central Control Building Rack Room',
            status: 'ON TRACK',
            rfiCode: 'RFI-INS-2026-032',
          ),
          DisciplineWorkItem(
            code: 'INS-T4-002',
            name: 'Stainless Steel 1/2" Impulse Line Hydrostatic Testing',
            unit: 'm',
            todayActual: 120.0,
            todayTarget: 120.0,
            cumulative: 650.0,
            totalScope: 900.0,
            location: 'Manifold Valve Skid',
            status: 'COMPLETED',
            rfiCode: 'RFI-INS-2026-033',
          ),
          DisciplineWorkItem(
            code: 'INS-G3-005',
            name: 'ESD Emergency Shutdown Solenoid Valve Functional Stroking',
            unit: 'valves',
            todayActual: 6.0,
            todayTarget: 8.0,
            cumulative: 18.0,
            totalScope: 24.0,
            location: 'Pig Launcher ESD Block Station',
            status: 'ON TRACK',
            rfiCode: 'RFI-INS-2026-034',
          ),
        ],
        machinery: [
          DisciplineMachinery('Fluke 754 Documenting HART Calibrator', '2 Units', '7.0 hrs 5-point calibration', 'Operational', Icons.settings_input_component),
          DisciplineMachinery('Beamex MC6 Multifunction Field Calibrator', '1 Unit', '6.0 hrs mA loop simulation', 'Operational', Icons.tune),
          DisciplineMachinery('Swagelok Hydraulic Tube Bender 1/2"', '2 Units', '5.0 hrs cold impulse line bending', 'Operational', Icons.build_circle),
          DisciplineMachinery('Ralston Pneumatic Hand Pressure Pump', '3 Units', '5.5 hrs line hydrostatic proving', 'Operational', Icons.compress),
        ],
        materials: [
          DisciplineMaterialItem('Rosemount 3051S Coplanar Transmitters', '12 units', 'Emerson Process (PO-OIL-991)', 'NIST Traceable Cal Cert Cleared'),
          DisciplineMaterialItem('316L Stainless Steel 1/2" Seamless Tubing', '120 m', 'Swagelok (Heat #SS-9821)', 'Hydrotested 150 bar (Pass)'),
          DisciplineMaterialItem('5-Valve Instrument Manifolds 316SS', '14 sets', 'Parker Hannifin', 'NACE MR0175 Compliant'),
        ],
        inspections: [
          DisciplineInspectionItem('RFI-INS-2026-031', 'Pressure Transmitter 5-point calibration verification & 4-20mA DCS verification', 'ISA 51.1 / IEC 60770', 'PASSED (ACCURACY < 0.04% SPAN)', passed: true),
          DisciplineInspectionItem('RFI-INS-2026-033', 'SS Impulse line pneumatic decay leak test at 150 bar for 30 minutes', 'ASME B31.3', 'PASSED (ZERO PRESSURE LOSS)', passed: true),
        ],
        supervisorNotes: 'All 38 loops tested today showed 100% signal fidelity with Honeywell Experion DCS. 12 Rosemount transmitters successfully sealed against weather.',
      ),

      const DisciplineRecord(
        type: DisciplineType.hse,
        title: 'HSE & Quality Assurance',
        icon: Icons.health_and_safety,
        color: Color(0xFF10B981),
        totalMen: 50,
        manHours: 400,
        progressPct: 100.0,
        superintendent: 'Subhash Roy (Chief HSE & QA/QC Officer)',
        shiftHours: '07:00 – 17:30 (Continuous safety & environmental patrol)',
        weatherImpact: 'Emergency rain protocol activated: inspected trench perimeters, verified dewatering pump earth leakage, barricaded flooded zones.',
        trades: [
          DisciplineTrade('Site Safety Officers', 15, 'Active surveillance, PTW audits & hazard identification'),
          DisciplineTrade('Fire Watchers & Hole Watchers', 20, 'Confined space valve pit & welding safety cover'),
          DisciplineTrade('Certified First Aiders & Medics', 10, 'Medical health post & heat/rain illness prevention'),
          DisciplineTrade('Environmental & Spill Auditors', 5, 'Sediment basin & storm drainage monitoring'),
        ],
        workItems: [
          DisciplineWorkItem(
            code: 'HSE-TBT-01',
            name: 'Morning Confined Space Safety & Gas Testing Toolbox Talk',
            unit: 'men',
            todayActual: 450.0,
            todayTarget: 450.0,
            cumulative: 450.0,
            totalScope: 450.0,
            location: 'Central Muster Ground (07:30 AM)',
            status: 'COMPLETED (100%)',
            rfiCode: 'TBT-LOG-2026-0930',
          ),
          DisciplineWorkItem(
            code: 'HSE-AUD-06',
            name: 'Heavy Plant & Machinery Pre-Use Safety Audit',
            unit: 'units',
            todayActual: 18.0,
            todayTarget: 18.0,
            cumulative: 18.0,
            totalScope: 18.0,
            location: 'Site-wide Equipment Fleet',
            status: 'PASSED (100%)',
            rfiCode: 'AUD-EQ-2026-0930',
          ),
          DisciplineWorkItem(
            code: 'HSE-PTW-14',
            name: 'Permit-to-Work Post-Rain Gas Re-authorization',
            unit: 'permits',
            todayActual: 14.0,
            todayTarget: 14.0,
            cumulative: 14.0,
            totalScope: 14.0,
            location: 'Confined Space & Hot Work Zones',
            status: 'RE-AUTHORIZED',
            rfiCode: 'PTW-REV-2026-0930',
          ),
          DisciplineWorkItem(
            code: 'HSE-ENV-03',
            name: 'Stormwater Sediment Runoff & Silt Fence Inspection',
            unit: 'sectors',
            todayActual: 4.0,
            todayTarget: 4.0,
            cumulative: 4.0,
            totalScope: 4.0,
            location: 'Pipeline Sector 1 to 4 Outfalls',
            status: 'COMPLIANT',
            rfiCode: 'ENV-LOG-2026-0930',
          ),
        ],
        machinery: [
          DisciplineMachinery('MSA Altair 4XR Multi-Gas Monitors', '8 Units', 'Continuous active gas sampling', 'Calibrated', Icons.sensors),
          DisciplineMachinery('DBI-SALA Confined Space Rescue Tripod', '3 Sets', 'Standby at Valve Pit 3', 'Certified', Icons.shield),
          DisciplineMachinery('Hydrocarbon Spill Response Boom & Kit', '4 Units', 'Deployed at fuel refilling station', 'Ready', Icons.cleaning_services),
          DisciplineMachinery('AED & Automated Trauma Resuscitator', '2 Units', 'Central Medical Aid Post', 'Certified', Icons.medical_services),
        ],
        materials: [
          DisciplineMaterialItem('Multi-Gas Calibration Gas Cylinder', '1 unit', 'MSA (Lot #CG-994)', 'NIST Certified (O2, H2S, LEL, CO)'),
          DisciplineMaterialItem('Heavy Duty Geotextile Silt Fencing', '150 m', 'Maccaferri (Batch #SF-12)', 'Erosion Control Cleared'),
          DisciplineMaterialItem('High-Visibility Rain Gear & PPE Kits', '450 sets', 'Karam Safety Ltd.', 'EN 343 / IS 8519 Standard'),
        ],
        inspections: [
          DisciplineInspectionItem('HSE-AUDIT-2026-44', 'FIDIC Red Book Clause 6.7 Safety, Health and Accident Prevention Audit', 'FIDIC / OSHA 1926', 'ZERO NON-CONFORMANCES (100% CLEAN)', passed: true),
          DisciplineInspectionItem('ATMOS-GAS-0930', 'Atmospheric multi-gas testing in Valve Pit 3 post-rain stoppage', 'O2 > 20.8%, H2S 0ppm, LEL 0%', 'PERMIT RE-VALIDATED SAFE', passed: true),
        ],
        supervisorNotes: 'Zero incidents, zero near-misses recorded across 3,825 safe man-hours today. All 14 high-risk work permits successfully audited and cleared.',
      ),
    ];
  }
}

// ============================================================================
// SIGNATURE DRAWING & PAINTER
// ============================================================================

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;
  final double strokeWidth;
  final bool showGuidelines;

  const SignaturePainter({
    required this.points,
    this.strokeColor = const Color(0xFF38BDF8),
    this.strokeWidth = 2.5,
    this.showGuidelines = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGuidelines) {
      final linePaint = Paint()
        ..color = const Color(0xFF26396E)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Draw subtle dashed baseline
      final baselineY = size.height * 0.72;
      const dashWidth = 5.0;
      const dashSpace = 4.0;
      double startX = 14.0;
      while (startX < size.width - 14.0) {
        canvas.drawLine(
          Offset(startX, baselineY),
          Offset(startX + dashWidth, baselineY),
          linePaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    if (points.isEmpty) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class SealResult {
  final String hash;
  final DateTime signedAt;
  final String signatoryName;
  final String signatoryRole;
  final String licenseId;
  final List<Offset?> signaturePoints;
  final String certificateId;
  final String canonicalPayload;

  const SealResult({
    required this.hash,
    required this.signedAt,
    required this.signatoryName,
    required this.signatoryRole,
    required this.licenseId,
    required this.signaturePoints,
    required this.certificateId,
    required this.canonicalPayload,
  });
}

// ============================================================================
// INTERACTIVE SIGN & SEAL DIALOG
// ============================================================================

class SignAndSealDialog extends StatefulWidget {
  final ProjectModel? project;
  final DateTime diaryDate;
  final List<DisciplineRecord> disciplines;

  const SignAndSealDialog({
    super.key,
    required this.project,
    required this.diaryDate,
    required this.disciplines,
  });

  @override
  State<SignAndSealDialog> createState() => _SignAndSealDialogState();
}

class _SignAndSealDialogState extends State<SignAndSealDialog> {
  String _selectedRole = 'Marcus Vance, P.E. (FIDIC Resident Engineer Cl. 3.1)';
  String _licenseId = 'FIDIC-PE-IND-4921 / CE-88321';
  final TextEditingController _pinController = TextEditingController(text: '2026');
  bool _isBiometricVerified = true;

  // Sworn Statutory Declarations
  bool _physicalMusterChecked = true;
  bool _weatherDelayChecked = true;
  bool _fidicDeclarationChecked = true;

  // Signature canvas state
  final List<Offset?> _points = [];
  bool _isSealing = false;
  bool _showRawPayload = false;

  late DateTime _liveTimestamp;

  @override
  void initState() {
    super.initState();
    _liveTimestamp = DateTime.now();
    // Default with high-fidelity authorized signature curve
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyRegisteredElectronicToken();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _applyRegisteredElectronicToken() {
    setState(() {
      _points.clear();
      // Generate authentic cursive signature curve representing Marcus Vance P.E.
      const double cx = 24.0;
      const double cy = 68.0;

      // 'M' Initial
      _points.add(const Offset(cx, cy + 18));
      _points.add(const Offset(cx + 10, cy - 32));
      _points.add(const Offset(cx + 20, cy + 12));
      _points.add(const Offset(cx + 32, cy - 36));
      _points.add(const Offset(cx + 42, cy + 14));
      _points.add(null);

      // 'arcus' cursive flow
      for (int i = 0; i <= 24; i++) {
        final t = i / 24.0;
        final x = cx + 44 + (t * 55);
        final y = cy + math.sin(t * math.pi * 3.5) * 7 - 2;
        _points.add(Offset(x, y));
      }
      _points.add(null);

      // 'V' Capital
      const double vx = cx + 112;
      _points.add(const Offset(vx, cy - 32));
      _points.add(const Offset(vx + 16, cy + 18));
      _points.add(const Offset(vx + 32, cy - 22));
      _points.add(null);

      // 'ance' cursive tail
      for (int i = 0; i <= 26; i++) {
        final t = i / 26.0;
        final x = vx + 34 + (t * 60);
        final y = cy + math.sin(t * math.pi * 4.2) * 5;
        _points.add(Offset(x, y));
      }
      _points.add(null);

      // Professional flourish underline
      _points.add(const Offset(cx + 5, cy + 26));
      _points.add(const Offset(cx + 80, cy + 28));
      _points.add(const Offset(cx + 175, cy + 25));
      _points.add(const Offset(cx + 225, cy + 18));
      _points.add(const Offset(cx + 245, cy + 28));
      _points.add(const Offset(cx + 205, cy + 34));
      _points.add(const Offset(cx + 145, cy + 32));
      _points.add(null);
    });
  }

  Map<String, dynamic> _buildCanonicalPayload() {
    final project = widget.project;
    return {
      'protocol': 'FIDIC-RED-BOOK-1999-CL-4.21',
      'projectCode': project?.code ?? 'OIL-PL-024',
      'projectName': project?.name ?? 'EPC Project Duliajan',
      'client': project?.client ?? 'Oil India Limited',
      'diaryDate': DateFormat('yyyy-MM-dd').format(widget.diaryDate),
      'signatory': _selectedRole,
      'license': _licenseId,
      'timestampUtc': _liveTimestamp.toUtc().toIso8601String(),
      'disciplines': widget.disciplines.map((d) => {
        'discipline': d.title,
        'headcount': d.totalMen,
        'manHours': d.manHours,
        'progressPct': d.progressPct,
        'superintendent': d.superintendent,
        'activitiesCount': d.workItems.length,
      }).toList(),
      'siteTotals': {
        'totalWorkforce': 450,
        'activeEquipment': 18,
        'delayStoppageMinutes': 150, // 2.5 hours
        'lostTimeInjuries': 0,
        'permitsActive': 14,
      },
      'signatureStrokeCount': _points.where((p) => p != null).length,
      'authMode': _isBiometricVerified ? 'HARDWARE_KEY_2FA' : 'PIN_CONFIRMATION',
    };
  }

  String _computeCurrentHash() {
    final payload = _buildCanonicalPayload();
    final jsonStr = jsonEncode(payload);
    final bytes = utf8.encode(jsonStr);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _onConfirmSeal() async {
    final validPoints = _points.where((p) => p != null).length;
    if (validPoints < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign on the canvas to generate the cryptographic signature!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      return;
    }

    if (!_physicalMusterChecked || !_weatherDelayChecked || !_fidicDeclarationChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All statutory FIDIC Clause 4.21 undertakings must be affirmed.'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      return;
    }

    setState(() {
      _isSealing = true;
      _liveTimestamp = DateTime.now();
    });

    // Simulated cryptographic signature sealing delay
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    final hash = _computeCurrentHash();
    final canonicalStr = jsonEncode(_buildCanonicalPayload());
    final certId = 'CERT-FIDIC-2026-${DateFormat('MMdd').format(widget.diaryDate)}-${hash.substring(0, 8).toUpperCase()}';

    final result = SealResult(
      hash: hash,
      signedAt: _liveTimestamp,
      signatoryName: _selectedRole.split('(').first.trim(),
      signatoryRole: _selectedRole,
      licenseId: _licenseId,
      signaturePoints: List.from(_points),
      certificateId: certId,
      canonicalPayload: canonicalStr,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final currentHash = _computeCurrentHash();
    final validPointsCount = _points.where((p) => p != null).length;

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.tertiary.withAlpha(120)),
                    ),
                    child: const Icon(Icons.verified_user, color: AppTheme.tertiary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Sign & Seal Site Diary',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'FIDIC Red Book Clause 4.21 Cryptographic Daily Record',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Signatory Card & Role Picker
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'AUTHORIZING SIGNATORY',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiary.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _licenseId,
                                style: const TextStyle(color: AppTheme.tertiary, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            fillColor: AppTheme.surface,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.border)),
                          ),
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(
                              value: 'Marcus Vance, P.E. (FIDIC Resident Engineer Cl. 3.1)',
                              child: Text('Marcus Vance, P.E. (FIDIC Resident Engineer Cl. 3.1)'),
                            ),
                            DropdownMenuItem(
                              value: 'Vikram Joshi (Contractor Lead Representative Cl. 4.3)',
                              child: Text('Vikram Joshi (Contractor Lead Representative Cl. 4.3)'),
                            ),
                            DropdownMenuItem(
                              value: 'R. K. Sharma (QA/QC Lead Certifying Inspector)',
                              child: Text('R. K. Sharma (QA/QC Lead Certifying Inspector)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedRole = val;
                                if (val.contains('Marcus')) {
                                  _licenseId = 'FIDIC-PE-IND-4921 / CE-88321';
                                } else if (val.contains('Vikram')) {
                                  _licenseId = 'EPC-CONTRACTOR-REP-0941';
                                } else {
                                  _licenseId = 'ASNT-LEVEL-III-NDT-552';
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_clock, color: AppTheme.primaryLight, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('TIMESTAMP (UTC & IST)', style: TextStyle(color: AppTheme.textMuted, fontSize: 8.5)),
                                          Text(
                                            DateFormat('dd MMM yyyy, HH:mm:ss').format(_liveTimestamp),
                                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isBiometricVerified = !_isBiometricVerified;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                decoration: BoxDecoration(
                                  color: _isBiometricVerified ? AppTheme.tertiary.withAlpha(30) : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _isBiometricVerified ? AppTheme.tertiary : AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isBiometricVerified ? Icons.fingerprint : Icons.vpn_key,
                                      color: _isBiometricVerified ? AppTheme.tertiary : AppTheme.textMuted,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isBiometricVerified ? '2FA Token OK' : 'PIN Mode',
                                      style: TextStyle(
                                        color: _isBiometricVerified ? AppTheme.tertiary : AppTheme.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Digital Signature Interactive Canvas Pad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.draw, color: AppTheme.primaryLight, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Digital Signature Canvas',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            validPointsCount > 0 ? '($validPointsCount vector points)' : '(Touch/draw below)',
                            style: TextStyle(
                              color: validPointsCount > 0 ? AppTheme.tertiary : AppTheme.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            ),
                            icon: const Icon(Icons.refresh, size: 14, color: AppTheme.textMuted),
                            label: const Text('Clear', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            onPressed: () {
                              setState(() {
                                _points.clear();
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            ),
                            icon: const Icon(Icons.auto_fix_high, size: 14, color: AppTheme.primaryLight),
                            label: const Text('Auto-Sign', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11)),
                            onPressed: _applyRegisteredElectronicToken,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF070E1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: validPointsCount > 0 ? AppTheme.primary.withAlpha(160) : AppTheme.border,
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _points.add(details.localPosition);
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                _points.add(details.localPosition);
                              });
                            },
                            onPanEnd: (details) {
                              setState(() {
                                _points.add(null);
                              });
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CustomPaint(
                                painter: SignaturePainter(
                                  points: _points,
                                  strokeColor: const Color(0xFF38BDF8),
                                  strokeWidth: 2.6,
                                  showGuidelines: true,
                                ),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 8,
                          child: Text(
                            '✕  Resident Engineer / Contractor Representative Signature',
                            style: TextStyle(
                              color: AppTheme.textMuted.withAlpha(150),
                              fontSize: 9.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (validPointsCount == 0)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.gesture, color: AppTheme.textMuted, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Draw signature above with stylus, finger, or tap "Auto-Sign"',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Statutory Affirmations (FIDIC Red Book Clause 4.21)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FIDIC STATUTORY COMPLIANCE DECLARATIONS',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildCheckboxRow(
                          value: _physicalMusterChecked,
                          title: 'Physical Muster & Manpower Verification',
                          subtitle: 'Verified 450 personnel across Civil, Piping, Electrical, Instrumentation & HSE.',
                          onChanged: (v) => setState(() => _physicalMusterChecked = v ?? false),
                        ),
                        const Divider(color: AppTheme.border, height: 12),
                        _buildCheckboxRow(
                          value: _weatherDelayChecked,
                          title: 'Weather & Clause 8.4 Stoppage Confirmation',
                          subtitle: 'Certified 2.5 hrs rain stoppage (42mm precip) and 18 operational heavy units.',
                          onChanged: (v) => setState(() => _weatherDelayChecked = v ?? false),
                        ),
                        const Divider(color: AppTheme.border, height: 12),
                        _buildCheckboxRow(
                          value: _fidicDeclarationChecked,
                          title: 'Cryptographic Immutability Undertaking',
                          subtitle: 'Under FIDIC Clause 4.21, sealing creates a tamper-evident evidentiary record.',
                          onChanged: (v) => setState(() => _fidicDeclarationChecked = v ?? false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // SHA-256 Tamper-Proof Cryptographic Hash Live Preview Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071410),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withAlpha(120), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF34D399),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'SHA-256 CRYPTOGRAPHIC TAMPER-PROOF HASH',
                                  style: TextStyle(
                                    color: Color(0xFF6EE7B7),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showRawPayload = !_showRawPayload;
                                });
                              },
                              child: Text(
                                _showRawPayload ? 'Hide JSON' : 'Inspect JSON',
                                style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF059669).withAlpha(80)),
                          ),
                          child: SelectableText(
                            currentHash,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF34D399),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (_showRawPayload) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SelectableText(
                              const JsonEncoder.withIndent('  ').convert(_buildCanonicalPayload()),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFF94A3B8),
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Modal Actions Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _isSealing ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSealing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.lock_person, size: 18, color: Colors.black),
                      label: Text(
                        _isSealing ? 'Cryptographically Sealing...' : 'Sign & Seal Site Diary',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isSealing ? null : _onConfirmSeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                activeColor: AppTheme.tertiary,
                checkColor: Colors.black,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN SITE DIARY SCREEN
// ============================================================================

class SiteDiaryScreen extends StatefulWidget {
  const SiteDiaryScreen({super.key});

  @override
  State<SiteDiaryScreen> createState() => _SiteDiaryScreenState();
}

class _SiteDiaryScreenState extends State<SiteDiaryScreen> {
  final DateTime _diaryDate = DateTime.now();
  bool _isLocked = false;
  String? _sha256Stamp;
  DateTime? _signedAt;
  String _signatoryName = 'Marcus Vance, P.E. (FIDIC Engineer Cl. 3.1)';
  String _signatoryRole = 'FIDIC Resident Engineer Cl. 3.1';
  String _licenseId = 'FIDIC-PE-IND-4921 / CE-88321';
  String? _certificateId;
  String? _canonicalPayloadStr;
  List<Offset?> _savedSignaturePoints = [];
  final String _contractorRep = 'Vikram Joshi (Lead Site Piping Supervisor)';
  final TextEditingController _remarksController = TextEditingController(
    text: 'Site dewatering commenced post-rainfall in Sector 4. Covered shop spool prefabrication delivered 16 units. All safety precautions observed.',
  );

  // Multi-discipline selector state
  DisciplineType _selectedDiscipline = DisciplineType.civil;
  bool _showCrossDisciplineMatrix = false;

  late List<DisciplineRecord> _disciplineRecords;

  @override
  void initState() {
    super.initState();
    _disciplineRecords = DisciplineRepository.getDisciplines();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  String _computeSha256Digest(Map<String, dynamic> payload) {
    final rawString = jsonEncode(payload);
    final bytes = utf8.encode(rawString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _openSignAndSealModal(BuildContext context, ProjectModel? project) async {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diary is already locked and digitally sealed with SHA-256.'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<SealResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SignAndSealDialog(
        project: project,
        diaryDate: _diaryDate,
        disciplines: _disciplineRecords,
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _isLocked = true;
      _sha256Stamp = result.hash;
      _signedAt = result.signedAt;
      _signatoryName = result.signatoryName;
      _signatoryRole = result.signatoryRole;
      _licenseId = result.licenseId;
      _certificateId = result.certificateId;
      _savedSignaturePoints = result.signaturePoints;
      _canonicalPayloadStr = result.canonicalPayload;
    });

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceCard,
        duration: const Duration(seconds: 4),
        content: Row(
          children: const [
            Icon(Icons.verified, color: AppTheme.tertiary, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Site Diary sealed under FIDIC Clause 4.21! Cryptographic hash recorded.',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyTamperProofIntegrity() {
    if (_sha256Stamp == null) return;

    final computedHash = _canonicalPayloadStr != null
        ? _computeSha256Digest(jsonDecode(_canonicalPayloadStr!) as Map<String, dynamic>)
        : _sha256Stamp!;
    final isMatch = computedHash == _sha256Stamp;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isMatch ? AppTheme.tertiary : AppTheme.error, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(isMatch ? Icons.security_update_good : Icons.warning_amber, color: isMatch ? AppTheme.tertiary : AppTheme.error, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Tamper-Proof Integrity Check',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMatch ? const Color(0xFF0B291E) : const Color(0xFF331414),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isMatch ? AppTheme.tertiary : AppTheme.error),
              ),
              child: Row(
                children: [
                  Icon(isMatch ? Icons.check_circle : Icons.error_outline, color: isMatch ? AppTheme.tertiary : AppTheme.error, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isMatch
                          ? 'STATUS: INTEGRITY VERIFIED (PASS 100%)\nZero alteration detected since timestamping.'
                          : 'STATUS: TAMPER WARNING (HASH MISMATCH)\nPayload modified after sealing.',
                      style: TextStyle(color: isMatch ? AppTheme.tertiary : AppTheme.error, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('RECORD DIGEST (SHA-256):', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                computedHash,
                style: TextStyle(fontFamily: 'monospace', color: isMatch ? const Color(0xFF34D399) : AppTheme.error, fontSize: 10),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Certificate ID: ${_certificateId ?? 'CERT-FIDIC-2026'}\nSignatory: $_signatoryName ($_licenseId)\nRole: $_signatoryRole\nSealed At: ${_signedAt != null ? DateFormat('dd MMM yyyy, HH:mm:ss').format(_signedAt!) : 'N/A'}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isMatch ? AppTheme.tertiary : AppTheme.error, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close Verification', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCertificateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.tertiary, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.workspace_premium, color: AppTheme.secondary, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'FIDIC Clause 4.21 Certificate',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(bottomCtx),
                ),
              ],
            ),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _certificateId ?? 'CERT-FIDIC-2026-8812',
                        style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('IMMUTABLE RECORD', style: TextStyle(color: AppTheme.tertiary, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('FIDIC Resident Engineer: $_signatoryName', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('Designated Role: $_signatoryRole', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  Text('Contractor Representative: $_contractorRep', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  Text('Accreditation: $_licenseId', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                  const SizedBox(height: 6),
                  Text(
                    'Sealed at: ${_signedAt != null ? DateFormat('dd MMMM yyyy, HH:mm:ss.SSS').format(_signedAt!) : ''} IST',
                    style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
                  ),
                  if (_canonicalPayloadStr != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Canonical Payload Digest: ${_canonicalPayloadStr!.length} chars cryptographically hashed',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy SHA-256'),
                    onPressed: () {
                      if (_sha256Stamp != null) {
                        Clipboard.setData(ClipboardData(text: _sha256Stamp!));
                        Navigator.pop(bottomCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SHA-256 hash copied!'), backgroundColor: AppTheme.primary),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    icon: const Icon(Icons.verified, size: 16),
                    label: const Text('Verify Digest'),
                    onPressed: () {
                      Navigator.pop(bottomCtx);
                      _verifyTamperProofIntegrity();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfExportModal(BuildContext context, ProjectModel? project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppTheme.border, width: 1.5),
              left: BorderSide(color: AppTheme.border, width: 1.5),
              right: BorderSide(color: AppTheme.border, width: 1.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Export Formal FIDIC PDF',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'FIDIC Red Book Clause 4.21 Multi-Discipline Compliance Report',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(bottomCtx),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.border, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // PDF Document Simulation Sheet
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(120),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Official Header
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F2B5C),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Center(
                                  child: Icon(Icons.domain, color: Colors.white, size: 26),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'OIL INDIA LIMITED (OIL)',
                                      style: TextStyle(
                                        color: Color(0xFF0F2B5C),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Text(
                                      'EPC Project Duliajan — Field Operations Division',
                                      style: TextStyle(
                                        color: Color(0xFF334155),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Contract: FIDIC Red Book (1999) | Doc No: OIL-FIDIC-SD-${DateFormat('yyyyMMdd').format(_diaryDate)}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            color: const Color(0xFF0F2B5C),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "DAILY SITE DIARY / CONTRACTOR'S DAILY RECORD",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_diaryDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Metadata Grid
                          _buildPdfMetaRow('Weather Condition', 'Rainy / 32°C (42mm rain recorded)'),
                          _buildPdfMetaRow('Total Workforce Deployed', '450 Men (Civil: 140, Piping: 180, Elec: 80, Inst: 45, HSE: 50)'),
                          _buildPdfMetaRow('Active Plant & Machinery', '18 Units Active (90% Fleet Utilization)'),
                          _buildPdfMetaRow('Material Received (GRN)', 'GRN-2026-08 (120 MT Steel Rebar Fe-550D)'),
                          _buildPdfMetaRow('Delays & Stoppages', 'Heavy rain 14:00 to 16:30 (2.5 hrs outdoor stoppage)'),
                          _buildPdfMetaRow('Safety & Health (HSE)', 'Zero Incidents. 450 attended Confined Space TBT @ 07:30 AM'),
                          _buildPdfMetaRow('Engineer Notes', _remarksController.text),

                          const SizedBox(height: 16),
                          const Text(
                            'Multi-Discipline Progress Summary (FIDIC Clause 4.21)',
                            style: TextStyle(
                              color: Color(0xFF0F2B5C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Table(
                            border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.8),
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text('Discipline', style: TextStyle(color: Color(0xFF334155), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text('Muster', style: TextStyle(color: Color(0xFF334155), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text('Lead Superintendent', style: TextStyle(color: Color(0xFF334155), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text('Key Activity Executed', style: TextStyle(color: Color(0xFF334155), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text('Progress', style: TextStyle(color: Color(0xFF334155), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              for (final disc in _disciplineRecords)
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(disc.title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 8.5, fontWeight: FontWeight.w600)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text('${disc.totalMen} Men', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 8.5)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(disc.superintendent.split('(').first.trim(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 8.5)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        disc.workItems.isNotEmpty
                                            ? '${disc.workItems.first.code}: ${disc.workItems.first.name} (${disc.workItems.first.todayActual} ${disc.workItems.first.unit})'
                                            : 'N/A',
                                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 8.5),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text('${disc.progressPct.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF059669), fontSize: 8.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          // Signatures & Cryptographic Verification Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('FIDIC RESIDENT ENGINEER (Clause 3.1):', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(_signatoryName, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.bold)),
                                        Text('License: $_licenseId', style: const TextStyle(color: Color(0xFF64748B), fontSize: 8.5)),
                                        const SizedBox(height: 4),
                                        if (_savedSignaturePoints.isNotEmpty)
                                          SizedBox(
                                            width: 140,
                                            height: 45,
                                            child: CustomPaint(
                                              painter: SignaturePainter(
                                                points: _savedSignaturePoints,
                                                strokeColor: const Color(0xFF0284C7),
                                                strokeWidth: 1.8,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('CONTRACTOR REPRESENTATIVE:', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(_contractorRep, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.bold)),
                                        const Text('Field Operations Division', style: TextStyle(color: Color(0xFF64748B), fontSize: 8.5)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: const Color(0xFF059669)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('CO-SIGNED & COUNTERSIGNED', style: TextStyle(color: Color(0xFF059669), fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(color: Color(0xFFE2E8F0), height: 1),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.fingerprint, color: Color(0xFF0284C7), size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Digital SHA-256 Stamp: ${_sha256Stamp ?? 'PENDING LOCK & SEAL'}',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          color: _sha256Stamp != null ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Export Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(color: AppTheme.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share PDF'),
                            onPressed: () {
                              Navigator.pop(bottomCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sharing formal FIDIC Site Diary PDF...'),
                                  backgroundColor: AppTheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Download PDF'),
                            onPressed: () {
                              Navigator.pop(bottomCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.surfaceCard,
                                  content: Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf, color: AppTheme.error, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Exported: OIL-FIDIC-SD-${DateFormat('yyyyMMdd').format(_diaryDate)}.pdf saved to downloads!',
                                          style: const TextStyle(color: AppTheme.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final project = provider.currentProject;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'FIDIC Daily Site Diary',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Clause 4.21 Contractor\'s Daily Progress Record',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isLocked ? AppTheme.tertiary.withAlpha(30) : AppTheme.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isLocked ? AppTheme.tertiary : AppTheme.secondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLocked ? Icons.verified : Icons.edit_note,
                      color: _isLocked ? AppTheme.tertiary : AppTheme.secondary,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isLocked ? 'SEALED & LOCKED' : 'DRAFT (LIVE)',
                      style: TextStyle(
                        color: _isLocked ? AppTheme.tertiary : AppTheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAllData(silent: true),
        color: AppTheme.primary,
        backgroundColor: AppTheme.surfaceCard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Header Card: Project, Date & Weather
            _buildOfficialHeaderCard(project),
            const SizedBox(height: 14),

            // 2. Summary KPI Ribbon
            _buildSummaryKpiRibbon(),
            const SizedBox(height: 14),

            // 3. Multi-Discipline Summary Tabs Section (Civil, Piping, Electrical, Instrumentation, HSE)
            _buildMultiDisciplineSection(),
            const SizedBox(height: 14),

            // 4. Plant & Equipment Operating (18 units active)
            _buildEquipmentSection(),
            const SizedBox(height: 14),

            // 5. Materials Received (GRN-2026-08: 120 MT Steel Rebar)
            _buildMaterialsSection(),
            const SizedBox(height: 14),

            // 6. Delays & Stoppages (Heavy rain 14:00 to 16:30)
            _buildDelaysSection(),
            const SizedBox(height: 14),

            // 7. Safety & HSE Status (Zero incidents & Tool Box Talk)
            _buildSafetySection(),
            const SizedBox(height: 14),

            // 8. Digital SHA-256 Stamp & Tamper-Proof Verification Box
            _buildDigitalStampBox(context, project),
            const SizedBox(height: 20),

            // 9. Action Buttons (Export Formal PDF & Lock and Sign)
            _buildActionButtons(context, project),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialHeaderCard(ProjectModel? project) {
    final clientName = project?.client ?? 'Oil India Limited';
    final projectName = project?.name ?? 'EPC Project Duliajan';
    final location = project?.location ?? 'Duliajan, Assam';
    final projectCode = project?.code ?? 'OIL-PL-024';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.surface.withAlpha(200),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withAlpha(120)),
                ),
                child: const Icon(Icons.account_balance, color: AppTheme.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$clientName - $projectName',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            projectCode,
                            style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          // Diary Date & Weather Card
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primaryLight, size: 18),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DIARY DATE',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy').format(_diaryDate),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132342),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.thunderstorm, color: Color(0xFF38BDF8), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'WEATHER CONDITIONS',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Rainy / 32°C',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.info_outline, color: AppTheme.textMuted, size: 12),
              SizedBox(width: 5),
              Text(
                '42 mm precipitation recorded | Humidity 88% | Barometer 1008 hPa',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryKpiRibbon() {
    return Row(
      children: [
        _buildQuickKpi('Workforce', '450 Men', '5 Disciplines', Icons.group, AppTheme.secondary),
        const SizedBox(width: 8),
        _buildQuickKpi('Equipment', '18 Units', 'Fleet Eff: 90%', Icons.precision_manufacturing, AppTheme.primaryLight),
        const SizedBox(width: 8),
        _buildQuickKpi('Stoppage', '2.5 hrs', 'FIDIC Cl. 8.4', Icons.schedule, Colors.orangeAccent),
        const SizedBox(width: 8),
        _buildQuickKpi('HSE Status', 'Zero LTI', '100% Safe', Icons.health_and_safety, AppTheme.tertiary),
      ],
    );
  }

  Widget _buildQuickKpi(String label, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // MULTI-DISCIPLINE SUMMARY TABS SECTION
  // ==========================================================================

  Widget _buildMultiDisciplineSection() {
    final selectedRecord = _disciplineRecords.firstWhere(
      (d) => d.type == _selectedDiscipline,
      orElse: () => _disciplineRecords.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & View Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.category, color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Multi-Discipline Daily Summary',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _showCrossDisciplineMatrix = !_showCrossDisciplineMatrix;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _showCrossDisciplineMatrix ? AppTheme.primary.withAlpha(40) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _showCrossDisciplineMatrix ? AppTheme.primaryLight : AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showCrossDisciplineMatrix ? Icons.tab : Icons.table_chart,
                        size: 13,
                        color: _showCrossDisciplineMatrix ? AppTheme.primaryLight : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showCrossDisciplineMatrix ? 'Tab View' : 'Compare All',
                        style: TextStyle(
                          color: _showCrossDisciplineMatrix ? AppTheme.primaryLight : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Discipline Tabs (Civil, Piping, Electrical, Instrumentation, HSE)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _disciplineRecords.map((record) {
                final isSelected = record.type == _selectedDiscipline;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDiscipline = record.type;
                        _showCrossDisciplineMatrix = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? record.color.withAlpha(35) : AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? record.color : AppTheme.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(record.icon, color: isSelected ? record.color : AppTheme.textMuted, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            record.type.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? record.color : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSelected ? record.color.withAlpha(50) : AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${record.totalMen}',
                              style: TextStyle(
                                color: isSelected ? record.color : AppTheme.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Main View (Selected Tab Deep-Dive vs Cross-Discipline Matrix)
          if (_showCrossDisciplineMatrix)
            _buildCrossDisciplineMatrix()
          else
            _buildDisciplineTabDetail(selectedRecord),
        ],
      ),
    );
  }

  Widget _buildDisciplineTabDetail(DisciplineRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Discipline Banner Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: record.color.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(color: record.color, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record.title,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: record.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${record.progressPct.toStringAsFixed(1)}% Overall Scope',
                      style: TextStyle(color: record.color, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Superintendent: ${record.superintendent}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                'Shift: ${record.shiftHours}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.orangeAccent, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.weatherImpact,
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Trade Muster Breakdown
        const Text(
          'Manpower Muster & Trade Breakdown',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: record.trades.map((trade) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${trade.count}',
                    style: TextStyle(color: record.color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trade.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(trade.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // Work Activities & WBS Execution
        const Text(
          'Activities & Quantities Executed Today',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Column(
          children: record.workItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: record.color.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: record.color.withAlpha(100)),
                            ),
                            child: Text(
                              item.code,
                              style: TextStyle(color: record.color, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.rfiCode,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                          ),
                        ],
                      ),
                      Text(
                        '${item.progressPct.toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today: ${item.todayActual} ${item.unit} (Target: ${item.todayTarget})',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
                      ),
                      Text(
                        'Total: ${item.cumulative.toStringAsFixed(0)} / ${item.totalScope.toStringAsFixed(0)} ${item.unit}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.progressPct / 100,
                      backgroundColor: AppTheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(record.color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 11, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(item.location, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        // Dedicated Machinery & Materials Consumed
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plant & Tools Deployed', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...record.machinery.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Icon(m.icon, size: 14, color: record.color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${m.count} • ${m.hours}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Materials Consumed', style: TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...record.materials.map((mat) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mat.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 1),
                            Text('Qty: ${mat.qty}', style: TextStyle(color: record.color, fontSize: 9.5, fontWeight: FontWeight.bold)),
                            Text(mat.qcStatus, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Quality RFIs & Inspections
        const Text(
          'Discipline Quality RFIs & Statutory Inspections',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        ...record.inspections.map((insp) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppTheme.tertiary, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(insp.code, style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(insp.result, style: const TextStyle(color: AppTheme.tertiary, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(insp.title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        Text('Standard: ${insp.standard}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCrossDisciplineMatrix() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.4),
          3: FlexColumnWidth(1.4),
          4: FlexColumnWidth(1.5),
        },
        border: TableBorder.all(color: AppTheme.border, width: 0.6),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppTheme.surface),
            children: const [
              Padding(padding: EdgeInsets.all(6), child: Text('Discipline', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(6), child: Text('Muster', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(6), child: Text('Man-hrs', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(6), child: Text('Progress', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(6), child: Text('Machinery', style: TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          for (final d in _disciplineRecords)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      Icon(d.icon, size: 12, color: d.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          d.title.split(' ').first,
                          style: TextStyle(color: d.color, fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.all(6), child: Text('${d.totalMen} Men', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${d.manHours} hrs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${d.progressPct.toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold))),
                Padding(padding: const EdgeInsets.all(6), child: Text('${d.machinery.length} Units', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
              ],
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EQUIPMENT, MATERIALS, DELAYS & SAFETY SECTIONS
  // ==========================================================================

  Widget _buildEquipmentSection() {
    return _buildSectionCard(
      title: 'Plant & Equipment Operating',
      badgeText: '18 Units Active',
      badgeColor: AppTheme.primaryLight,
      icon: Icons.precision_manufacturing,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '18 / 20 Heavy Machinery Operational',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Fleet Eff: 90%',
              style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildEquipmentRow('Hydraulic Excavator (CAT 320D)', '4 Units', '5.5 hrs running (2.5 hrs rain idle)', Icons.agriculture),
        _buildEquipmentRow('Crawler Crane 50T (Kobelco 7055)', '2 Units', '5.0 hrs pipe laying & trench placement', Icons.precision_manufacturing),
        _buildEquipmentRow('Diesel Welding Generator (Lincoln 400)', '6 Units', '7.0 hrs spool welding & joint prep', Icons.power),
        _buildEquipmentRow('Transit Concrete Mixer 6m³ (Tata Signa)', '3 Units', '4.5 hrs foundation pour batching', Icons.local_shipping),
        _buildEquipmentRow('Trench Compactor / Roller (Dynapac)', '2 Units', '4.0 hrs bedding compaction', Icons.car_repair),
        _buildEquipmentRow('Wheel Loader (JCB 432ZX)', '1 Unit', '6.0 hrs aggregate handling', Icons.construction),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: const [
              Icon(Icons.local_gas_station, color: AppTheme.secondary, size: 14),
              SizedBox(width: 6),
              Text(
                'Total High-Speed Diesel (HSD) consumed today: 940 Litres',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentRow(String name, String count, String remarks, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryLight, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  Text(remarks, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                count,
                style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return _buildSectionCard(
      title: 'Materials Received',
      badgeText: 'GRN Logged',
      badgeColor: AppTheme.tertiary,
      icon: Icons.inventory_2,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.tertiary.withAlpha(120)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.receipt_long, color: AppTheme.tertiary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'GRN-2026-08',
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'QC Approved & Cleared',
                      style: TextStyle(color: AppTheme.tertiary, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '120 MT Steel Rebar (Fe-550D TMT)',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Diameter: 16mm, 20mm, 25mm | Standard: IS 1786 | PO Ref: PO-OIL-2026-881',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Supplier: Tata Steel Ltd. / SAIL', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                  Text('Heat No: #HT-884192', style: TextStyle(color: AppTheme.primaryLight, fontSize: 10.5, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Store Location: Central Yard 3 (Bar Bending Shed) | MTC Lab Verified',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDelaysSection() {
    return _buildSectionCard(
      title: 'Delays & Stoppages',
      badgeText: 'FIDIC Cl. 8.4 Candidate',
      badgeColor: AppTheme.secondary,
      icon: Icons.timer_off,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF261914),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withAlpha(120)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.cloud_sync, color: Colors.orangeAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Heavy Rain Event (Force Majeure / Weather)',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '2.5 Hours Stoppage',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Heavy rain from 14:00 to 16:30 (2.5 hrs outdoor stoppage)',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Rainfall gauge logged 42mm precipitation. Soil saturation in pipeline trench sector 4 caused temporary standing water. Outdoor welding and pipe lower-in halted for safety.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'FIDIC Contractual Impact (Clause 8.4c / 20.1):',
                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '• Stoppage recorded in official daily record for potential Extension of Time (EoT).\n• 320 outdoor personnel safely redeployed to covered spool prefabrication workshop.\n• Dewatering pumps mobilized at 16:45.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetySection() {
    return _buildSectionCard(
      title: 'Safety & HSE Status',
      badgeText: 'Zero Harm',
      badgeColor: AppTheme.tertiary,
      icon: Icons.health_and_safety,
      children: [
        Row(
          children: [
            _buildSafetyMetric('LTI', '0', AppTheme.tertiary),
            const SizedBox(width: 8),
            _buildSafetyMetric('Medical Cases', '0', AppTheme.tertiary),
            const SizedBox(width: 8),
            _buildSafetyMetric('First Aid', '0', AppTheme.tertiary),
            const SizedBox(width: 8),
            _buildSafetyMetric('Near Miss', '0', AppTheme.tertiary),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.record_voice_over, color: AppTheme.primaryLight, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Tool Box Talk (TBT) Conducted',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Text('07:30 AM', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Topic: Confined Space Safety & Multi-Gas Testing Procedures',
                style: TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Conducted by Subhash Roy (HSE Chief Officer). Covered multi-gas detectors (O₂, H₂S, LEL, CO), tripod rescue winches, and ventilation protocols. Total attendees: 450 (100% muster attendance).',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.shield, color: AppTheme.tertiary, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Active Permits: PTW-HW-941 (Hot Work) & PTW-CS-204 (Confined Space Valve Pit 3)',
                    style: TextStyle(color: AppTheme.tertiary, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyMetric(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // DIGITAL SHA-256 STAMP & TAMPER-PROOF VERIFICATION CARD
  // ==========================================================================

  Widget _buildDigitalStampBox(BuildContext context, ProjectModel? project) {
    return Container(
      decoration: BoxDecoration(
        color: _isLocked ? const Color(0xFF0B291E) : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isLocked ? AppTheme.tertiary : AppTheme.border,
          width: _isLocked ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isLocked ? Icons.verified : Icons.lock_outline,
                    color: _isLocked ? AppTheme.tertiary : AppTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLocked ? 'FIDIC CLAUSE 4.21 DIGITALLY SEALED' : 'DIGITAL AUDIT & STAMP',
                    style: TextStyle(
                      color: _isLocked ? AppTheme.tertiary : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (_isLocked && _signedAt != null)
                Text(
                  DateFormat('HH:mm:ss IST').format(_signedAt!),
                  style: const TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLocked && _sha256Stamp != null) ...[
            // Digital Signature Visual Rendering
            if (_savedSignaturePoints.isNotEmpty) ...[
              Container(
                height: 80,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.tertiary.withAlpha(70)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        painter: SignaturePainter(
                          points: _savedSignaturePoints,
                          strokeColor: const Color(0xFF34D399),
                          strokeWidth: 2.2,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiary.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('SEAL APPLIED', style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _licenseId,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // SHA-256 Hash Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.tertiary.withAlpha(90)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IMMUTABLE CRYPTOGRAPHIC HASH (SHA-256):',
                          style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          _sha256Stamp!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppTheme.tertiary, size: 18),
                    tooltip: 'Copy Hash',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _sha256Stamp!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SHA-256 fingerprint copied to clipboard!'),
                          backgroundColor: AppTheme.primary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.verified_user, color: AppTheme.tertiary, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Signed by: $_signatoryName & $_contractorRep',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.tertiary,
                      side: const BorderSide(color: AppTheme.tertiary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.verified, size: 15),
                    label: const Text('Verify Integrity', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: _verifyTamperProofIntegrity,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tertiary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.workspace_premium, size: 15, color: Colors.black),
                    label: const Text('View Certificate', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: _showCertificateModal,
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'This Site Diary is currently in draft mode. Upon multi-discipline review by the Resident Engineer and Contractor Representative, click "Sign & Seal Site Diary" below to execute digital signature confirmation and generate the SHA-256 tamper-proof seal.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProjectModel? project) {
    return Column(
      children: [
        Row(
          children: [
            // Export Formal PDF
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceCard,
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.primary, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryLight, size: 18),
                label: const Text(
                  'Export Formal PDF',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                onPressed: () => _showPdfExportModal(context, project),
              ),
            ),
            const SizedBox(width: 12),
            // Lock & Sign with Digital SHA-256 Stamp
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLocked ? const Color(0xFF0F766E) : AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  _isLocked ? Icons.verified : Icons.lock_clock,
                  size: 18,
                ),
                label: Text(
                  _isLocked ? 'Sealed & Locked' : 'Sign & Seal Diary',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                onPressed: () => _openSignAndSealModal(context, project),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryLight, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withAlpha(100)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
