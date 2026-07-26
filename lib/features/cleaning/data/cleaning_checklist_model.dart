import 'cleaning_task_model.dart';

/// Un checklist de limpieza, vinculado a una reserva. Las tareas se
/// guardan como Map (no List) con el taskId como clave, para poder
/// actualizar una sola tarea en Firestore usando notación de punto
/// (`tasks.task_0.isCompleted`) sin tener que leer y reescribir todo el
/// arreglo — evita condiciones de carrera si dos personas del equipo de
/// limpieza usan la app al mismo tiempo.
class CleaningChecklistModel {
  const CleaningChecklistModel({
    required this.id,
    required this.bookingId,
    required this.guestName,
    required this.checkOutDate,
    required this.status,
    required this.tasks,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String bookingId;

  /// Denormalizado desde la reserva para no tener que hacer un segundo
  /// query solo para mostrar el nombre en la lista de checklists.
  final String guestName;
  final DateTime checkOutDate;

  /// 'pending' | 'in_progress' | 'completed'
  final String status;
  final Map<String, CleaningTaskModel> tasks;
  final DateTime createdAt;
  final DateTime? completedAt;

  int get totalTasks => tasks.length;
  int get completedTasksCount => tasks.values.where((t) => t.isCompleted).length;
  bool get isFullyComplete => totalTasks > 0 && completedTasksCount == totalTasks;

  /// Tareas ordenadas de forma estable (task_0, task_1, ...) para que la
  /// UI no las muestre en orden aleatorio (los Map de Dart no garantizan
  /// orden de iteración consistente entre lecturas).
  List<CleaningTaskModel> get orderedTasks {
    final list = tasks.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  factory CleaningChecklistModel.fromJson(String id, Map<String, dynamic> json) {
    final rawTasks = (json['tasks'] as Map?)?.cast<String, dynamic>() ?? {};
    final tasks = rawTasks.map(
      (taskId, taskData) => MapEntry(
        taskId,
        CleaningTaskModel.fromJson(taskId, (taskData as Map).cast<String, dynamic>()),
      ),
    );

    return CleaningChecklistModel(
      id: id,
      bookingId: json['bookingId'] as String? ?? '',
      guestName: json['guestName'] as String? ?? '',
      checkOutDate: parseFlexibleDate(json['checkOutDate']),
      status: json['status'] as String? ?? 'pending',
      tasks: tasks,
      createdAt: parseFlexibleDate(json['createdAt']),
      completedAt:
          json['completedAt'] != null ? parseFlexibleDate(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'guestName': guestName,
      'checkOutDate': checkOutDate.toIso8601String(),
      'status': status,
      'tasks': tasks.map((taskId, task) => MapEntry(taskId, task.toJson())),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}