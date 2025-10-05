import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatContextMenu extends StatelessWidget {
  final Widget child;
  final List<ChatMenuAction> actions;

  const ChatContextMenu({
    super.key,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoContextMenu(
      actions: actions
          .map((action) => CupertinoContextMenuAction(
                onPressed: () {
                  Navigator.pop(context);
                  action.onPressed();
                },
                isDestructiveAction: action.isDestructive,
                child: Text(action.label),
              ))
          .toList(),
      child: child,

    );
  }
}

class ChatMenuAction {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  ChatMenuAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });
}
