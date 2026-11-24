import 'package:equatable/equatable.dart';

/// Pure configuration entity for rendering vector/raster map tiles.
class MapTileConfig extends Equatable {
  final String urlTemplate;
  final String userAgentPackageName;

  const MapTileConfig({
    required this.urlTemplate,
    required this.userAgentPackageName,
  });

  const MapTileConfig.defaults()
      : urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName = 'com.envivn.envivn';

  @override
  List<Object?> get props => [urlTemplate, userAgentPackageName];
}
