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

import 'package:flutter/material.dart';
import 'demos/chat/chat_demo.dart';
import 'demos/chat_nano/chat_nano_demo.dart';
import 'demos/multimodal/multimodal_demo.dart';
import 'demos/live_api/live_api_demo.dart';

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ChatDemoNanoState> _chatNanoKey = GlobalKey();
  bool _nanoPickerHasBeenShown = false;

  late final List<Widget> _demoPages;

  @override
  void initState() {
    super.initState();
    _demoPages = <Widget>[
      const ChatDemo(),
      const LiveAPIDemo(),
      ChatDemoNano(key: _chatNanoKey),
      const MultimodalDemo(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2 && !_nanoPickerHasBeenShown) {
      _chatNanoKey.currentState?.showModelPicker();
      _nanoPickerHasBeenShown = true;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.video_chat),
                label: Text('Live API'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text('Chat (Nano Banana) 🍌'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.photo_library),
                label: Text('Multimodal'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _demoPages,
            ),
          ),
        ],
      ),
    );
  }
}