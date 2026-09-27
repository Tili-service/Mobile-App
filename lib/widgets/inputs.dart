import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/* Labeled input (web AuthField / Field): label above, optional leading icon,
built-in show/hide toggle when `password` is true. Look comes from the theme's
InputDecorationTheme. */
class TiliField extends StatefulWidget {
  const TiliField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.password = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.autofocus = false,
    this.labelTrailing,
    this.helper,
    this.textInputAction,
    this.large = false,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool password;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final bool autofocus;
  final Widget? labelTrailing;
  final String? helper;
  final TextInputAction? textInputAction;
  final bool large;
  final Iterable<String>? autofillHints;

  @override
  State<TiliField> createState() => _TiliFieldState();
}

class _TiliFieldState extends State<TiliField> {
  late bool _hidden = widget.password;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final field = TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLines: widget.password ? 1 : widget.maxLines,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      style: widget.large ? context.text.bodyLarge : context.text.bodyMedium,
      decoration: InputDecoration(
        contentPadding: widget.large
            ? const EdgeInsets.symmetric(horizontal: TiliSpace.lg, vertical: (TiliSizes.inputLg - 24) / 2)
            : null,
        hintText: widget.hint,
        helperText: widget.helper,
        helperStyle: context.text.bodySmall,
        counterText: '',
        prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: widget.large ? TiliSizes.icon : TiliSizes.iconSm + 1),
        suffixIcon: widget.password
            ? IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: widget.large ? TiliSizes.icon : TiliSizes.iconSm + 1),
                color: p.textSubtle,
              )
            : null,
      ),
    );
    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.label!, style: context.text.labelLarge?.copyWith(color: p.textStrong, fontWeight: FontWeight.w500, fontSize: widget.large ? 15 : null)),
            ),
            if (widget.labelTrailing != null) widget.labelTrailing!,
          ],
        ),
        SizedBox(height: widget.large ? TiliSpace.sm : TiliSpace.xs + 2),
        field,
      ],
    );
  }
}

/* Compact search box used above lists. */
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      onChanged: onChanged,
      style: context.text.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: TiliSpace.md, vertical: TiliSpace.md),
        prefixIcon: const Icon(Icons.search, size: TiliSizes.iconSm + 1),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
      ),
    );
  }
}

/* Bordered dropdown matching the web `<select>` (border gray-200 rounded-xl bg-white). */
class TiliSelect<T> extends StatelessWidget {
  const TiliSelect({super.key, required this.value, required this.items, required this.onChanged, this.icon});

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: TiliSizes.buttonMd,
      padding: const EdgeInsets.symmetric(horizontal: TiliSpace.md),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: TiliRadius.all(TiliRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          borderRadius: TiliRadius.all(TiliRadius.md),
          icon: Icon(Icons.expand_more, size: TiliSizes.icon, color: p.textSubtle),
          style: context.text.bodyMedium,
          dropdownColor: p.surface,
          items: [
            for (final (v, label) in items)
              DropdownMenuItem<T>(
                value: v,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: TiliSizes.iconSm, color: p.textSubtle), const SizedBox(width: TiliSpace.sm)],
                    Text(label),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/* 6-digit PIN input (web PinForm: large spaced mono digits, underline). */
class PinField extends StatelessWidget {
  const PinField({super.key, required this.controller, this.onSubmitted, this.autofocus = true, this.length = 6});

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int length;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    UnderlineInputBorder line(Color c) => UnderlineInputBorder(borderSide: BorderSide(color: c, width: 2));
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: length,
      obscureText: true,
      obscuringCharacter: '●',
      onSubmitted: onSubmitted,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: context.text.headlineMedium?.copyWith(letterSpacing: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        filled: false,
        counterText: '',
        hintText: '• ' * length,
        hintStyle: context.text.headlineMedium?.copyWith(color: p.border, letterSpacing: 6),
        contentPadding: const EdgeInsets.symmetric(vertical: TiliSpace.sm),
        border: line(p.border),
        enabledBorder: line(p.border),
        focusedBorder: line(p.ink),
      ),
    );
  }
}

/* Pill toggle for category tabs / filters: ink when selected, outlined otherwise. */
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap, this.icon, this.trailing});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onInk : p.textStrong;
    return AnimatedContainer(
      duration: TiliMotion.fast,
      decoration: BoxDecoration(
        color: selected ? p.ink : p.surface,
        borderRadius: TiliRadius.all(TiliRadius.md),
        border: Border.all(color: selected ? p.ink : p.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: TiliRadius.all(TiliRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TiliSpace.lg, vertical: TiliSpace.sm + 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: TiliSizes.iconSm, color: selected ? p.accentSoft : p.textSubtle), const SizedBox(width: TiliSpace.xs + 2)],
                Text(label, style: context.text.labelLarge?.copyWith(color: fg, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
                if (trailing != null) ...[const SizedBox(width: TiliSpace.xs + 2), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
