import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String uid() => _uuid.v4();

String nowIso() => DateTime.now().toIso8601String();