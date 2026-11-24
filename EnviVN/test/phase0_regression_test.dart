import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:envivn/src/core/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/entities/base.dart';
import 'package:envivn/src/core/domain/entities/details_entity.dart';
import 'package:envivn/src/core/domain/interfaces/i_air_quality_repository.dart';
import 'package:envivn/src/core/infrastructure/configs/env_config.dart';
import 'package:envivn/src/core/infrastructure/services/edge_ai_inference_service.dart';
import 'package:envivn/src/core/presentation/widgets/app_dialog.dart';
import 'package:envivn/src/features/advisor/domain/entities/advisor_decision.dart';
import 'package:envivn/src/features/advisor/presentation/cubits/advisor_chat_cubit.dart';
import 'package:envivn/src/features/advisor/presentation/cubits/advisor_cubit.dart';
import 'package:envivn/src/features/advisor/presentation/widgets/advisor_modal_sheet.dart';
import 'package:envivn/src/features/air_quality/presentation/cubits/air_quality_cubit.dart';
import 'package:envivn/src/features/details/presentation/widgets/health_advisory_card.dart';
import 'package:envivn/src/features/map/domain/entities/map_layer_type.dart';
import 'package:envivn/src/features/map/domain/entities/station_entity.dart';
import 'package:envivn/src/features/map/infrastructure/models/station_model.dart';
import 'package:envivn/src/features/map/presentation/widgets/station_preview_card.dart';

class _ControlledBridge implements IAiChatBridge {
  final StreamController<String> streamController = StreamController<String>.broadcast();
  bool shouldError = false;

  @override
  Future<void> startSession({double? lat, double? lon}) async {}

  @override
  Stream<String> generateResponseStream(
    String message, {
    List<Map<String, String>> history = const [],
  }) {
    if (shouldError) return Stream<String>.error(Exception('network down'));
    return streamController.stream;
  }

  @override
  Future<String> generateResponse(
    String message, {
    List<Map<String, String>> history = const [],
  }) async => '';

  @override
  Future<void> close() async {
    await streamController.close();
  }
}

class _ClearingAirQualityRepo implements IAirQualityRepository {
  AirQualityEntity? cached;
  BaseResult<AirQualityEntity>? nextResult;

  @override
  AirQualityEntity? getCachedAirQuality({double? latitude, double? longitude}) => cached;

  @override
  Future<BaseResult<AirQualityEntity>> getAirQuality({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    return nextResult ?? BaseResult(success: true, data: const AirQualityEntity(usAqi: 30));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 0 Regression Tests', () {
    test('EnvConfig exposes empty clientApiKey by default and resolves Backend gateway URL', () {
      EnvConfig.reset();
      expect(EnvConfig.clientApiKey, isEmpty);
      expect(EnvConfig.backendBaseUrl, contains('http://'));
    });

    test('StationModel.fromBackendJson preserves null temperature when omitted and parses live weather when present', () {
      final stationNoTemp = StationModel.fromBackendJson({
        'id': 'st_hn_01',
        'name': 'Trạm Hoàn Kiếm',
        'province': 'Hà Nội',
        'latitude': 21.0285,
        'longitude': 105.8542,
        'aqi': 80,
        'pm25': 25.0,
        'pm10': 40.0,
      });
      expect(stationNoTemp.aqi, 80);
      expect(stationNoTemp.temperature, isNull);
      final stationWithTemp = StationModel.fromBackendJson({
        'id': 'st_hn_01',
        'name': 'Trạm Hoàn Kiếm',
        'province': 'Hà Nội',
        'latitude': 21.0285,
        'longitude': 105.8542,
        'aqi': 80,
        'pm25': 25.0,
        'pm10': 40.0,
        'temperature': 29.4,
        'relative_humidity': 74,
      });
      expect(stationWithTemp.temperature, 29.4);
      expect(stationWithTemp.humidity, 74);
    });

    test('AirQualityCubit clears stale offline notice and errorMessage on fresh online success', () async {
      final repo = _ClearingAirQualityRepo()
        ..cached = const AirQualityEntity(usAqi: 90)
        ..nextResult = BaseResult(success: true, data: const AirQualityEntity(usAqi: 42), message: null);
      final cubit = AirQualityCubit(repository: repo);
      expect(cubit.state.noticeMessage, 'Dữ liệu đã lưu ngoại tuyến');
      await cubit.fetchAirQuality(latitude: 21.0, longitude: 105.8);
      expect(cubit.state.noticeMessage, isNull);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('AdvisorChatCubit clearChat cancels active stream without deadlocking sendMessage', () async {
      final bridge = _ControlledBridge();
      final inference = EdgeAiInferenceService(bridge: bridge);
      final cubit = AdvisorChatCubit(inferenceService: inference);
      final loc = AppLocationEntity.defaultLocation;
      await cubit.initChat(location: loc);
      final pendingSend = cubit.sendMessage('Test câu 1');
      await pumpEventQueue();
      expect(cubit.state.isStreaming, isTrue);
      cubit.clearChat(location: loc);
      await pendingSend;
      await pumpEventQueue();
      expect(cubit.state.isStreaming, isFalse);
      bridge.shouldError = true;
      await cubit.sendMessage('Test lỗi mạng');
      expect(cubit.state.isStreaming, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.messages.last.text, contains('Không thể kết nối'));
      await cubit.close();
      await inference.dispose();
    });

    testWidgets('AdvisorModalSheet passes rain context to AdvisorCubit.selectPrompt', (tester) async {
      final inference = EdgeAiInferenceService(bridge: _ControlledBridge());
      final chatCubit = AdvisorChatCubit(inferenceService: inference);
      final advisorCubit = AdvisorCubit();
      addTearDown(() async {
        await chatCubit.close();
        await advisorCubit.close();
        await inference.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: advisorCubit),
                BlocProvider.value(value: chatCubit),
              ],
              child: AdvisorModalSheet(
                location: AppLocationEntity.defaultLocation,
                weather: const DetailsEntity(currentTemp: 25.0, precipitation: 12.0, weatherCode: 63),
                airQuality: const AirQualityEntity(usAqi: 30, pm25: 8.0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chạy bộ ngoài trời'));
      await tester.pumpAndSettle();
      expect(advisorCubit.state.decision, equals(AdvisorDecision.runningRainWarning));
    });

    testWidgets('AppDialog dismisses on outside tap and shows default close button', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDialog(
              title: 'Thông báo',
              content: 'Nội dung test',
              barrierDismissible: true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      expect(find.text('Đóng'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('HealthAdvisoryCard reflects real AQI and avoids hardcoded safe jogging', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HealthAdvisoryCard(aqi: 350))));
      expect(find.textContaining('Nguy hại'), findsOneWidget);
      expect(find.textContaining('14:00 - 18:00'), findsNothing);
    });

    testWidgets('StationPreviewCard does not hang in loading when picked station fails weather fetch', (tester) async {
      final failedPin = StationEntity(
        id: 'picked_21.0000_105.8000',
        name: 'Điểm ghim test',
        province: 'Hà Nội',
        latitude: 21.0,
        longitude: 105.8,
        aqi: 60,
        pm25: 18.0,
        pm10: 30.0,
        updatedAt: DateTime.now(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StationPreviewCard(station: failedPin, isLoading: false, activeLayer: MapLayerType.weather, onClose: () {}),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
