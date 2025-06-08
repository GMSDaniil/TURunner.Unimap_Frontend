class MensaMenuResponse {
  final String mensaName;
  final List<MensaDayMenu> days;

  MensaMenuResponse({required this.mensaName, required this.days});

  factory MensaMenuResponse.fromJson(Map<String, dynamic> json) {
    final menu = json['menu'] ?? {};
    return MensaMenuResponse(
      mensaName: menu['mensa_name'] ?? '',
      days: (menu['days'] as List<dynamic>? ?? [])
          .map((d) => MensaDayMenu.fromJson(d))
          .toList(),
    );
  }
}

class MensaDayMenu {
  final String dayName;
  final bool isAvailable;
  final Map<String, List<MensaDish>> groups;

  MensaDayMenu({
    required this.dayName,
    required this.isAvailable,
    required this.groups,
  });

  factory MensaDayMenu.fromJson(Map<String, dynamic> json) {
    final groupsJson = json['groups'] as Map<String, dynamic>? ?? {};
    return MensaDayMenu(
      dayName: json['day_name'] ?? '',
      isAvailable: json['is_available'] == true,
      groups: groupsJson.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => MensaDish.fromJson(e)).toList(),
        ),
      ),
    );
  }
}

class MensaDish {
  final String name;
  final String price;
  final bool vegan;
  final bool vegetarian;

  MensaDish({
    required this.name,
    required this.price,
    required this.vegan,
    required this.vegetarian,
  });

  factory MensaDish.fromJson(Map<String, dynamic> json) {
    return MensaDish(
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      vegan: json['vegan'] == true,
      vegetarian: json['vegetarian'] == true,
    );
  }
}
