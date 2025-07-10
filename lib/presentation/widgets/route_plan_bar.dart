// lib/presentation/widgets/route_plan_bar.dart
//
// Compact inline route-planner  (Start | ≤3 Stops | Destination)
// -------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'route_search_bar.dart';

typedef OnCancelled = void Function();
/// Called when the route changes:
/// [positions] is the list of LatLng for start, stops, destination
/// [startLabel] is the user-entered start text
/// [endLabel] is the user-entered destination text
typedef OnRouteChanged = Future<void> Function(List<LatLng> positions, String startLabel, String endLabel);

/*──────────────────────── helpers ───────────────────────*/
class _Cand {
  const _Cand(this.label, this.pos);
  final String label;
  final LatLng pos;

  @override
  bool operator ==(Object o) =>
      o is _Cand &&
      o.pos.latitude == pos.latitude &&
      o.pos.longitude == pos.longitude;
  @override
  int get hashCode => Object.hash(pos.latitude, pos.longitude);
}

/*──────────────────────── widget ───────────────────────*/
class RoutePlanBar extends StatefulWidget {
  const RoutePlanBar({
    super.key,
    required this.currentLocation,
    required this.initialDestination,
    required this.allPointers,
    required this.onCancelled,
    required this.onChanged,
  });

  final LatLng? currentLocation;
  final LatLng? initialDestination;
  final List<Pointer> allPointers;
  final OnCancelled onCancelled;
  final OnRouteChanged onChanged;

  @override
  State<RoutePlanBar> createState() => _RoutePlanBarState();
}

/*──────────────────────── state ───────────────────────*/
class _RoutePlanBarState extends State<RoutePlanBar> {
  final Set<_Cand> _chosen = {};
  final List<_Cand> _route = [];
  late final List<_Cand> _pool;

  late final List<TextEditingController> _ctls   = [];
  late final List<String>                _types  = []; // start|stop|dest

  _Cand? _start, _dest;
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();

    _pool = [
      if (widget.currentLocation != null)
        _Cand('Current location', widget.currentLocation!),
      ...widget.allPointers.map((p) => _Cand(p.name, LatLng(p.lat, p.lng))),
    ];

    /* start row */
    _ctls.add(TextEditingController(
        text: widget.currentLocation != null ? 'Current location' : ''));
    _types.add('start');
    _route.add(_ctls.first.text.isEmpty
        ? const _Cand('', LatLng(0, 0))
        : _pool.first);

    /* destination row */
    _ctls.add(TextEditingController(
        text: widget.initialDestination != null
            ? _pretty(widget.initialDestination!)
            : ''));
    _types.add('dest');
    _route.add(_ctls.last.text.isEmpty
        ? const _Cand('', LatLng(0, 0))
        : _pool.firstWhere(
            (c) => c.label == _ctls.last.text,
            orElse: () => _Cand(
                _ctls.last.text, widget.initialDestination ?? const LatLng(0, 0)),
          ));

    _start = _types.first == 'start' && _ctls.first.text.isNotEmpty ? _route.first : null;
    _dest  = _types.last  == 'dest'  && _ctls.last.text.isNotEmpty  ? _route.last  : null;
    if (_start != null) _chosen.add(_start!);
    if (_dest  != null) _chosen.add(_dest!);
  }

  /*──────── UI helpers ────────*/
  String _pretty(LatLng pos) {
    const d = Distance();
    for (final p in widget.allPointers) {
      if (d(pos, LatLng(p.lat, p.lng)) < 5) return p.name;
    }
    return '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 50, endIndent: 20, color: Color(0x33000000));

  /*──────── single pill row ────────*/
  Widget _pill(int i) {
    final icon = _types[i] == 'start'
        ? Icons.my_location
        : (_types[i] == 'dest' ? Icons.place_outlined : Icons.flag_outlined);
    final hint = _types[i] == 'start'
        ? 'Start'
        : (_types[i] == 'dest' ? 'Destination' : 'Stop');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (i != 0) _divider(),
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pick(i, hint),
                  child: AbsorbPointer(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      color: Colors.transparent,
                      child: Text(
                        _ctls[i].text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
              if (_ctls.length > 2)
                GestureDetector(
                  onTap: () => _removeStop(i),
                  child: Icon(Icons.remove_circle_outline,
                      size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                ),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.drag_handle, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /*──────── side icon button ────────*/
  Widget _iconBtn(IconData ic, String tip, VoidCallback tap,
          {bool enabled = true}) =>
      GestureDetector(
        onTap: enabled ? tap : null,
        child: Tooltip(
          message: tip,
          child: Icon(ic,
              size: 22, color: enabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ),
      );

  /*──────── actions ────────*/
  void _swap() {
    if (_ctls.length < 2) return;
    setState(() {
      _swapIdx(0, _ctls.length - 1);
      _fire();
    });
  }

  void _swapIdx(int a, int b) {
    final tCtl = _ctls[a];
    _ctls[a] = _ctls[b];
    _ctls[b] = tCtl;
    final tTy = _types[a];
    _types[a] = _types[b];
    _types[b] = tTy;
    final tCd = _route[a];
    _route[a] = _route[b];
    _route[b] = tCd;
    final tStart = _start;
    _start = _dest;
    _dest = tStart;
  }

  void _addStop() {
    if (_ctls.length >= 5) return; // 1+3+1
    // Count blank fields (fields with empty text)
    int blankCount = _ctls.where((c) => c.text.trim().isEmpty).length;
    if (blankCount >= 1) return;
    setState(() {
      _ctls.insert(_ctls.length - 1, TextEditingController());
      _types.insert(_types.length - 1, 'stop');
      _route.insert(_route.length - 1, const _Cand('', LatLng(0, 0)));
    });
  }

  void _removeStop(int i) {
    setState(() {
      _chosen.remove(_route[i]);
      _ctls[i].dispose();
      _ctls.removeAt(i);
      _types.removeAt(i);
      _route.removeAt(i);
      // Ensure first and last always have correct type
      if (_types.isNotEmpty) {
        _types[0] = 'start';
        _types[_types.length - 1] = 'dest';
        for (int j = 1; j < _types.length - 1; j++) {
          _types[j] = 'stop';
        }
      }
      _fire();
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    // Allow swapping any field with any other field
    setState(() {
      final c1 = _ctls.removeAt(oldIndex);
      final c2 = _types.removeAt(oldIndex);
      final c3 = _route.removeAt(oldIndex);
      _ctls.insert(newIndex, c1);
      _types.insert(newIndex, c2);
      _route.insert(newIndex, c3);
      // After reordering, always set types: first=start, last=dest, others=stop
      if (_types.isNotEmpty) {
        _types[0] = 'start';
        _types[_types.length - 1] = 'dest';
        for (int j = 1; j < _types.length - 1; j++) {
          _types[j] = 'stop';
        }
      }
      _fire();
    });
  }

  /*──────── overlay search ────────*/
  Future<_Cand?> _search(String hint) {
    final completer = Completer<_Cand?>();
    _overlay = OverlayEntry(
      builder: (_) => _RouteSearchOverlay(
        initialText: '',
        hint: hint,
        pool: _pool,
        allPointers: widget.allPointers,
        isTaken: (c) => _chosen.contains(c),
        onPicked: (c) {
          _overlay?.remove();
          _overlay = null;
          completer.complete(c);
        },
        onCancel: () {
          _overlay?.remove();
          _overlay = null;
          completer.complete(null);
        },
      ),
    );
    Overlay.of(context, rootOverlay: true)!.insert(_overlay!);
    return completer.future;
  }

  Future<void> _pick(int idx, String hint) async {
    final p = await _search(hint);
    if (p == null) return;
    setState(() {
      _chosen.remove(_route[idx]);
      _chosen.add(p);
      _route[idx] = p;
      _ctls[idx].text = p.label;
      if (_types[idx] == 'start')
        _start = p;
      else if (_types[idx] == 'dest') _dest = p;
      _fire();
    });
  }

  void _fire() {
    // If any field is blank, do not send a request
    if (_ctls.any((c) => c.text.trim().isEmpty)) return;
    if (_start != null && _dest != null) {
      final positions = _route.map((e) => e.pos).toList();
      final startLabel = _ctls.first.text.trim();
      final endLabel   = _ctls.last.text.trim();
      widget.onChanged(positions, startLabel, endLabel);
    }
  }

  /*──────── build ────────*/
  @override
  Widget build(BuildContext context) {
    return 
    // SafeArea(child: 
    Stack(
        children: [
          Positioned(
          // keep the bar clear of any notch / status bar
          top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                elevation: 10,
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 424),
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* pills */
                      Expanded(
                        child: ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorder: _reorder,
                          proxyDecorator: (c, i, a) => Material(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            elevation: 8,
                            child: c,
                          ),
                          children: List.generate(
                            _ctls.length,
                            (i) => ReorderableDragStartListener(
                              key: ValueKey('row$i'),
                              index: i,
                              child: _pill(i),
                            ),
                          ),
                        ),
                      ),
                    /* side buttons */
                    Column(
                      children: [
                        _iconBtn(Icons.swap_vert, 'Swap', _swap),
                        const SizedBox(height: 8),
                        _iconBtn(
                          Icons.add,
                          'Add stop',
                          _addStop,
                          enabled: _ctls.length < 5 && _ctls.where((c) => c.text.trim().isEmpty).length == 0,
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      // ),
    );
  }

  @override
  void dispose() {
    for (final c in _ctls) c.dispose();
    super.dispose();
  }
}

/*──────────────────────── search overlay (unchanged) ──────────*/
class _RouteSearchOverlay extends StatefulWidget {
  const _RouteSearchOverlay({
    required this.initialText,
    required this.pool,
    required this.isTaken,
    required this.allPointers,
    required this.onPicked,
    required this.onCancel,
    required this.hint,
  });

  final String initialText;
  final List<_Cand> pool;
  final List<Pointer> allPointers;
  final bool Function(_Cand) isTaken;
  final void Function(_Cand) onPicked;
  final VoidCallback onCancel;
  final String hint;

  @override
  State<_RouteSearchOverlay> createState() => _RouteSearchOverlayState();
}

class _RouteSearchOverlayState extends State<_RouteSearchOverlay>
    with SingleTickerProviderStateMixin {
  static const _fadeIn = Duration(milliseconds: 200);
  static const _fadeOut = Duration(milliseconds: 150);

  late final AnimationController _fadeCtr =
      AnimationController(vsync: this, duration: _fadeIn, reverseDuration: _fadeOut)
        ..forward();
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtr, curve: Curves.easeInOut);

  late final TextEditingController _searchCtl =
      TextEditingController(text: widget.initialText);

      
  late List<_Cand> _suggestions;
  final FocusNode _focusNode = FocusNode();

  List<_Cand> _getSuggestions(String q) {
    final l = q.toLowerCase();
    List<_Cand> suggestions = [];
    
    // Add regular pool items (current location + existing buildings)
    suggestions.addAll(
      widget.pool.where((c) =>
          !widget.isTaken(c) && (l.isEmpty || c.label.toLowerCase().contains(l)))
    );
    
    // ✅ Add buildings that have rooms matching the query
    if (l.isNotEmpty) {
      for (final pointer in widget.allPointers) {
        // Check if any room in this pointer matches
        final roomMatches = pointer.rooms.any((room) => 
            room.toLowerCase().contains(l));
        
        // Check if pointer name matches
        final nameMatches = pointer.name.toLowerCase().contains(l);
        
        if (roomMatches || nameMatches) {
          final cand = _Cand(pointer.name, LatLng(pointer.lat, pointer.lng));
          
          // Only add if not already in suggestions and not taken
          if (!suggestions.contains(cand) && !widget.isTaken(cand)) {
            suggestions.add(cand);
          }
        }
      }
    }
    
    return suggestions.take(40).toList();
  }

  @override
  void initState() {
    super.initState();
    _suggestions = _getSuggestions(_searchCtl.text);
    _searchCtl.addListener(() {
      setState(() => _suggestions = _getSuggestions(_searchCtl.text));
    });
    // Request focus as soon as the overlay is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _close() => _fadeCtr.reverse().then((_) => widget.onCancel());

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              RouteSearchBar(
                searchController: _searchCtl,
                suggestions: _suggestions
                    .map((c) => Pointer(
                          name: c.label,
                          lat: c.pos.latitude,
                          lng: c.pos.longitude,
                          category: '',
                          rooms: _getRoomsForPointer(c.label),
                        ))
                    .toList(),
                onClear: () => _searchCtl.clear(),
                onSuggestionSelected: (p) {
                  final cand = widget.pool.firstWhere(
                      (c) =>
                          c.label == p.name &&
                          c.pos.latitude == p.lat &&
                          c.pos.longitude == p.lng,
                      orElse: () => _Cand(p.name, LatLng(p.lat, p.lng)));
                  _fadeCtr.reverse().then((_) => widget.onPicked(cand));
                },
                focusNode: _focusNode,
                onBack: _close,
              ),
              Expanded(child: GestureDetector(onTap: _close)),
            ],
          ),
        ),
      ),
    );
  }
  List<String> _getRoomsForPointer(String pointerName) {
    final pointer = widget.allPointers.firstWhere(
      (p) => p.name == pointerName,
      orElse: () => Pointer(name: '', lat: 0, lng: 0, category: '', rooms: []),
    );
    return pointer.rooms;
  }

  @override
  void dispose() {
    _fadeCtr.dispose();
    _searchCtl.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}