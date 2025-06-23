// lib/presentation/widgets/route_plan_bar.dart
//
// Inline-search route planner (start | ≤3 stops | destination)
// ------------------------------------------------------------
import 'dart:async';                     // ← NEW
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/presentation/widgets/search_bar.dart';

typedef OnCancelled = void Function();

class RoutePlanBar extends StatefulWidget {
  static final GlobalKey _barKey = GlobalKey();
  //static final GlobalKey _barKey = GlobalKey();
  final LatLng? currentLocation;
  final LatLng? initialDestination;
  final List<Pointer> allPointers; // supply from MapPage
  final OnCancelled onCancelled;
  /// Called whenever both Start and Destination have been (re-)selected.
  final void Function(LatLng start, LatLng dest) onChanged;

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
  late final TextEditingController _startCtl;
  late final TextEditingController _destCtl;
  final List<TextEditingController> _stopCtls = [];

  final Set<_Cand> _chosen = {}; // what’s already used?

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
    }
    if (widget.initialDestination != null) {
      final lab = _prettyLabel(widget.initialDestination!);
      final cand = _pool.firstWhere(
        (c) => c.label == lab,
        orElse: () => _Cand(lab, widget.initialDestination!),
      );
      _destCand = cand;
      _chosen.add(_destCand!);
    }
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
              final picked = await _openSearchOverlay(context, ctl.text, hint);
              if (picked != null) {
                setState(() {
                  final old = _pool
                      .where((c) => c.label == ctl.text)
                      .cast<_Cand?>()
                      .firstWhere((_) => true, orElse: () => null);
                  if (old != null) _chosen.remove(old);
                  _chosen.add(picked);
                  ctl.text = picked.label;
                  if (hint == 'Start')     _startCand = picked;
                  else if (hint == 'Destination') _destCand = picked;
                  // fire onChanged if both endpoints are set
                  if (_startCand != null && _destCand != null) {
                    widget.onChanged(_startCand!.pos, _destCand!.pos);
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

     // 3️⃣ notify map if we now have both endpoints
    if (_startCand != null && _destCand != null) {
      widget.onChanged(_startCand!.pos, _destCand!.pos);
    }
  }

  void _addStop() {
    if (_stopCtls.length == 3) return;
    setState(() => _stopCtls.add(TextEditingController()));
  }

  void _removeStop(int i) {
    _stopCtls[i].dispose();
    setState(() => _stopCtls.removeAt(i));
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
                              enabled: _stopCtls.length < 3,
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

class _RouteSearchOverlayState extends State<_RouteSearchOverlay> {
  late TextEditingController _searchCtl;
  late List<_Cand> _suggestions;
  late final FocusNode _pillFocus;       // ← NEW

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController(text: widget.initialText);
    _suggestions = _getSuggestions(widget.initialText);
    _searchCtl.addListener(_onSearchChanged);

    /* keep the pill focused → MapSearchBar never shows category chips */
    _pillFocus = FocusNode();
    // whenever focus is lost, take it back immediately
    _pillFocus.addListener(() {
      if (!_pillFocus.hasFocus) {
        _pillFocus.requestFocus();
      }
    });

    // grab focus right after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        .where((c) => !widget.isTaken(c) && (lower.isEmpty || c.label.toLowerCase().contains(lower)))
        .take(40)
        .toList();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _pillFocus.dispose();               // ← NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // White backdrop that covers everything, tap outside to cancel
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            MapSearchBar(
              searchController: _searchCtl,
              suggestions: _suggestions.map((c) => Pointer(
                name: c.label,
                lat: c.pos.latitude,
                lng: c.pos.longitude,
                category: '', // No category in this context
              )).toList(),
              onSearch: (_) {}, // No-op, handled by suggestions
              onClear: () {
                _searchCtl.clear();
                setState(() {});
                widget.onCancel(); // keep this for closing on clear
              },
              onCategorySelected: (_, __) {}, // No categories in this context
              onSuggestionSelected: (Pointer p) {
                final cand = widget.pool.firstWhere(
                  (c) => c.label == p.name && c.pos.latitude == p.lat && c.pos.longitude == p.lng,
                  orElse: () => _Cand(p.name, LatLng(p.lat, p.lng)),
                );
                widget.onPicked(cand);
              },
              focusNode: _pillFocus,     // ← NEW
              showCategories: false,     // ← NEW: ensure categories never show
            ),
            Expanded(child: GestureDetector(onTap: widget.onCancel)),
          ],
        ),
      ),
    );
  }
}
