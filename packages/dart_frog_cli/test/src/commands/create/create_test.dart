import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_frog_cli/src/commands/commands.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockMasonGenerator extends Mock implements MasonGenerator {}

class _MockGeneratorHooks extends Mock implements GeneratorHooks {}

class _FakeDirectoryGeneratorTarget extends Fake
    implements DirectoryGeneratorTarget {}

void main() {
  group('dart_frog create', () {
    setUpAll(() {
      registerFallbackValue(_FakeDirectoryGeneratorTarget());
    });

    late ArgResults argResults;
    late Logger logger;
    late MasonGenerator generator;
    late CreateCommand command;

    setUp(() {
      argResults = _MockArgResults();
      logger = _MockLogger();
      when(() => logger.progress(any())).thenReturn(([_]) {});
      generator = _MockMasonGenerator();
      command = CreateCommand(
        logger: logger,
        generator: (_) async => generator,
      )
        ..testArgResults = argResults
        ..testUsage = 'test usage';
    });

    test('throws UsageException when args is empty.', () async {
      when(() => argResults.rest).thenReturn([]);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when too many args provided.', () async {
      when(() => argResults.rest).thenReturn(['too', 'many', 'args']);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when project name is invalid.', () async {
      final directory = Directory.systemTemp.createTempSync();
      when(() => argResults.rest).thenReturn([directory.path]);
      when<dynamic>(
        () => argResults['project-name'],
      ).thenReturn('invalid name');
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('throws UsageException when project directory is invalid.', () async {
      final directory = Directory.systemTemp.createTempSync();
      when(() => argResults.rest).thenReturn([directory.path]);
      when<dynamic>(() => argResults['project-name']).thenReturn(null);
      expect(command.run, throwsA(isA<UsageException>()));
    });

    test('generates a project successfully.', () async {
      final generatorHooks = _MockGeneratorHooks();
      when(
        () => generatorHooks.postGen(
          vars: any(named: 'vars'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async {});
      when<dynamic>(() => argResults['project-name']).thenReturn('example');
      when(() => argResults.rest).thenReturn(['.']);
      when(
        () => generator.generate(any(), vars: any(named: 'vars')),
      ).thenAnswer((_) async => []);
      when(() => generator.hooks).thenReturn(generatorHooks);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });
  });
}
