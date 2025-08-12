class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final DateTime? dueDate;
  final String colorHex;
  final DateTime createdAt;

  const Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.dueDate,
    this.colorHex = '#4F46E5',
    required this.createdAt,
  });

  double progress(double saved) {
    if (targetAmount <= 0) return 0;
    final p = saved / targetAmount;
    return p.clamp(0, 1);
  }

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: m['id'] as int?,
        name: m['name'] as String,
        targetAmount: (m['target_amount'] as num).toDouble(),
        dueDate: m['due_date'] == null ? null : DateTime.parse(m['due_date'] as String),
        colorHex: (m['color'] as String?) ?? '#4F46E5',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'due_date': dueDate?.toIso8601String(),
        'color': colorHex,
        'created_at': createdAt.toIso8601String(),
      };
}