import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  Timer? _autoRefreshTimer;
  Timer? _parkingTimeTimer;
  late TabController _tabController;
  int? _selectedSpotId;
  String? _selectedVehicleId;
  int _illegalParkingCount = 0;
  bool _isAdminMode = false;
  final String _correctPassword = '1234';

  List<Map<String, dynamic>> vehicles = [];

  List<Map<String, dynamic>> parkingSpots = [
    {'id': 1, 'occupied': false, 'x': 230.0, 'y': 260.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null},
    {'id': 2, 'occupied': false, 'x': 230.0, 'y': 235.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null},
    {'id': 3, 'occupied': false, 'x': 230.0, 'y': 210.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null},
    {'id': 4, 'occupied': false, 'x': 230.0, 'y': 185.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null},
    {'id': 5, 'occupied': false, 'x': 230.0, 'y': 160.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null},
    {'id': 6, 'occupied': false, 'x': 230.0, 'y': 135.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null},
    {'id': 7, 'occupied': false, 'x': 230.0, 'y': 110.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null},
    {'id': 8, 'occupied': false, 'x': 156.7, 'y': 260.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null},
    {'id': 9, 'occupied': false, 'x': 156.7, 'y': 235.0, 'angle': 1.5708, 'width': 25.0, 'height': 45.0, 'parkingStartTime': null}
  ];

  static const double mapWidth = 365.0;
  static const double mapHeight = 606.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fetchDataFromServer();

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _fetchDataFromServer();
        if (_isAdminMode) {
          _fetchVehicleData();
        }
      }
    });

    _parkingTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _parkingTimeTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataFromServer() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responseData = await _apiService.fetchParkingData();
      final List<dynamic> items = responseData['items'] ?? [];

      setState(() {
        _illegalParkingCount = 0;

        for (var itemData in items) {
          final spotId = itemData['id'];
          final spotStatus = itemData['status'];

          if (spotId != null && spotStatus != null) {
            final spotIndex = parkingSpots.indexWhere((spot) => spot['id'] == spotId);
            if (spotIndex != -1) {
              bool newOccupied = (spotStatus == 1);
              bool wasOccupied = parkingSpots[spotIndex]['occupied'];

              if (wasOccupied != newOccupied) {
                if (newOccupied) {
                  parkingSpots[spotIndex]['parkingStartTime'] = DateTime.now();
                } else {
                  parkingSpots[spotIndex]['parkingStartTime'] = null;
                }
              }

              parkingSpots[spotIndex]['occupied'] = newOccupied;
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "데이터 로딩 실패\n${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchVehicleData() async {
    try {
      final newVehicles = await _apiService.fetchVehicleData(vehicles);
      setState(() {
        vehicles = newVehicles;
        _illegalParkingCount = vehicles.length;
      });
    } catch (e) {
      // 차량 데이터 로딩 실패
    }
  }

  String _getParkingDuration(DateTime? startTime) {
    if (startTime == null) return '주차 가능';

    final duration = DateTime.now().difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _getVehicleDuration(DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
  }

  @override
  Widget build(BuildContext context) {
    int availableSpots = parkingSpots.where((spot) => !spot['occupied']).length;
    int occupiedSpots = parkingSpots.length - availableSpots;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🅿️ 주차장 현황',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showAdminDialog(),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _isAdminMode
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isAdminMode
                                        ? Colors.orange.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  color: _isAdminMode
                                      ? Colors.orange
                                      : Colors.white.withOpacity(0.5),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            iconSize: 22,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                                    ),
                                  )
                                : const Icon(Icons.refresh, color: Color(0xFF00D9FF)),
                            onPressed: _isLoading ? null : () {
                              _fetchDataFromServer();
                              if (_isAdminMode) {
                                _fetchVehicleData();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _buildStatsSummary(availableSpots, occupiedSpots),
              ),

              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF00D9FF).withOpacity(0.2),
                    ),
                    labelColor: const Color(0xFF00D9FF),
                    unselectedLabelColor: Colors.white.withOpacity(0.5),
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_view, size: 20), text: '목록'),
                      Tab(icon: Icon(Icons.map, size: 20), text: '지도'),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGridView(),
                      _buildMapView(),
                    ],
                  ),
                ),
              ),

              if (_isAdminMode)
                SliverToBoxAdapter(
                  child: _buildAdminStats(),
                ),

              SliverToBoxAdapter(
                child: _buildRealtimeIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(int available, int occupied) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(available.toString(), '주차 가능', const Color(0xFF51CF66)),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          _buildStatItem(occupied.toString(), '사용 중', const Color(0xFFFF6B6B)),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          _buildStatItem(parkingSpots.length.toString(), '전체', const Color(0xFF00D9FF)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '실시간 주차 현황',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: parkingSpots.length,
            itemBuilder: (context, index) {
              final spot = parkingSpots[index];
              return _buildParkingSpotCard(spot);
            },
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildParkingSpotCard(Map<String, dynamic> spot) {
    final isOccupied = spot['occupied'];
    final parkingDuration = _getParkingDuration(spot['parkingStartTime']);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isOccupied
            ? const Color(0xFFFF6B6B).withOpacity(0.15)
            : const Color(0xFF51CF66).withOpacity(0.15),
        border: Border.all(
          color: isOccupied
              ? const Color(0xFFFF6B6B).withOpacity(0.4)
              : const Color(0xFF51CF66).withOpacity(0.4),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedSpotId = spot['id'];
            });
            _tabController.animateTo(1);
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _selectedSpotId = null;
                });
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isOccupied ? '🚗' : '✅',
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  '${spot['id']}번',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isOccupied
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF51CF66),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? const Color(0xFFFF6B6B).withOpacity(0.1)
                        : const Color(0xFF51CF66).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOccupied ? '사용 중' : '주차 가능',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isOccupied
                          ? const Color(0xFFFF6B6B).withOpacity(0.9)
                          : const Color(0xFF51CF66).withOpacity(0.9),
                    ),
                  ),
                ),
                if (isOccupied) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00D9FF).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer,
                          size: 12,
                          color: Color(0xFF00D9FF),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            parkingDuration,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00D9FF),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: mapWidth,
          height: mapHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: mapWidth,
                height: mapHeight,
                child: const Image(
                  image: AssetImage('assets/images/2.png'),
                  fit: BoxFit.fill,
                ),
              ),

              ...parkingSpots.map((spot) {
                final isSelected = spot['id'] == _selectedSpotId;

                return Positioned(
                  left: spot['x'],
                  top: spot['y'],
                  child: Transform.rotate(
                    angle: spot['angle'],
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: spot['width'],
                      height: spot['height'],
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00D9FF).withOpacity(0.9)
                            : spot['occupied']
                                ? const Color(0xFFFF6B6B).withOpacity(0.7)
                                : const Color(0xFF51CF66).withOpacity(0.7),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00D9FF).withOpacity(0.6),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              spot['id'].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSelected ? 20 : 16,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF00D9FF),
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              if (_isAdminMode)
                ...vehicles.map((vehicle) {
                  final isSelected = vehicle['id'] == _selectedVehicleId;

                  return Positioned(
                    left: vehicle['x'] - 15,
                    top: vehicle['y'] - 15,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isSelected ? 40 : 30,
                      height: isSelected ? 40 : 30,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00D9FF).withOpacity(0.95)
                            : Colors.orange.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF00D9FF).withOpacity(0.6)
                                : Colors.orange.withOpacity(0.5),
                            blurRadius: isSelected ? 15 : 10,
                            spreadRadius: isSelected ? 3 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: isSelected ? 20 : 16,
                      ),
                    ),
                  );
                }).toList(),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(const Color(0xFF51CF66), '주차 가능'),
          const SizedBox(width: 20),
          _buildLegendItem(const Color(0xFFFF6B6B), '사용 중'),
          if (_isAdminMode) ...[
            const SizedBox(width: 20),
            _buildLegendItem(Colors.orange, '불법주차'),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.4), width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildRealtimeIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _isLoading ? const Color(0xFFFFB84D) : const Color(0xFF51CF66),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _isLoading
                      ? const Color(0xFFFFB84D).withOpacity(0.5)
                      : const Color(0xFF51CF66).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isLoading ? '업데이트 중...' : '3초마다 자동 업데이트',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!_isLoading) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle,
              color: Color(0xFF51CF66),
              size: 14,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.red.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '불법주차 현황',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$_illegalParkingCount대',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (vehicles.isEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '불법주차 차량이 없습니다',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _buildVehicleCard(vehicle, index);
              },
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '4점 투영 변환(Perspective Transform)으로 정확한 위치 매핑',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, int index) {
    final duration = _getVehicleDuration(vehicle['startTime']);
    final isSelected = vehicle['id'] == _selectedVehicleId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00D9FF).withOpacity(0.25)
            : Colors.orange.withOpacity(0.15),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00D9FF).withOpacity(0.6)
              : Colors.orange.withOpacity(0.4),
          width: isSelected ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedVehicleId = vehicle['id'];
            });
            _tabController.animateTo(1);
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _selectedVehicleId = null;
                });
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🚗',
                  style: TextStyle(fontSize: isSelected ? 40 : 36),
                ),
                const SizedBox(height: 6),
                Text(
                  '${index + 1}번',
                  style: TextStyle(
                    fontSize: isSelected ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF00D9FF) : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '불법주차',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00D9FF).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer,
                        size: 10,
                        color: Color(0xFF00D9FF),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00D9FF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminDialog() {
    String inputPassword = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock, color: Color(0xFF00D9FF)),
                  SizedBox(width: 12),
                  Text(
                    '관리자 모드',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isAdminMode ? '관리자 모드를 종료하시겠습니까?' : '비밀번호를 입력하세요',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  if (!_isAdminMode) ...[
                    const SizedBox(height: 20),
                    TextField(
                      autofocus: true,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: '••••',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        counterText: '',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00D9FF)),
                        ),
                      ),
                      onChanged: (value) {
                        inputPassword = value;
                      },
                      onSubmitted: (value) {
                        if (value == _correctPassword) {
                          setState(() {
                            _isAdminMode = true;
                          });
                          _fetchVehicleData();
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pop();
                          _showErrorDialog();
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '취소',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
                if (_isAdminMode)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isAdminMode = false;
                        vehicles.clear();
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      '종료',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () {
                      if (inputPassword == _correctPassword) {
                        setState(() {
                          _isAdminMode = true;
                        });
                        _fetchVehicleData();
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pop();
                        _showErrorDialog();
                      }
                    },
                    child: const Text(
                      '확인',
                      style: TextStyle(color: Color(0xFF00D9FF)),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withOpacity(0.5)),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 12),
              Text(
                '오류',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            '비밀번호가 올바르지 않습니다.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(color: Color(0xFF00D9FF)),
              ),
            ),
          ],
        );
      },
    );
  }
}
