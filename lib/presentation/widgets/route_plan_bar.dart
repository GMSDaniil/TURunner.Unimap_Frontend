// lib/presentation/widgets/route_plan_bar.dart
//
// Inline-search route planner (start | ≤3 stops | destination)
// ------------------------------------------------------------
import 'dart:async';                     // ← NEW
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/presentation/widgets/search_bar.dart';
import 'route_search_bar.dart';  // ← new import

typedef OnCancelled = void Function();

class RoutePlanBar extends StatefulWidget {
  static final GlobalKey _barKey = GlobalKey();
  //static final GlobalKey _barKey = GlobalKey();
  final LatLng? currentLocation;
  final LatLng? initialDestination;
  final List<Pointer> allPointers; // supply from MapPage
  final OnCancelled onCancelled;
  /// Called whenever both Start and Destination have been (re-)selected.
  final void Function(List<LatLng>) onChanged;

  const RoutePlanBar({
    super.key,
    required this.currentLocation,
    required this.initialDestination,
    required this.allPointers,
    required this.onCancelled,
    required this.onChanged,
  });

  @override
  State<RoutePlanBar> createState() => _RoutePlanBarState();
}

/* ------------------------------------------------------------------------- */
/* internal helper – wraps a label + precise position (for duplicate rules)  */
class _Cand {
  final String label;
  final LatLng pos;
  const _Cand(this.label, this.pos);

  @override
  bool operator ==(Object other) =>
      other is _Cand &&
      pos.latitude == other.pos.latitude &&
      pos.longitude == other.pos.longitude;
  @override
  int get hashCode => Object.hash(pos.latitude, pos.longitude);
}
/* ------------------------------------------------------------------------- */

class _RoutePlanBarState extends State<RoutePlanBar> {
  static const int _maxStops = 3;    // ← allow up to 3 stops now
  late final TextEditingController _startCtl;
  late final TextEditingController _destCtl;
  final List<TextEditingController> _stopCtls = [];

  final Set<_Cand> _chosen = {}; // what’s already used?

  final List<_Cand> _route = []; // all stops (up to 3)

  late final List<_Cand> _pool; // all searchable locations

  // tiny helper – best-effort match of LatLng → building name
  String _prettyLabel(LatLng pos) {
    const d = Distance();
    for (final p in widget.allPointers) {
      if (d(pos, LatLng(p.lat, p.lng)) < 5) return p.name;
    }
    return '${pos.latitude.toStringAsFixed(5)}, '
        '${pos.longitude.toStringAsFixed(5)}';
  }

  _Cand? _startCand, _destCand;

  /*═══════════════════════════════════════════════════════════════
   * FULL-SCREEN SEARCH  ➜ runs as an OverlayEntry (no new route)
   *══════════════════════════════════════════════════════════════*/
  OverlayEntry? _searchEntry;
  Future<_Cand?> _openSearchOverlay(
    BuildContext ctx,
    String       initial,
    String       hint,
  ) {
    final completer = Completer<_Cand?>();

    _searchEntry = OverlayEntry(
      builder: (_) => _RouteSearchOverlay(
        initialText : initial,
        hint        : hint,
        pool        : _pool,
        isTaken     : (c) => _chosen.contains(c),
        onPicked    : (c) {
          _searchEntry?.remove();
          _searchEntry = null;
          completer.complete(c);
        },
        onCancel    : () {
          _searchEntry?.remove();
          _searchEntry = null;
          completer.complete(null);
        },
      ),
    );

    Overlay.of(ctx, rootOverlay: true)!.insert(_searchEntry!);
    return completer.future;
  }

  @override
  void initState() {
    super.initState();

    // build search pool once
    _pool = [
      if (widget.currentLocation != null)
        _Cand('Current location', widget.currentLocation!),
      ...widget.allPointers.map((p) => _Cand(p.name, LatLng(p.lat, p.lng))),
    ];

    _startCtl = TextEditingController(
      text: widget.currentLocation != null ? 'Current location' : '',
    );
    _destCtl = TextEditingController(
      text: widget.initialDestination != null
          ? _prettyLabel(widget.initialDestination!)
          : '',
    );

    // mark pre-selected items as “taken”
    if (widget.currentLocation != null) {
      _startCand = _pool.first;
      _chosen.add(_startCand!);
      _route.add(_startCand!);
    }
    if (widget.initialDestination != null) {
      final lab = _prettyLabel(widget.initialDestination!);
      final cand = _pool.firstWhere(
        (c) => c.label == lab,
        orElse: () => _Cand(lab, widget.initialDestination!),
      );
      _destCand = cand;
      _chosen.add(_destCand!);
      _route.add(_destCand!);
    }

    // print(_route);
  }

  @override
  void dispose() {
    _startCtl.dispose();
    _destCtl.dispose();
    for (final c in _stopCtls) c.dispose();
    super.dispose();
  }

  /* ═══════════════════════━  UI helpers  ━═══════════════════════ */
  Widget _divider() => Padding(
    padding: const EdgeInsets.only(left: 4, right: 20),
    child: Container(height: 1, color: const Color(0x33000000)),
  );

  Widget _sideBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool enabled = true,
  }) => GestureDetector(
    onTap: enabled ? onTap : null,
    behavior: HitTestBehavior.opaque,
    child: Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 20,
        color: enabled ? Colors.black : Colors.black26,
      ),
    ),
  );

 Widget _searchRow({
  required IconData icon,
  required TextEditingController ctl,
  required String hint,
  VoidCallback? onDelete,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade800),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await _openSearchOverlay(context, '', hint);
              if (picked != null) {
                setState(() {
                  // 1) figure out which slot we’re editing
                  int targetIdx;
                  if (hint == 'Start') {
                    targetIdx = 0;
                  } else if (hint == 'Destination') {
                    targetIdx = _route.length - 1;
                  } else {
                    final stopIndex = _stopCtls.indexOf(ctl);
                    targetIdx = stopIndex + 1;
                  }

                  // ── 1.a) special‐case: Start <→ neighbour swap
                  if (hint == 'Start'
                      && _route.length > 1
                      && _route[1].pos == picked.pos) {
                    // swap the two entries
                    final oldStart = _route[0];
                    _route[0] = _route[1];
                    _route[1] = oldStart;

                    // update controllers & cands
                    _startCtl.text = _route[0].label;
                    _startCand   = _route[0];
                    if (_stopCtls.isNotEmpty) {
                      _stopCtls[0].text = _route[1].label;
                    } else {
                      _destCtl.text = _route[1].label;
                      _destCand     = _route[1];
                    }

                    // notify map immediately & bail
                    widget.onChanged(_route.map((c) => c.pos).toList());
                    return;
                  }

                  // ── 1.b) similar for Destination <→ neighbour
                  if (hint == 'Destination'
                      && _route.length > 1
                      && _route[_route.length - 2].pos == picked.pos) {
                    final oldDest = _route[_route.length - 1];
                    _route[_route.length - 1] = _route[_route.length - 2];
                    _route[_route.length - 2] = oldDest;

                    _destCtl.text = _route.last.label;
                    _destCand   = _route.last;
                    if (_stopCtls.isNotEmpty) {
                      _stopCtls.last.text = _route[_route.length - 2].label;
                    } else {
                      _startCtl.text = _route[0].label;
                      _startCand     = _route[0];
                    }

                    widget.onChanged(_route.map((c) => c.pos).toList());
                    return;
                  }

                  // ── 2) existing neighbour‐removal & insertion…
                  bool swappedOnly = false;
                  for (final nb in [targetIdx - 1, targetIdx + 1]) {
                    if (nb >= 0 && nb < _route.length && _route[nb].pos == picked.pos) {
                      // remove the neighbour entry
                      _route.removeAt(nb);
                      // drop its controller if it was a stop
                      if (nb > 0 && nb < _route.length) {
                        _stopCtls.removeAt(nb - 1);
                      }
                      // clear its text/cand
                      if (nb == 0) {
                        _startCtl.clear();
                        _startCand = null;
                      } else if (nb == _route.length) {
                        _destCtl.clear();
                        _destCand = null;
                      }
                      // if we removed something before us, shift our index left
                      if (nb < targetIdx) targetIdx--;
                      swappedOnly = true;
                    }
                  }


                  // ── 2.a) if anything was deleted, clear the old route on the map
                  if (swappedOnly) {
                    widget.onChanged(<LatLng>[]);  // tells the map “no route” now
                  }

                  // ── 3) place the new pick into this slot
                  ctl.text = picked.label;
                  switch (hint) {
                    case 'Start':
                      _startCand = picked;
                      _route.isNotEmpty
                        ? _route[0] = picked
                        : _route.insert(0, picked);
                      break;
                    case 'Destination':
                      _destCand = picked;
                      _route.length > 1
                        ? _route[_route.length - 1] = picked
                        : _route.add(picked);
                      break;
                    default:
                      _route[targetIdx] = picked;
                  }

                  // ── 4) only trigger backend if it wasn’t a neighbour‐swap
                  if (!swappedOnly && _startCand != null && _destCand != null) {
                    widget.onChanged(_route.map((c) => c.pos).toList());
                  }
                });
              }
            },
            child: AbsorbPointer(
              child: TextField(
                controller: ctl,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        if (onDelete != null)
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  /* ═══════════════════════━  actions  ━═════════════════════════ */
  void _swap() {
    /* 1️⃣ swap start ⟷ destination text */
    final tmp = _startCtl.text;
    _startCtl.text = _destCtl.text;
    _destCtl.text  = tmp;

    // swap underlying _Cand references
    final tmpCand = _startCand;
    _startCand = _destCand;
    _destCand  = tmpCand;

    /* 2️⃣ rotate every intermediate stop:  S1 S2 S3  →  S3 S2 S1  */
    if (_stopCtls.length > 1) {
      final reversedTexts =
          _stopCtls.map((c) => c.text).toList().reversed.toList();
      for (var i = 0; i < _stopCtls.length; i++) {
        _stopCtls[i].text = reversedTexts[i];
      }
    }

    List<_Cand> newRoute = [];
    for(int i = _route.length - 1; i >= 0; i--) {
      newRoute.add(_route[i]);
    }

    _route.clear();
    _route.addAll(newRoute);

    // print(_route.map((c) => c.label).toList());

     // 3️⃣ notify map if we now have both endpoints
    if (_startCand != null && _destCand != null) {
      widget.onChanged(_route.map((c) => c.pos).toList());
    }
  }

  void _addStop() {
    if (_stopCtls.length >= _maxStops) return;   // ← use new limit
    if (_stopCtls.length != _route.length - 2) return; //user must choose stop before creating a new one
    setState(() => _stopCtls.add(TextEditingController()));
  }

  void _removeStop(int i) {
    var updateRoute = true;
    if(_stopCtls[i].text.isEmpty) {
      updateRoute = false;
    }
    
    _stopCtls[i].dispose();
    _stopCtls.removeAt(i);
   
    _route.removeAt(i + 1); // +1 for start location
    // print(_route.map((c) => c.label).toList());
    
    if(updateRoute){
      setState(() {
          
      });
      widget.onChanged(_route.map((c) => c.pos).toList());
    }
    
  }

  /* ═══════════════════════━  build  ━═══════════════════════════ */
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          Align(
            key: RoutePlanBar._barKey,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ◀ way-points
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _searchRow(
                              icon: Icons.my_location,
                              ctl: _startCtl,
                              hint: 'Start',
                            ),
                            for (var i = 0; i < _stopCtls.length; i++) ...[
                              _divider(),
                              _searchRow(
                                icon: Icons.flag_outlined,
                                ctl: _stopCtls[i],
                                hint: 'Stop ${i + 1}',
                                onDelete: () => _removeStop(i),
                              ),
                            ],
                            _divider(),
                            _searchRow(
                              icon: Icons.place_outlined,
                              ctl: _destCtl,
                              hint: 'Destination',
                            ),
                          ],
                        ),
                      ),
                      // ▶ side-buttons
                      Transform.translate(
                        offset: const Offset(-8, 8),
                        child: Column(
                          children: [
                            _sideBtn(
                              icon: Icons.swap_vert,
                              tooltip: 'Swap',
                              onTap: _swap,
                            ),
                            const SizedBox(height: 8),
                            _sideBtn(
                              icon: Icons.add,
                              tooltip: 'Add stop',
                              onTap: _addStop,
                              enabled: _stopCtls.length < _maxStops,   // ← here too
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*───────────────────────────────────────────────────────────────
 * Overlay-based search UI (pill + suggestions)
 *──────────────────────────────────────────────────────────────*/
class _RouteSearchOverlay extends StatefulWidget {
  final String initialText;
  final List<_Cand> pool;
  final bool Function(_Cand) isTaken;
  final void Function(_Cand) onPicked;
  final VoidCallback onCancel;
  final String hint;

  const _RouteSearchOverlay({
    required this.initialText,
    required this.pool,
    required this.isTaken,
    required this.onPicked,
    required this.onCancel,
    required this.hint,
  });

  @override
  State<_RouteSearchOverlay> createState() => _RouteSearchOverlayState();
}

class _RouteSearchOverlayState extends State<_RouteSearchOverlay>
    with SingleTickerProviderStateMixin {
  static const _animDuration = Duration(milliseconds: 300);
  static const _fadeIn = Duration(milliseconds: 250);
  static const _fadeOut = Duration(milliseconds: 150);
  late final AnimationController _fadeCtr;
  late final Animation<double> _fadeAnim;

  late TextEditingController _searchCtl;
  late List<_Cand> _suggestions;
  late final FocusNode _pillFocus;

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController(text: widget.initialText);
    _suggestions = _getSuggestions(widget.initialText);
    _searchCtl.addListener(_onSearchChanged);

    // keep the pill focused
    _pillFocus = FocusNode();
    _pillFocus.addListener(() {
      if (!_pillFocus.hasFocus) _pillFocus.requestFocus();
    });

    // set up fade controller & start fade-in
    _fadeCtr = AnimationController(
      vsync: this,
      duration: _fadeIn,
      reverseDuration: _fadeOut,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtr, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeCtr.forward();
      _pillFocus.requestFocus();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _suggestions = _getSuggestions(_searchCtl.text);
    });
  }

  List<_Cand> _getSuggestions(String q) {
    final lower = q.toLowerCase();
    return widget.pool
        .where((c) => lower.isEmpty || c.label.toLowerCase().contains(lower))
        .take(40)
        .toList();
  }

  // helper to fade‐out then fire success callback
  void _fadeOutThenPick(_Cand cand) {
    _fadeCtr.reverse().then((_) => widget.onPicked(cand));
  }

  void _closeOverlay() {
    // reverse fade and then remove
    _fadeCtr.reverse().then((_) => widget.onCancel());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          bottom: true,
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
                        ))
                    .toList(),
                onClear: () {
                  _searchCtl.clear();
                  setState(() {});
                },
                onSuggestionSelected: (Pointer p) {
                  final cand = widget.pool.firstWhere(
                    (c) =>
                      c.label == p.name &&
                      c.pos.latitude == p.lat &&
                      c.pos.longitude == p.lng,
                    orElse: () => _Cand(p.name, LatLng(p.lat, p.lng)),
                  );
                  _fadeOutThenPick(cand);
                },
                focusNode: _pillFocus,
                onBack: _closeOverlay,
              ),
              Expanded(child: GestureDetector(onTap: _closeOverlay)),
            ],
          ),
        ),
      ),
    );
  }
}
