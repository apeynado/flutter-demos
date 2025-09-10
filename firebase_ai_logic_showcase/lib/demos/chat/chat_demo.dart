// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/ui/app_frame.dart';
import '../../shared/ui/app_spacing.dart';
import './ui_components/ui_components.dart';
import './firebaseai_chat_service.dart';
import 'ui_components/model_picker.dart';
import './models/models.dart';

class ChatDemo extends ConsumerStatefulWidget {
  const ChatDemo({super.key});

  @override
  ConsumerState<ChatDemo> createState() => _ChatDemoState();
}

class _ChatDemoState extends ConsumerState<ChatDemo> {
  // Service for interacting with the Gemini API.
  late final ChatService _chatService;

  // UI State
  final List<MessageData> _messages = <MessageData>[];
  final TextEditingController _userTextInputController =
      TextEditingController();
  Uint8List? _attachment;
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(ref);
    _chatService.init();
    _userTextInputController.text = geminiModels.selectedModel.defaultPrompt;
  }

  @override
  void didChangeDependencies() {
    requestPermissions();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userTextInputController.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    if (!kIsWeb) {
      await Permission.manageExternalStorage.request();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      final imageBytes = await pickedImage.readAsBytes();
      setState(() {
        _attachment = imageBytes;
      });
      log('attachment saved!');
    }
  }

  void sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
    });

    // Add user message to UI
    final userMessageText = text.trim();
    final userAttachment = _attachment;
    _messages.add(
      MessageData(
        text: userMessageText,
        image: userAttachment != null ? Image.memory(userAttachment) : null,
        fromUser: true,
      ),
    );
    setState(() {
      _attachment = null;
      _userTextInputController.clear();
    });
    _scrollToEnd();

    // Construct the Content object for the service
    final content = (userAttachment != null)
        ? Content.multi([
            TextPart(userMessageText),
            InlineDataPart('image/jpeg', userAttachment),
          ])
        : Content.text(userMessageText);

    // Call the service and handle the response
    try {
      final chatResponse = await _chatService.sendMessage(content);
      _messages.add(
        MessageData(
          text: chatResponse.text,
          image: chatResponse.image,
          fromUser: false,
        ),
      );
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Oops. Sorry, the message was unable to be sent!',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
      _scrollToEnd();
    }
  }

  void showModelPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return ModelPicker(
          selectedModel: geminiModels.selectedModel,
          onSelected: (value) {
            _chatService.changeModel(value);
            setState(() {
              _userTextInputController.text =
                  geminiModels.selectedModel.defaultPrompt;
              _messages.clear();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chat Demo'),
        actions: [
          IconButton(
            onPressed: showModelPicker,
            icon: Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: AppFrame(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: MessageListView(
                    messages: _messages,
                    scrollController: _scrollController,
                  ),
                ),
                if (_loading) const LinearProgressIndicator(),
                AttachmentPreview(attachment: _attachment),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MessageInputBar(
        textController: _userTextInputController,
        loading: _loading,
        sendMessage: sendMessage,
        onPickImagePressed: _pickImage,
      ),
    );
  }
}
