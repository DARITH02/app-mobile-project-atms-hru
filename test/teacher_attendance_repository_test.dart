import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hru_atms/features/attendance/data/teacher_attendance_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fetchAllSessions applies approved permission correction', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'plain-text-token'});

    final repository = TeacherAttendanceRepository(
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer plain-text-token');

        if (request.url.path.endsWith('/teacher/attendance/sessions')) {
          return http.Response(
            '''
            {
              "current_page": 1,
              "last_page": 1,
              "data": [
                {
                  "id": 12,
                  "subject": {"name": "Mobile App", "code": "MOB101"},
                  "class_group": {"name": "B26"},
                  "class_room": {"room_number": "A-101"},
                  "attendance_date": "2026-07-04",
                  "scheduled_start_time": "2026-07-04T08:00:00Z",
                  "scheduled_end_time": "2026-07-04T10:00:00Z",
                  "check_in_time": null,
                  "check_out_time": null,
                  "attendance_status": "scheduled"
                }
              ]
            }
            ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/teacher/attendance/corrections')) {
          return http.Response(
            '''
            {
              "current_page": 1,
              "last_page": 1,
              "data": [
                {
                  "id": 9,
                  "attendance_session_id": 12,
                  "status": "approved",
                  "requested_status": "permission"
                }
              ]
            }
            ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not found', 404);
      }),
    );

    final sessions = await repository.fetchAllSessions();

    expect(sessions.single.status, 'permission');
    expect(sessions.single.requestedStatus, 'permission');
    expect(sessions.single.correctionStatus, 'approved');
  });

  test('qrCheckIn sends token and location payload', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'plain-text-token'});

    final repository = TeacherAttendanceRepository(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/teacher/attendance/qr/check-in'));
        expect(request.headers['Authorization'], 'Bearer plain-text-token');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['token'], 'teacher-token');
        expect(body['latitude'], 11.524012);
        expect(body['longitude'], 104.876273);
        expect(body['accuracy'], 12.5);

        return http.Response(
          '''
          {
            "success": true,
            "session": {
              "id": 12,
              "subject": {"name": "Mobile App", "code": "MOB101"},
              "class_group": {"name": "B26"},
              "class_room": {"room_number": "A-101"},
              "attendance_date": "2026-07-04",
              "scheduled_start_time": "2026-07-04T08:00:00Z",
              "scheduled_end_time": "2026-07-04T10:00:00Z",
              "check_in_time": "2026-07-04T08:01:00Z",
              "check_out_time": null,
              "attendance_status": "present"
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final session = await repository.qrCheckIn(
      'teacher-token',
      latitude: 11.524012,
      longitude: 104.876273,
      accuracy: 12.5,
    );

    expect(session.id, 12);
    expect(session.status, 'present');
  });

  test('requiredCheckouts loads available checkout sessions', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'plain-text-token'});

    final repository = TeacherAttendanceRepository(
      client: MockClient((request) async {
        expect(
          request.url.path,
          endsWith('/teacher/attendance/required-checkouts'),
        );
        expect(request.headers['Authorization'], 'Bearer plain-text-token');

        return http.Response(
          '''
          {
            "sessions": [
              {
                "id": 12,
                "subject": {"name": "Mobile App", "code": "MOB101"},
                "class_group": {"name": "B26"},
                "class_room": {"room_number": "A-101"},
                "attendance_date": "2026-07-04",
                "scheduled_start_time": "2026-07-04T08:00:00Z",
                "scheduled_end_time": "2026-07-04T10:00:00Z",
                "check_in_time": "2026-07-04T08:01:00Z",
                "check_out_time": null,
                "attendance_status": "present"
              }
            ]
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final sessions = await repository.requiredCheckouts();

    expect(sessions.single.id, 12);
    expect(sessions.single.hasCheckIn, isTrue);
    expect(sessions.single.hasCheckOut, isFalse);
  });

  test('checkOut sends self checkout location payload', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'plain-text-token'});

    final repository = TeacherAttendanceRepository(
      client: MockClient((request) async {
        expect(
          request.url.path,
          endsWith('/teacher/attendance/sessions/12/check-out'),
        );
        expect(request.headers['Authorization'], 'Bearer plain-text-token');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['method'], 'self');
        expect(body['latitude'], 11.524012);
        expect(body['longitude'], 104.876273);
        expect(body['accuracy'], 12.5);

        return http.Response(
          '''
          {
            "success": true,
            "session": {
              "id": 12,
              "subject": {"name": "Mobile App", "code": "MOB101"},
              "class_group": {"name": "B26"},
              "class_room": {"room_number": "A-101"},
              "attendance_date": "2026-07-04",
              "scheduled_start_time": "2026-07-04T08:00:00Z",
              "scheduled_end_time": "2026-07-04T10:00:00Z",
              "check_in_time": "2026-07-04T08:01:00Z",
              "check_out_time": "2026-07-04T09:32:00Z",
              "attendance_status": "present"
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final session = await repository.checkOut(
      12,
      latitude: 11.524012,
      longitude: 104.876273,
      accuracy: 12.5,
    );

    expect(session.id, 12);
    expect(session.attendanceAction, 'check_out');
    expect(session.hasCheckOut, isTrue);
  });
}
