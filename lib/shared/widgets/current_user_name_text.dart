import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../core/firebase/current_user_context.dart';

class CurrentUserNameText extends StatelessWidget {
  final TextStyle? style;
  final TextOverflow overflow;
  final String fallback;

  const CurrentUserNameText({
    super.key,
    this.style,
    this.overflow = TextOverflow.ellipsis,
    this.fallback = 'User',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: sl<CurrentUserContext>().resolvedName(),
      builder: (context, snapshot) {
        final name = snapshot.data?.trim();
        return Text(
          (name == null || name.isEmpty) ? fallback : name,
          style: style,
          overflow: overflow,
        );
      },
    );
  }
}
