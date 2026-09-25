/// The v1/v2 boundary.
///
/// This app targets Horilla v2 only. v1 mounts its API at `/api/` with an
/// auth module containing nothing but `login/` -- no refresh, so a session
/// would die after an hour with no way to renew it. Supporting it would be a
/// second app, not a shim.
///
/// What is pinned here is that each way of being incompatible produces a
/// *different* message, because the thing the admin has to do differs: migrate
/// from v1, update an old v2, or check the address.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/auth/data/auth_models.dart';

void main() {
  group('server identification', () {
    // /health/ reports `product` and `api`, never the release string: it is
    // unauthenticated, and advisories name exact patched versions, so a patch
    // level would turn a scan into a list of applicable advisories.
    test('a Horilla health response carrying the contract is accepted', () {
      final info = ServerInfo.fromJson({
        'status': 'ok',
        'product': 'horilla',
        'api': 1,
      });
      expect(info, isNotNull);
      expect(info!.apiContract, 1);
    });

    test('a newer contract is still accepted', () {
      expect(
        ServerInfo.fromJson({
          'status': 'ok',
          'product': 'horilla',
          'api': 2,
        })!.apiContract,
        2,
      );
    });

    test('a health response without the contract is not enough', () {
      // Every Horilla before the contract fields looks like this -- all of v1
      // and early v2. The caller distinguishes them with a route probe.
      expect(ServerInfo.fromJson({'status': 'ok'}), isNull);
      expect(
        ServerInfo.fromJson({'status': 'ok', 'product': 'horilla'}),
        isNull,
      );
    });

    test('a release string is not mistaken for a contract', () {
      // The field this once read. A server sending it is not newer, it is
      // something else answering on /health/.
      expect(ServerInfo.fromJson({'status': 'ok', 'version': '2.2.0'}), isNull);
    });

    test('something that is not Horilla is rejected', () {
      expect(
        ServerInfo.fromJson({'status': 'ok', 'product': 'other', 'api': 1}),
        isNull,
      );
      expect(ServerInfo.fromJson({'status': 'healthy'}), isNull);
      expect(ServerInfo.fromJson({'ok': true}), isNull);
      expect(ServerInfo.fromJson(const {}), isNull);
    });
  });

  group('mobile API presence', () {
    SignInResult parse(Map<String, dynamic> json) =>
        SignInResult.fromJson(json)!;

    Map<String, dynamic> body({
      String? refresh = 'r',
      Map<String, dynamic>? capabilities = const {
        'role': 'employee',
        'permissions': {'view_team': false},
        'features': {'leave': true},
      },
    }) => {
      'access': 'a',
      'refresh': ?refresh,
      'employee': {'id': 1, 'full_name': 'Test'},
      'capabilities': ?capabilities,
    };

    test('a v2 server with the mobile API is usable', () {
      expect(parse(body()).hasMobileApi, isTrue);
    });

    test('no refresh token means the session would die in an hour', () {
      // The exact shape an early v2 returns: login succeeds, but the app
      // could not renew the token and would sign the user out unprompted.
      expect(parse(body(refresh: null)).hasMobileApi, isFalse);
      expect(parse(body(refresh: '')).hasMobileApi, isFalse);
    });

    test('no capabilities means the navigation has nothing to read', () {
      expect(parse(body(capabilities: null)).hasMobileApi, isFalse);
    });

    test('capabilities parse into something the UI can branch on', () {
      final caps = parse(body()).capabilities;
      expect(caps.role, 'employee');
      expect(caps.isManager, isFalse);
      expect(caps.has('leave'), isTrue);
      expect(caps.can('view_team'), isFalse);
      // An unknown key must read false rather than throwing: a newer server
      // may report keys this build has never heard of.
      expect(caps.can('invented_permission'), isFalse);
      expect(caps.has('invented_feature'), isFalse);
    });
  });
}
