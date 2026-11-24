import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/infrastructure/services/edge_ai_inference_service.dart';
import 'package:envivn/src/features/advisor/presentation/cubits/advisor_chat_cubit.dart';
import 'package:envivn/src/features/advisor/presentation/cubits/advisor_cubit.dart';
import 'package:envivn/src/features/advisor/presentation/widgets/advisor_modal_sheet.dart';
import 'package:envivn/src/features/air_quality/domain/entities/air_quality_entity.dart';
import 'package:envivn/src/features/details/domain/entities/details_entity.dart';

class _FakeSheetBridge implements IAiChatBridge {
  @override
  Future<void> startSession({double? lat, double? lon}) async {}

  @override
  Stream<String> generateResponseStream(String message) async* {
    yield 'Phản hồi từ Local AI Node.';
  }

  @override
  Future<String> generateResponse(String message) async => 'Phản hồi từ Local AI Node.';

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EdgeAiInferenceService inferenceService;
  late AdvisorChatCubit chatCubit;
  late AdvisorCubit advisorCubit;

  setUp(() {
    inferenceService = EdgeAiInferenceService(bridge: _FakeSheetBridge());
    chatCubit = AdvisorChatCubit(inferenceService: inferenceService);
    advisorCubit = AdvisorCubit();
  });

  tearDown(() async {
    await chatCubit.close();
    await advisorCubit.close();
    await inferenceService.dispose();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: advisorCubit),
            BlocProvider.value(value: chatCubit),
          ],
          child: AdvisorModalSheet(
            location: AppLocationEntity.city(name: 'Hà Nội', province: 'Hà Nội', latitude: 21.0285, longitude: 105.8542),
            weather: const DetailsEntity(currentTemp: 28.0, relativeHumidity: 65, precipitation: 0.0),
            airQuality: const AirQualityEntity(usAqi: 75, pm25: 25.0),
          ),
        ),
      ),
    );
  }

  group('AdvisorModalSheet Dual Mode Widget Tests', () {
    testWidgets('renders toggle switch and rule-based cards by default when AI is OFF', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Trợ lý AI EnviVN'), findsOneWidget);
      expect(find.text('Quy tắc cố định WHO/EPA (0ms)'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.text('Chạy bộ ngoài trời'), findsOneWidget);
    });

    testWidgets('toggling switch opens AI chat conversation immediately without legacy download card', (tester) async {
      await chatCubit.initChat(location: AppLocationEntity.defaultLocation);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(chatCubit.state.isAiEnabled, isTrue);
      expect(find.text('Local AI Node • Phản hồi thông minh'), findsOneWidget);
      expect(find.text('Gói trí tuệ nhân tạo Gemma 2B'), findsNothing);
      expect(find.text('Cố vấn AI EnviVN'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Hỏi về không khí, chạy bộ, ngập úng...'), findsOneWidget);
    });
  });
}
