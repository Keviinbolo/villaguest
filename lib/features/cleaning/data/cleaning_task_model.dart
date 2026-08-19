import 'package:villaguest/core/utils/date_utils.dart';

/// Una tarea individual dentro de un checklist de limpieza. La foto es
/// obligatoria para marcarla como completada — no existe ningún método
/// en el repositorio que permita completar una tarea sin foto, a
/// propósito, siguiendo lo que pedía tu doc original.
class CleaningTaskModel {
  const CleaningTaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.photoUrl,
    this.completedAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final String? photoUrl;
  final DateTime? completedAt;

  factory CleaningTaskModel.fromJson(String id, Map<String, dynamic> json) {
    return CleaningTaskModel(
      id: id,
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
      completedAt:
          json['completedAt'] != null ? parseFlexibleDate(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'photoUrl': photoUrl,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

/// Lista de tareas estándar que se genera automáticamente al crear un
/// checklist nuevo. Pensada como punto de partida editable, no como
/// lista cerrada — si más adelante quieres tareas personalizadas por
/// villa, esto se puede mover a Firestore en vez de vivir en código.
class DefaultCleaningTasks {
  static const List<String> titles = [
    'Cambiar sábanas y toallas',
    'Limpiar baños',
    'Limpiar cocina y electrodomésticos',
    'Sacar la basura',
    'Reponer consumibles (papel, jabón, café)',
    'Revisar daños o artículos faltantes',
    'Foto general: villa lista para el próximo huésped',
  ];
}