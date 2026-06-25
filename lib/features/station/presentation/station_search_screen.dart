import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/model/nearby_station.dart';
import '../domain/station_provider.dart';

class StationSearchScreen extends ConsumerStatefulWidget {
  const StationSearchScreen({super.key});

  @override
  ConsumerState<StationSearchScreen> createState() =>
      _StationSearchScreenState();
}

class _StationSearchScreenState extends ConsumerState<StationSearchScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(nearbyStationsProvider.notifier).search(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(nearbyStationsProvider);
    final fuelType = ref.watch(stationFuelTypeProvider);
    final radius = ref.watch(stationRadiusProvider);
    final sort = ref.watch(stationSortProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('주유소 검색')),
      body: Column(
        children: [
          _FilterBar(
            fuelType: fuelType,
            radius: radius,
            sort: sort,
            onFuelTypeChanged: (v) {
              ref.read(stationFuelTypeProvider.notifier).state = v;
              ref.read(nearbyStationsProvider.notifier).search();
            },
            onRadiusChanged: (v) {
              ref.read(stationRadiusProvider.notifier).state = v;
              ref.read(nearbyStationsProvider.notifier).search();
            },
            onSortChanged: (v) {
              ref.read(stationSortProvider.notifier).state = v;
              ref.read(nearbyStationsProvider.notifier).search();
            },
          ),
          Expanded(
            child: stationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.read(nearbyStationsProvider.notifier).search(),
              ),
              data: (stations) {
                if (stations.isEmpty) {
                  return _EmptyView(
                    onRetry: () =>
                        ref.read(nearbyStationsProvider.notifier).search(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(nearbyStationsProvider.notifier).search(),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16, 8, 16,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: stations.length,
                    itemBuilder: (context, index) => _StationCard(
                      station: stations[index],
                      fuelTypeLabel: _fuelTypeLabel(fuelType),
                      onTap: () =>
                          _showStationDetail(context, stations[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fuelTypeLabel(String code) {
    switch (code) {
      case 'B027':
        return '휘발유';
      case 'B034':
        return '고급휘발유';
      default:
        return '휘발유';
    }
  }

  void _showStationDetail(BuildContext context, NearbyStation station) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _StationDetailSheet(station: station),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String fuelType;
  final int radius;
  final int sort;
  final ValueChanged<String> onFuelTypeChanged;
  final ValueChanged<int> onRadiusChanged;
  final ValueChanged<int> onSortChanged;

  const _FilterBar({
    required this.fuelType,
    required this.radius,
    required this.sort,
    required this.onFuelTypeChanged,
    required this.onRadiusChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _FilterDropdown<String>(
            value: fuelType,
            items: const [
              DropdownMenuItem(value: 'B027', child: Text('휘발유')),
              DropdownMenuItem(value: 'B034', child: Text('고급휘발유')),
            ],
            onChanged: onFuelTypeChanged,
          ),
          const SizedBox(width: 8),
          _FilterDropdown<int>(
            value: sort,
            items: const [
              DropdownMenuItem(value: 1, child: Text('가격순')),
              DropdownMenuItem(value: 2, child: Text('거리순')),
            ],
            onChanged: onSortChanged,
          ),
          const Spacer(),
          Text('반경', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 4),
          _FilterDropdown<int>(
            value: radius,
            items: const [
              DropdownMenuItem(value: 1000, child: Text('1km')),
              DropdownMenuItem(value: 3000, child: Text('3km')),
              DropdownMenuItem(value: 5000, child: Text('5km')),
            ],
            onChanged: onRadiusChanged,
          ),
          const SizedBox(width: 4),
          Text('이내', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: const TextStyle(fontSize: 12, color: Color(0xFF1B2838)),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final NearbyStation station;
  final String fuelTypeLabel;
  final VoidCallback onTap;

  const _StationCard({
    required this.station,
    required this.fuelTypeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _brandColor(station.brand).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _brandShort(station.brand),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _brandColor(station.brand),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2838),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          station.distanceDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2838).withAlpha(13),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            station.brandDisplayName,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1B2838),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${station.priceDisplay}원',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  Text(
                    fuelTypeLabel,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _brandColor(String brand) {
    switch (brand) {
      case 'SKE':
        return const Color(0xFFFF0000);
      case 'GSC':
        return const Color(0xFF0066CC);
      case 'HDO':
        return const Color(0xFF00A550);
      case 'SOL':
        return const Color(0xFFFFCC00);
      default:
        return const Color(0xFF666666);
    }
  }

  String _brandShort(String brand) {
    switch (brand) {
      case 'SKE':
        return 'SK';
      case 'GSC':
        return 'GS';
      case 'HDO':
        return 'HD';
      case 'SOL':
        return 'S-O';
      case 'RTC':
        return '자영';
      case 'ETC':
        return '알뜰';
      default:
        return brand.length > 2 ? brand.substring(0, 2) : brand;
    }
  }
}

class _StationDetailSheet extends StatelessWidget {
  final NearbyStation station;

  const _StationDetailSheet({required this.station});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              station.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2838),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2838).withAlpha(13),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    station.brandDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B2838),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Text(
                  station.distanceDisplay,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_gas_station,
                      color: Color(0xFFFF6B35), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${station.priceDisplay}원/L',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '길찾기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B2838),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NavButton(
                    label: '네이버 지도',
                    color: const Color(0xFF03C75A),
                    onTap: () {
                      Navigator.pop(context);
                      _openNaverMap(station);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NavButton(
                    label: '카카오맵',
                    color: const Color(0xFFFEE500),
                    textColor: const Color(0xFF3C1E1E),
                    onTap: () {
                      Navigator.pop(context);
                      _openKakaoMap(station);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NavButton(
                    label: 'T맵',
                    color: const Color(0xFF0064FF),
                    onTap: () {
                      Navigator.pop(context);
                      _openTmap(station);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNaverMap(NearbyStation s) async {
    final url = Uri.parse(
      'nmap://navigation?dlat=${s.lat}&dlng=${s.lng}&dname=${Uri.encodeComponent(s.name)}&appname=com.bikeridediary.brd_app',
    );
    final fallback = Uri.parse('market://details?id=com.nhn.android.nmap');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      await launchUrl(fallback);
    }
  }

  Future<void> _openKakaoMap(NearbyStation s) async {
    final url = Uri.parse(
      'kakaomap://route?ep=${s.lat},${s.lng}&by=CAR',
    );
    final fallback = Uri.parse('market://details?id=net.daum.android.map');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      await launchUrl(fallback);
    }
  }

  Future<void> _openTmap(NearbyStation s) async {
    final url = Uri.parse(
      'tmap://route?goalx=${s.lng}&goaly=${s.lat}&goalname=${Uri.encodeComponent(s.name)}',
    );
    final fallback =
        Uri.parse('market://details?id=com.skt.tmap.ku');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      await launchUrl(fallback);
    }
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor ?? Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1B2838)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 검색'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ev_station_rounded,
              size: 40,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '주변에 주유소가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2838),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '검색 반경을 늘려보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 검색'),
          ),
        ],
      ),
    );
  }
}
