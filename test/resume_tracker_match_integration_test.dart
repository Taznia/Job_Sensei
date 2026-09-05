// End-to-end check for the three ported features: the Dart repositories are
// driven against a real running API and a real MongoDB.
//
//   cd ../job_sensei_backend && npm start
//   flutter test --dart-define=API_BASE_URL=http://localhost:5100 \
//     test/resume_tracker_match_integration_test.dart
//
// Without a reachable API the tests skip rather than fail, so `flutter test`
// stays green in CI and on a fresh clone.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:jobsensei_frontend/core/constants/app_constants.dart';
import 'package:jobsensei_frontend/core/network/dio_client.dart';
import 'package:jobsensei_frontend/core/storage/secure_storage.dart';
import 'package:jobsensei_frontend/features/ai/data/repositories/api_resume_match_repository.dart';
import 'package:jobsensei_frontend/features/applications/data/repositories/api_tracked_application_repository.dart';
import 'package:jobsensei_frontend/features/resumes/data/repositories/api_resume_repository.dart';
import 'package:jobsensei_frontend/shared/models/resume_models.dart';
import 'package:jobsensei_frontend/shared/models/tracked_application_models.dart';

/// In-memory stand-in for the real secure storage, which needs platform
/// channels that are not available under `flutter test`.
class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// Only ever run against a local API.
///
/// These tests register throwaway accounts. `AppConfig` falls back to the
/// deployed Vercel backend when no `API_BASE_URL` is supplied, so without this
/// guard a plain `flutter test` would create junk users in production.
bool get _isLocalApi {
  final host = Uri.tryParse(AppConstants.apiBaseUrl)?.host ?? '';
  return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
}

Future<bool> _serverIsUp() async {
  if (!_isLocalApi) return false;
  try {
    final response = await http
        .get(Uri.parse('${AppConstants.apiBaseUrl}/health'))
        .timeout(const Duration(seconds: 3));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool serverUp;
  late _MemorySecureStorage storage;
  late DioClient client;

  late ApiResumeRepository resumes;
  late ApiTrackedApplicationRepository applications;
  late ApiResumeMatchRepository matches;

  setUpAll(() async {
    // The test binding stubs every request with a 400 so tests cannot hit the
    // network by accident. This file talks to a real local server on purpose.
    HttpOverrides.global = null;

    serverUp = await _serverIsUp();
    if (!serverUp) return;

    storage = _MemorySecureStorage();
    client = DioClient(storage: storage);

    resumes = ApiResumeRepository(client: client);
    applications = ApiTrackedApplicationRepository(client: client);
    matches = ApiResumeMatchRepository(client: client);

    // Register a throwaway seeker straight against the API, then hand the token
    // to the storage the interceptor reads from.
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': 'Flutter Merge Test',
        'email': 'flutter_${DateTime.now().microsecondsSinceEpoch}@example.com',
        'password': 'secret12345',
        'role': 'seeker',
      }),
    );
    final token =
        (jsonDecode(response.body)['data'] as Map)['token'].toString();
    await storage.write(AppConstants.accessTokenKey, token);
  });

  void apiTest(String name, Future<void> Function() body) {
    test(name, () async {
      if (!serverUp) {
        markTestSkipped(
          _isLocalApi
              ? 'API not reachable at ${AppConstants.apiBaseUrl} — '
                  'start it with: cd job_sensei_backend && npm start'
              : 'Skipped: these tests only run against a local API. Pass '
                  '--dart-define=API_BASE_URL=http://localhost:5100',
        );
        return;
      }
      await body();
    });
  }

  ResumeDraft draft({String title = 'Integration Resume'}) => ResumeDraft(
        title: title,
        targetField: 'Senior Backend Engineer',
        template: 'Modern',
        fullName: 'Nazifa Rahman',
        email: 'nazifa@example.com',
        phone: '+8801700000000',
        location: 'Dhaka',
        linkedin: 'https://linkedin.com/in/nazifa',
        portfolio: 'https://nazifa.dev',
        summary: 'Backend engineer with Node and MongoDB experience.',
        skills: const ['Node.js', 'MongoDB', 'Express'],
        experience: const ['Backend Engineer at Acme — built REST APIs'],
        education: const ['BSc Computer Science, BRAC University'],
        projects: const ['Job Sensei — resume and career platform'],
        certifications: const ['AWS Certified Cloud Practitioner'],
      );

  group('resume builder', () {
    apiTest('create, read back, update and delete a resume', () async {
      final created = await resumes.createResume(draft());
      expect(created.id, isNotEmpty);
      // The builder fields are the whole point of the backend change.
      expect(created.fullName, 'Nazifa Rahman');
      expect(created.targetField, 'Senior Backend Engineer');
      expect(created.template, 'Modern');
      expect(created.projects, hasLength(1));
      expect(created.certifications, hasLength(1));

      final fetched = await resumes.getResume(created.id);
      expect(fetched.title, 'Integration Resume');
      expect(fetched.skills, ['Node.js', 'MongoDB', 'Express']);
      expect(fetched.createdAt, isA<DateTime>());

      final renamed = await resumes.updateResume(
        created.id,
        ResumeDraft.fromResume(fetched.copyWith(title: 'Renamed')),
      );
      expect(renamed.title, 'Renamed');
      expect(renamed.fullName, 'Nazifa Rahman');

      final list = await resumes.listResumes();
      expect(list.map((item) => item.id), contains(created.id));

      await resumes.deleteResume(created.id);
      final after = await resumes.listResumes();
      expect(after.map((item) => item.id), isNot(contains(created.id)));
    });

    apiTest('duplicate appends Copy to the title', () async {
      final original = await resumes.createResume(draft(title: 'Original'));
      final copy = await resumes.duplicateResume(original);

      expect(copy.title, 'Original Copy');
      expect(copy.id, isNot(original.id));
      expect(copy.skills, original.skills);

      await resumes.deleteResume(original.id);
      await resumes.deleteResume(copy.id);
    });
  });

  group('application tracker', () {
    apiTest('track an application and walk it down the pipeline', () async {
      final resume = await resumes.createResume(draft(title: 'Tracker Resume'));

      final tracked = await applications.track(
        jobTitle: 'Platform Engineer',
        companyName: 'Acme',
        resumeId: resume.id,
      );
      expect(tracked.status, AppStatus.applied);
      expect(tracked.statusHistory, hasLength(1));
      expect(tracked.resumeTitle, 'Tracker Resume');
      expect(tracked.isFromJobBoard, isFalse);

      // More than one manual application per user — this is what the partial
      // unique index on the backend makes possible.
      final second = await applications.track(
        jobTitle: 'Node Developer',
        companyName: 'Globex',
      );
      expect(second.id, isNot(tracked.id));

      final shortlisted =
          await applications.updateStatus(tracked.id, AppStatus.shortlisted);
      expect(shortlisted.status, AppStatus.shortlisted);

      final interviewDate = DateTime.now().add(const Duration(days: 3));
      final interview = await applications.updateStatus(
        tracked.id,
        AppStatus.interview,
        interviewDate: interviewDate,
      );
      expect(interview.status, AppStatus.interview);
      expect(interview.interviewDate, isNotNull);
      expect(interview.statusHistory, hasLength(3));

      final list = await applications.listApplications();
      expect(list.map((item) => item.id), containsAll([tracked.id, second.id]));

      await applications.deleteTracked(tracked.id);
      await applications.deleteTracked(second.id);
      await resumes.deleteResume(resume.id);
    });
  });

  group('ai resume match', () {
    apiTest('analyse a resume against a job description', () async {
      final resume = await resumes.createResume(draft(title: 'Match Resume'));

      final result = await matches.analyse(
        resumeId: resume.id,
        jobDescription:
            'We are hiring a Senior Backend Engineer with strong Node.js, '
            'Express and MongoDB experience. You will design REST APIs, own '
            'data modelling and mentor junior engineers.',
      );

      expect(result.id, isNotEmpty);
      expect(result.matchScore, inInclusiveRange(0, 100));
      expect(result.overallFeedback, isNotEmpty);
      expect(result.resumeTitle, 'Match Resume');

      final history = await matches.history();
      expect(history.map((item) => item.id), contains(result.id));

      final filtered = await matches.history(resumeId: resume.id);
      expect(filtered, hasLength(history.length));

      await matches.delete(result.id);
      final afterDelete = await matches.history();
      expect(afterDelete.map((item) => item.id), isNot(contains(result.id)));

      await resumes.deleteResume(resume.id);
    }, );

    apiTest('a job description that is too short is rejected', () async {
      final resume = await resumes.createResume(draft(title: 'Guard Resume'));

      await expectLater(
        matches.analyse(resumeId: resume.id, jobDescription: 'too short'),
        throwsA(isA<Exception>()),
      );

      await resumes.deleteResume(resume.id);
    });
  });
}
