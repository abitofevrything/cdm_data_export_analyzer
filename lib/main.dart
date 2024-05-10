import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cdm_data_export_analyzer/extract_zip.dart';
import 'package:cdm_data_export_analyzer/report/reporter.dart';
import 'package:cdm_data_export_analyzer/report/report.dart';
import 'package:cdm_data_export_analyzer/report_stats.dart';
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const DataReportApp());
}

class DataReportApp extends StatelessWidget {
  const DataReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Export Analyzer',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(outline: Colors.grey),
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
      ),
      home: const DataReportScreen(),
    );
  }
}

class DataReportScreen extends StatefulWidget {
  const DataReportScreen({super.key});

  @override
  State<DataReportScreen> createState() => _DataReportScreenState();
}

class _DataReportScreenState extends State<DataReportScreen> {
  Directory? dataDirectory;

  String? error;
  Stream<double>? extractProgress;
  Future<Report>? report;

  void _openZips() async {
    final zipFiles = await openFiles(acceptedTypeGroups: const [
      XTypeGroup(label: 'ZIP files', extensions: ['zip']),
    ]);

    if (!context.mounted) return;

    if (zipFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.transparent,
        content: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Please select at least one file'),
            ),
          ),
        ),
      ));
    } else {
      final temporaryDirectory = await getTemporaryDirectory();

      setState(() {
        var hash = Uint8List(32);
        for (final file in zipFiles) {
          final fileHash = sha256.convert(utf8.encode(file.path));
          for (int i = 0; i < fileHash.bytes.length; i++) {
            hash[i] ^= fileHash.bytes[i];
          }
        }
        final hashString =
            hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

        dataDirectory = Directory(path.join(
          temporaryDirectory.path,
          'reports',
          hashString,
        ));

        extractProgress = extractZips(
          [for (final file in zipFiles) File(file.path)],
          dataDirectory!,
        ).transform(StreamTransformer.fromBind((stream) async* {
          try {
            yield* stream;
          } on Exception catch (e) {
            setState(() {
              error = e.toString();
            });
          } finally {
            setState(() {
              extractProgress = null;
            });
          }
        }));
      });
    }
  }

  void _selectDataDirectory() async {
    final directory = await getDirectoryPath();
    if (directory == null) return;
    setState(() {
      dataDirectory = Directory(directory);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        // Intentionally reset state when report future changes, since setting
        // it to null does not cause the FutureBuilder to reset its state.
        key: ValueKey(report),
        future: report,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Google Takeout Analyzer'),
              centerTitle: true,
              leading: snapshot.hasData
                  ? BackButton(
                      onPressed: () {
                        setState(() {
                          report = null;
                        });
                      },
                    )
                  : null,
            ),
            body: snapshot.hasData
                ? ReportStats(report: snapshot.data!)
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: OutlinedButton(
                              onPressed: extractProgress == null &&
                                      (report == null || snapshot.hasError)
                                  ? _openZips
                                  : null,
                              child: const Text('Select ZIP file(s)'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: OutlinedButton(
                              onPressed: extractProgress == null &&
                                      (report == null || snapshot.hasError)
                                  ? _selectDataDirectory
                                  : null,
                              child: const Text('Select export folder'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FilledButton(
                              onPressed: dataDirectory != null &&
                                      extractProgress == null &&
                                      (report == null || snapshot.hasError)
                                  ? () {
                                      setState(() {
                                        report = Reporter(dataDirectory!)
                                            .generateReport();
                                      });
                                    }
                                  : null,
                              child: const Text('Generate report'),
                            ),
                          ),
                          const Spacer(),
                          if (error ?? snapshot.error case final error?)
                            Text(
                              style: const TextStyle(color: Colors.grey),
                              'Error: $error',
                            )
                          else if (extractProgress != null)
                            _ExtractProgress(
                              extractProgress: extractProgress,
                              dataDirectoryPath: dataDirectory!.path,
                            )
                          else if (report != null)
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Colors.grey),
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5),
                                      child: SizedBox.square(
                                        dimension: 10,
                                        child: CircularProgressIndicator(
                                          color: Colors.grey,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextSpan(text: 'Generating report...')
                                ],
                              ),
                            )
                          else if (dataDirectory case Directory(:final path))
                            Text(
                              style: const TextStyle(color: Colors.grey),
                              'Selected folder: $path',
                            ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ExtractProgress extends StatelessWidget {
  const _ExtractProgress({
    required this.extractProgress,
    required this.dataDirectoryPath,
  });

  final Stream<double>? extractProgress;
  final String dataDirectoryPath;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: extractProgress,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Error should never be shown here as the stream is un-set
          // when an error occurs.
          return const SizedBox();
        }

        final message = switch (snapshot.data) {
          final progress? =>
            'Extracting files to $dataDirectoryPath: ${(progress * 100).toStringAsFixed(2)}%...',
          _ => 'Extracting files to $dataDirectoryPath...',
        };

        return RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.grey),
            children: [
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: SizedBox.square(
                    dimension: 10,
                    child: CircularProgressIndicator(
                      color: Colors.grey,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              TextSpan(text: message)
            ],
          ),
        );
      },
    );
  }
}
