class MealEntity {
  final String name;
  final bool vegan;
  final bool vegetarian;
  final List<double> prices; // [Student, Employee, Gast]

  MealEntity({
    required this.name,
    required this.vegan,
    required this.vegetarian,
    required this.prices,
  });
}
