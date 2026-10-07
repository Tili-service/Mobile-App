import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import 'display.dart';
import 'inputs.dart';
import 'tili_button.dart';

void showMessage(BuildContext context, String message, {bool error = false}) {
  final p = context.palette;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: error ? p.danger : p.ink,
      content: Row(
        children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: p.onInk, size: TiliSizes.icon),
          const SizedBox(width: TiliSpace.md),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/* Base modal used by every dialog in the app (web ConfirmModal / SidePanel
look): optional tinted icon, title, body, right-aligned actions. */
class TiliDialog extends StatelessWidget {
  const TiliDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.icon,
    this.tone = TiliTone.accent,
    this.width = 440,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final IconData? icon;
  final TiliTone tone;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      insetPadding: const EdgeInsets.all(TiliSpace.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(TiliSpace.xl, TiliSpace.xl, TiliSpace.md, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[IconTile(icon: icon!, tone: tone), const SizedBox(width: TiliSpace.md + 2)],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: TiliSpace.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.text.titleLarge),
                          if (subtitle != null) ...[
                            const SizedBox(height: TiliSpace.xxs),
                            Text(subtitle!, style: context.text.bodySmall?.copyWith(color: p.textSubtle)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  TiliIconButton(icon: Icons.close, tooltip: 'Fermer', onPressed: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(TiliSpace.xl, TiliSpace.lg + 4, TiliSpace.xl, TiliSpace.xl),
                child: DefaultTextStyle.merge(
                  style: context.text.bodyMedium?.copyWith(color: p.textMuted),
                  child: child,
                ),
              ),
            ),
            if (actions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: TiliSpace.xl, vertical: TiliSpace.lg),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: p.borderSubtle))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(width: TiliSpace.sm), a],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Supprimer',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => TiliDialog(
      title: title,
      icon: destructive ? Icons.delete_outline : Icons.help_outline,
      tone: destructive ? TiliTone.danger : TiliTone.accent,
      actions: [
        TiliButton(label: 'Annuler', variant: TiliButtonVariant.outline, onPressed: () => Navigator.of(context).pop(false)),
        TiliButton(
          label: confirmLabel,
          variant: destructive ? TiliButtonVariant.danger : TiliButtonVariant.brand,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      child: Text(message),
    ),
  );
  return result == true;
}

Future<String?> textInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
  String confirmLabel = 'Enregistrer',
  IconData? icon,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(
      title: title,
      label: label,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      icon: icon,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.confirmLabel,
    this.icon,
  });

  final String title;
  final String label;
  final String initialValue;
  final String confirmLabel;
  final IconData? icon;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return TiliDialog(
      title: widget.title,
      icon: widget.icon,
      width: 400,
      actions: [
        TiliButton(label: 'Annuler', variant: TiliButtonVariant.outline, onPressed: () => Navigator.of(context).pop()),
        TiliButton(label: widget.confirmLabel, onPressed: _submit),
      ],
      child: TiliField(controller: _controller, label: widget.label, autofocus: true, onSubmitted: (_) => _submit()),
    );
  }
}

/* The backend returns a profile's PIN only once (on creation or reset), so it
must be shown to the manager before the dialog closes. */
Future<void> showPinOnceDialog(BuildContext context, {required String title, required String name, required String pin}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PinOnceDialog(title: title, name: name, pin: pin),
  );
}

class _PinOnceDialog extends StatefulWidget {
  const _PinOnceDialog({required this.title, required this.name, required this.pin});

  final String title;
  final String name;
  final String pin;

  @override
  State<_PinOnceDialog> createState() => _PinOnceDialogState();
}

class _PinOnceDialogState extends State<_PinOnceDialog> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TiliDialog(
      title: widget.title,
      subtitle: 'PIN de ${widget.name}',
      icon: Icons.pin_outlined,
      tone: TiliTone.success,
      width: 400,
      actions: [TiliButton(label: "J'ai noté le PIN, fermer", onPressed: () => Navigator.of(context).pop())],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: TiliSpace.lg, vertical: TiliSpace.md),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: TiliRadius.all(TiliRadius.md),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _visible ? widget.pin : '••••••',
                    style: context.text.headlineMedium?.copyWith(letterSpacing: 10),
                  ),
                ),
                TiliIconButton(
                  tooltip: _visible ? 'Masquer' : 'Afficher',
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                TiliIconButton(
                  tooltip: 'Copier',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.pin));
                    showMessage(context, 'PIN copié');
                  },
                  icon: Icons.copy_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: TiliSpace.md),
          const Notice(message: 'Notez ce PIN maintenant — il ne sera plus affiché.'),
        ],
      ),
    );
  }
}
