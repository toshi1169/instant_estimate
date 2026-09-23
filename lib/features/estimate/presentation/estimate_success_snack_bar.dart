import 'package:flutter/material.dart';

const estimateSuccessSnackBarDuration = Duration(seconds: 2);

void showEstimateSuccessSnackBar(
  BuildContext context, {
  required Widget content,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(duration: estimateSuccessSnackBarDuration, content: content),
    );
}
