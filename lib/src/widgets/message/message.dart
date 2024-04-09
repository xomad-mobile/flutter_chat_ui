import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart' as date;
import 'package:visibility_detector/visibility_detector.dart';

import '../../models/bubble_rtl_alignment.dart';
import '../../models/emoji_enlargement_behavior.dart';
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
    required this.message,
    required this.messageWidth,
    this.nameBuilder,
    this.onAvatarTap,
    this.onMessageDoubleTap,
    this.onMessageLongPress,
    this.onMessageTapDown,
    this.onMessageStatusLongPress,
    this.onMessageStatusTap,
    this.onMessageTap,
    this.onMessageVisibilityChanged,
    this.onPreviewDataFetched,
    required this.roundBorder,
    required this.showAvatar,
    required this.showName,
    required this.showStatus,
    required this.showUserAvatars,
    this.textMessageBuilder,
    required this.textMessageOptions,
    required this.usePreviewData,
    this.userAgent,
    this.videoMessageBuilder,
    this.sideMarginValue = 12.0,
    this.showTimeSeenMessage,
    this.forwardMessageBuilder,
    this.replyMessageBuilder,
    this.onTapLinkCustomize,
  });

  /// Build an audio message inside predefined bubble.
  final Widget Function(types.AudioMessage, {required int messageWidth})? audioMessageBuilder;

  /// This is to allow custom user avatar builder
  /// By using this we can fetch newest user info based on id
  final Widget Function(String userId)? avatarBuilder;

  /// Customize the default bubble using this function. `child` is a content
  /// you should render inside your bubble, `message` is a current message
  /// (contains `author` inside) and `nextMessageInGroup` allows you to see
  /// if the message is a part of a group (messages are grouped when written
  /// in quick succession by the same author)
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
  final Widget Function(types.Message message, {required BuildContext context})?
      customStatusBuilder;

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

  /// Build customize tap link.
  final Function(String urlText)? onTapLinkCustomize;

  /// Any message type.
  final types.Message message;

  /// Maximum message width.
  final int messageWidth;

  /// See [TextMessage.nameBuilder].
  final Widget Function(String userId)? nameBuilder;

  /// See [UserAvatar.onAvatarTap].
  final void Function(types.User)? onAvatarTap;

  /// Called when user double taps on any message.
  final void Function(BuildContext context, types.Message)? onMessageDoubleTap;

  /// Called when user makes a long press on any message.
  final void Function(BuildContext context, types.Message, int messageWidth)? onMessageLongPress;

  /// Called when user makes a long press on any message.
  final void Function(TapDownDetails)? onMessageTapDown;

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

  /// Show time seen message.

  final bool? showTimeSeenMessage;

  /// Show user avatars for received messages. Useful for a group chat.
  final bool showUserAvatars;

  /// Side padding between Avatar - Left/Right Size
  final double? sideMarginValue;

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

  final Widget Function(
    types.Message, {
    required int messageWidth,
  })? replyMessageBuilder;

  final Widget Function(
    types.Message, {
    required int messageWidth,
  })? forwardMessageBuilder;

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
    final timeMessageWidget = showStatus
        ? Padding(
            padding: const EdgeInsets.only(
              left: 40.0,
              top: 4.0,
              bottom: 4.0,
              right: 8.0,
            ),
            child: Align(
              alignment: currentUserIsAuthor ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                message.updatedAt != null
                    ? message.status == types.Status.seen && showTimeSeenMessage == true
                        ? 'Seen at ${date.DateFormat("h:mma").format(DateTime.fromMillisecondsSinceEpoch(message.updatedAt!))}'
                        : date.DateFormat('h:mma').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              message.updatedAt!,
                            ),
                          )
                    : '',
                style: currentUserIsAuthor
                    ? InheritedChatTheme.of(context).theme.timeSentMessageTextStyle
                    : InheritedChatTheme.of(context).theme.timeRecieveMessageTextStyle,
              ),
            ),
          )
        : const SizedBox.shrink();
    return Column(
      children: [
        Container(
          alignment: bubbleRtlAlignment == BubbleRtlAlignment.left
              ? currentUserIsAuthor
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart
              : currentUserIsAuthor
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          margin: bubbleRtlAlignment == BubbleRtlAlignment.left
              ? EdgeInsetsDirectional.only(
                  bottom: 4,
                  end: isMobile ? query.padding.right : 0,
                  start: sideMarginValue! + (isMobile ? query.padding.left : 0),
                )
              : EdgeInsets.only(
                  bottom: 4,
                  left: sideMarginValue! + (isMobile ? query.padding.left : 0),
                  right: isMobile ? query.padding.right : 0,
                ),
          child: Column(
            crossAxisAlignment:
                currentUserIsAuthor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                textDirection:
                    bubbleRtlAlignment == BubbleRtlAlignment.left ? null : TextDirection.ltr,
                children: [
                  if (!currentUserIsAuthor && showUserAvatars) _avatarBuilder(),
                  LayoutBuilder(
                    builder: (context, constraints) => ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: messageWidth.toDouble(),
                      ),
                      child: Opacity(
                        opacity: message.status == types.Status.error ? 0.3 : 1.0,
                        child: Column(
                          crossAxisAlignment: currentUserIsAuthor
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onDoubleTap: () => onMessageDoubleTap?.call(context, message),
                              onLongPress: () => onMessageLongPress?.call(
                                context,
                                message,
                                messageWidth,
                              ),
                              onTapDown: (postition) => onMessageTapDown?.call(postition),
                              onTap: () => onMessageTap?.call(context, message),
                              child: onMessageVisibilityChanged != null
                                  ? VisibilityDetector(
                                      key: Key(message.id),
                                      onVisibilityChanged: (visibilityInfo) =>
                                          onMessageVisibilityChanged!(
                                        message,
                                        visibilityInfo.visibleFraction > 0.1,
                                      ),
                                      child: _bubbleBuilder(
                                        context,
                                        borderRadius.resolve(
                                          Directionality.of(context),
                                        ),
                                        currentUserIsAuthor,
                                        enlargeEmojis,
                                      ),
                                    )
                                  : _bubbleBuilder(
                                      context,
                                      borderRadius.resolve(Directionality.of(context)),
                                      currentUserIsAuthor,
                                      enlargeEmojis,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (currentUserIsAuthor)
                    Padding(
                      padding: InheritedChatTheme.of(context).theme.statusIconPadding,
                      child: message.status == types.Status.error
                          ? const Icon(
                              Icons.error_sharp,
                              color: Color(0xffE30000),
                              size: 16.0,
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
              timeMessageWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarBuilder() => showAvatar
      ? avatarBuilder?.call(message.author.id) ??
          UserAvatar(
            author: message.author,
            bubbleRtlAlignment: bubbleRtlAlignment,
            imageHeaders: imageHeaders,
            onAvatarTap: onAvatarTap,
          )
      : const SizedBox(width: 40);

  Widget _bubbleBuilder(
    BuildContext context,
    BorderRadius borderRadius,
    bool currentUserIsAuthor,
    bool enlargeEmojis,
  ) =>
      bubbleBuilder != null
          ? bubbleBuilder!(
              _messageBuilder(
                message,
                currentUserIsAuthor,
                context,
              ),
              message: message,
              nextMessageInGroup: roundBorder,
            )
          : enlargeEmojis && hideBackgroundOnEmojiMessages
              ? _messageBuilder(
                  message,
                  currentUserIsAuthor,
                  context,
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: !currentUserIsAuthor || message.type == types.MessageType.image
                        ? InheritedChatTheme.of(context).theme.secondaryColor
                        : InheritedChatTheme.of(context).theme.primaryColor,
                  ),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: _messageBuilder(
                      message,
                      currentUserIsAuthor,
                      context,
                    ),
                  ),
                );

  Widget _fwMessageDefault(
    types.Message message,
    bool currentUserIsAuthor,
    BuildContext context,
  ) {
    final fwMessage = types.Message.fromJson(message.metadata!['forwardMsg']);

    fwMessage.metadata!['isForwardMsg'] = true;
    final style = currentUserIsAuthor
        ? InheritedChatTheme.of(context).theme.sentMessageBodyCodeTextStyle
        : InheritedChatTheme.of(context).theme.receivedMessageBodyCodeTextStyle;
    const maxLengthNameCreator = 30;
    final messageCreator = message.metadata!['creator'] == null
        ? ''
        : message.metadata!['creator'].length >= maxLengthNameCreator
            ? ('${message.metadata!['creator'].substring(0, maxLengthNameCreator)}...')
            : '${message.metadata!['creator']}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: currentUserIsAuthor ? const Color(0xff747D89) : const Color(0xffDFE4EE),
            ),
            padding: const EdgeInsets.only(left: 3.0),
            child: Container(
              padding: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4.0),
                  bottomRight: Radius.circular(4.0),
                ),
                color: currentUserIsAuthor ? const Color(0xff141414) : const Color(0xffffffff),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Forwarded message',
                          style: style?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          messageCreator,
                          style: style?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: (messageWidth - 35.0),
                        ),
                        child: _messageBuilder(
                          fwMessage.copyWith(
                            author: fwMessage.author.copyWith(id: message.metadata!['authorId']),
                          ),
                          currentUserIsAuthor,
                          context,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.metadata != null &&
              message.metadata!['msg'] != null &&
              message.metadata!['msg'].isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: TextMessageText(
                bodyTextStyle: style!,
                text: message.metadata!['msg'],
              ),
            ),
        ],
      ),
    );
  }

  Widget _replyMessageDefault(
    types.Message message,
    bool currentUserIsAuthor,
    BuildContext context,
  ) {
    final replyMessage = types.Message.fromJson(message.metadata!['replyMsg']);

    replyMessage.metadata!['isReplyMsg'] = true;
    final style = currentUserIsAuthor
        ? InheritedChatTheme.of(context).theme.sentMessageBodyCodeTextStyle
        : InheritedChatTheme.of(context).theme.receivedMessageBodyCodeTextStyle;
    const maxLengthNameCreator = 30;
    final messageCreator = message.metadata!['creator'] == null
        ? ''
        : message.metadata!['creator'].length >= maxLengthNameCreator
            ? ('${message.metadata!['creator'].substring(0, maxLengthNameCreator)}...')
            : '${message.metadata!['creator']}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: currentUserIsAuthor ? const Color(0xff747D89) : const Color(0xffDFE4EE),
            ),
            padding: const EdgeInsets.only(left: 3.0),
            child: Container(
              padding: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4.0),
                  bottomRight: Radius.circular(4.0),
                ),
                color: currentUserIsAuthor ? const Color(0xff141414) : const Color(0xffffffff),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          messageCreator,
                          style: style?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: (messageWidth - 35.0),
                        ),
                        child: _messageBuilder(
                          replyMessage.copyWith(
                            author: replyMessage.author.copyWith(id: message.metadata!['authorId']),
                          ),
                          currentUserIsAuthor,
                          context,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.metadata != null &&
              message.metadata!['msg'] != null &&
              message.metadata!['msg'].isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: TextMessageText(
                bodyTextStyle: style!,
                text: message.metadata!['msg'],
              ),
            ),
        ],
      ),
    );
  }

  Widget _messageBuilder(
    types.Message message,
    bool currentUserIsAuthor,
    BuildContext context,
  ) {
    if (message.metadata != null && message.metadata!['forwardMsg'] != null) {
      return forwardMessageBuilder != null
          ? forwardMessageBuilder!(message, messageWidth: messageWidth)
          : _fwMessageDefault(message, currentUserIsAuthor, context);
    }
    if (message.metadata != null && message.metadata!['replyMsg'] != null) {
      return replyMessageBuilder != null
          ? replyMessageBuilder!(message, messageWidth: messageWidth)
          : _replyMessageDefault(message, currentUserIsAuthor, context);
    }
    switch (message.type) {
      case types.MessageType.audio:
        final audioMessage = message as types.AudioMessage;
        return audioMessageBuilder != null
            ? audioMessageBuilder!(audioMessage, messageWidth: messageWidth)
            : const SizedBox();
      case types.MessageType.custom:
        final customMessage = message as types.CustomMessage;
        return customMessageBuilder != null
            ? customMessageBuilder!(customMessage, messageWidth: messageWidth)
            : const SizedBox();
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
                onTapLinkCustomize: onTapLinkCustomize,
              );
      case types.MessageType.video:
        final videoMessage = message as types.VideoMessage;
        return videoMessageBuilder != null
            ? videoMessageBuilder!(videoMessage, messageWidth: messageWidth)
            : const SizedBox();
      default:
        return const SizedBox();
    }
  }
}
