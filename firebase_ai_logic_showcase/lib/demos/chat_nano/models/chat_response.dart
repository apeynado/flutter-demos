import 'package:flutter/material.dart';

/// A simple container for the response from the ChatService.
class ChatResponse {
  final String? text;
  final Image? image;

  ChatResponse({this.text, this.image});
}
