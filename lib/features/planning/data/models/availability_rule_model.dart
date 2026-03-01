class AvailabilityRuleModel {
  final String id;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> daysOfWeek;
  final int startHour;
  final int endHour;
  final int slotDurationMins;
  final int capacity;
  final List<String> excludedTimes;
  final String status;

  AvailabilityRuleModel({
    required this.id,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.daysOfWeek,
    required this.startHour,
    required this.endHour,
    required this.slotDurationMins,
    required this.capacity,
    this.excludedTimes = const [],
    required this.status,
  });

  factory AvailabilityRuleModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityRuleModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      daysOfWeek: (json['daysOfWeek'] as List).map((e) => e as int).toList(),
      startHour: json['startHour'] as int,
      endHour: json['endHour'] as int,
      slotDurationMins: json['slotDurationMins'] as int,
      capacity: json['capacity'] as int? ?? 1,
      excludedTimes: (json['excludedTimes'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  String get daysLabel {
    const dayNames = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return daysOfWeek.map((d) => dayNames[d]).join(', ');
  }

  String get hoursLabel => '${startHour}h - ${endHour}h';
}
