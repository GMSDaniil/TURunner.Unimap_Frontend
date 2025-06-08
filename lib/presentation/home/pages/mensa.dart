/* import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:auth_app/core/constants/api_urls.dart';

class MensaPage extends StatefulWidget {
  final String mensaName;

  const MensaPage({Key? key, required this.mensaName}) : super(key: key);

  @override
  State<MensaPage> createState() => _MensaPageState();
}

class _MensaPageState extends State<MensaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _days = [];
  bool _loading = true;
  String? _error;

  static const weekdayNames = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];
  static const weekdayShort = ["Mo", "Tu", "We", "Th", "Fr", "Sa"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: weekdayNames.length, vsync: this);
    _fetchMenu();
  }

  String _mapUiNameToApiName(String name) {
    final n = name.toLowerCase();
    if (n.contains('veggie')) return 'veggie';
    if (n.contains('march')) return 'marchstrasse';
    if (n.contains('hardenberg')) return 'hardenbergstrasse';
    return 'hardenbergstrasse';
  }

  Future<void> _fetchMenu() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiName = _mapUiNameToApiName(widget.mensaName);
      final url = '${ApiUrls.baseURL}mensa/$apiName/menu';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _days = data['menu']?['days'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Server error: ${response.statusCode}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  Widget _buildDayMenu(Map<String, dynamic> day) {
    if (day['is_available'] != true) {
      return const Center(child: Text("No menu for this day."));
    }
    final groups = day['groups'] as Map<String, dynamic>? ?? {};
    if (groups.isEmpty) {
      return const Center(child: Text("No menu for this day."));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      children: groups.entries.map<Widget>((entry) {
        final groupName = entry.key;
        final dishes = entry.value as List<dynamic>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 8),
              child: Text(
                groupName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            ...dishes.map<Widget>(
              (dish) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(dish['name']),
                subtitle:
                    (dish['price'] != null &&
                        dish['price'].toString().trim().isNotEmpty)
                    ? Text('Price: ${dish['price']}')
                    : null,
                trailing: dish['vegan'] == true
                    ? const Icon(Icons.eco, color: Colors.green)
                    : dish['vegetarian'] == true
                    ? const Icon(Icons.spa, color: Colors.orange)
                    : null,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mensaName),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: List.generate(
            weekdayShort.length,
            (i) => Tab(text: weekdayShort[i]),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : TabBarView(
              controller: _tabController,
              children: List.generate(weekdayNames.length, (i) {
                final day = _days.firstWhere(
                  (d) =>
                      (d['day_name'] as String?)?.toLowerCase() ==
                      weekdayNames[i].toLowerCase(),
                  orElse: () => {},
                );
                if (day.isEmpty) {
                  return const Center(child: Text("No menu for this day."));
                }
                return _buildDayMenu(day);
              }),
            ),
    );
  }
} */
