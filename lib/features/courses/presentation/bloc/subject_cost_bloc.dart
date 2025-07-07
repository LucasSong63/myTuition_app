// lib/features/courses/presentation/bloc/subject_cost_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/subject_cost.dart';
import '../../domain/repositories/subject_cost_repository.dart';

part 'subject_cost_event.dart';

part 'subject_cost_state.dart';

class SubjectCostBloc extends Bloc<SubjectCostEvent, SubjectCostState> {
  final SubjectCostRepository _subjectCostRepository;

  SubjectCostBloc({required SubjectCostRepository subjectCostRepository})
      : _subjectCostRepository = subjectCostRepository,
        super(SubjectCostInitial()) {
    on<LoadAllSubjectCostsEvent>(_onLoadAllSubjectCosts);
    on<UpdateSubjectCostEvent>(_onUpdateSubjectCost);
    on<DeleteSubjectCostEvent>(_onDeleteSubjectCost);
  }

  Future<void> _onLoadAllSubjectCosts(
      LoadAllSubjectCostsEvent event, Emitter<SubjectCostState> emit) async {
    emit(SubjectCostLoading());
    try {
      final subjectCosts = await _subjectCostRepository.getAllSubjectCosts();
      emit(AllSubjectCostsLoaded(subjectCosts: subjectCosts));
    } catch (e) {
      emit(SubjectCostError(message: 'Failed to load subject costs: $e'));
    }
  }

  Future<void> _onUpdateSubjectCost(
      UpdateSubjectCostEvent event, Emitter<SubjectCostState> emit) async {
    emit(SubjectCostLoading());
    try {
      await _subjectCostRepository.updateSubjectCost(
        subjectCostId: event.subjectCostId,
        grade: event.grade,
        newCost: event.newCost,
      );

      emit(SubjectCostActionSuccess(
        message: 'Subject cost updated successfully',
      ));

      // Reload subject costs
      add(LoadAllSubjectCostsEvent());
    } catch (e) {
      emit(SubjectCostError(message: 'Failed to update subject cost: $e'));
    }
  }

  Future<void> _onDeleteSubjectCost(
      DeleteSubjectCostEvent event, Emitter<SubjectCostState> emit) async {
    emit(SubjectCostLoading());
    try {
      await _subjectCostRepository.deleteSubjectCost(
        subjectCostId: event.subjectCostId,
      );

      emit(SubjectCostActionSuccess(
        message: 'Subject cost deleted successfully',
      ));

      // Reload subject costs
      add(LoadAllSubjectCostsEvent());
    } catch (e) {
      emit(SubjectCostError(message: 'Failed to delete subject cost: $e'));
    }
  }
}
