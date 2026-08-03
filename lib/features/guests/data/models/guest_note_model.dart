import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw FormatException('Formato de fecha no reconocido: $value');
}

/// Información adicional sobre un huésped que NO vive en las reservas:
/// notas del anfitrión y marca VIP. El ID del documento es el email del
/// huésped en minúsculas — así nunca se duplica ni desincroniza con los
/// datos de contacto que ya están en cada BookingModel.
class GuestNoteModel {
  const GuestNoteModel({
    required this.email,
    this.notes = '',
    this.isVip = false,
    required this.updatedAt,
  });

  final String email;
  final String notes;
  final bool isVip;
  final DateTime updatedAt;

  factory GuestNoteModel.fromJson(String email, Map<String, dynamic> json) {
    return GuestNoteModel(
      email: email,
      notes: json['notes'] as String? ?? '',
      isVip: json['isVip'] as bool? ?? false,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notes': notes,
      'isVip': isVip,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}