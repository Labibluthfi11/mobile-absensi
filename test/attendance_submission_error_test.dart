import 'package:absensi_app/services/attendance_submission_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('attendance submission policy errors', () {
    test('returns a face-specific message for errors.foto validation', () {
      const response = {
        'errors': {
          'foto': ['Wajah tidak terdeteksi'],
        },
      };

      expect(isAttendanceFacePhotoValidationError(response), isTrue);
      expect(
        attendanceSubmissionPolicyErrorMessage(422, response),
        contains('ambil ulang foto'),
      );
    });

    test('asks the user to retry when face checking is unavailable', () {
      expect(
        attendanceSubmissionPolicyErrorMessage(503, const {}),
        contains('coba lagi'),
      );
    });

    test('does not classify unrelated validation errors as face errors', () {
      const response = {
        'errors': {
          'lat': ['Lokasi tidak valid'],
        },
      };

      expect(isAttendanceFacePhotoValidationError(response), isFalse);
      expect(attendanceSubmissionPolicyErrorMessage(422, response), isNull);
    });
  });
}
