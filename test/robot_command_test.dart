import 'package:flutter_test/flutter_test.dart';
import 'package:voice_command_robot/models/robot_command.dart';

void main() {
  group('RobotCommand.match', () {
    test('maps the plain command words', () {
      expect(RobotCommand.match('forward'), RobotCommand.forward);
      expect(RobotCommand.match('backward'), RobotCommand.backward);
      expect(RobotCommand.match('left'), RobotCommand.left);
      expect(RobotCommand.match('right'), RobotCommand.right);
      expect(RobotCommand.match('stop'), RobotCommand.stop);
    });

    test('is case insensitive and tolerates surrounding words', () {
      expect(RobotCommand.match('Please Go Forward Now'), RobotCommand.forward);
      expect(RobotCommand.match('turn to the RIGHT'), RobotCommand.right);
    });

    test('stop beats any movement word in the same phrase', () {
      expect(RobotCommand.match('stop turning left'), RobotCommand.stop);
      expect(RobotCommand.match('forward stop'), RobotCommand.stop);
    });

    test('a direction beats the generic "go" keyword', () {
      expect(RobotCommand.match('go left'), RobotCommand.left);
      expect(RobotCommand.match('go back'), RobotCommand.backward);
      expect(RobotCommand.match('go'), RobotCommand.forward);
    });

    test('does not match words that merely contain a keyword', () {
      expect(RobotCommand.match('goal'), isNull);
      expect(RobotCommand.match('stopwatch'), isNull);
      expect(RobotCommand.match('hello there'), isNull);
    });

    test('every command carries the character the sketch expects', () {
      expect(RobotCommand.forward.code, '1');
      expect(RobotCommand.backward.code, '2');
      expect(RobotCommand.left.code, '3');
      expect(RobotCommand.right.code, '4');
      expect(RobotCommand.stop.code, '0');
    });
  });
}
