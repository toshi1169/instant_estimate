import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android release signing configuration', () {
    late String appGradle;
    late String androidGitignore;
    late String exampleProperties;

    setUpAll(() {
      appGradle = File('android/app/build.gradle.kts').readAsStringSync();
      androidGitignore = File('android/.gitignore').readAsStringSync();
      exampleProperties = File(
        'android/key.properties.example',
      ).readAsStringSync();
    });

    test('release builds never use the debug signing key', () {
      expect(
        appGradle,
        isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
      );
      expect(appGradle, contains('create("release")'));
      expect(
        appGradle,
        contains('signingConfig = signingConfigs.getByName("release")'),
      );
    });

    test('release signing requires an external key.properties file', () {
      expect(appGradle, contains('rootProject.file("key.properties")'));
      expect(appGradle, contains('isReleaseTaskRequested'));
      expect(
        appGradle,
        contains('Release signing requires android/key.properties'),
      );
      expect(appGradle, contains('Release upload keystore was not found'));
    });

    test('keystore secrets and files stay outside Git', () {
      expect(androidGitignore, contains('key.properties'));
      expect(androidGitignore, contains('**/*.keystore'));
      expect(androidGitignore, contains('**/*.jks'));
    });

    test('the committed example documents every required property', () {
      for (final property in <String>[
        'storeFile=',
        'storePassword=',
        'keyAlias=',
        'keyPassword=',
      ]) {
        expect(exampleProperties, contains(property));
      }
      expect(exampleProperties, contains('REPLACE_WITH_STORE_PASSWORD'));
      expect(exampleProperties, contains('REPLACE_WITH_KEY_PASSWORD'));
    });
  });
}
