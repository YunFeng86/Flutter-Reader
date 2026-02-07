import 'package:flutter/material.dart';

Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? labelText,
  String? hintText,
  String initialText = '',
  TextInputType? keyboardType,
  String? confirmText,
}) async {
  final controller = TextEditingController(text: initialText);

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: labelText, hintText: hintText),
          autofocus: true,
          keyboardType: keyboardType,
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(
              confirmText ?? MaterialLocalizations.of(context).okButtonLabel,
            ),
          ),
        ],
      );
    },
  );
}
