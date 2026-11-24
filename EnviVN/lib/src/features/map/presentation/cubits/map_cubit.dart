import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../common/utils/geo_distance_helper.dart';
import '../../../../core/domain/entities/air_quality_entity.dart';
import '../../../../core/domain/entities/details_entity.dart';
import '../../../../core/domain/interfaces/i_air_quality_repository.dart';
import '../../../../core/domain/interfaces/i_details_repository.dart';
import '../../../../core/domain/interfaces/i_location_service.dart';
import '../../domain/entities/map_filter.dart';
import '../../domain/entities/map_layer_type.dart';
import '../../domain/entities/quick_city_target.dart';
import '../../domain/entities/station_entity.dart';
import '../../domain/interfaces/i_map_repository.dart';
import '../../domain/interfaces/i_nasa_firms_repository.dart';
import '../../domain/utils/map_location_resolver.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final IMapRepository repository;
  final IDetailsRepository? detailsRepository;
  final IAirQualityRepository? airQualityRepository;
  final ILocationService? locationService;
  final INasaFirmsRepository? nasaFirmsRepository;
  int _weatherSeq = 0;
  int _pickSeq = 0;

  MapCubit({
    required this.repository,
    this.detailsRepository,
    this.airQualityRepository,
    this.locationService,
    this.nasaFirmsRepository,
  }) : super(const MapState());

  Future<void> fetchVietnamStations({
    String? initialCity,
    LatLng? initialCoords,
  }) async {
    emit(state.copyWith(status: MapStatus.loading, clearErrorMessage: true));
    final result = await repository.getVietnamStations();
    if (isClosed) return;
    if (result.isSuccess && result.data != null) {
      emit(
        state.copyWith(
          status: MapStatus.success,
          stations: result.data!,
          clearErrorMessage: true,
        ),
      );
      await loadUserGpsLocation();
      if (isClosed) return;
      if (state.selectedStation != null || state.targetLocation != null) return;
      if (initialCoords != null) {
        selectLocationCoordinates(
          initialCoords.latitude,
          initialCoords.longitude,
          label: initialCity,
        );
      } else if (initialCity != null && initialCity.isNotEmpty) {
        selectLocationByCityName(initialCity);
      }
    } else {
      emit(
        state.copyWith(
          status: MapStatus.failure,
          errorMessage:
              result.message ?? 'Không thể tải trạm quan trắc trên bản đồ',
        ),
      );
    }
  }

  void setUserGpsLocation(LatLng? coords) {
    if (coords == null) {
      clearUserGpsLocation();
    } else if (state.userGpsLocation != coords) {
      emit(state.copyWith(userGpsLocation: coords));
    }
  }

  void clearUserGpsLocation() {
    if (state.userGpsLocation != null) {
      emit(state.copyWith(clearUserGpsLocation: true));
    }
  }

  Future<void> loadUserGpsLocation({LatLng? fallbackCoords}) async {
    if (locationService == null) {
      if (!isClosed) emit(state.copyWith(clearUserGpsLocation: true));
      return;
    }
    try {
      final isGranted = await locationService!.checkPermissionGranted();
      if (isClosed) return;
      if (!isGranted) {
        emit(state.copyWith(clearUserGpsLocation: true));
        return;
      }
      if (fallbackCoords != null && state.userGpsLocation == null) {
        emit(state.copyWith(userGpsLocation: fallbackCoords));
      }
      final loc = await locationService!.getCurrentLocation();
      if (isClosed) return;
      if (!loc.isDefault && !loc.isPermissionDenied) {
        emit(
          state.copyWith(userGpsLocation: LatLng(loc.latitude, loc.longitude)),
        );
      } else {
        emit(state.copyWith(clearUserGpsLocation: true));
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(clearUserGpsLocation: true));
    }
  }

  void selectStation(StationEntity station, {QuickCityTarget? quickCity}) {
    final matchedQuickCity =
        quickCity ??
        QuickCityTarget.findForStation(
          name: station.name,
          province: station.province,
          lat: station.latitude,
          lon: station.longitude,
        );
    final needsWeather = station.temperature == null;
    emit(
      state.copyWith(
        selectedStation: station,
        targetLocation: LatLng(station.latitude, station.longitude),
        targetZoom: 12.0,
        selectedCityName: matchedQuickCity?.label ?? station.province,
        selectedQuickCity: matchedQuickCity,
        clearSelectedQuickCity: matchedQuickCity == null,
        isHomeSelected: false,
        clearPickedLocation: true,
        isLoadingPointData: needsWeather,
        isShowedAllVN: false,
      ),
    );
    if (needsWeather) _enrichStationWeather(station);
  }

  void switchMapLayer(MapLayerType layer) {
    if (state.activeLayer == layer) return;
    emit(state.copyWith(activeLayer: layer));
    if (layer == MapLayerType.thermal) fetchThermalHotspots();
  }

  Future<void> fetchThermalHotspots({bool forceRefresh = false}) async {
    if (nasaFirmsRepository == null || isClosed) return;
    emit(state.copyWith(isLoadingThermal: true));
    try {
      final result = await nasaFirmsRepository!.getVietnamActiveFires(
        forceRefresh: forceRefresh,
      );
      if (isClosed) return;
      if (result.isSuccess && result.data != null) {
        emit(
          state.copyWith(
            thermalHotspots: result.data!,
            isLoadingThermal: false,
            thermalNotice: result.message,
            isThermalFromCache: nasaFirmsRepository!.isServingCachedData,
          ),
        );
      } else {
        emit(
          state.copyWith(
            thermalHotspots: result.data ?? const [],
            isLoadingThermal: false,
            thermalNotice: result.message,
            isThermalFromCache: false,
          ),
        );
      }
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingThermal: false,
          thermalNotice: 'Không thể tải dữ liệu điểm nhiệt vệ tinh lúc này.',
          isThermalFromCache: false,
        ),
      );
    }
  }

  Future<void> _enrichStationWeather(StationEntity station) async {
    final seq = ++_weatherSeq;
    if (detailsRepository == null) {
      if (!isClosed && state.isLoadingPointData) {
        emit(state.copyWith(isLoadingPointData: false));
      }
      return;
    }
    try {
      final res = await detailsRepository!.getDetailsForecast(
        latitude: station.latitude,
        longitude: station.longitude,
      );
      if (isClosed || seq != _weatherSeq) return;
      if (res.isSuccess &&
          res.data != null &&
          state.selectedStation?.id == station.id) {
        final w = res.data!;
        final updated = station.copyWith(
          temperature: w.currentTemp,
          apparentTemp: w.apparentTemp,
          weatherCode: w.weatherCode,
          humidity: w.relativeHumidity,
          windSpeed: w.windSpeed,
          precipitation: w.precipitation,
          uvIndex: w.uvIndex,
        );
        emit(
          state.copyWith(selectedStation: updated, isLoadingPointData: false),
        );
      } else if (state.selectedStation?.id == station.id &&
          state.isLoadingPointData) {
        emit(state.copyWith(isLoadingPointData: false));
      }
    } catch (_) {
      if (isClosed || seq != _weatherSeq) return;
      if (state.selectedStation?.id == station.id && state.isLoadingPointData) {
        emit(state.copyWith(isLoadingPointData: false));
      }
    }
  }

  void selectLocationByCityName(String cityName) {
    final matchedStation = MapLocationResolver.findStationByCityName(
      state.stations,
      cityName,
    );
    final matchedQuickCity = QuickCityTarget.findByQuery(cityName);
    if (matchedStation != null) {
      selectStation(matchedStation, quickCity: matchedQuickCity);
      return;
    }
    final cityCoords = MapLocationResolver.getCityCoordinates(cityName);
    if (cityCoords != null) {
      selectLocationCoordinates(
        cityCoords.latitude,
        cityCoords.longitude,
        zoom: 11.5,
        label: cityName,
        quickCity: matchedQuickCity,
      );
    }
  }

  void selectHomeLocation({
    required double lat,
    required double lon,
    double zoom = 12.0,
    String? label,
  }) {
    final closest = MapLocationResolver.findClosestStation(
      state.stations,
      lat,
      lon,
    );
    if (closest.station != null && closest.distanceKm <= 35.0) {
      final needsWeather = closest.station!.temperature == null;
      emit(
        state.copyWith(
          selectedStation: closest.station,
          targetLocation: LatLng(lat, lon),
          targetZoom: zoom,
          selectedCityName: label ?? 'Vị trí hiện tại',
          isHomeSelected: true,
          clearSelectedQuickCity: true,
          clearPickedLocation: true,
          isLoadingPointData: needsWeather,
          isShowedAllVN: false,
        ),
      );
      if (needsWeather) _enrichStationWeather(closest.station!);
    } else {
      emit(
        state.copyWith(
          clearSelectedStation: true,
          targetLocation: LatLng(lat, lon),
          targetZoom: zoom,
          selectedCityName: label ?? 'Vị trí hiện tại',
          isHomeSelected: true,
          clearSelectedQuickCity: true,
          clearPickedLocation: true,
          isLoadingPointData: false,
          isShowedAllVN: false,
        ),
      );
    }
  }

  bool moveToUserGpsLocation({double zoom = 12.0}) {
    final coords = state.userGpsLocation;
    if (coords == null) return false;
    selectHomeLocation(
      lat: coords.latitude,
      lon: coords.longitude,
      zoom: zoom,
      label: 'Vị trí hiện tại',
    );
    return true;
  }

  void selectLocationCoordinates(
    double lat,
    double lon, {
    double zoom = 12.0,
    String? label,
    bool isHome = false,
    QuickCityTarget? quickCity,
  }) {
    if (isHome) {
      selectHomeLocation(lat: lat, lon: lon, zoom: zoom, label: label);
      return;
    }
    final matchedQuickCity =
        quickCity ??
        (label != null ? QuickCityTarget.findByQuery(label) : null);
    final closest = MapLocationResolver.findClosestStation(
      state.stations,
      lat,
      lon,
    );
    if (closest.station != null && closest.distanceKm <= 35.0) {
      selectStation(closest.station!, quickCity: matchedQuickCity);
    } else {
      emit(
        state.copyWith(
          clearSelectedStation: true,
          targetLocation: LatLng(lat, lon),
          targetZoom: zoom,
          selectedCityName: label,
          selectedQuickCity: matchedQuickCity,
          clearSelectedQuickCity: matchedQuickCity == null,
          isHomeSelected: false,
          clearPickedLocation: true,
          isLoadingPointData: false,
          isShowedAllVN: false,
        ),
      );
    }
  }

  void selectQuickCity(QuickCityTarget target) {
    if (target.isAllCountry) {
      showAllVietnam();
    } else {
      selectLocationCoordinates(
        target.latitude,
        target.longitude,
        zoom: target.zoom,
        label: target.label,
        isHome: false,
        quickCity: target,
      );
    }
  }

  void updateQuickCities(List<QuickCityTarget> cities) =>
      emit(state.copyWith(quickCities: cities));

  void showAllVietnam() {
    emit(
      state.copyWith(
        clearSelectedStation: true,
        targetLocation: const LatLng(16.0544, 108.2022),
        targetZoom: 5.8,
        selectedCityName: 'Toàn quốc',
        selectedQuickCity: QuickCityTarget.allVietnam,
        isHomeSelected: false,
        clearPickedLocation: true,
        isLoadingPointData: false,
        isShowedAllVN: true,
      ),
    );
  }

  Future<void> pickCustomLocation(
    LatLng point, {
    String? customName,
    String? customProvince,
    double zoom = 12.5,
  }) async {
    final meta = MapLocationResolver.resolvePickedMeta(
      point: point,
      stations: state.stations,
      quickCities: state.quickCities,
      customName: customName,
      customProvince: customProvince,
    );
    final placeholder = StationEntity(
      id: 'picked_${point.latitude.toStringAsFixed(4)}_${point.longitude.toStringAsFixed(4)}',
      name: meta.name,
      province: meta.province,
      latitude: point.latitude,
      longitude: point.longitude,
      aqi: 0,
      pm25: 0.0,
      pm10: 0.0,
      updatedAt: DateTime.now(),
    );
    final seq = ++_pickSeq;
    emit(
      state.copyWith(
        pickedLocation: point,
        pickedReferenceLocation: meta.referenceCoords,
        pickedDistanceKm: meta.distanceKm.isFinite ? meta.distanceKm : null,
        isPickingLocation: true,
        isLoadingPointData: true,
        selectedStation: placeholder,
        targetLocation: point,
        targetZoom: zoom,
        isHomeSelected: false,
        isShowedAllVN: false,
        clearSelectedCityName: true,
        clearSelectedQuickCity: true,
      ),
    );
    try {
      final results = await Future.wait<dynamic>([
        if (airQualityRepository != null)
          airQualityRepository!.getAirQuality(
            latitude: point.latitude,
            longitude: point.longitude,
          )
        else
          Future<dynamic>.value(null),
        if (detailsRepository != null)
          detailsRepository!.getDetailsForecast(
            latitude: point.latitude,
            longitude: point.longitude,
          )
        else
          Future<dynamic>.value(null),
      ]);
      if (isClosed || seq != _pickSeq || state.pickedLocation != point) return;
      final airRes = results[0];
      final weatherRes = results[1];
      int aqi = 0;
      double pm25 = 0.0;
      double pm10 = 0.0;
      if (airRes != null && airRes.isSuccess && airRes.data != null) {
        final AirQualityEntity airData = airRes.data!;
        aqi = airData.usAqi;
        pm25 = airData.pm25;
        pm10 = airData.pm10;
      }
      double? temp;
      double? apparentTemp;
      int? weatherCode;
      int? humidity;
      double? windSpeed;
      double? precipitation;
      double? uvIndex;
      if (weatherRes != null &&
          weatherRes.isSuccess &&
          weatherRes.data != null) {
        final DetailsEntity w = weatherRes.data!;
        temp = w.currentTemp;
        apparentTemp = w.apparentTemp;
        weatherCode = w.weatherCode;
        humidity = w.relativeHumidity;
        windSpeed = w.windSpeed;
        precipitation = w.precipitation;
        uvIndex = w.uvIndex;
      }
      final enriched = placeholder.copyWith(
        aqi: aqi,
        pm25: pm25,
        pm10: pm10,
        temperature: temp,
        apparentTemp: apparentTemp,
        weatherCode: weatherCode,
        humidity: humidity,
        windSpeed: windSpeed,
        precipitation: precipitation,
        uvIndex: uvIndex,
      );
      emit(
        state.copyWith(
          selectedStation: enriched,
          isPickingLocation: false,
          isLoadingPointData: false,
          clearSelectedCityName: true,
          clearSelectedQuickCity: true,
          isHomeSelected: false,
        ),
      );
    } catch (_) {
      if (isClosed || seq != _pickSeq || state.pickedLocation != point) return;
      emit(
        state.copyWith(
          isPickingLocation: false,
          isLoadingPointData: false,
          clearSelectedCityName: true,
          clearSelectedQuickCity: true,
          isHomeSelected: false,
        ),
      );
    }
  }

  void clearPickedLocation() {
    final wasPickedSelected =
        state.selectedStation?.id.startsWith('picked_') ?? false;
    emit(
      state.copyWith(
        clearPickedLocation: true,
        isPickingLocation: false,
        isLoadingPointData: false,
        clearSelectedStation: wasPickedSelected,
        clearSelectedQuickCity: wasPickedSelected,
        clearSelectedCityName: wasPickedSelected,
      ),
    );
    showAllVietnam();
  }

  void clearSelection() {
    emit(
      state.copyWith(
        clearSelectedStation: true,
        clearTargetLocation: true,
        clearSelectedCityName: true,
        clearSelectedQuickCity: true,
        clearPickedLocation: true,
        isPickingLocation: false,
        isLoadingPointData: false,
        isHomeSelected: false,
      ),
    );
  }

  void setFilter(MapFilter filter) =>
      emit(state.copyWith(activeFilter: filter));

  void toggleHeatmap() => emit(state.copyWith(showHeatmap: !state.showHeatmap));

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) => GeoDistanceHelper.distanceInKm(lat1, lon1, lat2, lon2);
}
