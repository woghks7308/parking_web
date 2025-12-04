// 4점 투영 변환 (Perspective Transform)
class CoordinateTransformer {
  late List<double> _transformMatrix;

  // 캘리브레이션 포인트 (카메라 좌표 -> 지도 좌표)
  static const List<Map<String, double>> calibrationPoints = [
    // 좌상단
    {'cameraX': 216, 'cameraY': 210, 'mapX': 177.2, 'mapY': 342.6},
    // 우상단
    {'cameraX': 417, 'cameraY': 32, 'mapX': 261.2, 'mapY': 225.6},
    // 우하단
    {'cameraX': 554, 'cameraY': 438, 'mapX': 259.2, 'mapY': 436.6},
    // 좌하단
    {'cameraX': 142, 'cameraY': 443, 'mapX': 165.2, 'mapY': 437.6},
  ];

  CoordinateTransformer() {
    _transformMatrix = _calculatePerspectiveMatrix();
  }

  // Perspective Transform 행렬 계산
  List<double> _calculatePerspectiveMatrix() {
    final src = calibrationPoints.map((p) => [p['cameraX']!, p['cameraY']!]).toList();
    final dst = calibrationPoints.map((p) => [p['mapX']!, p['mapY']!]).toList();

    // 행렬 A 구성 (8x8)
    List<List<double>> A = [];
    List<double> b = [];

    for (int i = 0; i < 4; i++) {
      double x = src[i][0];
      double y = src[i][1];
      double u = dst[i][0];
      double v = dst[i][1];

      A.add([x, y, 1, 0, 0, 0, -u * x, -u * y]);
      b.add(u);

      A.add([0, 0, 0, x, y, 1, -v * x, -v * y]);
      b.add(v);
    }

    List<double> h = _solveLinearSystem(A, b);
    return [...h, 1.0];
  }

  // 선형 시스템 풀기 (가우스 소거법)
  List<double> _solveLinearSystem(List<List<double>> A, List<double> b) {
    int n = A.length;

    for (int i = 0; i < n; i++) {
      int maxRow = i;
      for (int k = i + 1; k < n; k++) {
        if (A[k][i].abs() > A[maxRow][i].abs()) {
          maxRow = k;
        }
      }

      var temp = A[i];
      A[i] = A[maxRow];
      A[maxRow] = temp;

      double tempB = b[i];
      b[i] = b[maxRow];
      b[maxRow] = tempB;

      for (int k = i + 1; k < n; k++) {
        double factor = A[k][i] / A[i][i];
        for (int j = i; j < n; j++) {
          A[k][j] -= factor * A[i][j];
        }
        b[k] -= factor * b[i];
      }
    }

    List<double> x = List.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      x[i] = b[i];
      for (int j = i + 1; j < n; j++) {
        x[i] -= A[i][j] * x[j];
      }
      x[i] /= A[i][i];
    }

    return x;
  }

  // 좌표 변환 함수: 카메라 좌표 -> 지도 좌표
  Map<String, double> convertCameraToMapCoords(double cameraX, double cameraY) {
    List<double> h = _transformMatrix;

    double x = cameraX;
    double y = cameraY;

    double denominator = h[6] * x + h[7] * y + 1.0;
    double mapX = (h[0] * x + h[1] * y + h[2]) / denominator;
    double mapY = (h[3] * x + h[4] * y + h[5]) / denominator;

    return {
      'x': mapX - 10.0,
      'y': mapY - 110.0,
    };
  }
}
