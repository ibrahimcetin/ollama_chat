import 'package:flutter/material.dart';
import 'package:ollama_chat/Providers/chat_provider.dart';
import 'package:ollama_chat/Widgets/ollama_bottom_sheet_header.dart';
import 'package:provider/provider.dart';

class ChatConfigureBottomSheet extends StatefulWidget {
  const ChatConfigureBottomSheet({super.key});

  @override
  State<ChatConfigureBottomSheet> createState() =>
      _ChatConfigureBottomSheetState();
}

class _ChatConfigureBottomSheetState extends State<ChatConfigureBottomSheet> {
  final _scrollController = ScrollController();

  double _temperature = 0.8;

  bool _showAdvancedConfigurations = false;

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.58,
      ),
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OllamaBottomSheetHeader(title: 'Configure The Chat'),
            Divider(),
            Expanded(
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RenameButton(),
                      _BottomSheetButton(
                        icon: const Icon(Icons.save_as_outlined),
                        title: 'Save as a new model',
                        onPressed: () {},
                      ),
                      _DeleteButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BottomSheetTextField(
                    labelText: 'System Prompt',
                    infoText:
                        'The system prompt is the message that the AI will see before generating a response. '
                        'It is used to provide context to the AI. '
                        'For example, if you are asking the AI to generate a response to a question, '
                        'you can provide the question as the system prompt.',
                  ),
                  const SizedBox(height: 16),
                  Divider(),
                  const SizedBox(height: 16),
                  _BottomSheetTextField(
                    labelText: 'Temperature',
                    hintText: 'Enter a value between 0 and 1',
                    errorText: (_temperature < 0.0 || _temperature > 1.0)
                        ? 'Temperature must be between 0 and 1'
                        : null,
                    infoText: 'The temperature of the model. '
                        'Increasing the temperature will make the model answer more creatively.',
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        value = value.replaceAll(',', '.');
                        _temperature = double.tryParse(value) ?? 0.8;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _BottomSheetTextField(
                    labelText: 'Seed',
                    infoText:
                        'Sets the random number seed to use for generation. '
                        'Setting this to a specific number will make the model generate the same text for the same prompt.',
                    keyboardType: TextInputType.number,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAdvancedConfigurations =
                            !_showAdvancedConfigurations;

                        _scrollController.animateTo(
                          _showAdvancedConfigurations
                              ? _scrollController.position.pixels + 100
                              : _scrollController.position.minScrollExtent,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      });
                    },
                    child: Text(
                      _showAdvancedConfigurations
                          ? 'Hide Advanced Configurations'
                          : 'Show Advanced Configurations',
                    ),
                  ),
                  if (_showAdvancedConfigurations) ...[
                    _BottomSheetTextField(
                      labelText: 'Number of Predictions',
                      infoText:
                          'Maximum number of tokens to predict when generating text.',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _BottomSheetTextField(
                      labelText: 'Repeat Penalty',
                      infoText: 'Sets how strongly to penalize repetitions.',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.settings_backup_restore_rounded),
                      label: const Text('Reset to Defaults'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenameButton extends StatelessWidget {
  const _RenameButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetButton(
      icon: const Icon(Icons.edit_outlined),
      title: 'Rename',
      onPressed: () async {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);

        final newTitle = await _showRenameDialog(
          context,
          currentTitle: chatProvider.currentChat?.title,
        );

        if (newTitle != null) {
          await chatProvider.updateCurrentChat(newTitle: newTitle);
        }
      },
      isDisabled:
          Provider.of<ChatProvider>(context, listen: false).currentChat == null,
    );
  }

  Future<String?> _showRenameDialog(
    BuildContext context, {
    String? currentTitle,
  }) async {
    String? newTitle;

    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Chat'),
          content: TextFormField(
              initialValue: currentTitle,
              decoration: const InputDecoration(
                labelText: 'New Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) => newTitle = value,
              onTapOutside: (PointerDownEvent event) {
                FocusManager.instance.primaryFocus?.unfocus();
              }),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newTitle != null && newTitle!.trim().isNotEmpty) {
                  Navigator.of(context).pop(newTitle!.trim());
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetButton(
      icon: const Icon(Icons.delete_outline),
      title: 'Delete',
      onPressed: () {
        _showDeleteDialog(context);
      },
      isDestructive: true,
      isDisabled:
          Provider.of<ChatProvider>(context, listen: false).currentChat == null,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Chat?'),
          content: const Text(
            'This action can\'t be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<ChatProvider>(context, listen: false)
                    .deleteCurrentChat();

                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _BottomSheetButton extends StatelessWidget {
  final Icon icon;
  final String title;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final bool isDestructive;

  const _BottomSheetButton({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.isDisabled = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        foregroundColor: isDestructive ? Colors.red : null,
        padding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Column(
        children: [
          icon,
          Text(title),
        ],
      ),
    );
  }
}

class _BottomSheetTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final String? errorText;

  final String infoText;

  final TextInputType keyboardType;

  final Function(String)? onChanged;

  const _BottomSheetTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.errorText,
    required this.infoText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(labelText),
                  content: Text(infoText),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
          icon: Icon(Icons.info_outline),
        ),
      ),
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      onTapOutside: (PointerDownEvent event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }
}
