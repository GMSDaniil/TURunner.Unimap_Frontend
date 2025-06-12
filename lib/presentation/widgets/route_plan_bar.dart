// lib/presentation/widgets/route_plan_bar.dart
//
// Inline-search route planner (start | ≤3 stops | destination)
// ------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/models/pointer.dart';

typedef OnCancelled = void Function();

class RoutePlanBar extends StatefulWidget {
  static final GlobalKey _barKey = GlobalKey();
  //static final GlobalKey _barKey = GlobalKey();
  final LatLng? currentLocation;
  final LatLng? initialDestination;
  final List<Pointer> allPointers; // supply from MapPage
  final OnCancelled onCancelled;

  const RoutePlanBar({
    super.key,
    required this.currentLocation,
    required this.initialDestination,
    required this.allPointers,
    required this.onCancelled,
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
    if (widget.currentLocation != null) _chosen.add(_pool.first);
    if (widget.initialDestination != null) {
      final lab = _prettyLabel(widget.initialDestination!);
      final cand = _pool.firstWhere(
        (c) => c.label == lab,
        orElse: () => _Cand(lab, widget.initialDestination!),
      );
      _chosen.add(cand);
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
          child: _AutocompleteBox(
            controller: ctl,
            hint: hint,
            pool: _pool,
            isTaken: (c) => _chosen.contains(c),
            onPicked: (newCand, previousText) {
              setState(() {
                final old = _pool
                    .where((c) => c.label == previousText)
                    .cast<_Cand?>()
                    .firstWhere((_) => true, orElse: () => null);
                if (old != null) _chosen.remove(old);
                _chosen.add(newCand);
              });
            },
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
                // round “minus-in-circle” instead of a second X
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

    /* 2️⃣ rotate every intermediate stop:  S1 S2 S3  →  S3 S2 S1  */
    if (_stopCtls.length > 1) {
      final reversedTexts =
          _stopCtls.map((c) => c.text).toList().reversed.toList();
      for (var i = 0; i < _stopCtls.length; i++) {
        _stopCtls[i].text = reversedTexts[i];
      }
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
    return Wrap(
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
    );
  }
}

/* ──────────────────────────────────────────────────────────────── */
/* Improved inline-autocomplete box                                */
/* ──────────────────────────────────────────────────────────────── */
class _AutocompleteBox extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final List<_Cand> pool;
  final bool Function(_Cand) isTaken;
  final void Function(_Cand newPick, String previousText) onPicked;

  const _AutocompleteBox({
    required this.controller,
    required this.hint,
    required this.pool,
    required this.isTaken,
    required this.onPicked,
  });

  @override
  State<_AutocompleteBox> createState() => _AutocompleteBoxState();
}

class _AutocompleteBoxState extends State<_AutocompleteBox> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();

    // when the field gains focus and is empty → open the overlay immediately
    _focus.addListener(() {
      if (_focus.hasFocus)
        _openOverlay('');
      else
        _removeOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _focus.dispose();
    super.dispose();
  }

  /* ── overlay machinery ───────────────────────────────────────── */
  OverlayEntry? _entry;

  void _openOverlay(String text) {
    _removeOverlay();

    final matches = _optionsFor(text);
    if (matches.isEmpty) return;

    // ② ── find whole-bar rectangle, not the individual field
    final barBox =
        RoutePlanBar._barKey.currentContext?.findRenderObject() as RenderBox?;
    final barPos = barBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final top = barPos.dy + (barBox?.size.height ?? 0) + 4;

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        // ③ ── full-width, aligned with screen edges
        left: 0,
        right: 0,
        top: top,
        child: Material(
          color: Colors.white,
          elevation: 6,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(12),
              top: Radius.circular(12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: matches.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: .6, indent: 48),
              itemBuilder: (_, idx) {
                final cand = matches[idx];

                /* highlight the typed part */
                final lowerQ = text.toLowerCase();
                final label   = cand.label;
                final start   = label.toLowerCase().indexOf(lowerQ);
                final end     = start + lowerQ.length;

                return InkWell(
                  onTap: () {
                    final prev = widget.controller.text;
                    widget.controller.text = cand.label;
                    widget.onPicked(cand, prev);
                    _focus.unfocus();
                  },
                  child: SizedBox(
                    height: 44,                              // tighter row
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 20),
                        Expanded(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87
                              ),
                              children: [
                                if (start >= 0) ...[
                                  TextSpan(text: label.substring(0, start)),
                                  TextSpan(
                                    text: label.substring(start, end),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: label.substring(end)),
                                ] else
                                  TextSpan(text: label),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true)!.insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  List<_Cand> _optionsFor(String q) {
    final lower = q.toLowerCase();
    return widget.pool
        .where(
          (c) =>
              !widget.isTaken(c) &&
              (lower.isEmpty || c.label.toLowerCase().contains(lower)),
        )
        .take(40) // safety limit
        .toList();
  }

  /* ── build input field ───────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    // thin, border-less TextField with a clear ("×") button
    final hasText = widget.controller.text.isNotEmpty;
    final isEditing = _focus.hasFocus;

    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.white,
        // only show when in edit & has text
        suffixIcon: (isEditing && hasText)
            ? GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  widget.controller.clear();
                  setState(() {});
                  _openOverlay('');
                },
                child: const Icon(Icons.clear, size: 18),
              )
            : null,
        // keep the field’s height fixed
        suffixIconConstraints:
            const BoxConstraints.tightFor(width: 18, height: 18),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: widget.controller.text.trim() == 'Current location'
            ? Colors.black.withOpacity(0.45)
            : Colors.black,
      ),
      onChanged: (txt) {
        setState(() {});
        _openOverlay(txt);
      },
      onTap: () => _openOverlay(widget.controller.text),
    );
  }
}
