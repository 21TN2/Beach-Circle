class Building {
  final String name;
  final double lat;
  final double lng;
  final String category;

  const Building({
    required this.name,
    required this.lat,
    required this.lng,
    required this.category,
  });
}

//CSULB Building Coordinates
//Categories based on the official CSULB campus map zones
const List<Building> csulbBuildings = [
  // =========================
  // WEST CAMPUS
  // =========================
  Building(name: 'PYR', lat: 33.7874, lng: -118.1140, category: 'West Campus'),
  Building(name: 'BAC', lat: 33.7863, lng: -118.1150, category: 'West Campus'),
  Building(name: 'POOL', lat: 33.7840, lng: -118.1130, category: 'West Campus'),
  Building(name: 'Rhodes Tennis Center', lat: 33.7847, lng: -118.1110, category: 'West Campus'),
  Building(name: 'George Allen Field', lat: 33.7859, lng: -118.1110, category: 'West Campus'),
  Building(name: 'RUGBY', lat: 33.7849, lng: -118.1120, category: 'West Campus'),
  Building(name: 'SOFTBALL', lat: 33.7861, lng: -118.1120, category: 'West Campus'),
  Building(name: 'BASEBALL', lat: 33.7860, lng: -118.1130, category: 'West Campus'),

  // =========================
  // NORTH CAMPUS
  // =========================
  Building(name: 'CPAC', lat: 33.7884, lng: -118.1130, category: 'North Campus'),
  Building(name: 'DC', lat: 33.7882, lng: -118.1130, category: 'North Campus'),
  Building(name: 'Bob Cole Conservatory', lat: 33.7877, lng: -118.1120, category: 'North Campus'),
  Building(name: 'UMC', lat: 33.7871, lng: -118.1120, category: 'North Campus'),

  // =========================
  // EAST CAMPUS
  // =========================
  Building(name: 'SRWC', lat: 33.7851, lng: -118.1090, category: 'East Campus'),
  Building(name: 'UP', lat: 33.7844, lng: -118.1090, category: 'East Campus'),
  Building(name: 'UPS', lat: 33.7843, lng: -118.1080, category: 'East Campus'),
  Building(name: 'CORP', lat: 33.7839, lng: -118.1090, category: 'East Campus'),
  Building(name: 'BBS', lat: 33.7836, lng: -118.1090, category: 'East Campus'),
  Building(name: 'MS', lat: 33.7837, lng: -118.1100, category: 'East Campus'),
  Building(name: 'REC', lat: 33.7834, lng: -118.1090, category: 'East Campus'),
  Building(name: 'VEC', lat: 33.7828, lng: -118.1100, category: 'East Campus'),
  Building(name: 'ECS', lat: 33.7836, lng: -118.1100, category: 'East Campus'),
  Building(name: 'ET', lat: 33.7831, lng: -118.1090, category: 'East Campus'),
  Building(name: 'EN2', lat: 33.7832, lng: -118.1110, category: 'East Campus'),
  Building(name: 'EN3', lat: 33.7836, lng: -118.1110, category: 'East Campus'),
  Building(name: 'EN4', lat: 33.7837, lng: -118.1110, category: 'East Campus'),
  Building(name: 'DESN', lat: 33.7821, lng: -118.1090, category: 'East Campus'),
  Building(name: 'HSD', lat: 33.7827, lng: -118.1100, category: 'East Campus'),
  Building(name: 'SSPA', lat: 33.7821, lng: -118.1110, category: 'East Campus'),
  Building(name: 'CPCE', lat: 33.7820, lng: -118.1110, category: 'East Campus'),
  Building(name: 'FND', lat: 33.7813, lng: -118.1100, category: 'East Campus'),
  Building(name: 'OP', lat: 33.7824, lng: -118.1100, category: 'East Campus'),
  Building(name: 'OCS', lat: 33.7824, lng: -118.1110, category: 'East Campus'),

  // =========================
  // CENTRAL CAMPUS
  // =========================
  Building(name: 'COB', lat: 33.7841, lng: -118.1160, category: 'Central Campus'),
  Building(name: 'KCAM', lat: 33.7835, lng: -118.1150, category: 'Central Campus'),
  Building(name: 'BH', lat: 33.78295, lng: -118.11542, category: 'Central Campus'),
  Building(name: 'HC', lat: 33.7835, lng: -118.1140, category: 'Central Campus'),
  Building(name: 'KIN', lat: 33.7830, lng: -118.1120, category: 'Central Campus'),
  Building(name: 'USU', lat: 33.7812, lng: -118.1140, category: 'Central Campus'),
  Building(name: 'CP', lat: 33.7816, lng: -118.1120, category: 'Central Campus'),
  Building(name: 'FCS', lat: 33.7815, lng: -118.1160, category: 'Central Campus'),
  Building(name: 'SHS', lat: 33.7825, lng: -118.1180, category: 'Central Campus'),
  Building(name: 'PTS', lat: 33.7853, lng: -118.1160, category: 'Central Campus'),

  // =========================
  // SOUTH CAMPUS
  // =========================
  Building(name: 'BKS', lat: 33.7799, lng: -118.1140, category: 'South Campus'),
  Building(name: 'PSY', lat: 33.7793, lng: -118.1140, category: 'South Campus'),
  Building(name: 'HSCI', lat: 33.7800, lng: -118.1130, category: 'South Campus'),
  Building(name: 'MLSC', lat: 33.7801, lng: -118.1120, category: 'South Campus'),
  Building(name: 'MIC', lat: 33.7794, lng: -118.1120, category: 'South Campus'),
  Building(name: 'LIB', lat: 33.7773, lng: -118.1150, category: 'South Campus'),
];