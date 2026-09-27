import 'package:flutter/material.dart';

class TextGuidanceMetrics {
  const TextGuidanceMetrics({
    required this.characters,
    required this.lines,
    required this.longestLineCharacters,
  });

  factory TextGuidanceMetrics.fromText(String value) {
    final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    return TextGuidanceMetrics(
      characters: lines.fold<int>(
        0,
        (total, line) => total + line.characters.length,
      ),
      lines: lines.length,
      longestLineCharacters: lines.fold<int>(
        0,
        (longest, line) =>
            line.characters.length > longest ? line.characters.length : longest,
      ),
    );
  }

  final int characters;
  final int lines;
  final int longestLineCharacters;
}
