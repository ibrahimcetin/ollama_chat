import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ollama_chat/Models/settings_route_arguments.dart';

import 'subwidgets/subwidgets.dart';

class SettingsPage extends StatelessWidget {
  final SettingsRouteArguments? arguments;

  const SettingsPage({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.pacifico()),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ThemesSettings(),
              SizedBox(height: 16),
              ServerSettings(
                autoFocusServerAddress:
                    arguments?.autoFocusServerAddress ?? false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}