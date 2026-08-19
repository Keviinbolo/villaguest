import 'package:cloud_firestore/cloud_firestore.dart';

/// Formatea una fecha como 'dd/MM/yyyy'.
String formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

/// Convierte un valor de fecha que puede llegar como [Timestamp] de
/// Firestore, [DateTime] o [String] ISO-8601.
DateTime parseFlexibleDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw FormatException('Formato de fecha no reconocido: $value');
}
