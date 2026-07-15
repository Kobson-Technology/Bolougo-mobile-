import 'package:flutter/services.dart';
import 'dart:math';

/// Formats a number with space as thousand separator
/// e.g. 150000 → "150 000"
String formatMontant(num? amount, {bool withSuffix = true}) {
  if (amount == null) return withSuffix ? '0 F' : '0';
  final n = amount.toDouble();
  final parts = n.toStringAsFixed(0).split('');
  final buffer = StringBuffer();
  int count = 0;
  for (int i = parts.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write('\u202F'); // narrow no-break space
    buffer.write(parts[i]);
    count++;
  }
  final formatted = buffer.toString().split('').reversed.join('');
  return withSuffix ? '$formatted F' : formatted;
}

/// Formats a phone number with spaces every 2 digits
/// e.g. "0707070707" → "07 07 07 07 07"
String formatPhone(String? phone) {
  if (phone == null || phone.isEmpty) return '';
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && i % 2 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// TextInputFormatter that inserts narrow spaces every 3 digits (for amounts)
class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('\u202F');
      buffer.write(digits[i]);
      count++;
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// TextInputFormatter that inserts spaces every 2 digits (for phone numbers)
class PhoneSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Parses a formatted amount string back to double (removes non-digit chars except .)
double parseMontant(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^\d.]'), '');
  return double.tryParse(cleaned) ?? 0;
}
