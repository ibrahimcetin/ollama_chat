import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ollama_chat/Widgets/chat_configure_bottom_sheet.dart';
import 'package:ollama_chat/Widgets/ollama_bottom_sheet_header.dart';
import 'package:ollama_chat/Widgets/selection_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const ChatAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return AppBar(
      title: Column(
        children: [
          Text(title, style: GoogleFonts.pacifico()),
          if (chatProvider.currentChat != null)
            InkWell(
              onTap: () {
                _handleModelSelectionButton(context);
              },
              customBorder: StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  chatProvider.currentChat!.model,
                  style: GoogleFonts.kodeMono(
                    textStyle: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () {
            _handleCustomizeButton(context);
          },
        ),
      ],
      forceMaterialTransparency: !ResponsiveBreakpoints.of(context).isMobile,
    );
  }

  void _handleModelSelectionButton(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final selectedModelName = await showSelectionBottomSheet(
      key: ValueKey("${Hive.box('settings').get('serverAddress')}-string"),
      context: context,
      header: OllamaBottomSheetHeader(title: "Change The Model"),
      fetchItems: () async {
        final models = await chatProvider.fetchAvailableModels();

        return models.map((model) => model.name).toList();
      },
      currentSelection: chatProvider.currentChat!.model,
    );

    await chatProvider.updateCurrentChat(newModel: selectedModelName);
  }

  void _handleCustomizeButton(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: const ChatConfigureBottomSheet(),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
