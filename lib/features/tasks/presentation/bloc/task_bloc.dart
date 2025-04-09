import 'package:flutter_bloc/flutter_bloc.dart';
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
      final tasks = await getTasksByCourseUseCase.execute(event.courseId);
      emit(TasksLoaded(tasks: tasks));
    } catch (e) {
      emit(TaskError(message: e.toString()));
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
      // Get task details
      final tasks = await getTasksByCourseUseCase.execute(event.taskId);
      if (tasks.isEmpty) {
        emit(const TaskError(message: 'Task not found'));
        return;
      }

      // Get student-specific task status
      final studentTask = await getStudentTaskUseCase.execute(
        event.taskId,
        event.studentId,
      );

      emit(StudentTaskLoaded(task: tasks.first, studentTask: studentTask));
    } catch (e) {
      emit(TaskError(message: e.toString()));
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
      await deleteTaskUseCase.execute(event.taskId);

      emit(const TaskActionSuccess(message: 'Task deleted successfully'));

      // Note: We can't reload tasks by course here because we don't have the courseId
      // The calling component should reload tasks if needed
    } catch (e) {
      emit(TaskError(message: e.toString()));
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
