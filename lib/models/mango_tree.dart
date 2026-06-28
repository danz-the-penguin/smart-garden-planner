class MangoTree {
  final int? id;
  final String plotName;
  final DateTime plantingDate;
  final String status; // seedling, vegetative, flowering, fruiting, harvest 

  MangoTree({
    this.id,
    required this.plotName,
    required this.plantingDate,
    required this.status,
  });

  // Converts a MangoTree object into a Map for SQLite [cite: 1408]
  Map<String, dynamic> toMap() {
    return {
      'tree_id': id,
      'user_id': 1, // Defaulting to 1 for now until you build login
      'plot_name': plotName,
      'planting_date': plantingDate.toIso8601String(),
      'status': status,
    };
  }
}
