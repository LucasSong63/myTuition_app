// lib/features/courses/presentation/bloc/subject_cost_event.dart
part of 'subject_cost_bloc.dart';

abstract class SubjectCostEvent extends Equatable {
  const SubjectCostEvent();

  @override
  List<Object> get props => [];
}

class LoadAllSubjectCostsEvent extends SubjectCostEvent {}

class AddSubjectCostEvent extends SubjectCostEvent {
  final String subjectName;
  final double cost;

  const AddSubjectCostEvent({
    required this.subjectName,
    required this.cost,
  });

  @override
  List<Object> get props => [subjectName, cost];
}

class UpdateSubjectCostEvent extends SubjectCostEvent {
  final String subjectCostId;
  final double newCost;

  const UpdateSubjectCostEvent({
    required this.subjectCostId,
    required this.newCost,
  });

  @override
  List<Object> get props => [subjectCostId, newCost];
}

class DeleteSubjectCostEvent extends SubjectCostEvent {
  final String subjectCostId;

  const DeleteSubjectCostEvent({
    required this.subjectCostId,
  });

  @override
  List<Object> get props => [subjectCostId];
}
