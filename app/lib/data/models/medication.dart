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
      'id': id,
      'name': name,
      'dosage': dosage,
      'stockCount': stockCount,
      'scheduleHours': scheduleHours,
      'scheduleMinutes': scheduleMinutes,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      stockCount: map['stockCount'] as int? ?? 0,
      scheduleHours: List<int>.from(map['scheduleHours'] as List? ?? []),
      scheduleMinutes: List<int>.from(map['scheduleMinutes'] as List? ?? []),
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
