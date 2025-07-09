import 'package:auth_app/common/providers/user.dart';
import 'package:auth_app/data/models/user_meal_model.dart';
import 'package:flutter/material.dart';
import 'package:auth_app/data/models/mensa_menu_response.dart';
import 'package:provider/provider.dart';

/// Expects an already loaded [menu] as a parameter.
class WeeklyMensaPlan extends StatefulWidget {
  final MensaMenuResponse menu;
  final ScrollController? scrollController;

  const WeeklyMensaPlan({Key? key, required this.menu, this.scrollController})
    : super(key: key);

  @override
  State<WeeklyMensaPlan> createState() => _WeeklyMensaPlanState();
}

class _WeeklyMensaPlanState extends State<WeeklyMensaPlan> {
  int selectedDayIndex = 0;
  static const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const weekdayNames = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
  ];

  List<DateTime> weekDates = [];

  @override
  void initState() {
    super.initState();
    _calculateWeekDates();
    final today = DateTime.now().weekday;
    // If today is saturday or sonnday, we set the selected day to friday
    // otherwise set it to the previous day (Mon-Fri)
    selectedDayIndex = today >= 6 ? 4 : today - 1;
  }

  void _calculateWeekDates() {
    final now = DateTime.now();
    final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    weekDates = List.generate(5, (index) {
      return mondayOfWeek.add(Duration(days: index));
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
           date.month == today.month &&
           date.day == today.day;
  }

  bool _isMealFavorited(String mealName, List<UserMealModel> favoriteMeals) {
    return favoriteMeals.any((meal) => 
      meal.name.toLowerCase().trim() == mealName.toLowerCase().trim());
  }

  Future<void> _toggleFavoriteMeal(
    int id,
    String mealName, 
    List<double> price, 
    bool isVegan, 
    bool isVegetarian,
    UserProvider userProvider,
  ) async {
    final favoriteMeals = userProvider.favouriteMeals;
    print(mealName + " 000 " + favoriteMeals.toString());
    final isFavorited = _isMealFavorited(mealName, favoriteMeals);

    if (isFavorited) {
      // Remove from favorites
      await userProvider.removeFavoriteMeal(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$mealName removed from favourites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Add to favorites
      final userMeal = UserMealModel(
        id: -1,
        name: mealName,
        prices: price,
        vegan: isVegan,
        vegetarian: isVegetarian,
      );
      await userProvider.addFavoriteMeal(userMeal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$mealName added to favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  List<UserMealModel> _getFavoriteMealsForToday(
    List<UserMealModel> favoriteMeals, 
    MensaDayMenu selectedMenu
  ) {
    if (!selectedMenu.isAvailable || selectedMenu.groups.isEmpty) {
      return [];
    }

    // Get all dish names from today's menu
    final todaysDishes = <String>{};
    for (final dishes in selectedMenu.groups.values) {
      for (final dish in dishes) {
        todaysDishes.add(dish.name.toLowerCase().trim());
      }
    }

    // Filter favorite meals that appear in today's menu
    return favoriteMeals.where((meal) {
      return todaysDishes.contains(meal.name.toLowerCase().trim());
    }).toList();
  }


  Widget _buildFavoriteMealsSection(List<UserMealModel> favoriteMeals, MensaDayMenu selectedMenu) {
    if (favoriteMeals.isEmpty) return const SizedBox.shrink();

    final todaysFavoriteMeals = _getFavoriteMealsForToday(favoriteMeals, selectedMenu);

    return favoriteMeals.isEmpty ?
      const SizedBox.shrink() :
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Row(
            children: [
              Icon(
                todaysFavoriteMeals.isEmpty ? Icons.heart_broken : Icons.favorite, 
                color: Theme.of(context).colorScheme.secondary, 
                size: 18),
              const SizedBox(width: 8),
              Text(
                todaysFavoriteMeals.isEmpty ? 'No Favourites Today' :'Todays Favourites',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: todaysFavoriteMeals.isEmpty ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        ...todaysFavoriteMeals.map<Widget>(
          (meal) => Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.favorite, 
                  color: Theme.of(context).colorScheme.secondary, 
                  size: 20),
                title: Text(
                  meal.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: meal.prices.isNotEmpty
                    ? Text('Price: ${meal.prices.map((p) => p.toStringAsFixed(2)).join(' / ')}')
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (meal.vegan)
                      const Icon(Icons.eco, color: Colors.green, size: 20),
                    if (meal.vegetarian && !meal.vegan)
                      const Icon(Icons.spa, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.favorite, color: Theme.of(context).colorScheme.secondary),
                      onPressed: () => _toggleFavoriteMeal(
                        meal.id,
                        meal.name,
                        meal.prices,
                        meal.vegan,
                        meal.vegetarian,
                        userProvider,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(thickness: 2),
        const SizedBox(height: 8),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final response = widget.menu;

    if (response.days.isEmpty) {
      return const Center(child: Text("No menu available."));
    }

    //menu for the selected day
    final selectedDayName = weekdayNames[selectedDayIndex];
    final selectedMenu = response.days.firstWhere(
      (d) => d.dayName.toLowerCase() == selectedDayName.toLowerCase(),
      orElse: () => MensaDayMenu(dayName: '', isAvailable: false, groups: {}),
    );

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final favoriteMeals = userProvider.favouriteMeals;
        return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Title
              const Text(
                "Weekly Canteen Plan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 12),
              // Weekday selector bar
              SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(weekdayLabels.length, (i) {
                    final date = weekDates[i];
                    final isToday = _isToday(date);
                    final isSelected = i == selectedDayIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDayIndex = i;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4CAF50).withOpacity(0.15)
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weekdayLabels[i],
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF4CAF50)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              
                              Text(
                                _formatDate(date),
                                style: TextStyle(
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isToday
                                          ? Theme.of(context).colorScheme.secondary
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
      
              if (!selectedMenu.isAvailable || selectedMenu.groups.isEmpty)
                const Center(
                  child: Text(
                    "No menu for today.",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    controller: widget.scrollController,
                    children:  [
                        _buildFavoriteMealsSection(favoriteMeals, selectedMenu),


                        ...selectedMenu.groups.entries.expand((entry) {
                          final groupName = entry.key;
                          final dishes = entry.value;
                          return [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                              child: Text(
                                groupName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            ...dishes.map<Widget>(
                              (dish) {
                                final isFavorited = _isMealFavorited(dish.name, favoriteMeals);
                                
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    dish.name,
                                    style: TextStyle(
                                      fontWeight: isFavorited 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: dish.price.isNotEmpty
                                      ? Text('Price: ${dish.price}')
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (dish.vegan)
                                        const Icon(Icons.eco, color: Colors.green),
                                      if (dish.vegetarian && !dish.vegan)
                                        const Icon(Icons.spa, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      // ✅ Heart icon to toggle favorite
                                      IconButton(
                                        icon: Icon(
                                          isFavorited ? Icons.favorite : Icons.favorite_border,
                                          color: isFavorited ? Colors.red : Colors.grey,
                                        ),
                                        onPressed: () => _toggleFavoriteMeal(
                                          -1,
                                          dish.name,
                                          dish.price.isNotEmpty
                                            ? dish.price.substring(1).split('/').map((p) {print(p); return double.tryParse(p.trim().replaceAll(',', ".")) ?? 0.0;}).toList()
                                            : [],
                                          dish.vegan,
                                          dish.vegetarian,
                                          userProvider,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ];
                        }).toList(),
                      ]
                    
                  ),
                ),
            ],
          ),
        ),
      );
      },
    );
    
  }
}