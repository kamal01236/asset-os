@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/verification/verification_engine.dart';
import 'package:asset_os/domain/verification/verification_models.dart';

void main() {
  group('verification_engine', () {
    test('generateOfflineOtp returns 6 digits', () {
      final String otp = generateOfflineOtp();
      expect(otp.length, 6);
      expect(int.tryParse(otp), isNotNull);
      expect(int.parse(otp), inInclusiveRange(100000, 999999));
    });

    test('validatePin matches stored pin', () {
      expect(validatePin('1234', '1234'), isTrue);
      expect(validatePin('1234', '5678'), isFalse);
      expect(validatePin('1234', null), isFalse);
    });

    test('validateChecklist requires all items true', () {
      const List<String> items = <String>['a', 'b'];
      expect(
        validateChecklist(<String, bool>{'a': true, 'b': true}, items),
        isTrue,
      );
      expect(
        validateChecklist(<String, bool>{'a': true, 'b': false}, items),
        isFalse,
      );
    });

    test('buildVerificationRecord captures method and media ids', () {
      final VerificationRecord record = buildVerificationRecord(
        method: VerificationMethod.otpDisplay,
        code: '123456',
        mediaIds: <String>['MED-1'],
      );
      expect(record.method, VerificationMethod.otpDisplay);
      expect(record.code, '123456');
      expect(record.mediaIds, <String>['MED-1']);
    });
  });
}
