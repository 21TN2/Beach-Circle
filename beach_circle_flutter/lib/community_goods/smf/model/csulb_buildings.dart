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
const List<Building> csulbBuildings = [

  // =========================
  // WEST CAMPUS
  // =========================
  Building(name: 'Walter Pyramid (PYR)', lat: 33.7874, lng: -118.1140, category: 'West Campus'),
  Building(name: 'Barrett Athletic Administration (BAC)', lat: 33.7863, lng: -118.1150, category: 'West Campus'),
  Building(name: 'College of Business (COB)', lat: 33.7838, lng: -118.1150, category: 'West Campus'),
  Building(name: 'George Allen Field', lat: 33.7859, lng: -118.1110, category: 'West Campus'),
  Building(name: 'Rhodes Tennis Center', lat: 33.7847, lng: -118.1110, category: 'West Campus'),
  Building(name: 'Rugby Field', lat: 33.7849, lng: -118.1120, category: 'West Campus'),
  Building(name: 'Softball Complex', lat: 33.7861, lng: -118.1120, category: 'West Campus'),
  Building(name: 'Baseball Field', lat: 33.7860, lng: -118.1130, category: 'West Campus'),

  // =========================
  // LOWER CAMPUS
  // =========================
  Building(name: 'Carpenter Performing Arts Center (CPAC)', lat: 33.7884, lng: -118.1130, category: 'Lower Campus'),
  Building(name: 'Dance Center (DC)', lat: 33.7881, lng: -118.1130, category: 'Lower Campus'),
  Building(name: 'Bob Cole Conservatory of Music', lat: 33.7877, lng: -118.1120, category: 'Lower Campus'),
  Building(name: 'University Music Center (UMC)', lat: 33.7871, lng: -118.1120, category: 'Lower Campus'),

  Building(name: 'Horn Center (HC)', lat: 33.7834, lng: -118.1140, category: 'Lower Campus'),
  Building(name: 'Health and Human Services 1 (HHS1)', lat: 33.7824, lng: -118.1130, category: 'Lower Campus'),
  Building(name: 'Health and Human Services 2 (HHS2)', lat: 33.7822, lng: -118.1130, category: 'Lower Campus'),
  Building(name: 'Central Plant (CP)', lat: 33.7817, lng: -118.1130, category: 'Lower Campus'),
  Building(name: 'Lindgren Aquatics Center (POOL)', lat: 33.7838, lng: -118.1130, category: 'Lower Campus'),
  Building(name: 'Carolyn Campagna Kleefeld Contemporary Art Museum (KCAM)', lat: 33.7834, lng: -118.1150, category: 'Lower Campus'),

  Building(name: 'College of Professional and Continuing Education (CPaCE)', lat: 33.7822, lng: -118.1110, category: 'Lower Campus'),
  Building(name: 'Social Sciences/Public Administration (SSPA)', lat: 33.7821, lng: -118.1110, category: 'Lower Campus'),
  Building(name: 'Outpost', lat: 33.7823, lng: -118.1110, category: 'Lower Campus'),
  Building(name: 'Vivian Engineering Center (VEC)', lat: 33.7828, lng: -118.1110, category: 'Lower Campus'),

  Building(name: 'Engineering 2 (EN2)', lat: 33.7832, lng: -118.1110, category: 'Lower Campus'),
  Building(name: 'Engineering 3 (EN3)', lat: 33.7836, lng: -118.1110, category: 'Lower Campus'),
  Building(name: 'Engineering 4 (EN4)', lat: 33.7835, lng: -118.1110, category: 'Lower Campus'),
  Building(name: 'Engineering and Computer Science (ECS)', lat: 33.7834, lng: -118.1100, category: 'Lower Campus'),

  // =========================
  // EAST CAMPUS
  // =========================
  Building(name: 'Design (DESN)', lat: 33.7820, lng: -118.1100, category: 'East Campus'),
  Building(name: 'Human Services and Design (HSD)', lat: 33.7827, lng: -118.1100, category: 'East Campus'),
  Building(name: 'Engineering Technology (ET)', lat: 33.7832, lng: -118.1100, category: 'East Campus'),
  Building(name: 'Mail Services (MS)', lat: 33.7837, lng: -118.1100, category: 'East Campus'),
  Building(name: 'Beach Building Services (BBS)', lat: 33.7837, lng: -118.1080, category: 'East Campus'),
  Building(name: 'Corporation Yard (CORP)', lat: 33.7839, lng: -118.1090, category: 'East Campus'),
  Building(name: 'Receiving (REC)', lat: 33.7834, lng: -118.1090, category: 'East Campus'),
  Building(name: 'University Police Department (UP)', lat: 33.7844, lng: -118.1090, category: 'East Campus'),
  Building(name: 'University Print Shop (UPS)', lat: 33.7843, lng: -118.1080, category: 'East Campus'),
  Building(name: 'Student Recreation and Wellness Center (SRWC)', lat: 33.7850, lng: -118.1090, category: 'East Campus'),

  // =========================
  // UPPER CAMPUS
  // =========================
  Building(name: 'Education 2 (ED2)', lat: 33.7758, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Bob and Barbara Ellis Education (EED)', lat: 33.7764, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Academic Services (AS)', lat: 33.7773, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Multi-Media Center (MMC)', lat: 33.7767, lng: -118.1150, category: 'Upper Campus'),
  Building(name: 'McIntosh Humanities (MHB)', lat: 33.7770, lng: -118.1130, category: 'Upper Campus'),
  Building(name: 'Theatre Arts (TA)', lat: 33.7766, lng: -118.1120, category: 'Upper Campus'),
  Building(name: 'Cinematic Arts (CA)', lat: 33.7769, lng: -118.1120, category: 'Upper Campus'),
  Building(name: 'Language Arts Building (LAB)', lat: 33.7770, lng: -118.1130, category: 'Upper Campus'),

  Building(name: 'Fine Arts 1 (FA1)', lat: 33.7772, lng: -118.1130, category: 'Upper Campus'),
  Building(name: 'Fine Arts 2 (FA2)', lat: 33.7776, lng: -118.1130, category: 'Upper Campus'),
  Building(name: 'Fine Arts 3 (FA3)', lat: 33.7780, lng: -118.1130, category: 'Upper Campus'),
  Building(name: 'Fine Arts 4 (FA4)', lat: 33.7785, lng: -118.1130, category: 'Upper Campus'),

  Building(name: 'Faculty Office 2 (FO2)', lat: 33.7784, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Faculty Office 3 (FO3)', lat: 33.7788, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Faculty Office 4 (FO4)', lat: 33.7783, lng: -118.1120, category: 'Upper Campus'),
  Building(name: 'Faculty Office 5 (FO5)', lat: 33.7792, lng: -118.1130, category: 'Upper Campus'),

  Building(name: 'Peterson Hall 1 (PH1)', lat: 33.7791, lng: -118.1130, category: 'Upper Campus'),
  Building(name: 'Shakarian Student Success Center (SSSC)', lat: 33.7795, lng: -118.1130, category: 'Upper Campus'),

  Building(name: 'Microbiology (MIC)', lat: 33.7795, lng: -118.1120, category: 'Upper Campus'),
  Building(name: 'Hall of Science (HSCI)', lat: 33.7800, lng: -118.1130, category: 'Upper Campus'),
  Building(name: 'Molecular and Life Sciences Center (MLSC)', lat: 33.7804, lng: -118.1130, category: 'Upper Campus'),

  Building(name: 'University Bookstore (BKS)', lat: 33.7800, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Psychology (PSY)', lat: 33.7794, lng: -118.1140, category: 'Upper Campus'),

  Building(name: 'Liberal Arts 1 (LA1)', lat: 33.7776, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Liberal Arts 2 (LA2)', lat: 33.7780, lng: -118.1150, category: 'Upper Campus'),
  Building(name: 'Liberal Arts 3 (LA3)', lat: 33.7782, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Liberal Arts 4 (LA4)', lat: 33.7785, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Liberal Arts 5 (LA5)', lat: 33.7788, lng: -118.1140, category: 'Upper Campus'),

  Building(name: 'College of Liberal Arts (CLA)', lat: 33.7780, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Lecture Halls 150/151 (LH)', lat: 33.7781, lng: -118.1140, category: 'Upper Campus'),
  Building(name: 'Library (LIB)', lat: 33.7773, lng: -118.1150, category: 'Upper Campus'),

  // =========================
  // DORMS - BEACHSIDE
  // =========================
  Building(name: 'Pacific', lat: 33.7862, lng: -118.1350, category: 'Dorms - Beachside'),
  Building(name: 'Atlantic', lat: 33.7868, lng: -118.1353, category: 'Dorms - Beachside'),

  // =========================
  // DORMS - HILLSIDE
  // =========================
  Building(name: 'Hillside A', lat: 33.7828, lng: -118.1210, category: 'Dorms - Hillside'),
  Building(name: 'Hillside B', lat: 33.7823, lng: -118.1200, category: 'Dorms - Hillside'),
  Building(name: 'Hillside C', lat: 33.7824, lng: -118.1203, category: 'Dorms - Hillside'),
  Building(name: 'Hillside D', lat: 33.7837, lng: -118.1205, category: 'Dorms - Hillside'),
  Building(name: 'Hillside E', lat: 33.7837, lng: -118.1193, category: 'Dorms - Hillside'),
  Building(name: 'Hillside F', lat: 33.7841, lng: -118.1193, category: 'Dorms - Hillside'),
  Building(name: 'Hillside Commons', lat: 33.7834, lng: -118.1203, category: 'Dorms - Hillside'),
  Building(name: 'Los Cerritos Hall (LCH)', lat: 33.7823, lng: -118.1193, category: 'Dorms - Hillside'),
  Building(name: 'Los Alamitos Hall (LAH)', lat: 33.7832, lng: -118.1193, category: 'Dorms - Hillside'),

  // =========================
  // DORMS - PARKSIDE
  // =========================
  Building(name: 'Parkside G', lat: 33.7859, lng: -118.1203, category: 'Dorms - Parkside'),
  Building(name: 'Parkside H', lat: 33.7867, lng: -118.1193, category: 'Dorms - Parkside'),
  Building(name: 'Parkside J', lat: 33.7863, lng: -118.1203, category: 'Dorms - Parkside'),
  Building(name: 'Parkside K', lat: 33.7864, lng: -118.1203, category: 'Dorms - Parkside'),
  Building(name: 'Parkside L', lat: 33.7864, lng: -118.1213, category: 'Dorms - Parkside'),
  Building(name: 'Parkside M', lat: 33.7873, lng: -118.1193, category: 'Dorms - Parkside'),
  Building(name: 'Parkside N', lat: 33.7872, lng: -118.1203, category: 'Dorms - Parkside'),
  Building(name: 'Parkside P', lat: 33.7876, lng: -118.1203, category: 'Dorms - Parkside'),
  Building(name: 'Parkside Q', lat: 33.7876, lng: -118.1213, category: 'Dorms - Parkside'),
  Building(name: 'Parkside North', lat: 33.7879, lng: -118.1203, category: 'Dorms - Parkside'),
  Building(name: 'Parkside Service Center', lat: 33.7870, lng: -118.1203, category: 'Dorms - Parkside'),

  // =========================
  // DINING HALLS
  // =========================
  Building(name: 'Beachside Dining', lat: 33.7864, lng: -118.1350, category: 'Dining Halls'),
  Building(name: 'Parkside Dining', lat: 33.7868, lng: -118.1213, category: 'Dining Halls'),
  Building(name: 'Hillside Dining', lat: 33.7832, lng: -118.1200, category: 'Dining Halls'),

  // =========================
  // INTERNATIONAL
  // =========================
  Building(name: 'International House', lat: 33.7818, lng: -118.1210, category: 'International'),

  // =========================
  // CAMPUS SERVICES
  // =========================
  Building(name: 'Child Development Center (CDC)', lat: 33.7881, lng: -118.1200, category: 'Campus Services'),
  Building(name: 'Student Health Services (SHS)', lat: 33.7822, lng: -118.1180, category: 'Campus Services'),
  Building(name: 'Visitor Information Center (VIC)', lat: 33.7820, lng: -118.1190, category: 'Campus Services'),
  Building(name: 'Parking and Transportation Services (PTS)', lat: 33.7853, lng: -118.1160, category: 'Campus Services'),
  Building(name: 'Anna W. Ngai Alumni Center (ANAC)', lat: 33.7818, lng: -118.1170, category: 'Campus Services'),
  Building(name: 'Brotman Hall (BH)', lat: 33.7825, lng: -118.1150, category: 'Campus Services'),
];