import 'package:flutter/material.dart';

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsGroup({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SettingsLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Reload')),
        ],
      ),
    ),
  );
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: trailing ?? const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

Future<T?> showSettingsChoice<T>({
  required BuildContext context,
  required String title,
  required T selected,
  required List<(T, String, String)> options,
}) {
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(title),
      children: [
        for (final (value, label, description) in options)
          RadioListTile<T>(
            value: value,
            groupValue: selected,
            title: Text(label),
            subtitle: description.isEmpty ? null : Text(description),
            onChanged: (choice) => Navigator.pop(dialogContext, choice),
          ),
      ],
    ),
  );
}
