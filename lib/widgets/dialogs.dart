import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : null,
    ),
  );
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
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700) : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
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
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(
      title: title,
      label: label,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String initialValue;
  final String confirmLabel;

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
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: widget.label, border: const OutlineInputBorder()),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
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
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PIN de ${widget.name} :'),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _visible ? widget.pin : '••••••',
                style: const TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                tooltip: _visible ? 'Masquer' : 'Afficher',
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
              ),
              IconButton(
                tooltip: 'Copier',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.pin));
                  showMessage(context, 'PIN copié');
                },
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Text('Notez ce PIN maintenant — il ne sera plus affiché.'),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("J'ai noté le PIN, fermer"),
        ),
      ],
    );
  }
}
