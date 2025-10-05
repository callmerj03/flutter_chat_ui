import 'dart:ui';
import 'dart:typed_data';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;

class IOSContextMenu extends StatefulWidget {
  final Widget child;
  final List<ContextMenuItem> actions;
  final GlobalKey? previewKey;
  final List<Map>? emojiList;
  final String? chatReaction;
  final Function(String?) emojiClick;
  final Function(bool) backmanage;
  final bool isDarkMode;

  const IOSContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.previewKey,
    this.emojiList,
    required this.emojiClick,
    required this.backmanage,
    this.chatReaction,
    required this.isDarkMode,
  });

  @override
  State<IOSContextMenu> createState() => _IOSContextMenuState();
}

class _IOSContextMenuState extends State<IOSContextMenu> {
  OverlayEntry? _menuEntry;
  Uint8List? _previewBytes;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  Future<void> _capturePreview() async {
    if (widget.previewKey == null) return;

    RenderRepaintBoundary? boundary = widget.previewKey!.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData != null) {
        _previewBytes = byteData.buffer.asUint8List();
      }
    }
  }

  // version 1
  // void _showMenu(BuildContext context, Rect rect) async {
  //   await _capturePreview();
  //
  //   final overlay = Overlay.of(context);
  //   if (overlay == null) return;
  //
  //   final screenSize = MediaQuery.of(context).size;
  //   final menuHeight = 50.0 * widget.actions.length + 12;
  //   final menuWidth = screenSize.width * 0.6;
  //   const padding = 8.0;
  //   const menuGap = 6.0;
  //   const emojiBarHeight = 48.0;
  //   const bubbleGap = 8.0; // space between bubble and emoji bar
  //
  //   // Initial positions
  //   double bubbleTop = rect.top;
  //   double emojiTop = rect.top - emojiBarHeight - bubbleGap;
  //   double menuTop = rect.bottom + menuGap;
  //
  //   final totalHeightNeeded = emojiBarHeight + bubbleGap + rect.height + menuGap + menuHeight;
  //
  //   // Check if there is enough space above or below
  //   final spaceAbove = rect.top;
  //   final spaceBelow = screenSize.height - rect.bottom;
  //
  //   if (spaceAbove >= emojiBarHeight + bubbleGap && spaceBelow >= menuGap + menuHeight) {
  //     // Enough space, no change
  //     bubbleTop = rect.top;
  //     emojiTop = rect.top - emojiBarHeight - bubbleGap;
  //     menuTop = rect.bottom + menuGap;
  //   } else if (spaceBelow >= totalHeightNeeded) {
  //     // Enough space below to fit everything
  //     bubbleTop = rect.top;
  //     emojiTop = rect.top + rect.height + bubbleGap; // emoji below if needed
  //     menuTop = bubbleTop + rect.height + emojiBarHeight + bubbleGap;
  //   } else if (spaceAbove >= totalHeightNeeded) {
  //     // Enough space above
  //     bubbleTop = rect.top - totalHeightNeeded + rect.height;
  //     emojiTop = bubbleTop - emojiBarHeight - bubbleGap;
  //     menuTop = bubbleTop + rect.height + menuGap;
  //   } else {
  //     // Not enough space either side, shift bubble to center
  //     bubbleTop = (screenSize.height - rect.height) / 2;
  //     emojiTop = bubbleTop - emojiBarHeight - bubbleGap;
  //     menuTop = bubbleTop + rect.height + menuGap;
  //
  //     // Clamp bubble inside screen
  //     if (emojiTop < padding) {
  //       bubbleTop += padding - emojiTop;
  //       emojiTop = padding;
  //       menuTop = bubbleTop + rect.height + menuGap;
  //     }
  //     if (menuTop + menuHeight > screenSize.height - padding) {
  //       bubbleTop -= (menuTop + menuHeight - screenSize.height + padding);
  //       emojiTop = bubbleTop - emojiBarHeight - bubbleGap;
  //       menuTop = bubbleTop + rect.height + menuGap;
  //     }
  //   }
  //
  //   // Horizontal position
  //   double leftPosition = rect.left + rect.width / 2 - menuWidth / 2;
  //   if (leftPosition + menuWidth + padding > screenSize.width) {
  //     leftPosition = screenSize.width - menuWidth - padding;
  //   }
  //   if (leftPosition < padding) {
  //     leftPosition = padding;
  //   }
  //
  //   _menuEntry = OverlayEntry(
  //     builder: (context) => Material(
  //       type: MaterialType.transparency,
  //       child: Stack(
  //         children: [
  //           // Dimmed background with blur
  //           Positioned.fill(
  //             child: GestureDetector(
  //               onTap: _removeMenu,
  //               child: BackdropFilter(
  //                 filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
  //                 child: Container(color: Colors.black26),
  //               ),
  //             ),
  //           ),
  //
  //           // Bubble preview
  //           AnimatedPositioned(
  //             duration: const Duration(milliseconds: 250),
  //             curve: Curves.easeOut,
  //             left: rect.left,
  //             top: bubbleTop,
  //             width: rect.width,
  //             height: rect.height,
  //             child: TweenAnimationBuilder<double>(
  //               tween: Tween(begin: 1.0, end: 1.05),
  //               duration: const Duration(milliseconds: 150),
  //               builder: (context, scale, child) => Transform.scale(
  //                 scale: scale,
  //                 alignment: Alignment.center,
  //                 child: child,
  //               ),
  //               child: _previewBytes != null ? Image.memory(_previewBytes!) : const SizedBox(),
  //             ),
  //           ),
  //
  //           // Emoji bar
  //           if (widget.emojiList != null && widget.emojiList!.isNotEmpty)
  //             AnimatedPositioned(
  //               duration: const Duration(milliseconds: 250),
  //               curve: Curves.easeOut,
  //               left: leftPosition,
  //               top: emojiTop,
  //               child: Material(
  //                 color: Colors.transparent,
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: Theme.of(context).primaryColor,
  //                     borderRadius: BorderRadius.circular(100),
  //                   ),
  //                   height: emojiBarHeight,
  //                   child: SingleChildScrollView(
  //                     scrollDirection: Axis.horizontal,
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: widget.emojiList!.map((map) {
  //                         if (map['emoji'] != null) {
  //                           return GestureDetector(
  //                             onTap: () {
  //                               if (map['emoji'] == widget.chatReaction) {
  //                                 widget.emojiClick(null);
  //                               } else {
  //                                 widget.emojiClick(map['emoji']);
  //                               }
  //                               widget.backmanage(true);
  //                               _removeMenu();
  //                             },
  //                             child: Padding(
  //                               padding: const EdgeInsets.symmetric(horizontal: 4.0),
  //                               child: Text(
  //                                 map['emoji'],
  //                                 style: const TextStyle(fontSize: 28),
  //                               ),
  //                             ),
  //                           );
  //                         } else {
  //                           return GestureDetector(
  //                             onTap: () {},
  //                             child: const Padding(
  //                               padding: EdgeInsets.symmetric(horizontal: 4.0),
  //                               child: Icon(Icons.add, size: 28),
  //                             ),
  //                           );
  //                         }
  //                       }).toList(),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //
  //           // Menu actions
  //           AnimatedPositioned(
  //             duration: const Duration(milliseconds: 250),
  //             curve: Curves.easeOut,
  //             left: leftPosition,
  //             top: menuTop,
  //             child: TweenAnimationBuilder<double>(
  //               tween: Tween(begin: 0.8, end: 1.0),
  //               duration: const Duration(milliseconds: 250),
  //               curve: Curves.elasticOut,
  //               builder: (context, scale, child) {
  //                 return Transform.scale(
  //                   scale: scale,
  //                   alignment: Alignment.center,
  //                   child: child,
  //                 );
  //               },
  //               child: Material(
  //                 color: Colors.transparent,
  //                 child: Container(
  //                   width: menuWidth,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(12),
  //                     boxShadow: const [
  //                       BoxShadow(
  //                         color: Colors.black26,
  //                         blurRadius: 6,
  //                         offset: Offset(2, 2),
  //                       ),
  //                     ],
  //                   ),
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: widget.actions.map((item) {
  //                       return GestureDetector(
  //                         onTap: () {
  //                           _removeMenu();
  //                           item.onTap();
  //                         },
  //                         child: Container(
  //                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //                           alignment: Alignment.center,
  //                           child: Row(
  //                             mainAxisSize: MainAxisSize.max,
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               if (item.leading != null) item.leading! else const SizedBox(width: 18),
  //                               Flexible(
  //                                 child: Text(
  //                                   item.title,
  //                                   textAlign: TextAlign.center,
  //                                   style: TextStyle(
  //                                     fontSize: 16,
  //                                     color: item.isDestructive ? Colors.red : Colors.blue,
  //                                   ),
  //                                 ),
  //                               ),
  //                               if (item.trailing != null) item.trailing! else const SizedBox(width: 18),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     }).toList(),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  //
  //   overlay.insert(_menuEntry!);
  // }

  // version 2
  // void _showMenu(BuildContext context, Rect rect) async {
  //   await _capturePreview();
  //
  //   final overlay = Overlay.of(context);
  //   if (overlay == null) return;
  //
  //   final screenSize = MediaQuery.of(context).size;
  //   final menuHeight = 50.0 * widget.actions.length + 12;
  //   final menuWidth = screenSize.width * 0.6;
  //   const padding = 8.0;
  //   const menuGap = 6.0;
  //   const emojiBarHeight = 48.0;
  //   const bubbleGap = 8.0;
  //
  //   double bubbleTop = rect.top;
  //   double emojiTop = bubbleTop - emojiBarHeight - bubbleGap;
  //   double menuTop = rect.bottom + menuGap;
  //
  //   final totalHeight = emojiBarHeight + bubbleGap + rect.height + menuGap + menuHeight;
  //
  //   // Check if it overflows screen bottom
  //   final overflow = (menuTop + menuHeight + padding) - screenSize.height;
  //   if (overflow > 0) {
  //     // Shift entire block up by overflow amount
  //     bubbleTop -= overflow;
  //     emojiTop -= overflow;
  //     menuTop -= overflow;
  //
  //     // Ensure we don't go above top padding
  //     if (emojiTop < padding) {
  //       final shiftDown = padding - emojiTop;
  //       bubbleTop += shiftDown;
  //       emojiTop += shiftDown;
  //       menuTop += shiftDown;
  //     }
  //   }
  //
  //   // Horizontal position
  //   double leftPosition = rect.left + rect.width / 2 - menuWidth / 2;
  //   leftPosition = leftPosition.clamp(padding, screenSize.width - menuWidth - padding);
  //
  //   _menuEntry = OverlayEntry(
  //     builder: (context) => Material(
  //       type: MaterialType.transparency,
  //       child: Stack(
  //         children: [
  //           Positioned.fill(
  //             child: GestureDetector(
  //               onTap: _removeMenu,
  //               child: BackdropFilter(
  //                 filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
  //                 child: Container(color: Colors.black26),
  //               ),
  //             ),
  //           ),
  //
  //           // Bubble preview
  //           Positioned(
  //             left: rect.left,
  //             top: bubbleTop,
  //             width: rect.width,
  //             height: rect.height,
  //             child: TweenAnimationBuilder<double>(
  //               tween: Tween(begin: 1.0, end: 1.05),
  //               duration: const Duration(milliseconds: 150),
  //               builder: (context, scale, child) => Transform.scale(
  //                 scale: scale,
  //                 alignment: Alignment.center,
  //                 child: child,
  //               ),
  //               child: _previewBytes != null ? Image.memory(_previewBytes!) : const SizedBox(),
  //             ),
  //           ),
  //
  //           // Emoji bar
  //           if (widget.emojiList != null && widget.emojiList!.isNotEmpty)
  //             Positioned(
  //               left: leftPosition,
  //               top: emojiTop,
  //               child: Material(
  //                 color: Colors.transparent,
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: Theme.of(context).primaryColor,
  //                     borderRadius: BorderRadius.circular(100),
  //                   ),
  //                   height: emojiBarHeight,
  //                   child: SingleChildScrollView(
  //                     scrollDirection: Axis.horizontal,
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: widget.emojiList!.map((map) {
  //                         if (map['emoji'] != null) {
  //                           return GestureDetector(
  //                             onTap: () {
  //                               if (map['emoji'] == widget.chatReaction) {
  //                                 widget.emojiClick(null);
  //                               } else {
  //                                 widget.emojiClick(map['emoji']);
  //                               }
  //                               widget.backmanage(true);
  //                               _removeMenu();
  //                             },
  //                             child: Padding(
  //                               padding: const EdgeInsets.symmetric(horizontal: 4.0),
  //                               child: Text(
  //                                 map['emoji'],
  //                                 style: const TextStyle(fontSize: 28),
  //                               ),
  //                             ),
  //                           );
  //                         } else {
  //                           return GestureDetector(
  //                             onTap: () {},
  //                             child: const Padding(
  //                               padding: EdgeInsets.symmetric(horizontal: 4.0),
  //                               child: Icon(Icons.add, size: 28),
  //                             ),
  //                           );
  //                         }
  //                       }).toList(),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //
  //           // Menu actions
  //           Positioned(
  //             left: leftPosition,
  //             top: menuTop,
  //             child: TweenAnimationBuilder<double>(
  //               tween: Tween(begin: 0.8, end: 1.0),
  //               duration: const Duration(milliseconds: 250),
  //               curve: Curves.elasticOut,
  //               builder: (context, scale, child) {
  //                 return Transform.scale(
  //                   scale: scale,
  //                   alignment: Alignment.center,
  //                   child: child,
  //                 );
  //               },
  //               child: Material(
  //                 color: Colors.transparent,
  //                 child: Container(
  //                   width: menuWidth,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(12),
  //                     boxShadow: const [
  //                       BoxShadow(
  //                         color: Colors.black26,
  //                         blurRadius: 6,
  //                         offset: Offset(2, 2),
  //                       ),
  //                     ],
  //                   ),
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: widget.actions.map((item) {
  //                       return GestureDetector(
  //                         onTap: () {
  //                           _removeMenu();
  //                           item.onTap();
  //                         },
  //                         child: Container(
  //                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //                           alignment: Alignment.center,
  //                           child: Row(
  //                             mainAxisSize: MainAxisSize.max,
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               if (item.leading != null) item.leading! else const SizedBox(width: 18),
  //                               Flexible(
  //                                 child: Text(
  //                                   item.title,
  //                                   textAlign: TextAlign.center,
  //                                   style: TextStyle(
  //                                     fontSize: 16,
  //                                     color: item.isDestructive ? Colors.red : Colors.blue,
  //                                   ),
  //                                 ),
  //                               ),
  //                               if (item.trailing != null) item.trailing! else const SizedBox(width: 18),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     }).toList(),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  //
  //   overlay.insert(_menuEntry!);
  // }

  //  version 3
  // void _showMenu(BuildContext context, Rect rect) async {
  //   await _capturePreview();
  //
  //   final overlay = Overlay.of(context);
  //   if (overlay == null) return;
  //
  //   final screenSize = MediaQuery.of(context).size;
  //   final menuHeight = 50.0 * widget.actions.length + 12;
  //   final menuWidth = screenSize.width * 0.6;
  //   const padding = 8.0;
  //   const menuGap = 6.0;
  //   const emojiBarHeight = 48.0;
  //   const bubbleGap = 8.0;
  //   const overlapGap = 8.0; // gap to keep bubble visible when overlapping
  //
  //   double bubbleTop = rect.top;
  //   double emojiTop = bubbleTop - emojiBarHeight - bubbleGap;
  //   double menuTop = rect.bottom + menuGap;
  //
  //   // Original shifting logic
  //   final overflow = (menuTop + menuHeight + padding) - screenSize.height;
  //   if (overflow > 0) {
  //     bubbleTop -= overflow;
  //     emojiTop -= overflow;
  //     menuTop -= overflow;
  //
  //     // Keep bubble inside top padding
  //     if (emojiTop < padding) {
  //       final shiftDown = padding - emojiTop;
  //       bubbleTop += shiftDown;
  //       emojiTop += shiftDown;
  //       menuTop += shiftDown;
  //     }
  //   }
  //
  //   // Adjust menuTop if it still overflows: overlap bubble but keep gap
  //   final maxMenuTop = rect.bottom - menuHeight + overlapGap;
  //   if (menuTop + menuHeight > screenSize.height) {
  //     menuTop = maxMenuTop;
  //   }
  //
  //   // Horizontal position
  //   double leftPosition = rect.left + rect.width / 2 - menuWidth / 2;
  //   leftPosition = leftPosition.clamp(padding, screenSize.width - menuWidth - padding);
  //
  //   _menuEntry = OverlayEntry(
  //     builder: (context) => Material(
  //       type: MaterialType.transparency,
  //       child: Stack(
  //         children: [
  //           // Background blur
  //           Positioned.fill(
  //             child: GestureDetector(
  //               onTap: _removeMenu,
  //               child: BackdropFilter(
  //                 filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
  //                 child: Container(color: Colors.black26),
  //               ),
  //             ),
  //           ),
  //
  //           // Bubble preview
  //           Positioned(
  //             left: rect.left,
  //             top: bubbleTop,
  //             width: rect.width,
  //             height: rect.height,
  //             child: TweenAnimationBuilder<double>(
  //               tween: Tween(begin: 1.0, end: 1.05),
  //               duration: const Duration(milliseconds: 150),
  //               builder: (context, scale, child) => Transform.scale(
  //                 scale: scale,
  //                 alignment: Alignment.center,
  //                 child: child,
  //               ),
  //               child: _previewBytes != null ? Image.memory(_previewBytes!) : const SizedBox(),
  //             ),
  //           ),
  //
  //           // Emoji bar
  //           if (widget.emojiList != null && widget.emojiList!.isNotEmpty)
  //             Positioned(
  //               left: leftPosition,
  //               top: emojiTop,
  //               child: Material(
  //                 color: Colors.transparent,
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: Theme.of(context).primaryColor,
  //                     borderRadius: BorderRadius.circular(100),
  //                   ),
  //                   height: emojiBarHeight,
  //                   child: SingleChildScrollView(
  //                     scrollDirection: Axis.horizontal,
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: widget.emojiList!.map((map) {
  //                         if (map['emoji'] != null) {
  //                           return GestureDetector(
  //                             onTap: () {
  //                               if (map['emoji'] == widget.chatReaction) {
  //                                 widget.emojiClick(null);
  //                               } else {
  //                                 widget.emojiClick(map['emoji']);
  //                               }
  //                               widget.backmanage(true);
  //                               _removeMenu();
  //                             },
  //                             child: Padding(
  //                               padding: const EdgeInsets.symmetric(horizontal: 4.0),
  //                               child: Text(
  //                                 map['emoji'],
  //                                 style: const TextStyle(fontSize: 28),
  //                               ),
  //                             ),
  //                           );
  //                         } else {
  //                           return GestureDetector(
  //                             onTap: () {},
  //                             child: const Padding(
  //                               padding: EdgeInsets.symmetric(horizontal: 4.0),
  //                               child: Icon(Icons.add, size: 28),
  //                             ),
  //                           );
  //                         }
  //                       }).toList(),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //
  //           // Menu actions
  //           Positioned(
  //             left: leftPosition,
  //             top: menuTop,
  //             child: TweenAnimationBuilder<double>(
  //               tween: Tween(begin: 0.8, end: 1.0),
  //               duration: const Duration(milliseconds: 250),
  //               curve: Curves.elasticOut,
  //               builder: (context, scale, child) {
  //                 return Transform.scale(
  //                   scale: scale,
  //                   alignment: Alignment.center,
  //                   child: child,
  //                 );
  //               },
  //               child: Material(
  //                 color: Colors.transparent,
  //                 child: Container(
  //                   width: menuWidth,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(12),
  //                     boxShadow: const [
  //                       BoxShadow(
  //                         color: Colors.black26,
  //                         blurRadius: 6,
  //                         offset: Offset(2, 2),
  //                       ),
  //                     ],
  //                   ),
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: widget.actions.map((item) {
  //                       return GestureDetector(
  //                         onTap: () {
  //                           _removeMenu();
  //                           item.onTap();
  //                         },
  //                         child: Container(
  //                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //                           alignment: Alignment.center,
  //                           child: Row(
  //                             mainAxisSize: MainAxisSize.max,
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               if (item.leading != null) item.leading! else const SizedBox(width: 18),
  //                               Flexible(
  //                                 child: Text(
  //                                   item.title,
  //                                   textAlign: TextAlign.center,
  //                                   style: TextStyle(
  //                                     fontSize: 16,
  //                                     color: item.isDestructive ? Colors.red : Colors.blue,
  //                                   ),
  //                                 ),
  //                               ),
  //                               if (item.trailing != null) item.trailing! else const SizedBox(width: 18),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     }).toList(),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  //
  //   overlay.insert(_menuEntry!);
  // }

  Widget emojiViewAddIcon() {
    bool reactionisPartOfMap = false;

    widget.emojiList?.forEach((element) {
      if (widget.chatReaction == element['emoji']) {
        reactionisPartOfMap = true;
      }
    });

    return widget.chatReaction == null || widget.chatReaction == "" || reactionisPartOfMap
        ? GestureDetector(
            onTap: () {
              _insertOverlay(context);
            },
            child: Container(
              height: 48,
              width: 48,
              margin: const EdgeInsets.only(top: 6, bottom: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.5),
              ),
              child: Center(
                  child: Icon(
                Icons.add,
                size: 22,
              )),
            ),
          )
        : GestureDetector(
            onTap: () {
              print("111111111333333");
              widget.backmanage(true);
              widget.emojiClick(null);
            },
            child: emojiView(widget.chatReaction!));
  }

  Widget emojiView(
      String emoji,
      ) {
    return Container(
      height: 48,
      width: 48,
      decoration: widget.chatReaction == emoji
          ? BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.5),
      )
          : null,
      margin: EdgeInsets.only(top: 6, bottom: 6),
      child: Center(
          child: DefaultTextStyle(
            style: TextStyle(fontSize: 22),
            child: Text(
              emoji,
            ),
          )),
    );
  }

  void _showMenu(BuildContext context, Rect rect) async {
    await _capturePreview();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final screenSize = MediaQuery.of(context).size;
    final menuHeight = 50.0 * widget.actions.length + 12;
    final menuWidth = screenSize.width * 0.6;
    const padding = 8.0;
    const menuGap = 6.0;
    const emojiBarHeight = 48.0;
    const bubbleGap = 8.0;
    const overlapGap = 8.0;

    double bubbleTop = rect.top;
    double emojiTop = bubbleTop - emojiBarHeight - bubbleGap;
    double menuTop = rect.bottom + menuGap;

    // Original shifting logic
    final overflow = (menuTop + menuHeight + padding) - screenSize.height;
    if (overflow > 0) {
      bubbleTop -= overflow;
      emojiTop -= overflow;
      menuTop -= overflow;

      // Keep bubble inside top padding + status bar
      final topLimit = MediaQuery.of(context).padding.top + padding;
      if (emojiTop < topLimit) {
        final shiftDown = topLimit - emojiTop;
        bubbleTop += shiftDown;
        emojiTop += shiftDown;
        menuTop += shiftDown;
      }
    }

    // Adjust menuTop if it still overflows: overlap bubble but keep gap
    final maxMenuTop = rect.bottom - menuHeight + overlapGap;
    if (menuTop + menuHeight > screenSize.height) {
      menuTop = maxMenuTop;
    }

    // Horizontal position
    double leftPosition = rect.left + rect.width / 2 - menuWidth / 2;
    leftPosition = leftPosition.clamp(padding, screenSize.width - menuWidth - padding);

    _menuEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Background blur
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeMenu,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black26),
                ),
              ),
            ),

            // Bubble preview
            Positioned(
              left: rect.left,
              top: bubbleTop,
              width: rect.width,
              height: rect.height,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.05),
                duration: const Duration(milliseconds: 150),
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
                child: _previewBytes != null ? Image.memory(_previewBytes!) : const SizedBox(),
              ),
            ),

            // Emoji bar
            if (widget.emojiList != null && widget.emojiList!.isNotEmpty)
              Positioned(
                left: leftPosition,
                top: emojiTop,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    height: emojiBarHeight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.emojiList!.map((map) {
                          if (map['emoji'] != null) {
                            return GestureDetector(
                              onTap: () {
                                if (map['emoji'] == widget.chatReaction) {
                                  widget.emojiClick(null);
                                } else {
                                  widget.emojiClick(map['emoji']);
                                }
                                widget.backmanage(true);
                                _removeMenu();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  map['emoji'],
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            );
                          } else {
                            return emojiViewAddIcon();
                          }
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),

            // Menu actions
            Positioned(
              left: leftPosition,
              top: menuTop,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: menuWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.actions.map((item) {
                        return GestureDetector(
                          onTap: () {
                            _removeMenu();
                            item.onTap();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (item.leading != null) item.leading! else const SizedBox(width: 18),
                                Flexible(
                                  child: Text(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: item.isDestructive ? Colors.red : Colors.blue,
                                    ),
                                  ),
                                ),
                                if (item.trailing != null) item.trailing! else const SizedBox(width: 18),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_menuEntry!);
  }

  void _removeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  OverlayEntry? overlayWidget;
  final _scrollController = ScrollController();

  void closeOverlay() {
    if (overlayWidget == null || overlayWidget?.mounted == false) return;
    overlayWidget?.remove();
    overlayWidget = null;
    _removeMenu();
  }

  void _insertOverlay(BuildContext context) {
    overlayWidget = OverlayEntry(builder: (context) {
      final size = MediaQuery.of(context).size;
      return Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                closeOverlay();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            width: size.width,
            child: Material(
              // color: widget.isDarkMode == true ? Colors.black : Colors.white,
              child: Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: EmojiPicker(
                  scrollController: _scrollController,
                  onEmojiSelected: (emoji.Category? category, Emoji emoji) {
                    widget.emojiClick(emoji.emoji);
                    widget.backmanage(true);

                    closeOverlay();
                  },
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0),
                        // backgroundColor: widget.isDarkMode == true ? Colors.black : Colors.white,
                        columns: 8,
                        noRecents: Text(
                          'No Recents',
                          style: TextStyle(
                            fontSize: 20,
                            color: widget.isDarkMode == true ? Colors.white60 : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        )),
                    // swapCategoryAndBottomBar: true,
                    skinToneConfig: SkinToneConfig(
                        indicatorColor: Colors.transparent,
                        dialogBackgroundColor: widget.isDarkMode == true ? Colors.black : Colors.white,
                        enabled: true),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: widget.isDarkMode == true ? Colors.black : Colors.white,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: widget.isDarkMode == true ? Colors.black : Colors.white,
                      showBackspaceButton: false,
                      buttonColor: Colors.transparent,
                      buttonIconColor: widget.isDarkMode == true ? Colors.white : Colors.black,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: widget.isDarkMode == true ? Colors.black : Colors.white,
                      // buttonColor: widget.isDarkMode == true ? Colors.white : Colors.black,
                      buttonIconColor: widget.isDarkMode == true ? Colors.white : Colors.black,
                      hintText: "Search emoji",
                      // hintStyle: TextStyle(
                      //   color: widget.isDarkMode == true ? Colors.white : Colors.black,
                      // ),
                      // emojiListBgColor: widget.isDarkMode == true ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
    return Overlay.of(context).insert(overlayWidget!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        final box = context.findRenderObject() as RenderBox;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        _showMenu(context, rect);
      },
      child: widget.child,
    );
  }
}

class ContextMenuItem {
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? leading;
  final Widget? trailing;

  ContextMenuItem(
    this.title,
    this.onTap, {
    this.isDestructive = false,
    this.leading,
    this.trailing,
  });
}
