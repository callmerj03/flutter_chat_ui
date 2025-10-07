import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;

import '../flutter_chat_ui.dart';

class IOSContextMenu extends StatefulWidget {
  final Widget child;
  final List<MenuActionModel> actions;
  final GlobalKey? previewKey;
  final List<Map>? emojiList;
  final String? chatReaction;
  final Function(String?) emojiClick;
  final Function(bool) backmanage;
  final bool isDarkMode;
  final types.Message message;

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
    required this.message,
  });

  @override
  State<IOSContextMenu> createState() => IOSContextMenuState();
}

class IOSContextMenuState extends State<IOSContextMenu> {
  OverlayEntry? _menuEntry;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    print("init_IOSContextMenuState");
  }

  @override
  void dispose() {
    // Unregister when widget disposed
    print("init_IOSContextMenuState_dispose");

    removeMenu(restoreKeyboard: false);
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
              height: 36,
              width: 36,
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

  bool _wasKeyboardOpenBeforeMenu = false;
  FocusNode? _lastFocusNode;

  void _showMenu(BuildContext context, Rect rect) async {
    await _capturePreview();

    // Remember current keyboard & focus state
    _wasKeyboardOpenBeforeMenu = MediaQuery.of(context).viewInsets.bottom > 0;
    _lastFocusNode = FocusManager.instance.primaryFocus;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final screenSize = MediaQuery.of(context).size;
    const padding = 8.0;
    const menuGap = 6.0;
    const emojiBarHeight = 48.0;
    const bubbleGap = 8.0;
    final safeTop = MediaQuery.of(context).padding.top + padding;
    final safeBottom = screenSize.height - MediaQuery.of(context).padding.bottom - padding;

    // Base sizes
    final menuHeight = 50.0 * widget.actions.length + 12;
    final menuWidth = screenSize.width * 0.6;

    // Initial positions
    double bubbleTop = rect.top;
    double emojiTop = bubbleTop - emojiBarHeight - bubbleGap;
    double menuTop = rect.bottom + menuGap;

    // --- Step 1: Prevent bottom overflow ---
    final overflowBottom = menuTop + menuHeight - safeBottom;
    if (overflowBottom > 0) {
      bubbleTop -= overflowBottom;
      emojiTop -= overflowBottom;
      menuTop -= overflowBottom;
    }

    // --- ✅ Step 1.5: Force everything below status bar (FIX ADDED HERE) ---
    final double minTopAllowed = safeTop + 8.0;
    if (emojiTop < minTopAllowed || bubbleTop < minTopAllowed) {
      final shiftDown = minTopAllowed - min(emojiTop, bubbleTop);
      bubbleTop += shiftDown;
      emojiTop += shiftDown;
      menuTop += shiftDown;
    }

    // --- Step 2: Prevent top overflow (redundant but kept for safety) ---
    if (emojiTop < safeTop) {
      final diff = safeTop - emojiTop;
      bubbleTop += diff;
      emojiTop += diff;
      menuTop += diff;
    }

    // --- Step 3: If total height overflows screen, auto adjust ---
    final totalTop = emojiTop;
    final totalBottom = menuTop + menuHeight;
    final totalHeight = totalBottom - totalTop;

    if (totalHeight > screenSize.height - (padding * 2)) {
      final overlapAmount = totalHeight - (screenSize.height - (padding * 2));
      menuTop -= overlapAmount + 12;
    }

    // --- Step 4: Center popup horizontally ---
    double leftPosition = rect.left + rect.width / 2 - menuWidth / 2;
    leftPosition = leftPosition.clamp(padding, screenSize.width - menuWidth - padding);

    await Future.delayed(const Duration(milliseconds: 250));

    _menuEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Background Blur
            Positioned.fill(
              child: GestureDetector(
                onTap: removeMenu,
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

            // Emoji bar (with dynamic centering)
            if (widget.emojiList != null && widget.emojiList!.isNotEmpty)
              Builder(
                builder: (context) {
                  final emojiCount = widget.emojiList!.length;
                  final singleEmojiWidth = 36.0;
                  final totalEmojiWidth = emojiCount * singleEmojiWidth + 16;
                  final maxEmojiWidth = screenSize.width * 0.8;
                  final emojiBarWidth = totalEmojiWidth.clamp(120.0, maxEmojiWidth);

                  double emojiLeft = rect.left + rect.width / 2 - emojiBarWidth / 2;
                  emojiLeft = emojiLeft.clamp(padding, screenSize.width - emojiBarWidth - padding);

                  return Positioned(
                    left: emojiLeft,
                    top: emojiTop,
                    child: Material(
                      color: Colors.transparent,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: emojiBarWidth,
                          maxHeight: emojiBarHeight * 2.2,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: widget.emojiList!.sublist(0, widget.emojiList!.length - 1).map((map) {
                                      if (map['emoji'] != null) {
                                        return GestureDetector(
                                          onTap: () {
                                            if (map['emoji'] == widget.chatReaction) {
                                              widget.emojiClick(null);
                                            } else {
                                              widget.emojiClick(map['emoji']);
                                            }
                                            removeMenu();
                                            widget.backmanage(true);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                            child: Text(
                                              map['emoji'],
                                              style: const TextStyle(fontSize: 22),
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
                              if (widget.emojiList!.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    final lastMap = widget.emojiList!.last;
                                    if (lastMap['emoji'] != null) {
                                      return GestureDetector(
                                        onTap: () {
                                          if (lastMap['emoji'] == widget.chatReaction) {
                                            widget.emojiClick(null);
                                          } else {
                                            widget.emojiClick(lastMap['emoji']);
                                          }
                                          removeMenu();
                                          widget.backmanage(true);
                                        },
                                        child: Text(
                                          lastMap['emoji'],
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      );
                                    } else {
                                      return emojiViewAddIcon();
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Popup Menu
            Positioned(
              left: leftPosition,
              top: menuTop,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: menuWidth,
                    decoration: BoxDecoration(
                      color: !widget.isDarkMode ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
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
                      children: widget.actions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isLast = index == widget.actions.length - 1;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                //
                                removeMenu();

                                //
                                item.callback!(widget.message , "");
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.title ?? "",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: item.isDestructive ? Colors.red : Colors.blue,
                                        ),
                                      ),
                                    ),
                                    if (item.icon != null) item.icon! else const SizedBox(width: 18),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 0.5,
                                thickness: 0.5,
                                color: widget.isDarkMode
                                    ? CupertinoColors.extraLightBackgroundGray.withOpacity(0.2)
                                    : CupertinoColors.darkBackgroundGray.withOpacity(0.2),
                              ),
                          ],
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

    widget.backmanage(false);
    overlay.insert(_menuEntry!);

    if (_menuEntry != null) {
      OverlayTracker.add(_menuEntry!);
    }
  }

  void removeMenu({bool restoreKeyboard = true}) {
    if (_menuEntry != null) {
      _menuEntry!.remove();
      OverlayTracker.remove(_menuEntry!);
      _menuEntry = null;

      widget.backmanage(true);

      // Restore keyboard if needed
      if (restoreKeyboard && _wasKeyboardOpenBeforeMenu) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _lastFocusNode != null) {
            FocusScope.of(context).requestFocus(_lastFocusNode);
          }
        });
      }
    }
  }

  OverlayEntry? overlayWidget;
  final _scrollController = ScrollController();

  void closeOverlay() {
    if (overlayWidget == null || overlayWidget?.mounted == false) return;
    overlayWidget?.remove();
    OverlayTracker.remove(overlayWidget!);
    overlayWidget = null;
    // removeMenu();
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
                    removeMenu();
                  },
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0),
                        backgroundColor: widget.isDarkMode == true ? Colors.black : Colors.white,
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
                      hintStyle: TextStyle(
                        color: widget.isDarkMode == true ? Colors.white : Colors.black,
                      ),
                      emojiListBgColor: widget.isDarkMode == true ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
    OverlayTracker.add(overlayWidget!);
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
