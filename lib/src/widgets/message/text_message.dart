import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_link_previewer/flutter_link_previewer.dart' show LinkPreview, regexLink;
import 'package:flutter_parsed_text/flutter_parsed_text.dart';

import '../../models/emoji_enlargement_behavior.dart';
import '../../models/matchers.dart';
import '../../models/pattern_style.dart';
import '../../util.dart';
import '../state/inherited_chat_theme.dart';
import '../state/inherited_user.dart';
import 'user_name.dart';

/// A class that represents text message widget with optional link preview.
class TextMessage extends StatelessWidget {
  /// Creates a text message widget from a [types.TextMessage] class.
  const TextMessage({
    super.key,
    required this.emojiEnlargementBehavior,
    required this.hideBackgroundOnEmojiMessages,
    required this.message,
    this.nameBuilder,
    this.onPreviewDataFetched,
    this.options = const TextMessageOptions(),
    required this.showName,
    required this.usePreviewData,
    this.userAgent,
  });

  /// See [Message.emojiEnlargementBehavior].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// See [Message.hideBackgroundOnEmojiMessages].
  final bool hideBackgroundOnEmojiMessages;

  /// [types.TextMessage].
  final types.TextMessage message;

  /// This is to allow custom user name builder
  /// By using this we can fetch newest user info based on id.
  final Widget Function(types.User)? nameBuilder;

  /// See [LinkPreview.onPreviewDataFetched].
  final void Function(types.TextMessage, types.PreviewData)? onPreviewDataFetched;

  /// Customisation options for the [TextMessage].
  final TextMessageOptions options;

  /// Show user name for the received message. Useful for a group chat.
  final bool showName;

  /// Enables link (URL) preview.
  final bool usePreviewData;

  /// User agent to fetch preview data with.
  final String? userAgent;

  Widget _linkPreview(
    types.User user,
    double width,
    BuildContext context,
  ) {
    final linkDescriptionTextStyle = user.id == message.author.id
        ? InheritedChatTheme.of(context).theme.sentMessageLinkDescriptionTextStyle
        : InheritedChatTheme.of(context).theme.receivedMessageLinkDescriptionTextStyle;
    final linkTitleTextStyle = user.id == message.author.id
        ? InheritedChatTheme.of(context).theme.sentMessageLinkTitleTextStyle
        : InheritedChatTheme.of(context).theme.receivedMessageLinkTitleTextStyle;

    return LinkPreview(
      enableAnimation: true,
      metadataTextStyle: linkDescriptionTextStyle,
      metadataTitleStyle: linkTitleTextStyle,
      onLinkPressed: options.onLinkPressed,
      onPreviewDataFetched: _onPreviewDataFetched,
      openOnPreviewImageTap: options.openOnPreviewImageTap,
      openOnPreviewTitleTap: options.openOnPreviewTitleTap,
      padding: EdgeInsets.symmetric(
        horizontal: InheritedChatTheme.of(context).theme.messageInsetsHorizontal,
        vertical: InheritedChatTheme.of(context).theme.messageInsetsVertical,
      ),
      previewData: message.previewData,
      text: message.text,
      textWidget: _textWidgetBuilder(user, context, false),
      userAgent: userAgent,
      width: width,
    );
  }

  void _onPreviewDataFetched(types.PreviewData previewData) {
    if (message.previewData == null) {
      onPreviewDataFetched?.call(message, previewData);
    }
  }

  Widget _textWidgetBuilder(
    types.User user,
    BuildContext context,
    bool enlargeEmojis,
  ) {
    final theme = InheritedChatTheme.of(context).theme;
    final bodyLinkTextStyle = user.id == message.author.id
        ? InheritedChatTheme.of(context).theme.sentMessageBodyLinkTextStyle
        : InheritedChatTheme.of(context).theme.receivedMessageBodyLinkTextStyle;
    final bodyTextStyle = user.id == message.author.id ? theme.sentMessageBodyTextStyle : theme.receivedMessageBodyTextStyle;
    final boldTextStyle = user.id == message.author.id ? theme.sentMessageBodyBoldTextStyle : theme.receivedMessageBodyBoldTextStyle;
    final codeTextStyle = user.id == message.author.id ? theme.sentMessageBodyCodeTextStyle : theme.receivedMessageBodyCodeTextStyle;
    final emojiTextStyle = user.id == message.author.id ? theme.sentEmojiMessageTextStyle : theme.receivedEmojiMessageTextStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showName) nameBuilder?.call(message.author) ?? UserName(author: message.author),
        if (enlargeEmojis)
          if (options.isTextSelectable) SelectableText(message.text, style: emojiTextStyle) else Text(message.text, style: emojiTextStyle)
        else
          TextMessageText(
            bodyLinkTextStyle: bodyLinkTextStyle,
            bodyTextStyle: bodyTextStyle,
            boldTextStyle: boldTextStyle,
            codeTextStyle: codeTextStyle,
            options: options,
            text: message.text,
  //           text: '''
  //           void _showMenu(BuildContext context, Rect rect) async {
  //   await _capturePreview();
  //
  //   // Remember current keyboard & focus state
  //   _wasKeyboardOpenBeforeMenu = MediaQuery.of(context).viewInsets.bottom > 0;
  //   _lastFocusNode = FocusManager.instance.primaryFocus;
  //
  //   // Dismiss keyboard
  //   FocusScope.of(context).unfocus();
  //
  //   final overlay = Overlay.of(context);
  //   if (overlay == null) return;
  //
  //   final screenSize = MediaQuery.of(context).size;
  //   const padding = 8.0;
  //   const menuGap = 6.0;
  //   const emojiBarHeight = 48.0;
  //   const bubbleGap = 8.0;
  //   final safeTop = MediaQuery.of(context).padding.top + padding;
  //   final safeBottom = screenSize.height - MediaQuery.of(context).padding.bottom - padding;
  //
  //   // Base sizes
  //   final menuHeight = 50.0 * widget.actions.length + 12;
  //   final menuWidth = screenSize.width * 0.6;
  //
  //   // Initial positions
  //   double bubbleTop = rect.top;
  //   double emojiTop = bubbleTop - emojiBarHeight - bubbleGap;
  //   double menuTop = rect.bottom + menuGap;
  //
  //   // --- Step 1: Prevent bottom overflow ---
  //   final overflowBottom = menuTop + menuHeight - safeBottom;
  //   if (overflowBottom > 0) {
  //     bubbleTop -= overflowBottom;
  //     emojiTop -= overflowBottom;
  //     menuTop -= overflowBottom;
  //   }
  //
  //   // --- ✅ Step 1.5: Force everything below status bar (FIX ADDED HERE) ---
  //   final double minTopAllowed = safeTop + 8.0;
  //   if (emojiTop < minTopAllowed || bubbleTop < minTopAllowed) {
  //     final shiftDown = minTopAllowed - min(emojiTop, bubbleTop);
  //     bubbleTop += shiftDown;
  //     emojiTop += shiftDown;
  //     menuTop += shiftDown;
  //   }
  //
  //   // --- Step 2: Prevent top overflow (redundant but kept for safety) ---
  //   if (emojiTop < safeTop) {
  //     final diff = safeTop - emojiTop;
  //     bubbleTop += diff;
  //     emojiTop += diff;
  //     menuTop += diff;
  //   }
  //
  //   // --- Step 3: If total height overflows screen, auto adjust ---
  //   final totalTop = emojiTop;
  //   final totalBottom = menuTop + menuHeight;
  //   final totalHeight = totalBottom - totalTop;
  //
  //   if (totalHeight > screenSize.height - (padding * 2)) {
  //     final overlapAmount = totalHeight - (screenSize.height - (padding * 2));
  //     menuTop -= overlapAmount + 12;
  //   }
  //
  //   // --- Step 4: Center popup horizontally ---
  //   double leftPosition = rect.left + rect.width / 2 - menuWidth / 2;
  //   leftPosition = leftPosition.clamp(padding, screenSize.width - menuWidth - padding);
  //
  //   await Future.delayed(const Duration(milliseconds: 250));
  //
  //   _menuEntry = OverlayEntry(
  //     builder: (context) => Material(
  //       type: MaterialType.transparency,
  //       child: Stack(
  //         children: [
  //           // Background Blur
  //           Positioned.fill(
  //             child: GestureDetector(
  //               onTap: removeMenu,
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
  //           // Emoji bar (with dynamic centering)
  //           if (widget.emojiList != null && widget.emojiList!.isNotEmpty)
  //             Builder(
  //               builder: (context) {
  //                 final emojiCount = widget.emojiList!.length;
  //                 final singleEmojiWidth = 36.0;
  //                 final totalEmojiWidth = emojiCount * singleEmojiWidth + 16;
  //                 final maxEmojiWidth = screenSize.width * 0.8;
  //                 final emojiBarWidth = totalEmojiWidth.clamp(120.0, maxEmojiWidth);
  //
  //                 double emojiLeft = rect.left + rect.width / 2 - emojiBarWidth / 2;
  //                 emojiLeft = emojiLeft.clamp(padding, screenSize.width - emojiBarWidth - padding);
  //
  //                 return Positioned(
  //                   left: emojiLeft,
  //                   top: emojiTop,
  //                   child: Material(
  //                     color: Colors.transparent,
  //                     child: ConstrainedBox(
  //                       constraints: BoxConstraints(
  //                         maxWidth: emojiBarWidth,
  //                         maxHeight: emojiBarHeight * 2.2,
  //                       ),
  //                       child: Container(
  //                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                         decoration: BoxDecoration(
  //                           color: Theme.of(context).primaryColor,
  //                           borderRadius: BorderRadius.circular(100),
  //                         ),
  //                         child: Row(
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             Expanded(
  //                               child: SingleChildScrollView(
  //                                 scrollDirection: Axis.horizontal,
  //                                 child: Row(
  //                                   children: widget.emojiList!.sublist(0, widget.emojiList!.length - 1).map((map) {
  //                                     if (map['emoji'] != null) {
  //                                       return GestureDetector(
  //                                         onTap: () {
  //                                           if (map['emoji'] == widget.chatReaction) {
  //                                             widget.emojiClick(null);
  //                                           } else {
  //                                             widget.emojiClick(map['emoji']);
  //                                           }
  //                                           removeMenu();
  //                                           widget.backmanage(true);
  //                                         },
  //                                         child: Padding(
  //                                           padding: const EdgeInsets.symmetric(horizontal: 4.0),
  //                                           child: Text(
  //                                             map['emoji'],
  //                                             style: const TextStyle(fontSize: 22),
  //                                           ),
  //                                         ),
  //                                       );
  //                                     } else {
  //                                       return emojiViewAddIcon();
  //                                     }
  //                                   }).toList(),
  //                                 ),
  //                               ),
  //                             ),
  //                             if (widget.emojiList!.isNotEmpty)
  //                               Builder(
  //                                 builder: (context) {
  //                                   final lastMap = widget.emojiList!.last;
  //                                   if (lastMap['emoji'] != null) {
  //                                     return GestureDetector(
  //                                       onTap: () {
  //                                         if (lastMap['emoji'] == widget.chatReaction) {
  //                                           widget.emojiClick(null);
  //                                         } else {
  //                                           widget.emojiClick(lastMap['emoji']);
  //                                         }
  //                                         removeMenu();
  //                                         widget.backmanage(true);
  //                                       },
  //                                       child: Text(
  //                                         lastMap['emoji'],
  //                                         style: const TextStyle(fontSize: 22),
  //                                       ),
  //                                     );
  //                                   } else {
  //                                     return emojiViewAddIcon();
  //                                   }
  //                                 },
  //                               ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //
  //           // Popup Menu
  //           Positioned(
  //             left: leftPosition,
  //             top: menuTop,
  //             child: TweenAnimationBuilder<double>(
  //               tween: Tween(begin: 0.8, end: 1.0),
  //               duration: const Duration(milliseconds: 250),
  //               curve: Curves.elasticOut,
  //               builder: (context, scale, child) => Transform.scale(
  //                 scale: scale,
  //                 alignment: Alignment.center,
  //                 child: child,
  //               ),
  //               child: Material(
  //                 color: Colors.transparent,
  //                 child: Container(
  //                   width: menuWidth,
  //                   decoration: BoxDecoration(
  //                     color: !widget.isDarkMode ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray,
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
  //                     children: widget.actions.asMap().entries.map((entry) {
  //                       final index = entry.key;
  //                       final item = entry.value;
  //                       final isLast = index == widget.actions.length - 1;
  //
  //                       return Column(
  //                         children: [
  //                           InkWell(
  //                             onTap: () {
  //                               //
  //                               removeMenu();
  //
  //                               //
  //                               item.callback!(widget.message , "");
  //                             },
  //                             child: Container(
  //                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //                               alignment: Alignment.center,
  //                               child: Row(
  //                                 mainAxisSize: MainAxisSize.max,
  //                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                                 children: [
  //                                   Flexible(
  //                                     child: Text(
  //                                       item.title ?? "",
  //                                       textAlign: TextAlign.center,
  //                                       style: TextStyle(
  //                                         fontSize: 16,
  //                                         color: item.isDestructive ? Colors.red : Colors.blue,
  //                                       ),
  //                                     ),
  //                                   ),
  //                                   if (item.icon != null) item.icon! else const SizedBox(width: 18),
  //                                 ],
  //                               ),
  //                             ),
  //                           ),
  //                           if (!isLast)
  //                             Divider(
  //                               height: 0.5,
  //                               thickness: 0.5,
  //                               color: widget.isDarkMode
  //                                   ? CupertinoColors.extraLightBackgroundGray.withOpacity(0.2)
  //                                   : CupertinoColors.darkBackgroundGray.withOpacity(0.2),
  //                             ),
  //                         ],
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
  //   widget.backmanage(false);
  //   overlay.insert(_menuEntry!);
  //
  //   if (_menuEntry != null) {
  //     OverlayTracker.add(_menuEntry!);
  //   }
  // }
  //           ''',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never && isConsistsOfEmojis(emojiEnlargementBehavior, message);
    final theme = InheritedChatTheme.of(context).theme;
    final user = InheritedUser.of(context).user;
    final width = MediaQuery.of(context).size.width;

    if (usePreviewData && onPreviewDataFetched != null) {
      final urlRegexp = RegExp(regexLink, caseSensitive: false);
      final matches = urlRegexp.allMatches(message.text);

      if (matches.isNotEmpty) {
        return _linkPreview(user, width, context);
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: theme.messageInsetsHorizontal,
        vertical: theme.messageInsetsVertical,
      ),
      child: _textWidgetBuilder(user, context, enlargeEmojis),
    );
  }
}

/// Widget to reuse the markdown capabilities, e.g., for previews.
class TextMessageText extends StatelessWidget {
  const TextMessageText({
    super.key,
    this.bodyLinkTextStyle,
    required this.bodyTextStyle,
    this.boldTextStyle,
    this.codeTextStyle,
    this.maxLines,
    this.options = const TextMessageOptions(),
    this.overflow = TextOverflow.clip,
    required this.text,
  });

  /// Style to apply to anything that matches a link.
  final TextStyle? bodyLinkTextStyle;

  /// Regular style to use for any unmatched text. Also used as basis for the fallback options.
  final TextStyle bodyTextStyle;

  /// Style to apply to anything that matches bold markdown.
  final TextStyle? boldTextStyle;

  /// Style to apply to anything that matches code markdown.
  final TextStyle? codeTextStyle;

  /// See [ParsedText.maxLines].
  final int? maxLines;

  /// See [TextMessage.options].
  final TextMessageOptions options;

  /// See [ParsedText.overflow].
  final TextOverflow overflow;

  /// Text that is shown as markdown.
  final String text;

  @override
  Widget build(BuildContext context) => ParsedText(
        parse: [
          ...options.matchers,
          mailToMatcher(
            style: bodyLinkTextStyle ??
                bodyTextStyle.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
          urlMatcher(
            onLinkPressed: options.onLinkPressed,
            style: bodyLinkTextStyle ??
                bodyTextStyle.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
          boldMatcher(
            style: boldTextStyle ?? bodyTextStyle.merge(PatternStyle.bold.textStyle),
          ),
          italicMatcher(
            style: bodyTextStyle.merge(PatternStyle.italic.textStyle),
          ),
          lineThroughMatcher(
            style: bodyTextStyle.merge(PatternStyle.lineThrough.textStyle),
          ),
          codeMatcher(
            style: codeTextStyle ?? bodyTextStyle.merge(PatternStyle.code.textStyle),
          ),
        ],
        maxLines: maxLines,
        overflow: overflow,
        regexOptions: const RegexOptions(multiLine: true, dotAll: true),
        selectable: options.isTextSelectable,
        style: bodyTextStyle,
        text: text,
        textWidthBasis: TextWidthBasis.longestLine,
      );
}

@immutable
class TextMessageOptions {
  const TextMessageOptions({
    this.isTextSelectable = true,
    this.onLinkPressed,
    this.openOnPreviewImageTap = false,
    this.openOnPreviewTitleTap = false,
    this.matchers = const [],
  });

  /// Whether user can tap and hold to select a text content.
  final bool isTextSelectable;

  /// Custom link press handler.
  final void Function(String)? onLinkPressed;

  /// See [LinkPreview.openOnPreviewImageTap].
  final bool openOnPreviewImageTap;

  /// See [LinkPreview.openOnPreviewTitleTap].
  final bool openOnPreviewTitleTap;

  /// Additional matchers to parse the text.
  final List<MatchText> matchers;
}
