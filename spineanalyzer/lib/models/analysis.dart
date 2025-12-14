class Analysis {
  int id;
  int userId;
  String imagePath;
  double angle;
  String date;
  String notes;

  Analysis({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.angle,
    required this.date,
    required this.notes,
  });

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      id: json['id'],
      userId: json['userId'],
      imagePath: json['imagePath'],
      angle: (json['angle'] as num).toDouble(),
      date: json['date'],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imagePath': imagePath,
      'angle': angle,
      'date': date,
      'notes': notes,
    };
  }
}
