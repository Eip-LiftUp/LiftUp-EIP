import 'package:flutter/material.dart';
import 'package:app/config/theme.dart';

/// h3 heading placed above a group of cards (`mb-3`), with an optional
/// trailing action such as "Voir tout".
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(container: true, header: true, child: Text(title, style: AppText.h3)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
