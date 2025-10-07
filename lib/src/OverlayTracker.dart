import 'package:flutter/material.dart';

class OverlayTracker {
  static final List<OverlayEntry> _activeOverlays = [];

  static void add(OverlayEntry entry) => _activeOverlays.add(entry);

  static void remove(OverlayEntry entry) => _activeOverlays.remove(entry);

  static void dismissAll() {
    for (final overlay in List<OverlayEntry>.from(_activeOverlays)) {
      overlay.remove();
    }
    _activeOverlays.clear();
  }

  static void dismissLatest() {
    if (_activeOverlays.isNotEmpty) {
      final latest = _activeOverlays.removeLast();
      latest.remove();
    }
  }
  static bool get hasOverlays => _activeOverlays.isNotEmpty;
}
