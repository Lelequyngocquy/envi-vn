import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/entities/base.dart';
import 'package:envivn/src/core/infrastructure/configs/env_config.dart';
import 'package:envivn/src/core/infrastructure/datasources/local/local_storage.dart';
import 'package:envivn/src/core/infrastructure/services/edge_ai_inference_service.dart';
import 'package:envivn/src/core/infrastructure/services/model_download_service.dart';
import 'package:envivn/src/core/presentation/widgets/app_dialog.dart';
import 'package:envivn/src/features/advisor/domain/entities/advisor_decision.dart';
import 'package:envivn/src/features/advisor/presentation/cubits/advisor_chat_cubit.dart';
import 'package:envivn/src/features/advisor/presentation/cubits/advisor_cubit.dart';
import 'package:envivn/src/features/advisor/presentation/widgets/advisor_modal_sheet.dart';
import 'package:envivn/src/features/air_quality/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/features/air_quality/domain/interfaces/i_air_quality_repository.dart';
import 'package:envivn/src/features/air_quality/presentation/cubits/air_quality_cubit.dart';
import 'package:envivn/src/features/details/domain/entities/details_entity.dart';
import 'package:envivn/src/features/details/presentation/widgets/health_advisory_card.dart';
import 'package:envivn/src/features/map/domain/entities/map_layer_type.dart';
import 'package:envivn/src/features/map/domain/entities/station_entity.dart';
import 'package:envivn/src/features/map/domain/entities/vietnam_monitoring_station.dart';
import 'package:envivn/src/features/map/infrastructure/models/station_model.dart';
import 'package:envivn/src/features/map/presentation/widgets/station_preview_card.dart';

class _ControlledBridge implements IGemmaBridge {
  final StreamController<String> streamController = StreamController<String>.broadcast();
  bool shouldError = false;

  @override
  Future<bool> isModelInstalled() async => true;

  @override
  Future<void> setModelPath(String path) async {}

  @override
  Future<void> createModel({required bool isInstructionTuned, int maxTokens = 2048}) async {}

  @override
  Future<void> createChatSession({String? systemPrompt}) async {}

  @override
  Stream<String> generateResponseAsync(String message) {
    if (shouldError) return Stream<String>.error(Exception('network down'));
    return streamController.stream;
  }

  @override
  Future<String> generateResponse(String message) async => '';

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
    test('EnvConfig does not hardcode NASA FIRMS API key fallback', () {
      EnvConfig.reset();
      expect(EnvConfig.nasaFirmsMapKey, isEmpty);
    });

    test('StationModel.fromApiResponse leaves temperature null so live weather enrichment triggers', () {
      final station = StationModel.fromApiResponse(
        station: VietnamMonitoringStation.hoanKiem,
        currentData: {'us_aqi': 80, 'pm2_5': 25.0, 'pm10': 40.0},
      );
      expect(station.aqi, 80);
      expect(station.temperature, isNull);
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
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs: prefs);
      final tempDir = Directory.systemTemp.createTempSync('phase0_chat_test_');
      final downloadService = ModelDownloadService(localStorage: storage, customDirectoryProvider: () async => tempDir);
      final modelFile = await downloadService.getModelFile();
      modelFile.writeAsBytesSync(List.filled(64, 1));
      await downloadService.init();
      final bridge = _ControlledBridge();
      final inference = EdgeAiInferenceService(downloadService: downloadService, bridge: bridge);
      final cubit = AdvisorChatCubit(downloadService: downloadService, inferenceService: inference, localStorage: storage);
      final loc = AppLocationEntity.defaultLocation;
      await cubit.initChat(location: loc, weather: const DetailsEntity(), airQuality: const AirQualityEntity());
      final pendingSend = cubit.sendMessage('Test câu 1');
      await pumpEventQueue();
      expect(cubit.state.isStreaming, isTrue);
      cubit.clearChat(location: loc, weather: const DetailsEntity(), airQuality: const AirQualityEntity());
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
      downloadService.dispose();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    testWidgets('AdvisorModalSheet passes rain context to AdvisorCubit.selectPrompt', (tester) async {
      late LocalStorage storage;
      late Directory tempDir;
      late ModelDownloadService downloadService;
      late EdgeAiInferenceService inference;
      late AdvisorChatCubit chatCubit;
      late AdvisorCubit advisorCubit;
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        storage = LocalStorage(prefs: prefs);
        tempDir = Directory.systemTemp.createTempSync('phase0_rain_test_');
        downloadService = ModelDownloadService(localStorage: storage, customDirectoryProvider: () async => tempDir);
        inference = EdgeAiInferenceService(downloadService: downloadService, bridge: _ControlledBridge());
        chatCubit = AdvisorChatCubit(downloadService: downloadService, inferenceService: inference, localStorage: storage);
        advisorCubit = AdvisorCubit();
      });
      addTearDown(() async {
        await chatCubit.close();
        await advisorCubit.close();
        await inference.dispose();
        downloadService.dispose();
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
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
