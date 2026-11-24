import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/features/details/presentation/widgets/aqi_24h_chart_card.dart';

void main() {
  Widget buildTestWidget({required List<HourlyAqiPoint> points}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Aqi24hChartCard(hourlyPoints: points),
        ),
      ),
    );
  }

  group('Aqi24hChartCard Widget Tests', () {
    testWidgets('renders title, subtitle, AQI US tag and empty state when no points', (tester) async {
      await tester.pumpWidget(buildTestWidget(points: []));
      expect(find.text('Diễn biến nồng độ 24 giờ qua'), findsOneWidget);
      expect(find.text('Chỉ số AQI theo từng khung giờ'), findsOneWidget);
      expect(find.text('AQI US'), findsOneWidget);
      expect(find.text('Chưa có dữ liệu diễn biến AQI 24 giờ'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets(
      'renders LineChart with strongly typed hourly points without crashing',
      (tester) async {
        final now = DateTime.now();
        final points = List.generate(
          24,
          (i) => HourlyAqiPoint(
            time: now.add(Duration(hours: i)),
            aqi: 40 + i * 2,
            pm25: 15.0 + i,
            pm10: 30.0 + i,
          ),
        );

        await tester.pumpWidget(buildTestWidget(points: points));

        expect(find.byType(LineChart), findsOneWidget);
      },
    );
  });
}
