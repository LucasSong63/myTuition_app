import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/features/tasks/domain/entities/student_task.dart';
import 'package:mytuition/features/tasks/domain/entities/task.dart';
import '../../domain/usecases/get_tasks_by_course_usecase.dart';
import '../../domain/usecases/get_tasks_for_student_usecase.dart';
import '../../domain/usecases/get_student_task_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/mark_task_as_completed_usecase.dart';
import '../../domain/usecases/mark_task_as_incomplete_usecase.dart';
import '../../domain/usecases/add_task_remarks_usecase.dart';
import '../../domain/usecases/get_task_completion_status_usecase.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksByCourseUseCase getTasksByCourseUseCase;
  final GetTasksForStudentUseCase getTasksForStudentUseCase;
  final GetStudentTaskUseCase getStudentTaskUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final MarkTaskAsCompletedUseCase markTaskAsCompletedUseCase;
  final MarkTaskAsIncompleteUseCase markTaskAsIncompleteUseCase;
  final AddTaskRemarksUseCase addTaskRemarksUseCase;
  final GetTaskCompletionStatusUseCase getTaskCompletionStatusUseCase;

  TaskBloc({
    required this.getTasksByCourseUseCase,
    required this.getTasksForStudentUseCase,
    required this.getStudentTaskUseCase,
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.markTaskAsCompletedUseCase,
    required this.markTaskAsIncompleteUseCase,
    required this.addTaskRemarksUseCase,
    required this.getTaskCompletionStatusUseCase,
  }) : super(TaskInitial()) {
    on<LoadTasksByCourseEvent>(_onLoadTasksByCourse);
    on<LoadTasksForStudentEvent>(_onLoadTasksForStudent);
    on<LoadStudentTaskEvent>(_onLoadStudentTask);
    on<CreateTaskEvent>(_onCreateTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<MarkTaskAsCompletedEvent>(_onMarkTaskAsCompleted);
    on<MarkTaskAsIncompleteEvent>(_onMarkTaskAsIncomplete);
    on<AddTaskRemarksEvent>(_onAddTaskRemarks);
    on<LoadTaskCompletionStatusEvent>(_onLoadTaskCompletionStatus);
  }

  Future<void> _onLoadTasksByCourse(
    LoadTasksByCourseEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      // Add a small delay before loading tasks to ensure Firestore has time to process any recent changes
      await Future.delayed(const Duration(milliseconds: 300));

      final tasks = await getTasksByCourseUseCase.execute(event.courseId);
      emit(TasksLoaded(tasks: tasks));
    } catch (e) {
      emit(TaskError(message: 'Failed to load tasks: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTasksForStudent(
    LoadTasksForStudentEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final tasks = await getTasksForStudentUseCase.execute(event.studentId);
      emit(TasksLoaded(tasks: tasks));
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onLoadStudentTask(
    LoadStudentTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      // Debug logging
      print('Loading task ID: ${event.taskId}');
      print('For student ID: ${event.studentId}');

      // Step 1: Try to get the task directly from the tasks collection
      Task? foundTask;

      try {
        // Approach 1: Try to get tasks from the task's courseId
        final docSnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(event.taskId)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          foundTask = Task(
            id: docSnapshot.id,
            courseId: data['courseId'] ?? '',
            title: data['title'] ?? 'Untitled Task',
            description: data['description'] ?? '',
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
            isCompleted: data['isCompleted'] ?? false,
          );
        }
      } catch (e) {
        print('Error getting task by ID: $e');
        // Continue to fallback approach
      }

      // If direct approach failed, try to find it in course tasks
      if (foundTask == null) {
        try {
          final courseTasks =
              await getTasksByCourseUseCase.execute('bahasa-malaysia-grade1');
          // Use a manual loop to find the matching task
          for (final task in courseTasks) {
            if (task.id == event.taskId) {
              foundTask = task;
              break;
            }
          }
        } catch (e) {
          print('Error getting tasks by course: $e');
        }
      }

      // If we still couldn't find the task, emit an error
      if (foundTask == null) {
        print('Task not found: ${event.taskId}');
        emit(const TaskError(message: 'Task not found'));
        return;
      }

      // Step 2: Use the repository to get the student-specific task details
      final studentTask = await getStudentTaskUseCase.execute(
        event.taskId,
        event.studentId,
      );

      // Create placeholder if no student task exists
      final finalStudentTask = studentTask ??
          StudentTask(
            id: '${event.taskId}-${event.studentId}',
            taskId: event.taskId,
            studentId: event.studentId,
            remarks: '',
            isCompleted: false,
          );

      emit(StudentTaskLoaded(task: foundTask, studentTask: finalStudentTask));
    } catch (e) {
      print('Error loading student task: $e');
      emit(TaskError(message: 'Failed to load task details: $e'));
    }
  }

  Future<void> _onCreateTask(
    CreateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await createTaskUseCase.execute(
        event.courseId,
        event.title,
        event.description,
        event.dueDate,
      );

      emit(const TaskActionSuccess(message: 'Task created successfully'));
      add(LoadTasksByCourseEvent(courseId: event.courseId));
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await updateTaskUseCase.execute(event.task);

      emit(const TaskActionSuccess(message: 'Task updated successfully'));
      add(LoadTasksByCourseEvent(courseId: event.task.courseId));
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      // Delete the task
      await deleteTaskUseCase.execute(event.taskId);

      // Emit success state
      emit(const TaskActionSuccess(message: 'Task deleted successfully'));

      // Automatically reload the tasks after deletion
      final updatedTasks =
          await getTasksByCourseUseCase.execute(event.courseId);
      emit(TasksLoaded(tasks: updatedTasks));
    } catch (e) {
      emit(TaskError(message: 'Failed to delete task: ${e.toString()}'));
    }
  }

  Future<void> _onMarkTaskAsCompleted(
    MarkTaskAsCompletedEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await markTaskAsCompletedUseCase.execute(
        event.taskId,
        event.studentId,
        remarks: event.remarks,
      );

      emit(const TaskActionSuccess(message: 'Task marked as completed'));
      add(LoadStudentTaskEvent(
        taskId: event.taskId,
        studentId: event.studentId,
      ));
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onMarkTaskAsIncomplete(
    MarkTaskAsIncompleteEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await markTaskAsIncompleteUseCase.execute(
        event.taskId,
        event.studentId,
      );

      emit(const TaskActionSuccess(message: 'Task marked as incomplete'));
      add(LoadStudentTaskEvent(
        taskId: event.taskId,
        studentId: event.studentId,
      ));
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onAddTaskRemarks(
    AddTaskRemarksEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await addTaskRemarksUseCase.execute(
        event.taskId,
        event.studentId,
        event.remarks,
      );

      emit(const TaskActionSuccess(message: 'Remarks added successfully'));
      add(LoadStudentTaskEvent(
        taskId: event.taskId,
        studentId: event.studentId,
      ));
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onLoadTaskCompletionStatus(
    LoadTaskCompletionStatusEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final studentTasks =
          await getTaskCompletionStatusUseCase.execute(event.taskId);
      emit(TaskCompletionStatusLoaded(studentTasks: studentTasks));
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }
}
