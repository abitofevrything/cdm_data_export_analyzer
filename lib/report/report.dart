import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';

@freezed
class Report with _$Report {
  const factory Report({
    required Map<String, int> collectedDataSize,
    required AccessLogActivityReport? accessLogActivityReport,
    required AndroidDeviceConfigurationServiceReport?
        androidDeviceConfigurationServiceReport,
    required CalendarReport? calendarReport,
    required ChromeReport? chromeReport,
    required ClassroomReport? classroomReport,
    required ContactsReport? contactsReport,
    required DriveReport? driveReport,
    required AccountReport? accountReport,
    required ChatReport? chatReport,
    required PayReport? payReport,
    required PhotosReport? photosReport,
    required PlayGamesReport? playGamesReport,
    required PlayStoreReport? playStoreReport,
    required MailReport? mailReport,
    required ActivityReport? activityReport,
    required YouTubeReport? youTubeReport,
  }) = _Report;
}

@freezed
class AccessLogActivityReport with _$AccessLogActivityReport {
  const factory AccessLogActivityReport({
    required DateTime earliestAccess,
    required DateTime latestAccess,
    required int accessCount,
    required int deviceCount,
  }) = _AccessLogActivityReport;
}

@freezed
class AndroidDeviceConfigurationServiceReport
    with _$AndroidDeviceConfigurationServiceReport {
  const factory AndroidDeviceConfigurationServiceReport({
    required int detailedDeviceConfigurationCount,
  }) = _AndroidDeviceConfigurationServiceReport;
}

@freezed
class CalendarReport with _$CalendarReport {
  const factory CalendarReport({
    required int calendarCount,
  }) = _CalendarReport;
}

@freezed
class ChromeReport with _$ChromeReport {
  const factory ChromeReport({
    required int autofillCount,
    required int deviceCount,
    required int historyCount,
    required DateTime earliestHistoryEntry,
    required DateTime latestHistoryEntry,
  }) = _ChromeReport;
}

@freezed
class ClassroomReport with _$ClassroomReport {
  const factory ClassroomReport({
    required int classCount,
  }) = _ClassroomReport;
}

@freezed
class ContactsReport with _$ContactsReport {
  const factory ContactsReport({
    required int contactsCount,
    required int emailCount,
    required int phoneNumberCount,
  }) = _ContactsReport;
}

@freezed
class DriveReport with _$DriveReport {
  const factory DriveReport({
    required Map<String, int> filesByExtension,
    required Map<String, int> sizeByExtension,
  }) = _DriveReport;
}

@freezed
class AccountReport with _$AccountReport {
  const factory AccountReport({
    required int accessLogCount,
    required DateTime earliestAccess,
    required DateTime latestAccess,
  }) = _AccountReport;
}

@freezed
class ChatReport with _$ChatReport {
  const factory ChatReport({
    required int chatCount,
    required int messageCount,
  }) = _ChatReport;
}

@freezed
class PayReport with _$PayReport {
  const factory PayReport({
    required int transactionCount,
  }) = _PayReport;
}

@freezed
class PhotosReport with _$PhotosReport {
  const factory PhotosReport({
    required Map<String, int> photosCount,
  }) = _PhotosReport;
}

@freezed
class PlayGamesReport with _$PlayGamesReport {
  const factory PlayGamesReport({
    required int gamesCount,
  }) = _PlayGamesReport;
}

@freezed
class PlayStoreReport with _$PlayStoreReport {
  const factory PlayStoreReport({
    required int installationCount,
    required DateTime earliestInstallation,
    required DateTime latestInstallation,
  }) = _PlayStoreReport;
}

@freezed
class MailReport with _$MailReport {
  const factory MailReport({
    required int mailCount,
  }) = _MailReport;
}

@freezed
class ActivityReport with _$ActivityReport {
  const factory ActivityReport({
    required Map<String, ActivityReportDetails> details,
  }) = _ActivityReport;
}

@freezed
class ActivityReportDetails with _$ActivityReportDetails {
  const factory ActivityReportDetails({
    required int logCount,
  }) = _ActivityReportDetails;
}

@freezed
class YouTubeReport with _$YouTubeReport {
  const factory YouTubeReport({
    required int commentCount,
    required int liveChatMessageCount,
    required int playlistCount,
    required int subscriptionCount,
  }) = _YouTubeReport;
}
