import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:envivn/src/common/constants/colors.dart';
import 'package:envivn/src/core/presentation/widgets/future_work_widget.dart';
import 'package:envivn/src/core/presentation/widgets/location_loading_overlay.dart';
import 'package:envivn/src/features/advisor/presentation/widgets/advisor_modal_sheet.dart';
import 'package:envivn/src/features/air_quality/presentation/cubits/air_quality_cubit.dart';
import 'package:envivn/src/features/details/presentation/cubits/details_cubit.dart';
import 'package:envivn/src/features/explore/presentation/pages/explore_page.dart';
import 'package:envivn/src/features/home/presentation/cubits/home_dashboard_cubit.dart';
import 'package:envivn/src/features/home/presentation/cubits/home_dashboard_state.dart';
import 'package:envivn/src/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:envivn/src/features/home/presentation/widgets/liquid_glass_bottom_bar.dart';
import 'package:envivn/src/features/map/presentation/pages/map_page.dart';

class HomePage extends StatefulWidget {
  final int initialTab;

  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Tracks which tabs have been visited so heavy tabs like MapPage mount lazily on first visit.
  final Set<int> _mountedTabs = {};

  @override
  void initState() {
    super.initState();
    _mountedTabs.add(widget.initialTab);
    final cubit = context.read<HomeDashboardCubit>();
    cubit.initDashboard();
    if (widget.initialTab != 0) {
      cubit.setTab(widget.initialTab);
    }
  }

  void _openAdvisor(BuildContext context) {
    final detailsState = context.read<DetailsCubit>().state;
    final aqiState = context.read<AirQualityCubit>().state;
    final homeState = context.read<HomeDashboardCubit>().state;
    AdvisorModalSheet.show(
      context,
      airQuality: aqiState.airQuality,
      weather: detailsState.details,
      cityName: homeState.currentCity.name,
      location: homeState.currentLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeDashboardCubit, HomeDashboardState, int>(
      selector: (state) => state.currentTab,
      builder: (context, currentTab) {
        _mountedTabs.add(currentTab);
        return PopScope(
          canPop: currentTab == 0,
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            if (didPop) return;
            context.read<HomeDashboardCubit>().handleBackPress();
          },
          child: Scaffold(
            backgroundColor: UIColors.bg,
            body: Stack(
              children: [
                ClipRect(
                  child: IndexedStack(
                    index: currentTab,
                    children: [
                      _mountedTabs.contains(0)
                          ? const HomeDashboardView()
                          : const SizedBox.shrink(),
                      _mountedTabs.contains(1)
                          ? const MapPage()
                          : const SizedBox.shrink(),
                      _mountedTabs.contains(2)
                          ? const ExplorePage()
                          : const SizedBox.shrink(),
                      _mountedTabs.contains(3)
                          ? FutureWorkWidget(
                              title: 'Cài đặt hệ thống',
                              subtitle:
                                  'Khu vực quản lý thiết lập cá nhân, thông báo và tùy chỉnh ứng dụng đang được hoàn thiện.',
                              badgeText: 'Sắp ra mắt • COMING SOON',
                              centerIcon: Icons.tune_rounded,
                              onBack: () =>
                                  context.read<HomeDashboardCubit>().setTab(0),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: LiquidGlassBottomBar(
                    currentTab: currentTab,
                    onTabSelected: (index) =>
                        context.read<HomeDashboardCubit>().setTab(index),
                    onAdvisorTap: () => _openAdvisor(context),
                  ),
                ),
                BlocBuilder<HomeDashboardCubit, HomeDashboardState>(
                  buildWhen: (prev, curr) =>
                      prev.isChangingLocation != curr.isChangingLocation ||
                      (curr.isChangingLocation &&
                          prev.currentCity != curr.currentCity),
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: state.isChangingLocation
                          ? LocationLoadingOverlay(
                              key: const ValueKey('location_loading_overlay'),
                              cityName: state.currentCity.name,
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
