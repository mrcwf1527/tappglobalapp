// lib/services/env_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static const _prodEnv = {
    'FIREBASE_API_KEY_WEB': String.fromEnvironment('FIREBASE_API_KEY_WEB'),
    'AWS_ACCESS_KEY_ID': String.fromEnvironment('AWS_ACCESS_KEY_ID'),
    'AWS_SECRET_ACCESS_KEY': String.fromEnvironment('AWS_SECRET_ACCESS_KEY'),
    'AWS_REGION': String.fromEnvironment('AWS_REGION'),
    'AWS_BUCKET': String.fromEnvironment('AWS_BUCKET'),
    'AWS_DOMAIN': String.fromEnvironment('AWS_DOMAIN'),
  };

  static String getEnvVar(String key) {
    if (_prodEnv[key]?.isNotEmpty ?? false) {
      return _prodEnv[key]!;
    }
    return dotenv.env[key] ?? '';
  }
}