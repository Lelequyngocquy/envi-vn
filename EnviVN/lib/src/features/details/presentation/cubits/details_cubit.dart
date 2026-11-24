import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:envivn/src/core/domain/entities/app_location_entity.dart';
import 'package:envivn/src/core/domain/interfaces/i_details_repository.dart';
import '../../domain/entities/detail_tab.dart';
import 'details_state.dart';

class DetailsCubit extends Cubit<DetailsState> {
  final IDetailsRepository repository;
  int _requestSeq = 0;

  DetailsCubit({required this.repository}) : super(const DetailsState()) {
    final cached = repository.getCachedDetails();
    if (cached != null) {
      emit(
        state.copyWith(
          status: DetailsStatus.success,
          details: cached,
          noticeMessage: 'Dữ liệu đã lưu ngoại tuyến',
        ),
      );
    }
  }

  void setDetailTab(DetailTab tab) {
    if (state.activeDetailTab != tab) {
      emit(state.copyWith(activeDetailTab: tab));
    }
  }

  Future<void> fetchDetails({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    final seq = ++_requestSeq;
    emit(state.copyWith(status: DetailsStatus.loading, clearError: true));
    final result = await repository.getDetailsForecast(
      latitude: latitude,
      longitude: longitude,
      forceRefresh: forceRefresh,
    );
    if (isClosed || seq != _requestSeq) return;
    if (result.isSuccess && result.data != null) {
      emit(
        state.copyWith(
          status: DetailsStatus.success,
          details: result.data,
          noticeMessage: result.message,
          clearNotice: result.message == null,
          clearError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: DetailsStatus.failure,
          errorMessage: result.message ?? 'Không thể tải dữ liệu chi tiết',
        ),
      );
    }
  }

  Future<void> fetchForLocation(
    AppLocationEntity location, {
    bool forceRefresh = false,
  }) => fetchDetails(
    latitude: location.latitude,
    longitude: location.longitude,
    forceRefresh: forceRefresh,
  );
}
