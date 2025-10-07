import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MenuActionModel {
  String? title;
  Widget? icon;
  List<types.MessageType> typesMessage;
  List<String> authorIds;
  Function(types.Message, String)? callback;
  final bool isDestructive;

  MenuActionModel(
      {this.isDestructive = false, required this.title, required this.typesMessage, required this.authorIds, this.callback, this.icon});
}
