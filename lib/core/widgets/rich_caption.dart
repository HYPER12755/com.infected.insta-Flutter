import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Instagram-style caption with tappable #hashtags and @mentions.
class RichCaption extends StatefulWidget {
  final String username;
  final String caption;
  final int maxLines;
  final TextStyle? baseStyle;
  final TextStyle? nameStyle;

  const RichCaption({
    super.key,
    required this.username,
    required this.caption,
    this.maxLines = 2,
    this.baseStyle,
    this.nameStyle,
  });

  @override
  State<RichCaption> createState() => _RichCaptionState();
}

class _RichCaptionState extends State<RichCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.baseStyle ?? const TextStyle(fontSize: 13, color: Colors.white);
    final nameSt = widget.nameStyle ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white);
    final hashSt = base.copyWith(color: const Color(0xFF5B8FDE), fontWeight: FontWeight.w500);
    final mentionSt = hashSt;

    final spans = <InlineSpan>[
      TextSpan(
        text: '${widget.username} ',
        style: nameSt,
        recognizer: TapGestureRecognizer()
          ..onTap = () => context.push('/profile/${widget.username}'),
      ),
      ..._buildCaptionSpans(widget.caption, base, hashSt, mentionSt, context),
    ];

    final full = TextSpan(children: spans);

    return LayoutBuilder(builder: (ctx, constraints) {
      final tp = TextPainter(text: full, maxLines: widget.maxLines,
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: constraints.maxWidth);
      final overflow = tp.didExceedMaxLines;

      return RichText(
        maxLines: _expanded ? null : widget.maxLines,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        text: TextSpan(children: [
          ...spans,
          if (overflow && !_expanded)
            TextSpan(
              text: ' more',
              style: base.copyWith(color: Colors.white54, fontWeight: FontWeight.w500),
              recognizer: TapGestureRecognizer()
                ..onTap = () => setState(() => _expanded = true),
            ),
        ]),
      );
    });
  }

  List<InlineSpan> _buildCaptionSpans(String text, TextStyle base,
      TextStyle hashSt, TextStyle mentionSt, BuildContext context) {
    if (text.isEmpty) return [];

    // Match #hashtag or @mention
    final pattern = RegExp(r'(#[\w]+|@[\w.]+)');
    final spans = <InlineSpan>[];
    int last = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start), style: base));
      }
      final word = match.group(0)!;
      final isHash = word.startsWith('#');
      spans.add(TextSpan(
        text: word,
        style: isHash ? hashSt : mentionSt,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (isHash) {
              context.push('/search/${word.substring(1)}');
            } else {
              context.push('/profile/${word.substring(1)}');
            }
          },
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return spans;
  }
}
