import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/advisor/presentation/cubits/advisor_chat_cubit.dart';
import '../../features/advisor/presentation/cubits/advisor_cubit.dart';
import '../../features/air_quality/infrastructure/repositories/air_quality_repository.dart';
import '../../features/air_quality/presentation/cubits/air_quality_cubit.dart';
import '../../features/details/infrastructure/repositories/details_repository.dart';
import '../../features/details/presentation/cubits/details_cubit.dart';
import '../../features/home/presentation/cubits/home_dashboard_cubit.dart';
import '../../features/map/domain/interfaces/i_map_repository.dart';
import '../../features/map/domain/interfaces/i_nasa_firms_repository.dart';
import '../../features/map/infrastructure/repositories/map_repository.dart';
import '../../features/map/infrastructure/repositories/nasa_firms_repository.dart';
import '../../features/map/presentation/cubits/map_cubit.dart';
import '../domain/entities/map_tile_config.dart';
import '../domain/interfaces/i_ai_chat_service.dart';
import '../domain/interfaces/i_air_quality_repository.dart';
import '../domain/interfaces/i_cache_store.dart';
import '../domain/interfaces/i_details_repository.dart';
import '../domain/interfaces/i_location_service.dart';
import '../infrastructure/configs/env_config.dart';
import '../infrastructure/datasources/local/local_storage.dart';
import '../infrastructure/datasources/network/api/restful_request.dart';
import '../infrastructure/services/edge_ai_inference_service.dart';
import '../infrastructure/services/location_service.dart';
import '../presentation/cubits/app_location_cubit.dart';

final sl = GetIt.instance;

Future<void> setupGetIt() async {
  await sl.reset();
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<LocalStorage>(() => LocalStorage(prefs: sl<SharedPreferences>()));
  sl.registerLazySingleton<ICacheStore>(() => sl<LocalStorage>());
  sl.registerLazySingleton<http.Client>(() => http.Client(), dispose: (c) => c.close());
  sl.registerLazySingleton<RestfulRequest>(() => RestfulRequest(client: sl<http.Client>()), dispose: (r) => r.close());
  sl.registerLazySingleton<MapTileConfig>(() => MapTileConfig(urlTemplate: EnvConfig.osmTileUrl, userAgentPackageName: EnvConfig.mapUserAgent));
  sl.registerLazySingleton<ILocationService>(() => LocationService());
  sl.registerLazySingleton<IAiChatService>(
    () => EdgeAiInferenceService(bridge: BackendSseBridge(client: sl<http.Client>())),
    dispose: (s) => s.dispose(),
  );
  sl.registerLazySingleton<AppLocationCubit>(
    () => AppLocationCubit(cacheStore: sl<ICacheStore>(), locationService: sl<ILocationService>()),
    dispose: (c) => c.close(),
  );
  sl.registerLazySingleton<IDetailsRepository>(() => DetailsRepository(network: sl<RestfulRequest>(), storage: sl<ICacheStore>()));
  sl.registerLazySingleton<DetailsCubit>(() => DetailsCubit(repository: sl<IDetailsRepository>()), dispose: (c) => c.close());
  sl.registerLazySingleton<IAirQualityRepository>(() => AirQualityRepository(network: sl<RestfulRequest>(), storage: sl<ICacheStore>()));
  sl.registerLazySingleton<AirQualityCubit>(() => AirQualityCubit(repository: sl<IAirQualityRepository>()), dispose: (c) => c.close());
  sl.registerLazySingleton<IMapRepository>(() => MapRepository(network: sl<RestfulRequest>()));
  sl.registerLazySingleton<INasaFirmsRepository>(
    () => NasaFirmsRepository(client: sl<http.Client>(), storage: sl<ICacheStore>()),
    dispose: (r) {
      if (r is NasaFirmsRepository) r.close();
    },
  );
  sl.registerFactory<MapCubit>(
    () => MapCubit(
      repository: sl<IMapRepository>(),
      detailsRepository: sl<IDetailsRepository>(),
      airQualityRepository: sl<IAirQualityRepository>(),
      locationService: sl<ILocationService>(),
      nasaFirmsRepository: sl<INasaFirmsRepository>(),
    ),
  );
  sl.registerLazySingleton<HomeDashboardCubit>(
    () => HomeDashboardCubit(
      appLocationCubit: sl<AppLocationCubit>(),
      detailsCubit: sl<DetailsCubit>(),
      airQualityCubit: sl<AirQualityCubit>(),
    ),
    dispose: (c) => c.close(),
  );
  sl.registerFactory<AdvisorCubit>(() => AdvisorCubit());
  sl.registerFactory<AdvisorChatCubit>(() => AdvisorChatCubit(inferenceService: sl<IAiChatService>()));
}
