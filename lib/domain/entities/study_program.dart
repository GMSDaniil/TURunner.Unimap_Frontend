class StudyProgramEntity {
  final String name;
  final String stupoNumber;

  StudyProgramEntity({
    required this.name,
    required this.stupoNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyProgramEntity &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          stupoNumber == other.stupoNumber;

  @override
  int get hashCode => name.hashCode ^ stupoNumber.hashCode;

  @override
  String toString() => 'StudyProgramEntity(name: $name, stupoNumber: $stupoNumber)';
}