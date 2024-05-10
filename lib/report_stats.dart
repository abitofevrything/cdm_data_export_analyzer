import 'dart:math';

import 'package:cdm_data_export_analyzer/report/report.dart';
import 'package:cdm_data_export_analyzer/report_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';

extension FileFormatter on num {
  String readableFileSize() {
    if (this <= 0) return "0";
    final units = ["B", "kB", "MB", "GB", "TB"];
    int digitGroups = (log(this) / log(1000)).floor();
    return "${NumberFormat("#,##0.#").format(this / pow(1000, digitGroups))} ${units[digitGroups]}";
  }
}

class ReportStats extends StatelessWidget {
  final Report report;

  const ReportStats({required this.report, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: MediaQuery.sizeOf(context).width ~/ 180,
        children: [
          ..._buildDataCollectionStats(context, report.collectedDataSize),
          if (report.accessLogActivityReport case final report?)
            ..._buildAccessLogStats(context, report),
          if (report.androidDeviceConfigurationServiceReport case final report?)
            ..._buildAndroidDeviceConfigurationServiceStats(context, report),
          if (report.calendarReport case final report?)
            ..._buildCalendarStats(context, report),
          if (report.chromeReport case final report?)
            ..._buildChromeStats(context, report),
          if (report.classroomReport case final report?)
            ..._buildClassroomStats(context, report),
          if (report.contactsReport case final report?)
            ..._buildContactsStats(context, report),
          if (report.driveReport case final report?)
            ..._buildDriveStats(context, report),
          if (report.accountReport case final report?)
            ..._buildAccountStats(context, report),
          if (report.chatReport case final report?)
            ..._buildChatStats(context, report),
          if (report.payReport case final report?)
            ..._buildPayStats(context, report),
          if (report.photosReport case final report?)
            ..._buildPhotosStats(context, report),
          if (report.playGamesReport case final report?)
            ..._buildPlayGamesStats(context, report),
          if (report.playStoreReport case final report?)
            ..._buildPlayStoreStats(context, report),
          if (report.mailReport case final report?)
            ..._buildMailStats(context, report),
          if (report.activityReport case final report?)
            ..._buildActivityStats(context, report),
          if (report.youTubeReport case final report?)
            ..._buildYouTubeStats(context, report),
        ],
      ),
    );
  }

  List<Widget> _buildDataCollectionStats(
    BuildContext context,
    Map<String, int> collectedDataSize,
  ) =>
      [
        ScrollingReportTile(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          title: const Text('Takeout Size'),
          children: [
            ReportValue(
              title: const Text('Total'),
              value: Text(collectedDataSize.values
                  .reduce((a, b) => a + b)
                  .readableFileSize()),
            ),
            for (final MapEntry(:key, :value)
                in collectedDataSize.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
              ReportValue(
                title: Text(key),
                value: Text(value.readableFileSize()),
              ),
          ],
        ),
      ];

  List<Widget> _buildAccessLogStats(
    BuildContext context,
    AccessLogActivityReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Access Log'),
            value: Text(report.deviceCount.toString()),
            subtext: const Text('devices'),
          ),
        ),
        ReportTile(
          crossAxisCellCount: 2,
          child: ReportValue(
            title: const Text('Access Log'),
            value: Text(report.accessCount.toString()),
            subtext: Text(
              'entries from ${DateFormat.yMMMd().format(report.earliestAccess)} to ${DateFormat.yMMMd().format(report.latestAccess)}',
            ),
          ),
        ),
      ];

  List<Widget> _buildAndroidDeviceConfigurationServiceStats(
    BuildContext context,
    AndroidDeviceConfigurationServiceReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Android Configuration'),
            value: Text(report.detailedDeviceConfigurationCount.toString()),
            subtext: const Text('configured devices'),
          ),
        ),
      ];

  List<Widget> _buildCalendarStats(
    BuildContext context,
    CalendarReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Calendar'),
            value: Text(report.calendarCount.toString()),
            subtext: const Text('calendars'),
          ),
        ),
      ];

  List<Widget> _buildChromeStats(
    BuildContext context,
    ChromeReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Chrome'),
            value: Text(report.autofillCount.toString()),
            subtext: const Text('autofill entries'),
          ),
        ),
        ReportTile(
          child: ReportValue(
            title: const Text('Chrome'),
            value: Text(report.deviceCount.toString()),
            subtext: const Text('devices'),
          ),
        ),
        ReportTile(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: ReportValue(
            title: const Text('Chrome'),
            value: Text(report.historyCount.toString()),
            subtext: Column(
              children: [
                Text(
                  'history entries from ${DateFormat.yMMMd().format(report.earliestHistoryEntry)} to ${DateFormat.yMMMd().format(report.latestHistoryEntry)}',
                ),
              ],
            ),
          ),
        ),
      ];

  List<Widget> _buildClassroomStats(
    BuildContext context,
    ClassroomReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Classroom'),
            value: Text(report.classCount.toString()),
            subtext: const Text('classes'),
          ),
        ),
      ];

  List<Widget> _buildContactsStats(
    BuildContext context,
    ContactsReport report,
  ) =>
      [
        ReportTile(
          crossAxisCellCount: 3,
          child: ReportValue(
            title: const Text('Contacts'),
            value: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(report.contactsCount.toString()),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(report.emailCount.toString()),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(report.phoneNumberCount.toString()),
                  ),
                ),
              ],
            ),
            subtext: const Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text('contacts'),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('emails'),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('phone numbers'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];

  List<Widget> _buildDriveStats(
    BuildContext context,
    DriveReport report,
  ) =>
      [
        ScrollingReportTile(
          title: const Text('Drive'),
          children: [
            ReportValue(
              title: const Text('Number of files'),
              value: Text(
                report.filesByExtension.values
                    .reduce((a, b) => a + b)
                    .toString(),
              ),
              subtext: const Text('files'),
            ),
            for (final MapEntry(:key, :value)
                in report.filesByExtension.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
              ReportValue(
                title: const Text('Number of files'),
                value: Text(
                  value.toString(),
                ),
                subtext: switch (key) {
                  '' => const Text('files without extensions'),
                  'Directory' => const Text('folders'),
                  _ => Text('$key files'),
                },
              ),
          ],
        ),
        ScrollingReportTile(
          title: const Text('Drive'),
          children: [
            ReportValue(
              title: const Text('File size'),
              value: Text(
                report.sizeByExtension.values
                    .reduce((a, b) => a + b)
                    .readableFileSize(),
              ),
              subtext: const Text('all files'),
            ),
            for (final MapEntry(:key, :value)
                in report.sizeByExtension.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
              ReportValue(
                title: const Text('File size'),
                value: Text(
                  value.readableFileSize(),
                ),
                subtext: switch (key) {
                  '' => const Text('files without extensions'),
                  'Directory' => const Text('folders'),
                  _ => Text('$key files'),
                },
              ),
          ],
        ),
      ];

  List<Widget> _buildAccountStats(
    BuildContext context,
    AccountReport report,
  ) =>
      [
        ReportTile(
          crossAxisCellCount: 2,
          child: ReportValue(
            title: const Text('Account'),
            value: Text(report.accessLogCount.toString()),
            subtext: Column(
              children: [
                Text(
                  'logged accesses from ${DateFormat.yMMMd().format(report.earliestAccess)} to ${DateFormat.yMMMd().format(report.latestAccess)}',
                ),
              ],
            ),
          ),
        ),
      ];

  List<Widget> _buildChatStats(
    BuildContext context,
    ChatReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Chat'),
            value: Text(report.chatCount.toString()),
            subtext: const Text('chats'),
          ),
        ),
        ReportTile(
          child: ReportValue(
            title: const Text('Chat'),
            value: Text(report.messageCount.toString()),
            subtext: const Text('messages'),
          ),
        ),
      ];

  List<Widget> _buildPayStats(
    BuildContext context,
    PayReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Pay'),
            value: Text(report.transactionCount.toString()),
            subtext: const Text('transactions'),
          ),
        ),
      ];

  List<Widget> _buildPhotosStats(
    BuildContext context,
    PhotosReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Photos'),
            value: Text(
                report.photosCount.values.reduce((a, b) => a + b).toString()),
            subtext: const Text('photos'),
          ),
        ),
      ];

  List<Widget> _buildPlayGamesStats(
    BuildContext context,
    PlayGamesReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('Play Games'),
            value: Text(report.gamesCount.toString()),
            subtext: const Text('games'),
          ),
        ),
      ];

  List<Widget> _buildPlayStoreStats(
    BuildContext context,
    PlayStoreReport report,
  ) =>
      [
        ReportTile(
          crossAxisCellCount: 2,
          child: ReportValue(
            title: const Text('Play Games'),
            value: Text(report.installationCount.toString()),
            subtext: Text(
              'installations from ${DateFormat.yMMMd().format(report.earliestInstallation)} to ${DateFormat.yMMMd().format(report.latestInstallation)}',
            ),
          ),
        ),
      ];

  List<Widget> _buildMailStats(
    BuildContext context,
    MailReport report,
  ) =>
      [
        ReportTile(
          mainAxisCellCount: 2,
          crossAxisCellCount: 2,
          child: ReportValue(
            title: const Text('GMail'),
            value: Text(report.mailCount.toString()),
            subtext: const Text('emails'),
          ),
        ),
      ];

  List<Widget> _buildActivityStats(
    BuildContext context,
    ActivityReport report,
  ) =>
      [
        ScrollingReportTile(
          title: const Text('Activity'),
          children: [
            ReportValue(
              title: const Text('Total'),
              value: Text(
                report.details.values
                    .fold(0, (a, b) => a + b.logCount)
                    .toString(),
              ),
              subtext: const Text('logged events'),
            ),
            for (final MapEntry(:key, :value)
                in report.details.entries.toList()
                  ..sort(
                      (a, b) => b.value.logCount.compareTo(a.value.logCount)))
              ReportValue(
                title: Text(key),
                value: Text(value.logCount.toString()),
                subtext: const Text('logged events'),
              ),
          ],
        ),
      ];

  List<Widget> _buildYouTubeStats(
    BuildContext context,
    YouTubeReport report,
  ) =>
      [
        ReportTile(
          child: ReportValue(
            title: const Text('YouTube'),
            value: Text(report.commentCount.toString()),
            subtext: const Text('comments'),
          ),
        ),
        ReportTile(
          child: ReportValue(
            title: const Text('YouTube'),
            value: Text(report.liveChatMessageCount.toString()),
            subtext: const Text('live messages'),
          ),
        ),
        ReportTile(
          child: ReportValue(
            title: const Text('YouTube'),
            value: Text(report.playlistCount.toString()),
            subtext: const Text('playlists'),
          ),
        ),
        ReportTile(
          child: ReportValue(
            title: const Text('YouTube'),
            value: Text(report.subscriptionCount.toString()),
            subtext: const Text('subscriptions'),
          ),
        ),
      ];
}
