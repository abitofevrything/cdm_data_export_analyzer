import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grizzly_io/io_loader.dart';
import 'package:path/path.dart' as path;
import 'package:html/parser.dart' as html;

import 'package:cdm_data_export_analyzer/report/report.dart';

extension on Directory {
  Directory resolveDirectory(String reference) =>
      Directory.fromUri(uri.resolve(reference));
  File resolveFile(String reference) => File.fromUri(uri.resolve(reference));
}

class Reporter {
  final Directory dataDirectory;

  Reporter(Directory dataDirectory)
      : dataDirectory = dataDirectory.resolveDirectory('Takeout') {
    if (!dataDirectory.existsSync()) {
      throw ArgumentError(
          'Export folder was not a valid Google Takeout export');
    }
  }

  Future<Report> generateReport() async {
    Future<Map<String, int>> generateDataSizes() async {
      Future<int> collectSize(Directory d) async {
        final allSizes = <Future<int>>[];
        await for (final file in d.list(recursive: true, followLinks: false)) {
          allSizes.add(Future(() async {
            final stat = await file.stat();
            return stat.size;
          }));
        }
        return (await Future.wait(allSizes)).reduce((a, b) => a + b);
      }

      final serviceSizes = <Future<MapEntry<String, int>>>[];
      await for (final service in dataDirectory.list()) {
        if (service is! Directory) continue;

        serviceSizes.add(Future(() async {
          final size = await collectSize(service);
          return MapEntry(path.basename(service.path), size);
        }));
      }

      return Map.fromEntries(await Future.wait(serviceSizes));
    }

    return Report(
      collectedDataSize: await generateDataSizes(),
      accessLogActivityReport: await generateAccessLogActivityReport(),
      androidDeviceConfigurationServiceReport:
          await generateAndroidDeviceConfigurationServiceReport(),
      calendarReport: await generateCalendarReport(),
      chromeReport: await generateChromeReport(),
      classroomReport: await generateClassroomReport(),
      contactsReport: await generateContactsReport(),
      driveReport: await generateDriveReport(),
      accountReport: await generateAccountReport(),
      chatReport: await generateChatReport(),
      payReport: await generatePayReport(),
      photosReport: await generatePhotosReport(),
      playGamesReport: await generatePlayGamesReport(),
      playStoreReport: await generatePlayStoreReport(),
      mailReport: await generateMailReport(),
      activityReport: await generateActivityReport(),
      youTubeReport: await generateYouTubeReport(),
    );
  }

  Future<AccessLogActivityReport?> generateAccessLogActivityReport() async {
    final dataDirectory =
        this.dataDirectory.resolveDirectory('Access log activity');
    if (!await dataDirectory.exists()) return null;

    Future<(DateTime, DateTime, int)> generateActivities() async {
      final activitiesFile = await dataDirectory.list().firstWhere((e) =>
          e is File && path.basename(e.path).startsWith('Activities')) as File;
      final data = parseCsv(await activitiesFile.readAsString());

      DateTime? earliestAccess;
      DateTime? latestAccess;
      var accessCount = 0;

      for (final row in data.skip(1)) {
        final accessTime = DateTime.parse(row[1].replaceFirst('UTC', 'Z'));
        if (earliestAccess == null || earliestAccess.isAfter(accessTime)) {
          earliestAccess = accessTime;
        }
        if (latestAccess == null || latestAccess.isBefore(accessTime)) {
          latestAccess = accessTime;
        }
        accessCount++;
      }

      return (earliestAccess!, latestAccess!, accessCount);
    }

    Future<int> generateDevices() async {
      final devicesFile = await dataDirectory.list().firstWhere(
              (e) => e is File && path.basename(e.path).startsWith('Devices'))
          as File;
      final data = parseCsv(await devicesFile.readAsString());

      return data.length - 1;
    }

    final (earliestAccess, latestAccess, accessCount) =
        await generateActivities();
    final deviceCount = await generateDevices();

    return AccessLogActivityReport(
      earliestAccess: earliestAccess,
      latestAccess: latestAccess,
      accessCount: accessCount,
      deviceCount: deviceCount,
    );
  }

  Future<AndroidDeviceConfigurationServiceReport?>
      generateAndroidDeviceConfigurationServiceReport() async {
    final dataDirectory = this
        .dataDirectory
        .resolveDirectory('Android Device Configuration Service');
    if (!await dataDirectory.exists()) return null;

    return AndroidDeviceConfigurationServiceReport(
      detailedDeviceConfigurationCount: await dataDirectory.list().length,
    );
  }

  Future<CalendarReport?> generateCalendarReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Calendar');
    if (!await dataDirectory.exists()) return null;

    return CalendarReport(
      calendarCount: await dataDirectory.list().length,
    );
  }

  Future<ChromeReport?> generateChromeReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Chrome');
    if (!await dataDirectory.exists()) return null;

    Future<int> generateAutofill() async {
      final file = dataDirectory.resolveFile('Addresses and more.json');
      final content = json.decode(await file.readAsString());

      return (content['Autofill'] as List).length;
    }

    Future<int> generateDevices() async {
      final file = dataDirectory.resolveFile('Device Information.json');
      final content = json.decode(await file.readAsString());
      return (content['Device Info'] as List).length;
    }

    Future<(DateTime, DateTime, int)> generateHistory() async {
      final file = dataDirectory.resolveFile('History.json');
      final content = json.decode(await file.readAsString());

      DateTime? earliest;
      DateTime? latest;
      var count = 0;

      for (final entry in content['Browser History'] as List) {
        final time = DateTime.fromMicrosecondsSinceEpoch(entry['time_usec']);
        if (earliest == null || time.isBefore(earliest)) {
          earliest = time;
        }
        if (latest == null || time.isAfter(latest)) {
          latest = time;
        }
        count++;
      }

      return (earliest!, latest!, count);
    }

    final (earliestHistoryEntry, latestHistoryEntry, historyCount) =
        await generateHistory();

    return ChromeReport(
      autofillCount: await generateAutofill(),
      deviceCount: await generateDevices(),
      historyCount: historyCount,
      earliestHistoryEntry: earliestHistoryEntry,
      latestHistoryEntry: latestHistoryEntry,
    );
  }

  Future<ClassroomReport?> generateClassroomReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Classroom');
    if (!await dataDirectory.exists()) return null;

    return ClassroomReport(
      classCount: await dataDirectory.resolveDirectory('Classes').list().length,
    );
  }

  Future<ContactsReport?> generateContactsReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Contacts');
    if (!await dataDirectory.exists()) return null;

    final file = dataDirectory.resolveFile('All Contacts/All Contacts.vcf');
    final content = await file.readAsString();

    return ContactsReport(
      contactsCount: 'BEGIN:VCARD'.allMatches(content).length,
      emailCount: 'EMAIL;TYPE=INTERNET:'.allMatches(content).length,
      phoneNumberCount: 'TEL;'.allMatches(content).length,
    );
  }

  Future<DriveReport?> generateDriveReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Drive');
    if (!await dataDirectory.exists()) return null;

    final filesByExtension = <String, int>{};
    final sizeByExtension = <String, int>{};

    await for (final file
        in dataDirectory.list(recursive: true, followLinks: false)) {
      if (file is Directory) {
        filesByExtension.update(
          'Directory',
          (a) => a + 1,
          ifAbsent: () => 1,
        );
      } else if (file is Link) {
        filesByExtension.update(
          'Link',
          (a) => a + 1,
          ifAbsent: () => 1,
        );
      } else if (file is File) {
        final extension = path.extension(file.path);
        final stat = await file.stat();

        filesByExtension.update(
          extension,
          (a) => a + 1,
          ifAbsent: () => 1,
        );
        sizeByExtension.update(
          extension,
          (a) => a += stat.size,
          ifAbsent: () => stat.size,
        );
      }
    }

    return DriveReport(
      filesByExtension: filesByExtension,
      sizeByExtension: sizeByExtension,
    );
  }

  Future<AccountReport?> generateAccountReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Google Account');
    if (!await dataDirectory.exists()) return null;

    final file = await dataDirectory.list().single as File;
    final content = html.parse(await file.readAsString());

    DateTime? earliest;
    DateTime? latest;
    var count = 0;

    for (final element in content.querySelectorAll('tbody tr').skip(1)) {
      final time = DateTime.parse(element.children.first.innerHtml);
      if (earliest == null || time.isBefore(earliest)) {
        earliest = time;
      }
      if (latest == null || time.isAfter(latest)) {
        latest = time;
      }
      count++;
    }

    return AccountReport(
      accessLogCount: count,
      earliestAccess: earliest!,
      latestAccess: latest!,
    );
  }

  Future<ChatReport?> generateChatReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Google Chat');
    if (!await dataDirectory.exists()) return null;

    var chatCount = 0;
    var messageCount = 0;

    await for (final group in dataDirectory.resolveDirectory('Groups').list()) {
      if (group is! Directory) continue;

      chatCount++;

      final file = group.resolveFile('messages.json');
      final content = json.decode(await file.readAsString());

      messageCount += (content['messages'] as List).length;
    }

    return ChatReport(
      chatCount: chatCount,
      messageCount: messageCount,
    );
  }

  Future<PayReport?> generatePayReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Google Pay');
    if (!await dataDirectory.exists()) return null;

    var transactionCount = 0;

    await for (final file
        in dataDirectory.resolveDirectory('Google transactions').list()) {
      if (file is! File) continue;

      final content = parseCsv(await file.readAsString());
      transactionCount += content.length - 1;
    }

    return PayReport(transactionCount: transactionCount);
  }

  Future<PhotosReport?> generatePhotosReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Google Photos');
    if (!await dataDirectory.exists()) return null;

    final photosCount = <String, int>{};

    await for (final file
        in dataDirectory.list(recursive: true, followLinks: false)) {
      if (file is! File) continue;
      if (path.extension(file.path) != '.json') continue;

      final content = json.decode(await file.readAsString());

      if (content case {'title': String title}) {
        final imageFile = File.fromUri(file.uri.resolve(title));
        if (!await imageFile.exists()) continue;

        photosCount.update(
          path.extension(imageFile.path),
          (a) => a + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return PhotosReport(photosCount: photosCount);
  }

  Future<PlayGamesReport?> generatePlayGamesReport() async {
    final dataDirectory =
        this.dataDirectory.resolveDirectory('Google Play Games Services');
    if (!await dataDirectory.exists()) return null;

    return PlayGamesReport(
      gamesCount: await dataDirectory.resolveDirectory('Games').list().length,
    );
  }

  Future<PlayStoreReport?> generatePlayStoreReport() async {
    final dataDirectory =
        this.dataDirectory.resolveDirectory('Google Play Store');
    if (!await dataDirectory.exists()) return null;

    final file = dataDirectory.resolveFile('Installs.json');
    final content = json.decode(await file.readAsString());

    DateTime? earliest;
    DateTime? latest;
    var count = 0;

    for (final entry in content as List) {
      final time = DateTime.parse(entry['install']['firstInstallationTime']);
      if (earliest == null || time.isBefore(earliest)) {
        earliest = time;
      }
      if (latest == null || time.isAfter(latest)) {
        latest = time;
      }
      count++;
    }

    return PlayStoreReport(
      installationCount: count,
      earliestInstallation: earliest!,
      latestInstallation: latest!,
    );
  }

  Future<MailReport?> generateMailReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('Mail');
    if (!await dataDirectory.exists()) return null;

    final file = await dataDirectory
            .list()
            .firstWhere((e) => e is File && path.extension(e.path) == '.mbox')
        as File;
    final content = await file.readAsString();

    return MailReport(
      mailCount: '\nMessage-ID: '.allMatches(content).length,
    );
  }

  Future<ActivityReport?> generateActivityReport() async {
    final dataDirectory = this.dataDirectory.resolveDirectory('My Activity');
    if (!await dataDirectory.exists()) return null;

    Future<ActivityReportDetails> generateDetails(
        Directory dataDirectory) async {
      final file = dataDirectory.resolveFile('My Activity.html');
      final contents = html.parse(await file.readAsString());

      return ActivityReportDetails(
        logCount: contents.querySelectorAll('body > .mdl-grid > div').length,
      );
    }

    final details = <Future<MapEntry<String, ActivityReportDetails>>>[];
    await for (final service in dataDirectory.list()) {
      if (service is! Directory) continue;

      details.add(Future(() async {
        final details = await generateDetails(service);
        return MapEntry(path.basename(service.path), details);
      }));
    }

    return ActivityReport(
      details: Map.fromEntries(await Future.wait(details)),
    );
  }

  Future<YouTubeReport?> generateYouTubeReport() async {
    final dataDirectory =
        this.dataDirectory.resolveDirectory('YouTube and YouTube Music');
    if (!await dataDirectory.exists()) return null;

    return YouTubeReport(
      commentCount: parseCsv(
            await dataDirectory
                .resolveFile('comments/comments.csv')
                .readAsString(),
          ).length -
          1,
      liveChatMessageCount: parseCsv(
            await dataDirectory
                .resolveFile('live chats/live chats.csv')
                .readAsString(),
          ).length -
          1,
      playlistCount:
          await dataDirectory.resolveDirectory('playlists').list().length,
      subscriptionCount: parseCsv(
            await dataDirectory
                .resolveFile('subscriptions/subscriptions.csv')
                .readAsString(),
          ).length -
          1,
    );
  }
}
