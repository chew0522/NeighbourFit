import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId([String prefix = '']) => '$prefix${_uuid.v4()}';
