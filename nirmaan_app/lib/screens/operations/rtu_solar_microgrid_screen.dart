import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// DATA MODELS & ENUMS — IEEE 1547 / IEC 61427 SOLAR MICROGRID & SCADA RTU
// ============================================================================

/// Microgrid Power Routing & Operational Mode
enum MicrogridOperatingMode {
  solarActiveCharging, // Solar PV supplying loads and charging battery
  batteryDischarging,  // Night or overcast: battery bank supplying DC bus
  dgAutoRunning,       // AMF triggered: DG running on load, rapid charging
  hybridFloat,         // Battery at 100%, solar floating the DC bus
  emergencyIslanded,   // IEEE 1547 anti-islanding / fault isolation
}

/// RTU Hardware Model installed at Sectionalizing Valve Station
enum RtuControllerModel {
  abbRtu560,
  schneiderScadaPack357E,
  emersonControlWave,
}

/// Autonomy Compliance Status under IEC 61427 (72-hour No-Sun Standard)
enum AutonomyStatus {
  compliant, // >= 72.0 hours reserve
  marginal,  // 48.0 - 71.9 hours reserve
  critical,  // < 48.0 hours reserve
}

/// Diesel Generator AMF Controller State
enum DgSkidState {
  standbyAuto,
  cranking,
  runningOnLoad,
  cooldown,
  faultLockout,
}

/// Cell Voltage Balancing Status
enum CellBalanceState {
  optimal,
  balancingActive,
  overvoltageWarning,
  undervoltageWarning,
}

/// Individual LiFePO4 Cell Telemetry Model (16S Configuration)
class BatteryCellData {
  final int cellNumber; // 1 to 16
  final double voltage; // e.g., 3.325 V (Nominal: 3.2V, Max: 3.65V, Min: 2.5V)
  final double internalResistanceMilliOhm; // e.g., 0.45 mΩ
  final double temperatureCelsius; // e.g., 28.4 °C
  final bool isBalancing; // Active shunt/bleeding circuit active

  const BatteryCellData({
    required this.cellNumber,
    required this.voltage,
    required this.internalResistanceMilliOhm,
    required this.temperatureCelsius,
    this.isBalancing = false,
  });

  CellBalanceState get state {
    if (voltage > 3.60) return CellBalanceState.overvoltageWarning;
    if (voltage < 2.90) return CellBalanceState.undervoltageWarning;
    if (isBalancing) return CellBalanceState.balancingActive;
    return CellBalanceState.optimal;
  }

  Color get stateColor {
    switch (state) {
      case CellBalanceState.optimal:
        return const Color(0xFF4EDEA3); // Tertiary green
      case CellBalanceState.balancingActive:
        return const Color(0xFF38BDF8); // Primary light blue
      case CellBalanceState.overvoltageWarning:
        return const Color(0xFFFFB4AB); // Error pink/red
      case CellBalanceState.undervoltageWarning:
        return const Color(0xFFFFB95F); // Amber secondary
    }
  }

  String get stateLabel {
    switch (state) {
      case CellBalanceState.optimal:
        return 'BALANCED';
      case CellBalanceState.balancingActive:
        return 'ACTIVE SHUNT';
      case CellBalanceState.overvoltageWarning:
        return 'HIGH VOLT';
      case CellBalanceState.undervoltageWarning:
        return 'LOW VOLT';
    }
  }
}

/// Solar MPPT Controller Telemetry
class MpptTelemetryData {
  final double pvOpenCircuitVoltageVoc; // V (String Voc, e.g. 102.4 V)
  final double pvShortCircuitCurrentIsc; // A
  final double pvOperatingVoltageVmp; // V (MPPT tracking voltage, e.g. 82.6 V)
  final double pvOperatingCurrentImp; // A (e.g. 36.8 A)
  final double solarIrradianceWm2; // W/m² (Pyranometer reading, e.g. 885 W/m²)
  final double ambientTempCelsius; // °C
  final double moduleTempCelsius; // °C
  final double conversionEfficiencyPercent; // e.g. 98.4 %
  final double dailyYieldKwh; // kWh produced today
  final double peakPowerWatts; // Peak watts recorded today
  final String trackingAlgorithm; // e.g., 'Perturb & Observe (P&O)'
  final String stage; // 'Bulk MPPT', 'Absorption', 'Float', 'Equalization'

  const MpptTelemetryData({
    required this.pvOpenCircuitVoltageVoc,
    required this.pvShortCircuitCurrentIsc,
    required this.pvOperatingVoltageVmp,
    required this.pvOperatingCurrentImp,
    required this.solarIrradianceWm2,
    required this.ambientTempCelsius,
    required this.moduleTempCelsius,
    required this.conversionEfficiencyPercent,
    required this.dailyYieldKwh,
    required this.peakPowerWatts,
    this.trackingAlgorithm = 'Adaptive Perturb & Observe (P&O)',
    this.stage = 'Bulk MPPT',
  });

  double get arrayPowerWatts => pvOperatingVoltageVmp * pvOperatingCurrentImp;
}

/// 72-Hour No-Sun Autonomy Calculation Breakdown
class AutonomyCalculationResult {
  final double totalNominalCapacityKwh; // e.g. 30.72 kWh (48V * 640Ah)
  final double usableDodPercent; // e.g. 85.0% for LiFePO4
  final double currentSoCPercent; // e.g. 88.5%
  final double usableRemainingKwh; // e.g. 23.1 kWh
  final double continuousLoadWatts; // e.g. 280 W
  final double reserveHoursRemaining; // e.g. 82.5 hrs
  final double requiredReserveHours; // 72.0 hrs standard
  final AutonomyStatus status;

  const AutonomyCalculationResult({
    required this.totalNominalCapacityKwh,
    required this.usableDodPercent,
    required this.currentSoCPercent,
    required this.usableRemainingKwh,
    required this.continuousLoadWatts,
    required this.reserveHoursRemaining,
    this.requiredReserveHours = 72.0,
    required this.status,
  });

  double get surplusDeficitHours => reserveHoursRemaining - requiredReserveHours;

  Color get statusColor {
    switch (status) {
      case AutonomyStatus.compliant:
        return const Color(0xFF4EDEA3);
      case AutonomyStatus.marginal:
        return const Color(0xFFFFB95F);
      case AutonomyStatus.critical:
        return const Color(0xFFFFB4AB);
    }
  }

  String get statusTitle {
    switch (status) {
      case AutonomyStatus.compliant:
        return 'IEC 61427 COMPLIANT (>=72H)';
      case AutonomyStatus.marginal:
        return 'AUTONOMY MARGINAL (<72H)';
      case AutonomyStatus.critical:
        return 'CRITICAL DEFICIT (<48H)';
    }
  }
}

/// Emergency Diesel Generator (DG) Skid & Fuel Telemetry
class DgSkidTelemetry {
  final String modelName;
  final String amfController;
  final DgSkidState state;
  final double fuelTankCapacityLitres;
  final double fuelCurrentLitres;
  final double fuelBurnRateLitrePerHour; // e.g. 2.1 L/h @ load
  final double oilPressureBar; // e.g. 3.8 bar
  final double coolantTempCelsius; // e.g. 82.5 °C
  final double engineSpeedRpm; // e.g. 1500 RPM @ 50Hz
  final double frequencyHz; // e.g. 50.1 Hz
  final double outputVoltageVac; // e.g. 232 V
  final double starterBatteryVoltage; // e.g. 25.4 V (24V system)
  final double totalRunHours; // e.g. 142.5 hrs
  final String lastAutoExerciseTimestamp;
  final bool fuelTheftAlarm;

  const DgSkidTelemetry({
    required this.modelName,
    required this.amfController,
    required this.state,
    required this.fuelTankCapacityLitres,
    required this.fuelCurrentLitres,
    required this.fuelBurnRateLitrePerHour,
    required this.oilPressureBar,
    required this.coolantTempCelsius,
    required this.engineSpeedRpm,
    required this.frequencyHz,
    required this.outputVoltageVac,
    required this.starterBatteryVoltage,
    required this.totalRunHours,
    required this.lastAutoExerciseTimestamp,
    this.fuelTheftAlarm = false,
  });

  double get fuelPercentage =>
      (fuelCurrentLitres / fuelTankCapacityLitres * 100.0).clamp(0.0, 100.0);

  double get autonomousRunHours => fuelBurnRateLitrePerHour > 0
      ? (fuelCurrentLitres / fuelBurnRateLitrePerHour)
      : 0.0;

  Color get stateColor {
    switch (state) {
      case DgSkidState.standbyAuto:
        return const Color(0xFF38BDF8);
      case DgSkidState.cranking:
        return const Color(0xFFFFB95F);
      case DgSkidState.runningOnLoad:
        return const Color(0xFF4EDEA3);
      case DgSkidState.cooldown:
        return const Color(0xFF94A3B8);
      case DgSkidState.faultLockout:
        return const Color(0xFFFFB4AB);
    }
  }

  String get stateLabel {
    switch (state) {
      case DgSkidState.standbyAuto:
        return 'AUTO STANDBY';
      case DgSkidState.cranking:
        return 'CRANKING';
      case DgSkidState.runningOnLoad:
        return 'RUNNING ON LOAD';
      case DgSkidState.cooldown:
        return 'COOLDOWN';
      case DgSkidState.faultLockout:
        return 'FAULT LOCKOUT';
    }
  }
}

/// Critical DC Loads Model (RTU, Satellite Transceiver, Actuator Motor)
class DcSubsystemsTelemetry {
  final RtuControllerModel rtuModel;
  final String rtuFirmware;
  final double rtuPowerWatts; // e.g. 42 W
  final double rtuDcVoltage; // e.g. 24.1 V (via DC-DC converter)
  final String satelliteTransceiverModel; // e.g. Hughes 9502 BGAN Satellite Modem
  final double satRssiDbm; // e.g. -76 dBm
  final double satPowerWatts; // e.g. 24 W
  final String valveActuatorTag; // e.g. 24"-ESDV-0101
  final String actuatorType; // 'Rotork IQT3 48V DC Electro-Hydraulic'
  final double actuatorPositionPercent; // 100.0% (Fully Open)
  final double actuatorStandbyWatts; // e.g. 35 W
  final double actuatorPeakStrokeCurrentAmps; // e.g. 42.5 A (during stroke)
  final double cathodicProtectionTelemetryWatts; // e.g. 28 W
  final double gasDetectorWatts; // e.g. 18 W

  const DcSubsystemsTelemetry({
    required this.rtuModel,
    required this.rtuFirmware,
    required this.rtuPowerWatts,
    required this.rtuDcVoltage,
    required this.satelliteTransceiverModel,
    required this.satRssiDbm,
    required this.satPowerWatts,
    required this.valveActuatorTag,
    required this.actuatorType,
    required this.actuatorPositionPercent,
    required this.actuatorStandbyWatts,
    required this.actuatorPeakStrokeCurrentAmps,
    required this.cathodicProtectionTelemetryWatts,
    required this.gasDetectorWatts,
  });

  double get totalQuiescentWatts =>
      rtuPowerWatts +
      satPowerWatts +
      actuatorStandbyWatts +
      cathodicProtectionTelemetryWatts +
      gasDetectorWatts;

  String get rtuModelName {
    switch (rtuModel) {
      case RtuControllerModel.abbRtu560:
        return 'ABB RTU560 (IEC 60870-5-104 / DNP3)';
      case RtuControllerModel.schneiderScadaPack357E:
        return 'Schneider SCADAPack 357E (Modbus TCP/IP)';
      case RtuControllerModel.emersonControlWave:
        return 'Emerson ControlWave Micro Dual-Port';
    }
  }
}

/// Comprehensive Sectionalizing Valve Station Microgrid Model
class SvMicrogridStation {
  final String stationId; // SV-01 to SV-08
  final String stationName;
  final double chainageKm;
  final String coordinates;
  final MicrogridOperatingMode operatingMode;
  final double bus48vVoltage; // e.g. 52.4 V
  final double bus24vVoltage; // e.g. 24.1 V
  final double busTotalCurrentAmps; // e.g. 5.8 A
  final double batterySoCPercent; // e.g. 88.5%
  final double batterySoHPercent; // e.g. 97.4%
  final double batteryCurrentAmps; // Positive: charging, Negative: discharging
  final double batteryCapacityAh; // e.g. 640 Ah
  final double batteryNominalKwh; // e.g. 30.72 kWh
  final MpptTelemetryData mppt;
  final List<BatteryCellData> cells; // 16S cells
  final DcSubsystemsTelemetry dcLoads;
  final DgSkidTelemetry dgSkid;

  const SvMicrogridStation({
    required this.stationId,
    required this.stationName,
    required this.chainageKm,
    required this.coordinates,
    required this.operatingMode,
    required this.bus48vVoltage,
    required this.bus24vVoltage,
    required this.busTotalCurrentAmps,
    required this.batterySoCPercent,
    required this.batterySoHPercent,
    required this.batteryCurrentAmps,
    required this.batteryCapacityAh,
    required this.batteryNominalKwh,
    required this.mppt,
    required this.cells,
    required this.dcLoads,
    required this.dgSkid,
  });

  // Calculate cell voltage delta (max - min) in millivolts
  double get cellDeltaMillivolts {
    if (cells.isEmpty) return 0.0;
    double minV = cells.first.voltage;
    double maxV = cells.first.voltage;
    for (final c in cells) {
      if (c.voltage < minV) minV = c.voltage;
      if (c.voltage > maxV) maxV = c.voltage;
    }
    return (maxV - minV) * 1000.0;
  }

  // Calculate average cell internal resistance
  double get avgInternalResistanceMilliOhm {
    if (cells.isEmpty) return 0.0;
    final sum = cells.fold<double>(0.0, (acc, c) => acc + c.internalResistanceMilliOhm);
    return sum / cells.length;
  }

  // Calculate 72-Hour Autonomy Calculation
  AutonomyCalculationResult calculateAutonomy() {
    const double usableDod = 0.85; // 85% DoD
    final double continuousW = dcLoads.totalQuiescentWatts + 30.0; // include converter losses
    final double remainingKwh = batteryNominalKwh * (batterySoCPercent / 100.0) * usableDod;
    final double reserveHours = (remainingKwh * 1000.0) / math.max(continuousW, 10.0);

    AutonomyStatus status = AutonomyStatus.compliant;
    if (reserveHours < 48.0) {
      status = AutonomyStatus.critical;
    } else if (reserveHours < 72.0) {
      status = AutonomyStatus.marginal;
    }

    return AutonomyCalculationResult(
      totalNominalCapacityKwh: batteryNominalKwh,
      usableDodPercent: usableDod * 100.0,
      currentSoCPercent: batterySoCPercent,
      usableRemainingKwh: remainingKwh,
      continuousLoadWatts: continuousW,
      reserveHoursRemaining: reserveHours,
      status: status,
    );
  }

  Color get modeColor {
    switch (operatingMode) {
      case MicrogridOperatingMode.solarActiveCharging:
        return const Color(0xFF4EDEA3);
      case MicrogridOperatingMode.batteryDischarging:
        return const Color(0xFF38BDF8);
      case MicrogridOperatingMode.dgAutoRunning:
        return const Color(0xFFFFB95F);
      case MicrogridOperatingMode.hybridFloat:
        return const Color(0xFF0284C7);
      case MicrogridOperatingMode.emergencyIslanded:
        return const Color(0xFFFFB4AB);
    }
  }

  String get modeLabel {
    switch (operatingMode) {
      case MicrogridOperatingMode.solarActiveCharging:
        return 'SOLAR MPPT ACTIVE';
      case MicrogridOperatingMode.batteryDischarging:
        return 'BATTERY DISCHARGING';
      case MicrogridOperatingMode.dgAutoRunning:
        return 'DG RUNNING ON LOAD';
      case MicrogridOperatingMode.hybridFloat:
        return 'FLOAT TRICKLE';
      case MicrogridOperatingMode.emergencyIslanded:
        return 'ISLANDED DEFENSE';
    }
  }
}

// ============================================================================
// REPOSITORY / SEED DATA FOR ALL 8 SECTIONALIZING VALVE STATIONS
// ============================================================================

class RtuSolarMicrogridRepository {
  static List<SvMicrogridStation> getStations() {
    return [
      _buildStation(
        id: 'SV-01',
        name: 'Tingkhong SV Station',
        km: 24.6,
        coords: '27.1892° N, 95.1245° E',
        mode: MicrogridOperatingMode.solarActiveCharging,
        bus48V: 53.2,
        bus24V: 24.1,
        busAmps: 5.6,
        soc: 88.5,
        soh: 98.2,
        batAmps: 32.4, // charging
        batAh: 640.0,
        batKwh: 30.72,
        voc: 104.8,
        isc: 44.5,
        vmp: 84.6,
        imp: 40.2,
        irradiance: 890.0,
        ambientT: 31.5,
        moduleT: 48.2,
        eff: 98.6,
        yieldKwh: 26.4,
        peakW: 3410.0,
        rtu: RtuControllerModel.abbRtu560,
        fw: 'v12.4.8-IEC104',
        dgState: DgSkidState.standbyAuto,
        fuelL: 260.0,
        fuelCap: 300.0,
        valveTag: '24"-ESDV-0101',
        actuatorType: 'Rotork IQT3 48V DC Electro-Hydraulic',
        cellBaseV: 3.325,
        cellSpreadMv: 14.0,
      ),
      _buildStation(
        id: 'SV-02',
        name: 'Moran Junction SV Station',
        km: 52.3,
        coords: '27.1420° N, 94.9280° E',
        mode: MicrogridOperatingMode.solarActiveCharging,
        bus48V: 52.8,
        bus24V: 24.0,
        busAmps: 6.2,
        soc: 84.0,
        soh: 97.6,
        batAmps: 28.5,
        batAh: 640.0,
        batKwh: 30.72,
        voc: 102.5,
        isc: 42.0,
        vmp: 83.2,
        imp: 37.8,
        irradiance: 845.0,
        ambientT: 32.0,
        moduleT: 49.5,
        eff: 98.4,
        yieldKwh: 24.1,
        peakW: 3280.0,
        rtu: RtuControllerModel.schneiderScadaPack357E,
        fw: 'v3.7.2-DNP3',
        dgState: DgSkidState.standbyAuto,
        fuelL: 245.0,
        fuelCap: 300.0,
        valveTag: '24"-ESDV-0201',
        actuatorType: 'Limitorque MX40 48V DC Solid State',
        cellBaseV: 3.310,
        cellSpreadMv: 18.0,
      ),
      _buildStation(
        id: 'SV-03',
        name: 'Demow Bypass SV Station',
        km: 88.7,
        coords: '27.0850° N, 94.7430° E',
        mode: MicrogridOperatingMode.hybridFloat,
        bus48V: 54.4,
        bus24V: 24.2,
        busAmps: 4.8,
        soc: 99.2,
        soh: 98.8,
        batAmps: 2.1, // trickle float
        batAh: 640.0,
        batKwh: 30.72,
        voc: 106.2,
        isc: 45.0,
        vmp: 85.5,
        imp: 41.5,
        irradiance: 920.0,
        ambientT: 30.8,
        moduleT: 47.1,
        eff: 98.9,
        yieldKwh: 29.8,
        peakW: 3550.0,
        rtu: RtuControllerModel.abbRtu560,
        fw: 'v12.4.8-IEC104',
        dgState: DgSkidState.standbyAuto,
        fuelL: 285.0,
        fuelCap: 300.0,
        valveTag: '24"-ESDV-0301',
        actuatorType: 'Rotork IQT3 48V DC Electro-Hydraulic',
        cellBaseV: 3.340,
        cellSpreadMv: 9.0,
      ),
      _buildStation(
        id: 'SV-04',
        name: 'Sivasagar Town SV Station',
        km: 116.2,
        coords: '26.9826° N, 94.6425° E',
        mode: MicrogridOperatingMode.batteryDischarging,
        bus48V: 50.8,
        bus24V: 23.9,
        busAmps: 6.5,
        soc: 71.4,
        soh: 96.1,
        batAmps: -6.5, // discharging (overcast)
        batAh: 640.0,
        batKwh: 30.72,
        voc: 68.4,
        isc: 12.0,
        vmp: 54.2,
        imp: 4.8,
        irradiance: 180.0, // heavy cloud
        ambientT: 27.2,
        moduleT: 29.0,
        eff: 96.2,
        yieldKwh: 11.2,
        peakW: 1850.0,
        rtu: RtuControllerModel.schneiderScadaPack357E,
        fw: 'v3.7.2-DNP3',
        dgState: DgSkidState.standbyAuto,
        fuelL: 215.0,
        fuelCap: 300.0,
        valveTag: '24"-ESDV-0401',
        actuatorType: 'Limitorque MX40 48V DC Solid State',
        cellBaseV: 3.265,
        cellSpreadMv: 24.0,
      ),
      _buildStation(
        id: 'SV-05',
        name: 'Jorhat North SV Station',
        km: 144.8,
        coords: '26.7509° N, 94.2037° E',
        mode: MicrogridOperatingMode.solarActiveCharging,
        bus48V: 53.0,
        bus24V: 24.1,
        busAmps: 5.9,
        soc: 86.8,
        soh: 97.9,
        batAmps: 30.1,
        batAh: 640.0,
        batKwh: 30.72,
        voc: 103.4,
        isc: 43.8,
        vmp: 84.1,
        imp: 39.5,
        irradiance: 875.0,
        ambientT: 31.0,
        moduleT: 48.0,
        eff: 98.5,
        yieldKwh: 25.6,
        peakW: 3340.0,
        rtu: RtuControllerModel.abbRtu560,
        fw: 'v12.4.8-IEC104',
        dgState: DgSkidState.standbyAuto,
        fuelL: 255.0,
        fuelCap: 300.0,
        valveTag: '24"-ESDV-0501',
        actuatorType: 'Rotork IQT3 48V DC Electro-Hydraulic',
        cellBaseV: 3.320,
        cellSpreadMv: 12.0,
      ),
      _buildStation(
        id: 'SV-06',
        name: 'Dergaon Highway SV Station',
        km: 168.1,
        coords: '26.7020° N, 93.9720° E',
        mode: MicrogridOperatingMode.dgAutoRunning,
        bus48V: 54.0,
        bus24V: 24.2,
        busAmps: 8.4,
        soc: 48.2, // low SoC triggered DG AMF
        soh: 95.8,
        batAmps: 45.0, // fast charge via DG rectifier
        batAh: 640.0,
        batKwh: 30.72,
        voc: 32.0,
        isc: 4.0,
        vmp: 24.0,
        imp: 2.1,
        irradiance: 85.0, // monsoonal storm
        ambientT: 25.5,
        moduleT: 26.2,
        eff: 94.0,
        yieldKwh: 4.8,
        peakW: 950.0,
        rtu: RtuControllerModel.emersonControlWave,
        fw: 'v4.1.0-DNP3',
        dgState: DgSkidState.runningOnLoad,
        fuelL: 198.0,
        fuelCap: 300.0,
        valveTag: '24"-ESDV-0601',
        actuatorType: 'Rotork IQT3 48V DC Electro-Hydraulic',
        cellBaseV: 3.220,
        cellSpreadMv: 28.0,
      ),
      _buildStation(
        id: 'SV-07',
        name: 'Bokakhat Border SV Station',
        km: 182.4,
        coords: '26.6345° N, 93.5932° E',
        mode: MicrogridOperatingMode.solarActiveCharging,
        bus48V: 53.1,
        bus24V: 24.0,
        busAmps: 5.4,
        soc: 91.0,
        soh: 98.4,
        batAmps: 34.0,
        batAh: 640.0,
        batKwh: 30.72,
        voc: 105.1,
        isc: 44.2,
        vmp: 84.8,
        imp: 40.5,
        irradiance: 905.0,
        ambientT: 31.8,
        moduleT: 49.0,
        eff: 98.7,
        yieldKwh: 27.9,
        peakW: 3450.0,
        rtu: RtuControllerModel.abbRtu560,
        fw: 'v12.4.8-IEC104',
        dgState: DgSkidState.standbyAuto,
        fuelL: 270.0,
        fuelCap: 300.0,
        valveTag: '24"-ESDV-0701',
        actuatorType: 'Rotork IQT3 48V DC Electro-Hydraulic',
        cellBaseV: 3.330,
        cellSpreadMv: 11.0,
      ),
      _buildStation(
        id: 'SV-08',
        name: 'Numaligarh Terminal SV Station',
        km: 194.5,
        coords: '26.5810° N, 93.7540° E',
        mode: MicrogridOperatingMode.solarActiveCharging,
        bus48V: 53.4,
        bus24V: 24.1,
        busAmps: 5.7,
        soc: 93.5,
        soh: 99.0,
        batAmps: 35.8,
        batAh: 640.0,
        batKwh: 30.72,
        voc: 105.5,
        isc: 44.9,
        vmp: 85.0,
        imp: 40.8,
        irradiance: 915.0,
        ambientT: 32.2,
        moduleT: 49.8,
        eff: 98.8,
        yieldKwh: 28.5,
        peakW: 3480.0,
        rtu: RtuControllerModel.abbRtu560,
        fw: 'v12.4.8-IEC104',
        dgState: DgSkidState.standbyAuto,
        fuelL: 280.0,
        fuelCap: 300.0,
        valveTag: '24"-ESDV-0801',
        actuatorType: 'Rotork IQT3 48V DC Electro-Hydraulic',
        cellBaseV: 3.335,
        cellSpreadMv: 10.0,
      ),
    ];
  }

  static SvMicrogridStation _buildStation({
    required String id,
    required String name,
    required double km,
    required String coords,
    required MicrogridOperatingMode mode,
    required double bus48V,
    required double bus24V,
    required double busAmps,
    required double soc,
    required double soh,
    required double batAmps,
    required double batAh,
    required double batKwh,
    required double voc,
    required double isc,
    required double vmp,
    required double imp,
    required double irradiance,
    required double ambientT,
    required double moduleT,
    required double eff,
    required double yieldKwh,
    required double peakW,
    required RtuControllerModel rtu,
    required String fw,
    required DgSkidState dgState,
    required double fuelL,
    required double fuelCap,
    required String valveTag,
    required String actuatorType,
    required double cellBaseV,
    required double cellSpreadMv,
  }) {
    // Generate 16S LiFePO4 cells around base voltage
    final List<BatteryCellData> cellList = [];
    final random = math.Random(id.hashCode);

    for (int i = 1; i <= 16; i++) {
      final double offset = ((random.nextDouble() - 0.5) * cellSpreadMv) / 1000.0;
      final double v = double.parse((cellBaseV + offset).toStringAsFixed(3));
      final double ir = double.parse((0.42 + (random.nextDouble() * 0.16)).toStringAsFixed(2));
      final double temp = double.parse((ambientT - 3.5 + (random.nextDouble() * 2.0)).toStringAsFixed(1));
      // Cell 7 or 12 active balancing if spread > 15mV
      final bool isBal = (cellSpreadMv > 15.0) && (i == 4 || i == 11);

      cellList.add(
        BatteryCellData(
          cellNumber: i,
          voltage: v,
          internalResistanceMilliOhm: ir,
          temperatureCelsius: temp,
          isBalancing: isBal,
        ),
      );
    }

    return SvMicrogridStation(
      stationId: id,
      stationName: name,
      chainageKm: km,
      coordinates: coords,
      operatingMode: mode,
      bus48vVoltage: bus48V,
      bus24vVoltage: bus24V,
      busTotalCurrentAmps: busAmps,
      batterySoCPercent: soc,
      batterySoHPercent: soh,
      batteryCurrentAmps: batAmps,
      batteryCapacityAh: batAh,
      batteryNominalKwh: batKwh,
      mppt: MpptTelemetryData(
        pvOpenCircuitVoltageVoc: voc,
        pvShortCircuitCurrentIsc: isc,
        pvOperatingVoltageVmp: vmp,
        pvOperatingCurrentImp: imp,
        solarIrradianceWm2: irradiance,
        ambientTempCelsius: ambientT,
        moduleTempCelsius: moduleT,
        conversionEfficiencyPercent: eff,
        dailyYieldKwh: yieldKwh,
        peakPowerWatts: peakW,
      ),
      cells: cellList,
      dcLoads: DcSubsystemsTelemetry(
        rtuModel: rtu,
        rtuFirmware: fw,
        rtuPowerWatts: 42.0,
        rtuDcVoltage: bus24V,
        satelliteTransceiverModel: 'Hughes 9502 BGAN Satellite Modem (L-Band)',
        satRssiDbm: -74.0,
        satPowerWatts: 22.0,
        valveActuatorTag: valveTag,
        actuatorType: actuatorType,
        actuatorPositionPercent: 100.0,
        actuatorStandbyWatts: 35.0,
        actuatorPeakStrokeCurrentAmps: 38.5,
        cathodicProtectionTelemetryWatts: 26.0,
        gasDetectorWatts: 16.0,
      ),
      dgSkid: DgSkidTelemetry(
        modelName: 'Kirloskar Green 12.5 kVA Silent DG Skid',
        amfController: 'Deep Sea DSE 7320 MKII AMF Controller',
        state: dgState,
        fuelTankCapacityLitres: fuelCap,
        fuelCurrentLitres: fuelL,
        fuelBurnRateLitrePerHour: 2.1,
        oilPressureBar: dgState == DgSkidState.runningOnLoad ? 3.9 : 0.0,
        coolantTempCelsius: dgState == DgSkidState.runningOnLoad ? 84.5 : 28.0,
        engineSpeedRpm: dgState == DgSkidState.runningOnLoad ? 1500.0 : 0.0,
        frequencyHz: dgState == DgSkidState.runningOnLoad ? 50.1 : 0.0,
        outputVoltageVac: dgState == DgSkidState.runningOnLoad ? 232.0 : 0.0,
        starterBatteryVoltage: 25.4,
        totalRunHours: 142.8,
        lastAutoExerciseTimestamp: '2026-09-27 10:00 IST',
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN WIDGET
// ============================================================================

class RtuSolarMicrogridScreen extends StatefulWidget {
  const RtuSolarMicrogridScreen({super.key});

  @override
  State<RtuSolarMicrogridScreen> createState() => _RtuSolarMicrogridScreenState();
}

class _RtuSolarMicrogridScreenState extends State<RtuSolarMicrogridScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<SvMicrogridStation> _stations;
  late int _selectedStationIndex;

  // Real-time animation pulse simulation
  Timer? _telemetryTimer;
  double _flowAnimTick = 0.0;

  // DG Crank Test state
  bool _isCrankingDg = false;
  int _crankingCountdown = 0;
  Timer? _crankingTimer;

  // ESD Valve Stroke Test state
  bool _isPstInProgress = false;
  double _pstProgress = 0.0;
  Timer? _pstTimer;

  // Proper initState override
  @override
  // ignore: must_call_super
  void initState() {
    super.initState();
    _stations = RtuSolarMicrogridRepository.getStations();
    _selectedStationIndex = 0;
    _tabController = TabController(length: 5, vsync: this);

    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _flowAnimTick = (_flowAnimTick + 0.1) % 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _telemetryTimer?.cancel();
    _crankingTimer?.cancel();
    _pstTimer?.cancel();
    super.dispose();
  }

  SvMicrogridStation get currentStation => _stations[_selectedStationIndex];

  void _triggerDgCrankTest() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        title: Row(
          children: const [
            Icon(Icons.power_settings_new_rounded, color: AppTheme.secondary),
            SizedBox(width: 8),
            Text(
              'Initiate DG Auto-Exercise',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Station: ${currentStation.stationId} — ${currentStation.stationName}',
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This test commands the Deep Sea DSE 7320 AMF controller to execute a 15-second unloaded cranking and engine spin-up sequence to verify starter battery cranking amps (CCA), fuel solenoid response, and alternator excitation voltage.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_gas_station_rounded,
                      color: AppTheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fuel Tank Level: ${currentStation.dgSkid.fuelCurrentLitres.toStringAsFixed(0)} L (${currentStation.dgSkid.fuelPercentage.toStringAsFixed(1)}%) — OK to crank',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _startDgCrankSequence();
            },
            child: const Text('START DG CRANK TEST'),
          ),
        ],
      ),
    );
  }

  void _startDgCrankSequence() {
    setState(() {
      _isCrankingDg = true;
      _crankingCountdown = 15;
    });

    _crankingTimer?.cancel();
    _crankingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_crankingCountdown <= 1) {
        timer.cancel();
        setState(() {
          _isCrankingDg = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceCard,
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppTheme.tertiary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DG Auto-Exercise completed successfully. AMF engine telemetry logged to audit trail.',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _crankingCountdown--;
        });
      }
    });
  }

  void _triggerPstStrokeTest() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        title: Row(
          children: const [
            Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 8),
            Text(
              'Partial Stroke Test (PST)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actuator: ${currentStation.dcLoads.valveActuatorTag} (${currentStation.dcLoads.actuatorType})',
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The Partial Stroke Test commands a 10% valve travel movement (100% -> 90% -> 100%) to verify actuator break-away torque without disrupting pipeline gas throughput. Battery 48V DC bus sag will be captured.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppTheme.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Peak Inrush Allowance: ${currentStation.dcLoads.actuatorPeakStrokeCurrentAmps}A @ 48V DC. Current SoC: ${currentStation.batterySoCPercent}%',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _startPstExecution();
            },
            child: const Text('EXECUTE PST STROKE'),
          ),
        ],
      ),
    );
  }

  void _startPstExecution() {
    setState(() {
      _isPstInProgress = true;
      _pstProgress = 0.0;
    });

    _pstTimer?.cancel();
    _pstTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) return;
      if (_pstProgress >= 1.0) {
        timer.cancel();
        setState(() {
          _isPstInProgress = false;
          _pstProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceCard,
            content: Row(
              children: const [
                Icon(Icons.verified_rounded, color: AppTheme.tertiary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PST Stroke Verified: Actuator response 4.2 sec, Peak 38.2A, 48V DC bus sag <0.8V. Valve 100% OPEN.',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _pstProgress = math.min(1.0, _pstProgress + 0.1);
        });
      }
    });
  }

  void _showExportReportDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        title: Row(
          children: const [
            Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 8),
            Text(
              'Export IEEE/IEC Telemetry Audit',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Station: ${currentStation.stationId} (${currentStation.stationName})',
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Generate an engineering telemetry compliance certificate containing IEEE 1547 anti-islanding parameters, IEC 61427 72-hour autonomy calculations, MPPT string yields, 16S LiFePO4 cell balance logs, and DG fuel reservoir audit.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report Format: PDF / Vector CAD SLD / CSV Dump',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('Digital Signature: Chief SCADA Telemetry Engineer',
                      style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 11)),
                  const SizedBox(height: 4),
                  const Text('Target Autonomy: 72.0 Hours No-Sun (Compliant)',
                      style: TextStyle(color: AppTheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.surfaceCard,
                  content: Text(
                    'IEEE 1547 / IEC 61427 Telemetry Report for ${currentStation.stationId} generated successfully.',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ),
              );
            },
            child: const Text('GENERATE PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final station = currentStation;
    final autonomy = station.calculateAutonomy();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'RTU & Solar Microgrid',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: station.modeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: station.modeColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    station.modeLabel,
                    style: TextStyle(
                      color: station.modeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'IEEE 1547 / IEC 61427 — Remote SV Stations Telemetry',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export Audit Report',
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.textPrimary),
            onPressed: _showExportReportDialog,
          ),
          IconButton(
            tooltip: 'Live Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
            onPressed: () {
              setState(() {
                HapticFeedback.lightImpact();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 1),
                  backgroundColor: AppTheme.surfaceCard,
                  content: Text('Polling live SCADA RTU & MPPT telemetry modbus registers...'),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              _buildStationSelectorBar(),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryLight,
                indicatorWeight: 3,
                labelColor: AppTheme.primaryLight,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'SLD Microgrid Flow'),
                  Tab(text: 'PV & MPPT Telemetry'),
                  Tab(text: '16S LiFePO4 & 72h Autonomy'),
                  Tab(text: 'RTU & DC Subsystems'),
                  Tab(text: 'Emergency DG & Fuel Skid'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isCrankingDg) _buildDgCrankingBanner(),
          if (_isPstInProgress) _buildPstBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSldOverviewTab(station, autonomy),
                _buildPvMpptTab(station),
                _buildBatteryAutonomyTab(station, autonomy),
                _buildRtuSubsystemsTab(station),
                _buildDgSkidTab(station),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TOP BANNERS & STATION SELECTOR
  // --------------------------------------------------------------------------

  Widget _buildDgCrankingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.secondary.withOpacity(0.2),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'DG AUTO-EXERCISE IN PROGRESS: Cranking engine... $_crankingCountdown s remaining',
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPstBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primary.withOpacity(0.25),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ESDV PARTIAL STROKE TEST (PST) ACTIVE: Moving valve... ${(_pstProgress * 100).toInt()}%',
              style: const TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationSelectorBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = _stations[index];
          final isSelected = index == _selectedStationIndex;
          return Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                setState(() {
                  _selectedStationIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryLight : AppTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.modeColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.stationId,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Km ${s.chainageKm.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: SLD MICROGRID FLOW & OVERVIEW
  // --------------------------------------------------------------------------

  Widget _buildSldOverviewTab(SvMicrogridStation station, AutonomyCalculationResult autonomy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Identity Header Card
          _buildStationInfoCard(station),
          const SizedBox(height: 16),

          // Key Industrial KPI Strip
          _buildKeyKpiStrip(station, autonomy),
          const SizedBox(height: 16),

          // Single Line Diagram (SLD) Visualizer Card
          _buildSingleLineDiagramCard(station),
          const SizedBox(height: 16),

          // Microgrid Quick Actions
          _buildQuickActionButtons(station),
          const SizedBox(height: 16),

          // Dual DC Bus Voltage Distribution Card
          _buildDcBusDistributionCard(station),
        ],
      ),
    );
  }

  Widget _buildStationInfoCard(SvMicrogridStation station) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryLight.withOpacity(0.4)),
                  ),
                  child: const Icon(
                    Icons.solar_power_rounded,
                    color: AppTheme.primaryLight,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            station.stationId,
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              station.stationName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chainage: Km ${station.chainageKm.toStringAsFixed(1)} | GPS: ${station.coordinates}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoSubItem(
                  'RTU Controller',
                  station.dcLoads.rtuModelName.split('(').first.trim(),
                  Icons.developer_board_rounded,
                ),
                _buildInfoSubItem(
                  'Actuator Motor',
                  station.dcLoads.valveActuatorTag,
                  Icons.settings_suggest_rounded,
                ),
                _buildInfoSubItem(
                  'Emergency DG',
                  station.dgSkid.modelName.split(' ').first,
                  Icons.power_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSubItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyKpiStrip(SvMicrogridStation station, AutonomyCalculationResult autonomy) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'LiFePO4 SoC',
            value: '${station.batterySoCPercent.toStringAsFixed(1)}%',
            subtitle: '${station.batteryCapacityAh.toInt()} Ah / 48V',
            icon: Icons.battery_charging_full_rounded,
            color: station.batterySoCPercent > 50 ? AppTheme.tertiary : AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'PV Generation',
            value: '${station.mppt.arrayPowerWatts.toStringAsFixed(0)} W',
            subtitle: '${station.mppt.solarIrradianceWm2.toStringAsFixed(0)} W/m²',
            icon: Icons.wb_sunny_rounded,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: '72h Autonomy',
            value: '${autonomy.reserveHoursRemaining.toStringAsFixed(0)} hrs',
            subtitle: autonomy.status == AutonomyStatus.compliant ? 'COMPLIANT' : 'DEFICIT',
            icon: Icons.timer_rounded,
            color: autonomy.statusColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'DG Fuel Tank',
            value: '${station.dgSkid.fuelPercentage.toStringAsFixed(0)}%',
            subtitle: '${station.dgSkid.fuelCurrentLitres.toStringAsFixed(0)} L',
            icon: Icons.local_gas_station_rounded,
            color: AppTheme.primaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SINGLE LINE DIAGRAM (SLD) VISUALIZER
  // --------------------------------------------------------------------------

  Widget _buildSingleLineDiagramCard(SvMicrogridStation station) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_rounded, color: AppTheme.primaryLight, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Microgrid Single-Line Diagram (SLD)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Text(
                    'IEEE 1547.4 MICROGRID',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animated Visual Flow representation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  // Row 1: Generation Sources (Solar PV Array & Diesel Generator)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Solar PV Node
                      _buildSldNode(
                        title: 'SOLAR PV ARRAY',
                        subtitle: '${station.mppt.arrayPowerWatts.toStringAsFixed(0)}W (${station.mppt.pvOperatingVoltageVmp.toStringAsFixed(1)}V)',
                        icon: Icons.solar_power_rounded,
                        color: AppTheme.secondary,
                        isActive: station.mppt.arrayPowerWatts > 100,
                      ),
                      // Directional Arrow down to MPPT
                      Column(
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            color: station.mppt.arrayPowerWatts > 100
                                ? AppTheme.secondary
                                : AppTheme.textMuted,
                            size: 20,
                          ),
                          Text(
                            'MPPT: ${station.mppt.stage}',
                            style: TextStyle(
                              color: AppTheme.secondary.withOpacity(0.9),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Emergency DG Skid Node
                      _buildSldNode(
                        title: 'EMERGENCY DG',
                        subtitle: station.dgSkid.stateLabel,
                        icon: Icons.power_rounded,
                        color: station.dgSkid.stateColor,
                        isActive: station.dgSkid.state == DgSkidState.runningOnLoad,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Central Bus Bar Representation
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryLight, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MAIN 48V DC BUSBAR',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${station.bus48vVoltage.toStringAsFixed(1)} V DC | ${station.busTotalCurrentAmps.toStringAsFixed(1)} A',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Energy Storage and Subsystem Loads
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // LiFePO4 Battery Bank Node
                      _buildSldNode(
                        title: '16S LiFePO4 BANK',
                        subtitle: '${station.batterySoCPercent.toStringAsFixed(1)}% SoC (${station.batteryCurrentAmps >= 0 ? "+${station.batteryCurrentAmps.toStringAsFixed(1)}A" : "${station.batteryCurrentAmps.toStringAsFixed(1)}A"})',
                        icon: Icons.battery_charging_full_rounded,
                        color: AppTheme.tertiary,
                        isActive: true,
                      ),

                      // DC/DC Converter Bridge Node
                      Column(
                        children: const [
                          Icon(Icons.swap_vert_rounded, color: AppTheme.primaryLight, size: 20),
                          Text(
                            '48V -> 24V DC/DC',
                            style: TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Critical SCADA RTU & Actuator Loads
                      _buildSldNode(
                        title: 'SCADA RTU & LOADS',
                        subtitle: '${station.dcLoads.totalQuiescentWatts.toStringAsFixed(0)}W Quiescent',
                        icon: Icons.settings_remote_rounded,
                        color: AppTheme.primaryLight,
                        isActive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSldNode({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : AppTheme.border,
          width: isActive ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? color : AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(SvMicrogridStation station) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceCard,
              foregroundColor: AppTheme.primaryLight,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.settings_suggest_rounded, size: 18),
            label: const Text('VALVE PST TEST'),
            onPressed: _triggerPstStrokeTest,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceCard,
              foregroundColor: AppTheme.secondary,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.power_settings_new_rounded, size: 18),
            label: const Text('DG TEST CRANK'),
            onPressed: _triggerDgCrankTest,
          ),
        ),
      ],
    );
  }

  Widget _buildDcBusDistributionCard(SvMicrogridStation station) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DC Power Distribution Subsystem',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Redundant DC-DC converters feeding SCADA RTU, VSAT satellite, and ESD valve actuator.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Primary 48V DC Bus',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${station.bus48vVoltage.toStringAsFixed(2)} V',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Feeds Actuator & MPPT Charger',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Regulated 24V DC Bus',
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${station.bus24vVoltage.toStringAsFixed(2)} V',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Feeds RTU, VSAT & CP Telemetry',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
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
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: SOLAR PV & MPPT CHARGE CONTROLLER (IEEE 1547)
  // --------------------------------------------------------------------------

  Widget _buildPvMpptTab(SvMicrogridStation station) {
    final mppt = station.mppt;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IEEE 1547 Header Card
          _buildIeeeStandardBadge(),
          const SizedBox(height: 16),

          // Primary MPPT Telemetry Cards Grid
          _buildMpptGrid(mppt),
          const SizedBox(height: 16),

          // Pyranometer Irradiance & Thermal Derating Gauge
          _buildIrradianceThermalCard(mppt),
          const SizedBox(height: 16),

          // Hourly Solar Yield & Irradiance Chart (fl_chart)
          _buildSolarYieldChartCard(station),
          const SizedBox(height: 16),

          // MPPT Algorithm & PV String Technical Specs
          _buildPvStringSpecsCard(mppt),
        ],
      ),
    );
  }

  Widget _buildIeeeStandardBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.4)),
      ),
      child: Row(
        children: const [
          Icon(Icons.verified_rounded, color: AppTheme.secondary, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IEEE 1547 Distributed Energy Interoperability Standard',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Off-grid PV-battery hybrid system with MPPT Perturb & Observe, anti-islanding isolation, and reverse-polarity diode protection.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMpptGrid(MpptTelemetryData mppt) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTelemetryDataCard(
                title: 'PV Open-Circuit Voc',
                value: '${mppt.pvOpenCircuitVoltageVoc.toStringAsFixed(1)} V',
                subtext: 'Isc: ${mppt.pvShortCircuitCurrentIsc.toStringAsFixed(1)} A',
                icon: Icons.flash_on_rounded,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelemetryDataCard(
                title: 'MPPT Tracking Vmp',
                value: '${mppt.pvOperatingVoltageVmp.toStringAsFixed(1)} V',
                subtext: 'Imp: ${mppt.pvOperatingCurrentImp.toStringAsFixed(1)} A',
                icon: Icons.track_changes_rounded,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTelemetryDataCard(
                title: 'Conversion Efficiency',
                value: '${mppt.conversionEfficiencyPercent.toStringAsFixed(1)}%',
                subtext: 'Stage: ${mppt.stage}',
                icon: Icons.speed_rounded,
                color: AppTheme.tertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelemetryDataCard(
                title: 'Daily Solar Yield',
                value: '${mppt.dailyYieldKwh.toStringAsFixed(1)} kWh',
                subtext: 'Peak: ${mppt.peakPowerWatts.toStringAsFixed(0)} W',
                icon: Icons.energy_savings_leaf_rounded,
                color: AppTheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryDataCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrradianceThermalCard(MpptTelemetryData mppt) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: AppTheme.secondary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pyranometer Solar Irradiance & Module Thermal Derating',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Visual Progress Indicator for Solar Irradiance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Plane-of-Array (POA) Irradiance',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    Text(
                      '${mppt.solarIrradianceWm2.toStringAsFixed(0)} W/m² (1000 W/m² STC)',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (mppt.solarIrradianceWm2 / 1000.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppTheme.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Temperatures comparison
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ambient Air Temp',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          '${mppt.ambientTempCelsius.toStringAsFixed(1)} °C',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PV Module Backsheet',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          '${mppt.moduleTempCelsius.toStringAsFixed(1)} °C',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thermal Loss Derate',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          '-${((mppt.moduleTempCelsius - 25.0).clamp(0.0, 50.0) * 0.35).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
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
    );
  }

  Widget _buildSolarYieldChartCard(SvMicrogridStation station) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppTheme.primaryLight, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '24-Hour Solar Yield & Generation Curve',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Solar power generation (W) vs Irradiance from 06:00 to 18:00 IST.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 18),

            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.border.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 3,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          return Text(
                            '$hour:00',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 1000,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppTheme.border),
                  ),
                  minX: 6,
                  maxX: 18,
                  minY: 0,
                  maxY: 4000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(6, 0),
                        FlSpot(7, 240),
                        FlSpot(8, 850),
                        FlSpot(9, 1850),
                        FlSpot(10, 2750),
                        FlSpot(11, 3350),
                        FlSpot(12, 3500),
                        FlSpot(13, 3420),
                        FlSpot(14, 2900),
                        FlSpot(15, 2100),
                        FlSpot(16, 1200),
                        FlSpot(17, 350),
                        FlSpot(18, 0),
                      ],
                      isCurved: true,
                      color: AppTheme.secondary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.secondary.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPvStringSpecsCard(MpptTelemetryData mppt) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PV String & Inverter Hardware Specifications',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecRow('Solar Array Configuration', '12x 450W Monocrystalline PERC (3S4P)'),
            _buildSpecRow('Total Installed Capacity', '5.4 kWp Rated Peak PV'),
            _buildSpecRow('MPPT Tracking Algorithm', mppt.trackingAlgorithm),
            _buildSpecRow('DC Voltage Operating Window', '36V to 150V DC (160V Max Voc)'),
            _buildSpecRow('Surge & Lightning Protection', 'Class II SPD 40kA with Optical Isolation'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: highlightColor ?? AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: 16S LiFePO4 BATTERY & 72H AUTONOMY (IEC 61427)
  // --------------------------------------------------------------------------

  Widget _buildBatteryAutonomyTab(SvMicrogridStation station, AutonomyCalculationResult autonomy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 72-Hour No-Sun Autonomy Calculation Engine Card
          _buildAutonomyCalculationCard(station, autonomy),
          const SizedBox(height: 16),

          // 16S LiFePO4 Cell Voltage Balancing Grid
          _build16sBalancingGridCard(station),
          const SizedBox(height: 16),

          // Battery Health, Internal Resistance & C-Rate Specs
          _buildBatteryHealthSpecsCard(station),
        ],
      ),
    );
  }

  Widget _buildAutonomyCalculationCard(SvMicrogridStation station, AutonomyCalculationResult autonomy) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: autonomy.statusColor.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_rounded, color: autonomy.statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        autonomy.statusTitle,
                        style: TextStyle(
                          color: autonomy.statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'IEC 61427 Photovoltaic Energy Storage 72-Hour No-Sun Reserve Standard',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Autonomy Hours Progress Visualizer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reserve Time Remaining:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  '${autonomy.reserveHoursRemaining.toStringAsFixed(1)} Hours (${(autonomy.reserveHoursRemaining / 24.0).toStringAsFixed(1)} Days)',
                  style: TextStyle(
                    color: autonomy.statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (autonomy.reserveHoursRemaining / 96.0).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppTheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(autonomy.statusColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0h', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                Text('48h (Threshold)', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                Text('72h (IEC Standard)', style: TextStyle(color: AppTheme.tertiary, fontSize: 9, fontWeight: FontWeight.bold)),
                Text('96h Max', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 14),

            // Detailed calculation breakdown formula container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildCalcDetailRow('Total Installed Bank Energy', '${autonomy.totalNominalCapacityKwh.toStringAsFixed(2)} kWh (48V / ${station.batteryCapacityAh.toInt()}Ah)'),
                  _buildCalcDetailRow('Usable Depth of Discharge (DoD)', '${autonomy.usableDodPercent.toStringAsFixed(0)}% LiFePO4 Reserve Floor'),
                  _buildCalcDetailRow('Current Usable Energy Left', '${autonomy.usableRemainingKwh.toStringAsFixed(2)} kWh'),
                  _buildCalcDetailRow('Continuous Station Load', '${autonomy.continuousLoadWatts.toStringAsFixed(0)} W (RTU + VSAT + CP + Actuator)'),
                  const Divider(color: AppTheme.border, height: 12),
                  _buildCalcDetailRow(
                    'Autonomy Surplus Margin',
                    autonomy.surplusDeficitHours >= 0
                        ? '+${autonomy.surplusDeficitHours.toStringAsFixed(1)} hrs above 72h requirement'
                        : '${autonomy.surplusDeficitHours.toStringAsFixed(1)} hrs deficit below 72h',
                    highlightColor: autonomy.statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcDetailRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: highlightColor ?? AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build16sBalancingGridCard(SvMicrogridStation station) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: AppTheme.primaryLight, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '16S LiFePO4 Cell Voltage Balancing Matrix',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Cell Spread (ΔV): ${station.cellDeltaMillivolts.toStringAsFixed(1)} mV',
                  style: TextStyle(
                    color: station.cellDeltaMillivolts > 30 ? AppTheme.secondary : AppTheme.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Target ΔV: < 25 mV',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 16 Cells in 4x4 Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.15,
              ),
              itemCount: station.cells.length,
              itemBuilder: (context, index) {
                final cell = station.cells[index];
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cell.isBalancing ? AppTheme.primaryLight : AppTheme.border,
                      width: cell.isBalancing ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'C${cell.cellNumber}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (cell.isBalancing)
                            const Icon(
                              Icons.tune_rounded,
                              size: 10,
                              color: AppTheme.primaryLight,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cell.voltage.toStringAsFixed(3)}V',
                        style: TextStyle(
                          color: cell.stateColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cell.internalResistanceMilliOhm.toStringAsFixed(2)}mΩ',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryHealthSpecsCard(SvMicrogridStation station) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Battery Health & Electrochemical Parameters',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecRow('State of Health (SoH)', '${station.batterySoHPercent.toStringAsFixed(1)}% (Cycle count: 482 / 4000)'),
            _buildSpecRow('Pack Configuration', '16S2P LiFePO4 (3.2V / 320Ah prismatic cells)'),
            _buildSpecRow('Average Internal Resistance', '${station.avgInternalResistanceMilliOhm.toStringAsFixed(2)} mΩ / cell'),
            _buildSpecRow('Continuous Discharge C-Rate', '0.05C Quiescent / 0.15C Actuator Stroke'),
            _buildSpecRow('BMS Protection Protocol', 'Over-voltage, Under-voltage & High Temp Cutoff'),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 4: RTU & DC SUBSYSTEMS (ABB RTU560 / SCADAPack / Actuator)
  // --------------------------------------------------------------------------

  Widget _buildRtuSubsystemsTab(SvMicrogridStation station) {
    final dc = station.dcLoads;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SCADA RTU Controller Telemetry Card
          _buildRtuControllerCard(dc),
          const SizedBox(height: 16),

          // Mainline Sectionalizing Valve (ESDV) & Actuator Card
          _buildValveActuatorCard(dc),
          const SizedBox(height: 16),

          // Satellite Modem & Communications Card
          _buildSatelliteCommsCard(dc),
          const SizedBox(height: 16),

          // Critical Instrumentation & Auxiliary Loads
          _buildAuxiliaryLoadsCard(dc),
        ],
      ),
    );
  }

  Widget _buildRtuControllerCard(DcSubsystemsTelemetry dc) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory_rounded, color: AppTheme.primaryLight, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dc.rtuModelName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Firmware: ${dc.rtuFirmware} | SCADA Polling: 1.0 sec cycle',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.tertiary.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'ONLINE',
                    style: TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RTU Power Draw',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          '${dc.rtuPowerWatts.toStringAsFixed(0)} W',
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DC Bus Input',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          '${dc.rtuDcVoltage.toStringAsFixed(1)} V DC',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
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
    );
  }

  Widget _buildValveActuatorCard(DcSubsystemsTelemetry dc) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_suggest_rounded, color: AppTheme.secondary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sectionalizing Valve: ${dc.valveActuatorTag}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dc.actuatorType,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.tertiary.withOpacity(0.4)),
                  ),
                  child: const Text(
                    '100% OPEN',
                    style: TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSpecRow('Standby Power Draw', '${dc.actuatorStandbyWatts.toStringAsFixed(0)} W (Quiescent)'),
            _buildSpecRow('Peak Motor Inrush Current', '${dc.actuatorPeakStrokeCurrentAmps.toStringAsFixed(1)} A @ 48V DC'),
            _buildSpecRow('Stroke Travel Time (Full)', '18.4 seconds (Class 600 Ball Valve)'),
            _buildSpecRow('Emergency Shutdown (ESD)', 'Spring-Return / DC Solenoid Assisted'),
          ],
        ),
      ),
    );
  }

  Widget _buildSatelliteCommsCard(DcSubsystemsTelemetry dc) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.satellite_alt_rounded, color: AppTheme.primaryLight, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dc.satelliteTransceiverModel,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Continuous SCADA BGAN Uplink to Central Control Room',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSpecRow('Signal Strength (RSSI)', '${dc.satRssiDbm.toStringAsFixed(0)} dBm (Locked)'),
            _buildSpecRow('Transceiver Power Consumption', '${dc.satPowerWatts.toStringAsFixed(0)} W DC'),
            _buildSpecRow('Fallback Redundancy', 'Dual SIM 4G LTE Router with IPSec Tunnel'),
          ],
        ),
      ),
    );
  }

  Widget _buildAuxiliaryLoadsCard(DcSubsystemsTelemetry dc) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instrumentation & Security Auxiliary Loads',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecRow('Cathodic Protection Potential Monitor', '${dc.cathodicProtectionTelemetryWatts.toStringAsFixed(0)} W'),
            _buildSpecRow('Point Infrared Methane Gas Detector', '${dc.gasDetectorWatts.toStringAsFixed(0)} W'),
            _buildSpecRow('Station Perimeter Laser Beam Sensor', '14 W'),
            const Divider(color: AppTheme.border, height: 16),
            _buildSpecRow(
              'Total Station Quiescent Load',
              '${dc.totalQuiescentWatts.toStringAsFixed(0)} W Continuous',
              highlightColor: AppTheme.primaryLight,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 5: EMERGENCY DIESEL GENERATOR & AUTOMATED FUEL SKID
  // --------------------------------------------------------------------------

  Widget _buildDgSkidTab(SvMicrogridStation station) {
    final dg = station.dgSkid;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DG AMF State Header Card
          _buildDgAmfHeaderCard(dg),
          const SizedBox(height: 16),

          // Automated Fuel Tank Level & Autonomous Runtime Card
          _buildFuelTankLevelCard(dg),
          const SizedBox(height: 16),

          // Engine & Alternator Operating Telemetry
          _buildEngineOperatingTelemetryCard(dg),
          const SizedBox(height: 16),

          // Auto-Exercise & Cranking Test Trigger Card
          _buildDgExerciseCard(station, dg),
        ],
      ),
    );
  }

  Widget _buildDgAmfHeaderCard(DgSkidTelemetry dg) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: dg.stateColor.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: dg.stateColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.power_rounded, color: dg.stateColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dg.modelName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AMF Controller: ${dg.amfController}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dg.stateColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: dg.stateColor),
              ),
              child: Text(
                dg.stateLabel,
                style: TextStyle(
                  color: dg.stateColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelTankLevelCard(DgSkidTelemetry dg) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_gas_station_rounded, color: AppTheme.secondary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Automated Diesel Fuel Reservoir Telemetry',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Fuel Level Gauge Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tank Capacity (Magnetostrictive Sensor):',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  '${dg.fuelCurrentLitres.toStringAsFixed(0)} L / ${dg.fuelTankCapacityLitres.toStringAsFixed(0)} L (${dg.fuelPercentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (dg.fuelPercentage / 100.0).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: AppTheme.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fuel Burn Rate',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          '${dg.fuelBurnRateLitrePerHour.toStringAsFixed(1)} L/hr',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Continuous DG Runtime',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          '${dg.autonomousRunHours.toStringAsFixed(0)} Hours',
                          style: const TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 14,
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
    );
  }

  Widget _buildEngineOperatingTelemetryCard(DgSkidTelemetry dg) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engine & Alternator Telemetry (AMF Modbus)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecRow('Lube Oil Pressure', '${dg.oilPressureBar.toStringAsFixed(1)} bar (Normal: 3.5 - 4.5 bar)'),
            _buildSpecRow('Engine Coolant Temperature', '${dg.coolantTempCelsius.toStringAsFixed(1)} °C'),
            _buildSpecRow('Engine Speed', '${dg.engineSpeedRpm.toStringAsFixed(0)} RPM @ ${dg.frequencyHz.toStringAsFixed(1)} Hz'),
            _buildSpecRow('Alternator Voltage Output', '${dg.outputVoltageVac.toStringAsFixed(0)} V AC (Rectified to 48V DC)'),
            _buildSpecRow('DG Starter Battery Voltage', '${dg.starterBatteryVoltage.toStringAsFixed(1)} V (24V Lead-Acid)'),
            _buildSpecRow('Total Cumulative Engine Hours', '${dg.totalRunHours.toStringAsFixed(1)} hrs'),
          ],
        ),
      ),
    );
  }

  Widget _buildDgExerciseCard(SvMicrogridStation station, DgSkidTelemetry dg) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.secondary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Automated Periodic Exercise Scheduler',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Last automated exercise run: ${dg.lastAutoExerciseTimestamp}. Deep Sea AMF conducts a 15-minute weekly unloaded test crank to prevent fuel varnish and verify starter battery health.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('MANUAL DG EXERCISE CRANK'),
                onPressed: _triggerDgCrankTest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
