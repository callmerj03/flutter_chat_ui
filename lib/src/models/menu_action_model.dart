import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MenuActionModel {
  String? title;
  IconData? icon;
  Widget? widget;
  Function(types.Message)? callback;


  MenuActionModel({required this.title, this.callback, this.icon});


}
