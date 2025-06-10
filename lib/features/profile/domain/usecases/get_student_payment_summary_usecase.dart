// lib/features/profile/domain/usecases/get_student_payment_summary_usecase.dart

import '../entities/student_payment_summary.dart';
import '../repositories/profile_repository.dart';

class GetStudentPaymentSummaryUseCase {
  final ProfileRepository repository;

  GetStudentPaymentSummaryUseCase(this.repository);

  Future<StudentPaymentSummary> execute(String studentId) async {
    return await repository.getStudentPaymentSummary(studentId);
  }
}
