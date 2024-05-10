import 'dart:async';
import 'dart:io';

import 'package:anzip/anzip.dart';
import 'package:anio/anio.dart';
import 'package:path/path.dart' as path;

Stream<double> extractZip(File zipFile, Directory output) async* {
  yield 0;
  final controller = StreamController<double>();

  await output.create(recursive: true);

  final zip = await ZipFile.open(zipFile);
  var extractedCount = 0;

  for (final header in zip.fileHeaders) {
    () async {
      try {
        if (header.isDirectory) {
          await Directory(path.join(output.path, header.fileName))
              .create(recursive: true);
        } else if (header.isSymbolicLink) {
          throw UnsupportedError('Cannot extract symbolic links');
        } else {
          final source = await zip.getEntrySource(header);
          if (source == null) return;

          final outputFile = File(path.join(output.path, header.fileName));
          await outputFile.create(recursive: true);
          final handle = await outputFile.openHandle(mode: FileMode.write);
          final sink = handle.sink();
          final bufferedSink = sink.buffered();

          while (await source.read(bufferedSink.buffer, 1024 * 1024) != 0) {
            await bufferedSink.flush();
          }

          await sink.close();
        }
      } on Exception catch (e) {
        controller.addError(e);
      } finally {
        extractedCount++;
        controller.add(extractedCount / zip.fileHeaders.length);
        if (extractedCount == zip.fileHeaders.length) {
          controller.close();
        }
      }
    }();
  }

  try {
    yield* controller.stream;
  } on Exception {
    await output.delete(recursive: true);
  }
}

Stream<double> extractZips(List<File> zipFiles, Directory output) async* {
  final controller = StreamController<double>();

  final progresses = List<double>.filled(zipFiles.length, 0);
  var extractedCount = 0;

  for (final (index, zipFile) in zipFiles.indexed) {
    extractZip(zipFile, output).listen(
      (progress) {
        progresses[index] = progress;

        controller.add(progresses.reduce((a, b) => a + b) / zipFiles.length);
      },
      onError: controller.addError,
      onDone: () {
        extractedCount++;
        if (extractedCount == zipFiles.length) {
          controller.close();
        }
      },
    );
  }

  try {
    yield* controller.stream;
  } on Exception {
    await output.delete(recursive: true);
  }
}
