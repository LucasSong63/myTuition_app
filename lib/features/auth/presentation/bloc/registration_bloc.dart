import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/registration_repository.dart';
import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final RegistrationRepository registrationRepository;

  RegistrationBloc({
    required this.registrationRepository,
  }) : super(RegistrationInitial()) {
    on<LoadRegistrationsEvent>(_onLoadRegistrations);
    on<LoadRegistrationDetailsEvent>(_onLoadRegistrationDetails);
    on<ApproveRegistrationEvent>(_onApproveRegistration);
    on<RejectRegistrationEvent>(_onRejectRegistration);
  }

  Future<void> _onLoadRegistrations(
      LoadRegistrationsEvent event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(RegistrationLoading());

    try {
      // Get stream of pending registrations
      await emit.forEach(
        registrationRepository.getPendingRegistrations(),
        onData: (registrations) => RegistrationsLoaded(registrations: registrations),
        onError: (error, stackTrace) => RegistrationError(message: error.toString()),
      );
    } catch (e) {
      emit(RegistrationError(message: 'Failed to load registrations: ${e.toString()}'));
    }
  }

  Future<void> _onLoadRegistrationDetails(
      LoadRegistrationDetailsEvent event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(RegistrationLoading());

    try {
      final registration = await registrationRepository.getRegistrationById(event.id);
      emit(RegistrationDetailsLoaded(registration: registration));
    } catch (e) {
      emit(RegistrationError(message: 'Failed to load registration details: ${e.toString()}'));
    }
  }

  Future<void> _onApproveRegistration(
      ApproveRegistrationEvent event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(RegistrationLoading());

    try {
      await registrationRepository.approveRegistration(event.id);
      emit(const RegistrationActionSuccess(message: 'Registration approved successfully'));
    } catch (e) {
      emit(RegistrationError(message: 'Failed to approve registration: ${e.toString()}'));
    }
  }

  Future<void> _onRejectRegistration(
      RejectRegistrationEvent event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(RegistrationLoading());

    try {
      await registrationRepository.rejectRegistration(event.id, event.reason);
      emit(const RegistrationActionSuccess(message: 'Registration rejected successfully'));
    } catch (e) {
      emit(RegistrationError(message: 'Failed to reject registration: ${e.toString()}'));
    }
  }
}