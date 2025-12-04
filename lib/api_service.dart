import 'dart:convert';
import 'package:http/http.dart' as http;
import 'coordinate_transformer.dart';

class ApiService {
  final String serverUrl = 'http://3.36.54.178:4000/api/updates';
  final String vehicleUrl = 'http://3.36.54.178:4000/api/vehicles';
  final CoordinateTransformer _transformer = CoordinateTransformer();

  Future<Map<String, dynamic>> fetchParkingData() async {
    final response = await http.get(Uri.parse(serverUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('서버 응답 오류: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchVehicleData(List<Map<String, dynamic>> existingVehicles) async {
    final response = await http.get(Uri.parse(vehicleUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> vehicleList = responseData['vehicles'] ?? [];

      return vehicleList.map((v) {
        final existingVehicle = existingVehicles.firstWhere(
          (existing) => existing['id'] == v['id'].toString(),
          orElse: () => {},
        );

        final cameraX = (v['x'] as num).toDouble();
        final cameraY = (v['y'] as num).toDouble();
        final duration = v['duration'] ?? 0;

        final mapCoords = _transformer.convertCameraToMapCoords(cameraX, cameraY);

        return {
          'id': v['id'].toString(),
          'x': mapCoords['x']!,
          'y': mapCoords['y']!,
          'originalX': cameraX,
          'originalY': cameraY,
          'duration': duration,
          'msg': v['msg'] ?? 'Illegal Parking',
          'startTime': existingVehicle['startTime'] ??
              DateTime.now().subtract(Duration(seconds: duration)),
        };
      }).toList();
    }
    return existingVehicles;
  }
}
