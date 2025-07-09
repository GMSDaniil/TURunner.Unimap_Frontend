class AddFavouriteMealReqParams {
  final String name;
  final String price;
  final bool vegan;
  final bool vegetarian;

  AddFavouriteMealReqParams({
    required this.name,
    required this.price,
    required this.vegan,
    required this.vegetarian,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'vegan': vegan,
      'vegetarian': vegetarian,
    };
  }
}