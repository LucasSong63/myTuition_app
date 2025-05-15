// lib/features/courses/presentation/bloc/subject_cost_state.dart
part of 'subject_cost_bloc.dart';

abstract class SubjectCostState extends Equatable {
  const SubjectCostState();

  @override
  List<Object?> get props => [];
}

class SubjectCostInitial extends SubjectCostState {}

class SubjectCostLoading extends SubjectCostState {}

class AllSubjectCostsLoaded extends SubjectCostState {
  final List<SubjectCost> subjectCosts;

  const AllSubjectCostsLoaded({
    required this.subjectCosts,
  });

  @override
  List<Object?> get props => [subjectCosts];
}

class SubjectCostActionSuccess extends SubjectCostState {
  final String message;

  const SubjectCostActionSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class SubjectCostError extends SubjectCostState {
  final String message;

  const SubjectCostError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
