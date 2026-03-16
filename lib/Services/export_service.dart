import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _quarterFromDate(DateTime? date) {
    if (date == null) return '';
    if (date.month >= 1 && date.month <= 3) return 'Q1';
    if (date.month >= 4 && date.month <= 6) return 'Q2';
    if (date.month >= 7 && date.month <= 9) return 'Q3';
    return 'Q4';
  }

  static bool _matchesQuarterFromDate(DateTime? date, String selectedQuarter) {
    if (selectedQuarter == 'All') return true;
    return _quarterFromDate(date) == selectedQuarter;
  }

  static bool _matchesQuarterFromValue(
    String? quarter,
    String selectedQuarter,
  ) {
    if (selectedQuarter == 'All') return true;
    return (quarter ?? '') == selectedQuarter;
  }

  static bool _matchesUnit(String? unitNumber, String selectedUnit) {
    if (selectedUnit == 'All') return true;
    return (unitNumber ?? '') == selectedUnit;
  }

  static bool _matchesState(String? state, String selectedState) {
    if (selectedState == 'All') return true;
    return (state ?? '').toUpperCase() == selectedState;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$day/$year';
  }

  static Future<void> exportQuarterReport({
    required String selectedQuarter,
    required String selectedUnit,
    required String selectedState,
  }) async {
    final fuelSnapshot = await FirebaseFirestore.instance
        .collection('fuel_entries')
        .get();

    final tripSnapshot = await FirebaseFirestore.instance
        .collection('trip_entries')
        .get();

    final odometerSnapshot = await FirebaseFirestore.instance
        .collection('quarterly_odometers')
        .get();

    final fuelDocs = fuelSnapshot.docs.where((doc) {
      final data = doc.data();
      final date = _readDate(data['date']);
      final unitNumber = (data['unitNumber'] ?? '').toString();
      final state = (data['state'] ?? '').toString().toUpperCase();

      return _matchesQuarterFromDate(date, selectedQuarter) &&
          _matchesUnit(unitNumber, selectedUnit) &&
          _matchesState(state, selectedState);
    }).toList();

    final tripDocs = tripSnapshot.docs.where((doc) {
      final data = doc.data();
      final date = _readDate(data['date']);
      final unitNumber = (data['unitNumber'] ?? '').toString();
      final state = (data['state'] ?? '').toString().toUpperCase();

      return _matchesQuarterFromDate(date, selectedQuarter) &&
          _matchesUnit(unitNumber, selectedUnit) &&
          _matchesState(state, selectedState);
    }).toList();

    final odometerDocs = odometerSnapshot.docs.where((doc) {
      final data = doc.data();
      final quarter = (data['quarter'] ?? '').toString();
      final unitNumber = (data['unitNumber'] ?? data['unit'] ?? '').toString();

      return _matchesQuarterFromValue(quarter, selectedQuarter) &&
          _matchesUnit(unitNumber, selectedUnit);
    }).toList();

    double totalGallons = 0;
    for (final doc in fuelDocs) {
      totalGallons += ((doc.data()['gallons'] ?? 0) as num).toDouble();
    }

    double totalOutOfStateMiles = 0;
    for (final doc in tripDocs) {
      totalOutOfStateMiles += ((doc.data()['miles'] ?? 0) as num).toDouble();
    }

    double totalQuarterMiles = 0;
    for (final doc in odometerDocs) {
      final data = doc.data();
      final begin =
          ((data['quarterBeginningOdometer'] ?? data['begin'] ?? 0) as num)
              .toDouble();
      final end = ((data['quarterEndingOdometer'] ?? data['end'] ?? 0) as num)
          .toDouble();
      totalQuarterMiles += (end - begin);
    }

    final arkansasMilesRaw = totalQuarterMiles - totalOutOfStateMiles;
    final arkansasMiles = arkansasMilesRaw < 0 ? 0.0 : arkansasMilesRaw;

    final Map<String, double> milesByState = {};
    for (final doc in tripDocs) {
      final state = (doc.data()['state'] ?? '').toString().toUpperCase();
      final miles = ((doc.data()['miles'] ?? 0) as num).toDouble();
      milesByState[state] = (milesByState[state] ?? 0) + miles;
    }

    if (selectedState == 'All' || selectedState == 'AR') {
      milesByState['AR'] = (milesByState['AR'] ?? 0) + arkansasMiles;
    }

    final Map<String, double> fuelByState = {};
    for (final doc in fuelDocs) {
      final state = (doc.data()['state'] ?? '').toString().toUpperCase();
      final gallons = ((doc.data()['gallons'] ?? 0) as num).toDouble();
      fuelByState[state] = (fuelByState[state] ?? 0) + gallons;
    }

    final combinedStates = <String>{
      ...milesByState.keys,
      ...fuelByState.keys,
    }.toList()..sort();

    final overallMiles = milesByState.values.fold<double>(0, (a, b) => a + b);
    final overallGallons = fuelByState.values.fold<double>(0, (a, b) => a + b);
    final overallMpg = overallGallons == 0
        ? 0.0
        : overallMiles / overallGallons;

    final excel = Excel.createExcel();

    final summarySheet = excel['Summary'];
    summarySheet.appendRow([TextCellValue('Filter'), TextCellValue('Value')]);
    summarySheet.appendRow([
      TextCellValue('Quarter'),
      TextCellValue(selectedQuarter),
    ]);
    summarySheet.appendRow([
      TextCellValue('Unit'),
      TextCellValue(selectedUnit),
    ]);
    summarySheet.appendRow([
      TextCellValue('State'),
      TextCellValue(selectedState),
    ]);
    summarySheet.appendRow([]);
    summarySheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    summarySheet.appendRow([
      TextCellValue('Total Quarter Miles'),
      DoubleCellValue(totalQuarterMiles),
    ]);
    summarySheet.appendRow([
      TextCellValue('Out-of-State Miles'),
      DoubleCellValue(totalOutOfStateMiles),
    ]);
    summarySheet.appendRow([
      TextCellValue('Arkansas Miles'),
      DoubleCellValue(arkansasMiles),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Fuel Gallons'),
      DoubleCellValue(totalGallons),
    ]);
    summarySheet.appendRow([
      TextCellValue('Fuel Entry Count'),
      IntCellValue(fuelDocs.length),
    ]);
    summarySheet.appendRow([
      TextCellValue('Trip Entry Count'),
      IntCellValue(tripDocs.length),
    ]);

    summarySheet.appendRow([]);
    summarySheet.appendRow([
      TextCellValue('Miles by State'),
      TextCellValue('Miles'),
    ]);
    for (final entry in milesByState.entries) {
      summarySheet.appendRow([
        TextCellValue(entry.key),
        DoubleCellValue(entry.value),
      ]);
    }

    summarySheet.appendRow([]);
    summarySheet.appendRow([
      TextCellValue('Fuel by State'),
      TextCellValue('Gallons'),
    ]);
    for (final entry in fuelByState.entries) {
      summarySheet.appendRow([
        TextCellValue(entry.key),
        DoubleCellValue(entry.value),
      ]);
    }

    final iftaSheet = excel['IFTA Tax Report'];
    iftaSheet.appendRow([
      TextCellValue('State'),
      TextCellValue('Miles'),
      TextCellValue('Gallons'),
      TextCellValue('Miles Per Gallon'),
      TextCellValue('Taxable Gallons'),
    ]);

    for (final state in combinedStates) {
      final miles = milesByState[state] ?? 0.0;
      final gallons = fuelByState[state] ?? 0.0;
      final mpg = overallMpg == 0 ? 0.0 : overallMpg;
      final taxableGallons = mpg == 0 ? 0.0 : miles / mpg;

      iftaSheet.appendRow([
        TextCellValue(state),
        DoubleCellValue(miles),
        DoubleCellValue(gallons),
        DoubleCellValue(mpg),
        DoubleCellValue(taxableGallons),
      ]);
    }

    iftaSheet.appendRow([]);
    iftaSheet.appendRow([
      TextCellValue('TOTALS'),
      DoubleCellValue(overallMiles),
      DoubleCellValue(overallGallons),
      DoubleCellValue(overallMpg),
      DoubleCellValue(
        combinedStates.fold<double>(
          0,
          (sum, state) =>
              sum +
              ((overallMpg == 0
                  ? 0.0
                  : (milesByState[state] ?? 0.0) / overallMpg)),
        ),
      ),
    ]);

    final fuelSheet = excel['Fuel Entries'];
    fuelSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Unit'),
      TextCellValue('State'),
      TextCellValue('Gallons'),
      TextCellValue('Fuel Type'),
      TextCellValue('Created By'),
      TextCellValue('Document ID'),
    ]);

    for (final doc in fuelDocs) {
      final data = doc.data();
      fuelSheet.appendRow([
        TextCellValue(_formatDate(_readDate(data['date']))),
        TextCellValue((data['unitNumber'] ?? '').toString()),
        TextCellValue((data['state'] ?? '').toString()),
        DoubleCellValue(((data['gallons'] ?? 0) as num).toDouble()),
        TextCellValue((data['fuelType'] ?? '').toString()),
        TextCellValue((data['createdBy'] ?? '').toString()),
        TextCellValue(doc.id),
      ]);
    }

    final tripSheet = excel['Trip Entries'];
    tripSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Unit'),
      TextCellValue('State'),
      TextCellValue('Miles'),
      TextCellValue('Driver'),
      TextCellValue('Odometer Start'),
      TextCellValue('Odometer End'),
      TextCellValue('Document ID'),
    ]);

    for (final doc in tripDocs) {
      final data = doc.data();
      tripSheet.appendRow([
        TextCellValue(_formatDate(_readDate(data['date']))),
        TextCellValue((data['unitNumber'] ?? '').toString()),
        TextCellValue((data['state'] ?? '').toString()),
        DoubleCellValue(((data['miles'] ?? 0) as num).toDouble()),
        TextCellValue((data['driver'] ?? '').toString()),
        TextCellValue((data['odometerStart'] ?? '').toString()),
        TextCellValue((data['odometerEnd'] ?? '').toString()),
        TextCellValue(doc.id),
      ]);
    }

    final odometerSheet = excel['Quarter Odometers'];
    odometerSheet.appendRow([
      TextCellValue('Quarter'),
      TextCellValue('Unit'),
      TextCellValue('Beginning Odometer'),
      TextCellValue('Ending Odometer'),
      TextCellValue('Total Quarter Miles'),
      TextCellValue('Document ID'),
    ]);

    for (final doc in odometerDocs) {
      final data = doc.data();
      final begin =
          ((data['quarterBeginningOdometer'] ?? data['begin'] ?? 0) as num)
              .toDouble();
      final end = ((data['quarterEndingOdometer'] ?? data['end'] ?? 0) as num)
          .toDouble();

      odometerSheet.appendRow([
        TextCellValue((data['quarter'] ?? '').toString()),
        TextCellValue((data['unitNumber'] ?? data['unit'] ?? '').toString()),
        DoubleCellValue(begin),
        DoubleCellValue(end),
        DoubleCellValue(end - begin),
        TextCellValue(doc.id),
      ]);
    }

    excel.delete('Sheet1');

    final directory = await getTemporaryDirectory();
    final fileName =
        'ifta_export_${selectedQuarter}_${selectedUnit}_${selectedState}.xlsx';
    final file = File('${directory.path}/$fileName');

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to create Excel file');
    }

    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(file.path)], text: 'IFTA export');
  }
}
