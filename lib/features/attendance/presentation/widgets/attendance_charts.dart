import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class AttendancePieChart extends StatelessWidget {
  final Map<String, int> statusCounts;
  final int totalAttendances;

  const AttendancePieChart({
    Key? key,
    required this.statusCounts,
    required this.totalAttendances,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prepare data for the pie chart
    final List<AttendanceData> chartData = [
      AttendanceData(
        'Present',
        statusCounts['present'] ?? 0,
        AppColors.success,
        totalAttendances > 0
            ? ((statusCounts['present'] ?? 0) / totalAttendances * 100)
                    .toStringAsFixed(1) +
                '%'
            : '0.0%',
      ),
      AttendanceData(
        'Late',
        statusCounts['late'] ?? 0,
        AppColors.warning,
        totalAttendances > 0
            ? ((statusCounts['late'] ?? 0) / totalAttendances * 100)
                    .toStringAsFixed(1) +
                '%'
            : '0.0%',
      ),
      AttendanceData(
        'Excused',
        statusCounts['excused'] ?? 0,
        AppColors.accentTeal,
        totalAttendances > 0
            ? ((statusCounts['excused'] ?? 0) / totalAttendances * 100)
                    .toStringAsFixed(1) +
                '%'
            : '0.0%',
      ),
      AttendanceData(
        'Absent',
        statusCounts['absent'] ?? 0,
        AppColors.error,
        totalAttendances > 0
            ? ((statusCounts['absent'] ?? 0) / totalAttendances * 100)
                    .toStringAsFixed(1) +
                '%'
            : '0.0%',
      ),
    ];

    return SizedBox(
      height: 300,
      child: SfCircularChart(
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.x: point.y (point.percentage)',
        ),
        series: <CircularSeries>[
          DoughnutSeries<AttendanceData, String>(
            dataSource: chartData,
            xValueMapper: (AttendanceData data, _) => data.status,
            yValueMapper: (AttendanceData data, _) => data.count,
            dataLabelMapper: (AttendanceData data, _) => data.percentage,
            pointColorMapper: (AttendanceData data, _) => data.color,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              connectorLineSettings: ConnectorLineSettings(
                type: ConnectorType.curve,
                length: '15%',
              ),
            ),
            enableTooltip: true,
            animationDuration: 1200,
            explode: true,
            explodeIndex: 0,
          ),
        ],
      ),
    );
  }
}

class AttendanceTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const AttendanceTrendChart({
    Key? key,
    required this.weeklyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert the weekly data to chart format
    final List<TrendData> chartData = weeklyData.map((item) {
      return TrendData(
        item['week'] as String,
        (item['attendanceRate'] as double) * 100, // Convert to percentage
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          title: AxisTitle(text: 'Week'),
          labelRotation: 0,
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Attendance Rate %'),
          minimum: 0,
          maximum: 100,
          interval: 10,
          axisLine: const AxisLine(width: 0),
          labelFormat: '{value}%',
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
        ),
        series: <CartesianSeries>[
          // Change from ChartSeries to CartesianSeries
          // Line series
          LineSeries<TrendData, String>(
            name: 'Attendance Rate',
            dataSource: chartData,
            xValueMapper: (TrendData data, _) => data.week,
            yValueMapper: (TrendData data, _) => data.rate,
            color: AppColors.primaryBlue,
            width: 3,
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              height: 8,
              width: 8,
            ),
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.auto,
              useSeriesColor: true,
            ),
            enableTooltip: true,
            animationDuration: 1500,
          ),
          // Area series for visual effect
          AreaSeries<TrendData, String>(
            name: 'Trend Area',
            dataSource: chartData,
            xValueMapper: (TrendData data, _) => data.week,
            yValueMapper: (TrendData data, _) => data.rate,
            color: AppColors.primaryBlue.withOpacity(0.2),
            borderColor: AppColors.primaryBlue,
            borderWidth: 1,
            animationDuration: 1800,
          ),
        ],
        annotations: <CartesianChartAnnotation>[
          CartesianChartAnnotation(
            widget: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Overall: ${_calculateAverageRate(weeklyData).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            coordinateUnit: CoordinateUnit.percentage,
            region: AnnotationRegion.chart,
            x: '90%',
            y: '15%',
          ),
        ],
      ),
    );
  }

  // Calculate average attendance rate for annotation
  double _calculateAverageRate(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0;
    double sum = 0;
    for (var item in data) {
      sum += (item['attendanceRate'] as double) * 100;
    }
    return sum / data.length;
  }
}

// Data models for the charts
class AttendanceData {
  final String status;
  final int count;
  final Color color;
  final String percentage;

  AttendanceData(this.status, this.count, this.color, this.percentage);
}

class TrendData {
  final String week;
  final double rate;

  TrendData(this.week, this.rate);
}
