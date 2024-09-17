import 'dart:async';
import 'package:igtools/state_manager.dart';

Timer? timer; // Timer to run periodically

void startTimer() {}

Future<void> main() async {
  DateTime now = DateTime.now();
  print('starting timer: $now');
  StateManager();
  // Any additional setup code can go here.
}
