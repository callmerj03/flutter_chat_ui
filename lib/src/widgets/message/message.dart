import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:super_context_menu/super_context_menu.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../conditional/conditional.dart';
import '../../models/bubble_rtl_alignment.dart';
import '../../models/emoji_enlargement_behavior.dart';
import '../../models/menu_action_model.dart';
import '../../util.dart';
import '../state/inherited_chat_theme.dart';
import '../state/inherited_user.dart';
import 'file_message.dart';
import 'image_message.dart';
import 'message_status.dart';
import 'text_message.dart';
import 'user_avatar.dart';

/// Base widget for all message types in the chat. Renders bubbles around
/// messages and status. Sets maximum width for a message for
/// a nice look on larger screens.
class Message extends StatelessWidget {
  /// Creates a particular message from any message type.
  const Message({
    super.key,
    this.audioMessageBuilder,
    this.avatarBuilder,
    this.bubbleBuilder,
    this.bubbleRtlAlignment,
    this.customMessageBuilder,
    this.customStatusBuilder,
    required this.emojiEnlargementBehavior,
    this.fileMessageBuilder,
    required this.hideBackgroundOnEmojiMessages,
    this.imageHeaders,
    this.imageMessageBuilder,
    this.imageProviderBuilder,
    required this.message,
    required this.messageWidth,
    this.nameBuilder,
    this.onAvatarTap,
    this.onMessageDoubleTap,
    this.onMessageLongPress,
    this.onMessageStatusLongPress,
    this.onMessageStatusTap,
    this.onMessageTap,
    this.onMessageVisibilityChanged,
    this.onPreviewDataFetched,
    required this.roundBorder,
    required this.showAvatar,
    required this.showName,
    required this.showStatus,
    required this.isLeftStatus,
    required this.showUserAvatars,
    this.textMessageBuilder,
    required this.textMessageOptions,
    required this.usePreviewData,
    this.userAgent,
    this.videoMessageBuilder,
    required this.emojiList,
    required this.emojiClick,
    required this.menuActionModel,
    required this.index,
    required this.firebaseUserId,
    required this.backmanage,
    required this.isDarkMode,
  });

  //
  final List<Map> emojiList;
  final Function(String?, types.Message) emojiClick;
  final List<MenuActionModel> menuActionModel;

  final int? index;
  final bool isDarkMode;

  final String? firebaseUserId;

  final Function(bool) backmanage;

  /// Build an audio message inside predefined bubble.
  final Widget Function(types.AudioMessage, {required int messageWidth})? audioMessageBuilder;

  /// This is to allow custom user avatar builder
  /// By using this we can fetch newest user info based on id.
  final Widget Function(types.User author)? avatarBuilder;

  /// Customize the default bubble using this function. `child` is a content
  /// you should render inside your bubble, `message` is a current message
  /// (contains `author` inside) and `nextMessageInGroup` allows you to see
  /// if the message is a part of a group (messages are grouped when written
  /// in quick succession by the same author).
  final Widget Function(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  })? bubbleBuilder;

  /// Determine the alignment of the bubble for RTL languages. Has no effect
  /// for the LTR languages.
  final BubbleRtlAlignment? bubbleRtlAlignment;

  /// Build a custom message inside predefined bubble.
  final Widget Function(types.CustomMessage, {required int messageWidth})? customMessageBuilder;

  /// Build a custom status widgets.
  final Widget Function(types.Message message, {required BuildContext context})? customStatusBuilder;

  /// Controls the enlargement behavior of the emojis in the
  /// [types.TextMessage].
  /// Defaults to [EmojiEnlargementBehavior.multi].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// Build a file message inside predefined bubble.
  final Widget Function(types.FileMessage, {required int messageWidth})? fileMessageBuilder;

  /// Hide background for messages containing only emojis.
  final bool hideBackgroundOnEmojiMessages;

  /// See [Chat.imageHeaders].
  final Map<String, String>? imageHeaders;

  /// Build an image message inside predefined bubble.
  final Widget Function(types.ImageMessage, {required int messageWidth})? imageMessageBuilder;

  /// See [Chat.imageProviderBuilder].
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })? imageProviderBuilder;

  /// Any message type.
  final types.Message message;

  /// Maximum message width.
  final int messageWidth;

  /// See [TextMessage.nameBuilder].
  final Widget Function(types.User)? nameBuilder;

  /// See [UserAvatar.onAvatarTap].
  final void Function(types.User)? onAvatarTap;

  /// Called when user double taps on any message.
  final void Function(BuildContext context, types.Message)? onMessageDoubleTap;

  /// Called when user makes a long press on any message.
  final void Function(BuildContext context, types.Message)? onMessageLongPress;

  /// Called when user makes a long press on status icon in any message.
  final void Function(BuildContext context, types.Message)? onMessageStatusLongPress;

  /// Called when user taps on status icon in any message.
  final void Function(BuildContext context, types.Message)? onMessageStatusTap;

  /// Called when user taps on any message.
  final void Function(BuildContext context, types.Message)? onMessageTap;

  /// Called when the message's visibility changes.
  final void Function(types.Message, bool visible)? onMessageVisibilityChanged;

  /// See [TextMessage.onPreviewDataFetched].
  final void Function(types.TextMessage, types.PreviewData)? onPreviewDataFetched;

  /// Rounds border of the message to visually group messages together.
  final bool roundBorder;

  /// Show user avatar for the received message. Useful for a group chat.
  final bool showAvatar;

  /// See [TextMessage.showName].
  final bool showName;

  /// Show message's status.
  final bool showStatus;

  /// This is used to determine if the status icon should be on the left or
  /// right side of the message.
  /// This is only used when [showStatus] is true.
  /// Defaults to false.
  final bool isLeftStatus;

  /// Show user avatars for received messages. Useful for a group chat.
  final bool showUserAvatars;

  /// Build a text message inside predefined bubble.
  final Widget Function(
    types.TextMessage, {
    required int messageWidth,
    required bool showName,
  })? textMessageBuilder;

  /// See [TextMessage.options].
  final TextMessageOptions textMessageOptions;

  /// See [TextMessage.usePreviewData].
  final bool usePreviewData;

  /// See [TextMessage.userAgent].
  final String? userAgent;

  /// Build an audio message inside predefined bubble.
  final Widget Function(types.VideoMessage, {required int messageWidth})? videoMessageBuilder;

  Widget _avatarBuilder() => showAvatar
      ? avatarBuilder?.call(message.author) ??
          UserAvatar(
            author: message.author,
            bubbleRtlAlignment: bubbleRtlAlignment,
            imageHeaders: imageHeaders,
            onAvatarTap: onAvatarTap,
          )
      : const SizedBox(width: 40);

  List<dynamic> chatReactionGet() {
    return message.reaction as List<dynamic>;
  }

  bool isChatReactionEmpty() {
    bool isEmpty = true;

    if (message.reaction != null) {
      if (chatReactionGet().length > 0) {
        isEmpty = false;
      }
    }

    return isEmpty;
  }

  String getUserReaction() {
    if (message.reaction == null) return "";

    var list = chatReactionGet();
    if (list == null) return "";

    if (list.length == 0) return "";

    var selectedList = list.where((element) => element['userId'] == firebaseUserId).toList();

    if (selectedList.length > 0) {
      return selectedList[0]['reaction'];
    } else {
      return "";
    }
  }

  Widget _bubbleBuilder(BuildContext context, BorderRadius borderRadius, bool currentUserIsAuthor, bool enlargeEmojis,
      {bool showReaction = true}) {
    final defaultMessage = (enlargeEmojis && hideBackgroundOnEmojiMessages)
        ? _messageBuilder()
        : Stack(
            children: [
              Container(
                margin: isChatReactionEmpty() == false && showReaction == true ? EdgeInsets.only(bottom: 20) : null,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: !currentUserIsAuthor || message.type == types.MessageType.image
                      ? InheritedChatTheme.of(context).theme.secondaryColor
                      : InheritedChatTheme.of(context).theme.primaryColor,
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: _messageBuilder(),
                ),
              ),
              if (showReaction == true)
                if (message.reaction != null)
                  if (chatReactionGet().length > 0)
                    Positioned(
                      bottom: 0,
                      left: !currentUserIsAuthor ? null : 8,
                      right: currentUserIsAuthor ? null : 8,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                          color: currentUserIsAuthor
                              ? InheritedChatTheme.of(context).theme.secondaryColor
                              : InheritedChatTheme.of(context).theme.primaryColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Center(child: Text(chatReactionGet()[0]['reaction'])),
                              if (chatReactionGet().length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(chatReactionGet()[1]['reaction']),
                                ),
                              if (chatReactionGet().length > 1)
                                Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "${chatReactionGet().length}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          );

    return bubbleBuilder != null
        ? bubbleBuilder!(
            _messageBuilder(),
            message: message,
            nextMessageInGroup: roundBorder,
          )
        : defaultMessage;
  }

  Widget _messageBuilder() {
    switch (message.type) {
      case types.MessageType.audio:
        final audioMessage = message as types.AudioMessage;
        return audioMessageBuilder != null ? audioMessageBuilder!(audioMessage, messageWidth: messageWidth) : const SizedBox();
      case types.MessageType.custom:
        final customMessage = message as types.CustomMessage;
        return customMessageBuilder != null ? customMessageBuilder!(customMessage, messageWidth: messageWidth) : const SizedBox();
      case types.MessageType.file:
        final fileMessage = message as types.FileMessage;
        return fileMessageBuilder != null
            ? fileMessageBuilder!(fileMessage, messageWidth: messageWidth)
            : FileMessage(message: fileMessage);
      case types.MessageType.image:
        final imageMessage = message as types.ImageMessage;
        return imageMessageBuilder != null
            ? imageMessageBuilder!(imageMessage, messageWidth: messageWidth)
            : ImageMessage(
                imageHeaders: imageHeaders,
                imageProviderBuilder: imageProviderBuilder,
                message: imageMessage,
                messageWidth: messageWidth,
              );
      case types.MessageType.text:
        final textMessage = message as types.TextMessage;
        return textMessageBuilder != null
            ? textMessageBuilder!(
                textMessage,
                messageWidth: messageWidth,
                showName: showName,
              )
            : TextMessage(
                emojiEnlargementBehavior: emojiEnlargementBehavior,
                hideBackgroundOnEmojiMessages: hideBackgroundOnEmojiMessages,
                message: textMessage,
                nameBuilder: nameBuilder,
                onPreviewDataFetched: onPreviewDataFetched,
                options: textMessageOptions,
                showName: showName,
                usePreviewData: usePreviewData,
                userAgent: userAgent,
              );
      case types.MessageType.video:
        final videoMessage = message as types.VideoMessage;
        return videoMessageBuilder != null ? videoMessageBuilder!(videoMessage, messageWidth: messageWidth) : const SizedBox();
      default:
        return const SizedBox();
    }
  }

  Widget _statusIcon(
    BuildContext context,
  ) {
    if (!showStatus) return const SizedBox.shrink();

    return Padding(
      padding: InheritedChatTheme.of(context).theme.statusIconPadding,
      child: GestureDetector(
        onLongPress: () => onMessageStatusLongPress?.call(context, message),
        onTap: () => onMessageStatusTap?.call(context, message),
        child: customStatusBuilder != null ? customStatusBuilder!(message, context: context) : MessageStatus(status: message.status),
      ),
    );
  }

  Widget messageView(BuildContext context, dynamic currentUserIsAuthor, dynamic enlargeEmojis, {bool showReaction = true}) {
    return onMessageVisibilityChanged != null
        ? VisibilityDetector(
            key: Key(message.id),
            onVisibilityChanged: (visibilityInfo) => onMessageVisibilityChanged!(
              message,
              visibilityInfo.visibleFraction > 0.1,
            ),
            child: _bubbleBuilder(context, BorderRadius.all(Radius.circular(10)), currentUserIsAuthor, enlargeEmojis,
                showReaction: showReaction),
          )
        : _bubbleBuilder(context, BorderRadius.all(Radius.circular(10)), currentUserIsAuthor, enlargeEmojis, showReaction: showReaction);
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final user = InheritedUser.of(context).user;
    final currentUserIsAuthor = user.id == message.author.id;

    final enlargeEmojis = emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
        message is types.TextMessage &&
        isConsistsOfEmojis(
          emojiEnlargementBehavior,
          message as types.TextMessage,
        );
    final messageBorderRadius = InheritedChatTheme.of(context).theme.messageBorderRadius;

    final borderRadius = bubbleRtlAlignment == BubbleRtlAlignment.left
        ? BorderRadiusDirectional.only(
            bottomEnd: Radius.circular(
              !currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
            ),
            bottomStart: Radius.circular(
              currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
            ),
            topEnd: Radius.circular(messageBorderRadius),
            topStart: Radius.circular(messageBorderRadius),
          )
        : BorderRadius.only(
            bottomLeft: Radius.circular(
              currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
            ),
            bottomRight: Radius.circular(
              !currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
            ),
            topLeft: Radius.circular(messageBorderRadius),
            topRight: Radius.circular(messageBorderRadius),
          );

    final bubbleMargin = InheritedChatTheme.of(context).theme.bubbleMargin ??
        (bubbleRtlAlignment == BubbleRtlAlignment.left
            ? EdgeInsetsDirectional.only(
                bottom: 4,
                end: isMobile ? query.padding.right : 0,
                start: 20 + (isMobile ? query.padding.left : 0),
              )
            : EdgeInsets.only(
                bottom: 4,
                left: 20 + (isMobile ? query.padding.left : 0),
                right: isMobile ? query.padding.right : 0,
              ));

    return Container(
      alignment: bubbleRtlAlignment == BubbleRtlAlignment.left
          ? currentUserIsAuthor
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart
          : currentUserIsAuthor
              ? Alignment.centerRight
              : Alignment.centerLeft,
      margin: bubbleMargin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        textDirection: bubbleRtlAlignment == BubbleRtlAlignment.left ? null : TextDirection.ltr,
        children: [
          if (!currentUserIsAuthor && showUserAvatars) _avatarBuilder(),
          if (currentUserIsAuthor && isLeftStatus) _statusIcon(context),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: messageWidth.toDouble(),
            ),
            child: message.isDeleted == true
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: !currentUserIsAuthor || message.type == types.MessageType.image
                          ? InheritedChatTheme.of(context).theme.secondaryColor
                          : InheritedChatTheme.of(context).theme.primaryColor,
                    ),
                    child: ClipRRect(
                        borderRadius: borderRadius,
                        child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              "This meessage is deleted",
                              style: TextStyle(color: Colors.white),
                            ))),
                  )
                : ContextMenuWidget(
                    chatReaction: getUserReaction(),
                    menuProvider: (MenuRequest request) {
                      backmanage(false);
                      return Menu(
                        children: [
                          for (MenuActionModel item in menuActionModel)
                            if (item.typesMessage.where((element) => element == message.type).toList().isNotEmpty)
                              if (item.authorIds.where((element) => element == message.author.id).toList().isNotEmpty)
                                MenuAction(
                                  title: '${item.title}',
                                  state: MenuActionState.none,
                                  callback: () {
                                    if (item.callback != null) {
                                      item.callback!(message, item.title!);
                                    }
                                  },
                                  image: item.icon == null ? null : MenuImage.icon(item.icon!),
                                ),
                        ],
                      );
                    },
                    emojiList: emojiList,
                    liftBuilder: message is types.TextMessage == false
                        ? (context, child) {
                            return messageView(context, currentUserIsAuthor, false, showReaction: false);
                          }
                        : (message as types.TextMessage).text.length < 500
                            ? (context, child) {
                                return messageView(context, currentUserIsAuthor, false, showReaction: false);
                              }
                            : (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    "${(message as types.TextMessage).text}",
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 20,
                                  ),
                                );
                              },
                    emojiClick: (emoji) {
                      emojiClick(emoji, message);
                    },
                    backmanage: backmanage,
                    isDarkMode: isDarkMode,
                    child: messageView(context, currentUserIsAuthor, false)),
          ),
          if (currentUserIsAuthor && !isLeftStatus) _statusIcon(context),
        ],
      ),
    );
  }
}
