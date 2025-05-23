class MealEntity {
  final String name;
  final bool vegan;
  final bool vegetarian;
  final double preisStudent;
  final double preisTeacher;
  final double preisOther;
  // +) further fields like category etc.

  MealEntity({
    required this.name,
    required this.vegan,
    required this.vegetarian,
    required this.preisStudent,
    required this.preisTeacher,
    required this.preisOther,
  });
}
