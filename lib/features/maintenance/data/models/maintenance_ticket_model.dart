import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw FormatException('Formato de fecha no reconocido: $value');
}

/// Un reporte de avería o tarea de mantenimiento. No está ligado
/// obligatoriamente a una reserva (a diferencia del checklist de
/// limpieza) — puede ser cualquier cosa: un aire acondicionado roto,
/// una gotera, un electrodoméstico que hay que reponer.
class MaintenanceTicketModel {
  const MaintenanceTicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.reportedBy,
    required this.createdAt,
    this.photoUrl,
    this.resolvedAt,
  });

  final String id;
  final String title;
  final String description;

  /// 'low' | 'medium' | 'high'
  final String priority;

  /// 'open' | 'in_progress' | 'resolved'
  final String status;

  /// Email de quien reportó (admin o staff) — suficiente para un MVP,
  /// sin necesidad de una colección de usuarios más elaborada.
  final String reportedBy;
  final DateTime createdAt;
  final String? photoUrl;
  final DateTime? resolvedAt;

  factory MaintenanceTicketModel.fromJson(String id, Map<String, dynamic> json) {
    return MaintenanceTicketModel(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      reportedBy: json['reportedBy'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      photoUrl: json['photoUrl'] as String?,
      resolvedAt: json['resolvedAt'] != null ? _parseDate(json['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'reportedBy': reportedBy,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}