import 'package:flutter/material.dart';

final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const EmailField({super.key, required this.controller, this.label = 'Email'});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
        return null;
      },
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool showStrength;
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.showStrength = false,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  double _strength(String s) {
    int score = 0;
    if (s.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(s)) score++;
    if (RegExp(r'[a-z]').hasMatch(s)) score++;
    if (RegExp(r'[0-9]').hasMatch(s)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) score++;
    return (score / 5).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    final strength = widget.showStrength ? _strength(value) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Use at least 8 characters';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        if (strength != null) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(value: strength),
          const SizedBox(height: 4),
          Text(
            strength < 0.4
                ? 'Weak password'
                : strength < 0.7
                ? 'Okay password'
                : 'Strong password',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}
