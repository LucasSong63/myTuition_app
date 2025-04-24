import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/student_management_repository.dart';

class StudentManagementRepositoryImpl implements StudentManagementRepository {
  final FirebaseFirestore _firestore;

  StudentManagementRepositoryImpl(this._firestore);

  @override
  Future<List<Student>> getAllStudents() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) =>
              Student.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  @override
  Future<Student> getStudentById(String studentId) async {
    try {
      // Try finding student by document ID first
      final docRef = await _firestore.collection('users').doc(studentId).get();

      if (docRef.exists) {
        return Student.fromMap(
            docRef.data() as Map<String, dynamic>, docRef.id);
      }

      // If not found by doc ID, try finding by studentId field
      final querySnapshot = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Student not found');
      }

      final doc = querySnapshot.docs.first;
      return Student.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get student: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEnrolledCourses(
      String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'subject': data['subject'] ?? '',
          'grade': data['grade'] ?? 0,
          'tutorName': data['tutorName'] ?? '',
          // Add other fields as needed
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get enrolled courses: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableCourses(
      String studentId) async {
    try {
      // Get all courses
      final allCourses = await _firestore.collection('classes').get();

      // Get enrolled courses
      final enrolledCoursesQuery = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .get();

      // Create a set of enrolled course IDs for quick lookup
      final enrolledCourseIds =
          enrolledCoursesQuery.docs.map((doc) => doc.id).toSet();

      // Filter to get only available courses
      return allCourses.docs
          .where((doc) => !enrolledCourseIds.contains(doc.id))
          .map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'subject': data['subject'] ?? '',
          'grade': data['grade'] ?? 0,
          'tutorName': data['tutorName'] ?? '',
          // Add other fields as needed
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get available courses: $e');
    }
  }

  @override
  Future<void> enrollStudentInCourse(String studentId, String courseId) async {
    try {
      // Get the class document
      final classDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!classDoc.exists) {
        throw Exception('Course not found');
      }

      // Get current list of students
      final data = classDoc.data()!;
      List<dynamic> students = data['students'] ?? [];

      // Check if student is already enrolled
      if (students.contains(studentId)) {
        return; // Already enrolled, no need to do anything
      }

      // Add student to the course
      students.add(studentId);

      // Update the document
      await _firestore.collection('classes').doc(courseId).update({
        'students': students,
      });
    } catch (e) {
      throw Exception('Failed to enroll student: $e');
    }
  }

  @override
  Future<void> removeStudentFromCourse(
      String studentId, String courseId) async {
    try {
      // Get the class document
      final classDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!classDoc.exists) {
        throw Exception('Course not found');
      }

      // Get current list of students
      final data = classDoc.data()!;
      List<dynamic> students = List<dynamic>.from(data['students'] ?? []);

      // Remove student from the course
      students.removeWhere((element) => element == studentId);

      // Update the document
      await _firestore.collection('classes').doc(courseId).update({
        'students': students,
      });
    } catch (e) {
      throw Exception('Failed to remove student from course: $e');
    }
  }

  @override
  Future<void> updateStudentProfile(String userId,
      {String? name, String? phone, int? grade, List<String>? subjects}) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (grade != null) updateData['grade'] = grade;
      if (subjects != null) updateData['subjects'] = subjects;

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update student profile: $e');
    }
  }
}
