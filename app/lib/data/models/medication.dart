class Medication {
  final String id;
  final String name;
  final String dosage;
  final int stockCount;
  final List<int> scheduleHours; // Simplified schedule for now
  final List<int> scheduleMinutes;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.stockCount,
    required this.scheduleHours,
    required this.scheduleMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'stockCount': stockCount,
      'scheduleHours': scheduleHours,
      'scheduleMinutes': scheduleMinutes,
    };
  }

  factory Medication.fromMap(String id, Map<String, dynamic> map) {
    return Medication(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      stockCount: map['stockCount'] ?? 0,
      scheduleHours: List<int>.from(map['scheduleHours'] ?? []),
      scheduleMinutes: List<int>.from(map['scheduleMinutes'] ?? []),
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    int? stockCount,
    List<int>? scheduleHours,
    List<int>? scheduleMinutes,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      stockCount: stockCount ?? this.stockCount,
      scheduleHours: scheduleHours ?? this.scheduleHours,
      scheduleMinutes: scheduleMinutes ?? this.scheduleMinutes,
    );
  }
}
