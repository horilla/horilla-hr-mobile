/// Host normalisation, including the cleartext policy.
///
/// The policy is the part worth pinning: http:// is allowed for LAN
/// self-hosted installs, and refused for public hosts. Getting that backwards
/// either breaks a real deployment story or puts payslips on the wire in the
/// clear.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/api/host.dart';

void main() {
  group('normalisation', () {
    test('a bare hostname defaults to https', () {
      final result = normaliseHost('hr.company.com');
      expect(result.isValid, isTrue);
      expect(result.host, 'https://hr.company.com');
      expect(result.isCleartext, isFalse);
    });

    test('trailing slashes and paths are stripped to the origin', () {
      expect(
        normaliseHost('https://hr.company.com/api/v1/').host,
        'https://hr.company.com',
      );
      expect(
        normaliseHost('https://hr.company.com/').host,
        'https://hr.company.com',
      );
    });

    test('case is normalised', () {
      expect(
        normaliseHost('HTTPS://HR.Company.COM').host,
        'https://hr.company.com',
      );
    });

    test('an explicit port survives', () {
      expect(
        normaliseHost('http://192.168.1.9:8000').host,
        'http://192.168.1.9:8000',
      );
    });

    test('empty input is rejected with something actionable', () {
      final result = normaliseHost('   ');
      expect(result.isValid, isFalse);
      expect(result.error, contains('server address'));
    });

    test('a non-http scheme is rejected', () {
      expect(normaliseHost('ftp://hr.company.com').isValid, isFalse);
    });
  });

  group('cleartext policy', () {
    test('http is allowed on a private network and flagged', () {
      for (final host in [
        'http://192.168.1.9',
        'http://10.0.0.5:8000',
        'http://172.16.4.2',
        'http://localhost:8000',
        'http://hr.local',
      ]) {
        final result = normaliseHost(host);
        expect(result.isValid, isTrue, reason: '$host should be permitted');
        expect(result.isCleartext, isTrue, reason: '$host must be flagged');
      }
    });

    test('http is refused for a public host', () {
      final result = normaliseHost('http://hr.company.com');
      expect(result.isValid, isFalse);
      expect(result.error, contains('https'));
    });

    test('172.32 is public, not private — the range ends at 172.31', () {
      // Easy off-by-one in the RFC1918 middle block.
      expect(isPrivateHost('172.31.0.1'), isTrue);
      expect(isPrivateHost('172.32.0.1'), isFalse);
      expect(isPrivateHost('172.15.0.1'), isFalse);
    });

    test('a hostname that merely looks numeric is not treated as private', () {
      expect(isPrivateHost('10.0.0.5.example.com'), isFalse);
      expect(isPrivateHost('192.168.1.999'), isFalse);
    });
  });
}
