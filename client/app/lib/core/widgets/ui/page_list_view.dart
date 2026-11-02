import 'package:flutter/material.dart';

/// Scrollable tab content: 20px gutters, centered and capped at 600px wide.
class PageListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const PageListView({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 32, 20, 32),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: children,
        ),
      ),
    );
  }
}
