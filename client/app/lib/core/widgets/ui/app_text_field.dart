import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/config/theme.dart';

/// Figma `Input`: label above a 48px field, error caption below.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;

  /// Widget shown at the end of the field, e.g. a show-password button.
  final Widget? trailing;
  final String? suffixText;
  final int maxLines;
  final int? maxLength;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.trailing,
    this.suffixText,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final Widget field = readOnly && onTap != null && controller != null
        ? _PickerField(
            hint: hint,
            controller: controller!,
            validator: validator,
            onTap: onTap!,
            trailing: trailing,
          )
        : TextFormField(
            controller: controller,
            initialValue: initialValue,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: obscureText ? 1 : maxLines,
            maxLength: maxLength,
            style: AppText.body,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: trailing,
              suffixText: suffixText,
            ),
          );

    // The field is announced by its visible label rather than by its hint.
    final semanticField = Semantics(container: true, label: label, child: field);

    if (label == null) return semanticField;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text(label!, style: AppText.bodyMedium)),
        const SizedBox(height: 8),
        semanticField,
      ],
    );
  }
}

/// Read-only field that opens a picker (date…). Built as a button that looks
/// like a field, so Enter / Space and screen readers open the picker too.
class _PickerField extends StatefulWidget {
  final String? hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final VoidCallback onTap;
  final Widget? trailing;

  const _PickerField({
    required this.hint,
    required this.controller,
    required this.validator,
    required this.onTap,
    required this.trailing,
  });

  @override
  State<_PickerField> createState() => _PickerFieldState();
}

class _PickerFieldState extends State<_PickerField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPicked);
  }

  @override
  void didUpdateWidget(_PickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onPicked);
      widget.controller.addListener(_onPicked);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPicked);
    super.dispose();
  }

  void _onPicked() {
    setState(() {});
    // Clear a "required" error as soon as a value is picked.
    if (_fieldKey.currentState?.hasError ?? false) _fieldKey.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    final validator = widget.validator;
    return FormField<String>(
      key: _fieldKey,
      validator: validator == null ? null : (_) => validator(widget.controller.text),
      builder: (state) => Semantics(
        button: true,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (value) => setState(() => _focused = value),
          onHover: (value) => setState(() => _hovered = value),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            isEmpty: widget.controller.text.isEmpty,
            isFocused: _focused,
            isHovering: _hovered,
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: widget.trailing,
              errorText: state.errorText,
            ),
            child: Text(widget.controller.text, style: AppText.body),
          ),
        ),
      ),
    );
  }
}
