import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hru_atms/features/auth/data/auth_repository.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('login stores root-level Laravel Sanctum token response', () async {
    SharedPreferences.setMockInitialValues({});

    final repository = AuthRepository(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/login'));

        return http.Response(
          '''
          {
            "success": true,
            "token": "plain-text-token",
            "user": {
              "id": 7,
              "name": "Teacher User",
              "email": "teacher@example.com",
              "role": "teacher",
              "profile_photo_url": null,
              "student": null,
              "teacher": {
                "id": 3,
                "teacher_code": "HRU-TCH-0001"
              }
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final session = await repository.login(
      login: 'HRU-TCH-0001',
      password: 'password',
      role: 'teacher',
    );

    expect(session.token, 'plain-text-token');
    expect(session.user.role, 'teacher');
    expect(session.user.teacherCode, 'HRU-TCH-0001');
  });

  test('student login sends email and student code without password', () async {
    SharedPreferences.setMockInitialValues({});

    final repository = AuthRepository(
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;

        expect(body['email'], 'student@example.com');
        expect(body['student_code'], 'B26-0512');
        expect(body['role'], 'student');
        expect(body.containsKey('password'), isFalse);
        expect(body.containsKey('login'), isFalse);

        return http.Response(
          '''
          {
            "success": true,
            "token": "plain-text-token",
            "user": {
              "id": 9,
              "name": "Student User",
              "email": "student@example.com",
              "role": "student",
              "profile_photo_url": null,
              "student": {
                "id": 4,
                "student_code": "B26-0512"
              },
              "teacher": null
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final session = await repository.login(
      login: 'student@example.com',
      role: 'student',
      studentCode: 'B26-0512',
    );

    expect(session.token, 'plain-text-token');
    expect(session.user.role, 'student');
    expect(session.user.studentCode, 'B26-0512');
  });

  test('logout clears saved session when remote logout fails', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'stale-token'});

    final repository = AuthRepository(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/logout'));
        throw http.ClientException('offline');
      }),
    );

    await repository.logout();

    expect(await AuthSessionStore().hasToken(), isFalse);
  });
}
