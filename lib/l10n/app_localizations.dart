import 'package:flutter/material.dart';

/// Localization strings for FixFlow app
/// Supports English and Sinhala (si_LK)
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(Locale locale) {
    return AppLocalizations(locale);
  }

  bool get isEnglish => locale.languageCode == 'en';
  bool get isSinhala => locale.languageCode == 'si';

  // COMMON STRINGS
  String get appName {
    if (isSinhala) return 'FixFlow';
    return 'FixFlow';
  }

  String get companyName {
    if (isSinhala) return 'novetisPVT';
    return 'novetisPVT';
  }

  // LOGIN SCREEN

  String get loginSubtitle {
    if (isSinhala)
      return 'ප්‍රමුඛ පෙළේ කාර්මික ශිල්පීන් සහ කොන්ත්‍රාත්කරුවන්\nසමඟ ක්ෂණිකව සම්බන්ධ වන්න';
    return 'Connect with top tradespeople\nand contractors instantly';
  }

  String get signInWithGoogle {
    if (isSinhala) return 'Google සමඟ ඇතුළු වන්න';
    return 'Sign in with Google';
  }

  String get agreeToTerms {
    if (isSinhala) return 'මම FixFlow පරිශීලක ගිවිසුමට එකඟ වෙමි';
    return 'I agree to the FixFlow user agreement';
  }

  String get viewMore {
    if (isSinhala) return 'වැඩිතර බලන්න';
    return 'View more';
  }

  String get userAgreement {
    if (isSinhala) return 'FixFlow පරිශීලක ගිවිසුම';
    return 'FixFlow User Agreement';
  }

  String get agreementContent1 {
    if (isSinhala) return 'FixFlow යනු සම්බන්ධතා වේදිකාවකි';
    return 'FixFlow is a connection platform';
  }

  String get agreementDesc1 {
    if (isSinhala)
      return 'FixFlow මෙම යෙදුම සපයන්නේ සේවකයින්ට සහ කොන්ත්‍රාත්කරුවන්ට එකිනෙකා සොයා ගැනීමට සහ සම්බන්ධ වීමට උදව් කිරීම සඳහා පමණි. FixFlow ඔවුන්ගේ වැඩ ගිවිසුමේ පාර්ශවයක් නොවන අතර කිසිදු පාර්ශවයක සේවා යෝජකයෙකු, අධීක්ෂකයෙකු හෝ ඇපකරුවෙකු නොවේ.';
    return 'FixFlow only provides this app to help workers and contractors find and connect with each other. FixFlow is not a party to their work agreement and is not an employer, supervisor, or guarantor of either party.';
  }

  String get close {
    if (isSinhala) return 'වසා දමන්න';
    return 'Close';
  }

  // HOME SCREEN
  String get welcomeBack {
    if (isSinhala) return 'ආයුබෝවන් ආපසු';
    return 'Welcome back';
  }

  String get whoAreYou {
    if (isSinhala) return 'ඔබ කවුද?';
    return 'Who are you?';
  }

  String get createUserProfile {
    if (isSinhala) return 'පරිශීලක පැතිකඩ සාදන්න';
    return 'Create User Profile';
  }

  String get createUser {
    if (isSinhala) return 'පරිශීලක සාදන්න';
    return 'Create User';
  }

  String get workerProfile {
    if (isSinhala) return 'ශ්‍රමිකයා පැතිකඩ';
    return 'Worker Profile';
  }

  String get continueAsWorker {
    if (isSinhala) return 'ශ්‍රමිකයා ලෙස ඉදිරියට යන්න';
    return 'Continue as Worker';
  }

  String get contractorProfile {
    if (isSinhala) return 'කොන්ත්‍රාත්කරු පැතිකඩ';
    return 'Contractor Profile';
  }

  String get continueAsContractor {
    if (isSinhala) return 'කොන්ත්‍රාත්කරු ලෙස ඉදිරියට යන්න';
    return 'Continue as Contractor';
  }

  String get logout {
    if (isSinhala) return 'ඉවත් වන්න';
    return 'Logout';
  }

  String get continueToWorkerProfile {
    if (isSinhala) return 'ඔබගේ ශ්‍රමිකයා පැතිකඩේ ඉදිරියට යන්න';
    return 'Continue to your worker profile';
  }

  String get continueToContractorProfile {
    if (isSinhala) return 'ඔබගේ කොන්ත්‍රාත්කරු පැතිකඩේ ඉදිරියට යන්න';
    return 'Continue to your contractor profile';
  }

  String get createOneUserContinue {
    if (isSinhala)
      return 'එක පරිශීලක ශ්‍රමිකයා හෝ කොන්ත්‍රාත්කරු ලෙස සාදා ඉදිරියට යන්න';
    return 'Create one user and continue as a worker or contractor';
  }

  String get needHelpReachTeam {
    if (isSinhala)
      return 'සහයෝගය අවශ්‍ය හෝ සහකාරිත්ව විස්තර? ඔබගේ කණ්ඩායම ඇමතන්න:';
    return 'Need help or partnership details? Reach our team directly:';
  }

  String get tapToCall {
    if (isSinhala) return 'ඇමතීමට ටැප් කරන්න';
    return 'Tap to call';
  }

  String get tapToCopy {
    if (isSinhala) return 'පිටපත්ගත කිරීමට ටැප් කරන්න';
    return 'Tap to copy';
  }

  String get unableToOpenPhoneDialer {
    if (isSinhala) return 'දුරකතන කතා මාරුව විවෘත කිරීමට නොහැකි විය';
    return 'Unable to open phone dialer';
  }

  String get emailCopiedToClipboard {
    if (isSinhala) return 'ඊ-තැපැල් ලිපිනය පිටපත් කරන ලදී';
    return 'Email copied to clipboard';
  }

  // PROFILE SCREENS
  String get profile {
    if (isSinhala) return 'පැතිකඩ';
    return 'Profile';
  }

  String get editProfile {
    if (isSinhala) return 'පැතිකඩ සංස්කරණය';
    return 'Edit Profile';
  }

  String get firstName {
    if (isSinhala) return 'පළමු නම';
    return 'First Name';
  }

  String get lastName {
    if (isSinhala) return 'අවසාන නම';
    return 'Last Name';
  }

  String get email {
    if (isSinhala) return 'ඊ-තැපැල් ලිපිනය';
    return 'Email';
  }

  String get phone {
    if (isSinhala) return 'දුරකතන අංකය';
    return 'Phone Number';
  }

  String get location {
    if (isSinhala) return 'ස්ථානය';
    return 'Location';
  }

  String get save {
    if (isSinhala) return 'සුරකින්න';
    return 'Save';
  }

  String get cancel {
    if (isSinhala) return 'අවලංගු කරන්න';
    return 'Cancel';
  }

  String get update {
    if (isSinhala) return 'යාවත්කාල කරන්න';
    return 'Update';
  }

  String get delete {
    if (isSinhala) return 'මකා දමන්න';
    return 'Delete';
  }

  // JOBS
  String get jobs {
    if (isSinhala) return 'රැකියා';
    return 'Jobs';
  }

  String get newJob {
    if (isSinhala) return 'නව රැකියා';
    return 'New Job';
  }

  String get jobTitle {
    if (isSinhala) return 'රැකියා මාතෘකාව';
    return 'Job Title';
  }

  String get jobDescription {
    if (isSinhala) return 'රැකියා විස්තරය';
    return 'Job Description';
  }

  String get jobLocation {
    if (isSinhala) return 'රැකියා ස්ථානය';
    return 'Job Location';
  }

  String get jobRate {
    if (isSinhala) return 'ගාස්තුව';
    return 'Rate';
  }

  String get status {
    if (isSinhala) return 'තත්ත්වය';
    return 'Status';
  }

  String get active {
    if (isSinhala) return 'ක්‍රියාකාරී';
    return 'Active';
  }

  String get inactive {
    if (isSinhala) return 'අක්‍රියාකාරී';
    return 'Inactive';
  }

  // SETTINGS
  String get settings {
    if (isSinhala) return 'සැකසුම්';
    return 'Settings';
  }

  String get language {
    if (isSinhala) return 'භාෂාව';
    return 'Language';
  }

  String get english {
    if (isSinhala) return 'ඉංග්‍රීසි';
    return 'English';
  }

  String get sinhala {
    if (isSinhala) return 'සිංහල';
    return 'Sinhala';
  }

  // DIALOGS & MESSAGES
  String get loading {
    if (isSinhala) return 'පූරණය වෙමින් පවතී...';
    return 'Loading...';
  }

  String get error {
    if (isSinhala) return 'දෝෂය';
    return 'Error';
  }

  String get success {
    if (isSinhala) return 'සාර්ථකයි';
    return 'Success';
  }

  String get noData {
    if (isSinhala) return 'දත්ත නොමැත';
    return 'No Data';
  }

  String get confirm {
    if (isSinhala) return 'තහවුරු කරන්න';
    return 'Confirm';
  }

  String get yes {
    if (isSinhala) return 'ඔව්';
    return 'Yes';
  }

  String get no {
    if (isSinhala) return 'නැත';
    return 'No';
  }

  // MESSAGES
  String get signInFailed {
    if (isSinhala) return 'ඇතුළු වීම අසාර්ථක විය. කරුණාකර නැවතත් උත්සාහ කරන්න.';
    return 'Sign-in failed. Please try again.';
  }

  String get failedToLoadAccount {
    if (isSinhala)
      return 'ගිණුම පූරණය කිරීම අසාර්ථක විය. කරුණාකර නැවතත් උත්සාහ කරන්න.';
    return 'Failed to load account. Please try again.';
  }

  String get aboutUs {
    if (isSinhala) return 'අපි ගැන';
    return 'About Us';
  }

  String get contactSupport {
    if (isSinhala) return 'සහයෝගය සම්බන්ධ කරන්න';
    return 'Contact Support';
  }

  String get privacyPolicy {
    if (isSinhala) return 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය';
    return 'Privacy Policy';
  }

  String get termsOfService {
    if (isSinhala) return 'සේවා කොන්දේසි';
    return 'Terms of Service';
  }

  String get appVersion {
    if (isSinhala) return 'යෙදුම් සංස්කරණය';
    return 'App Version';
  }

  // WORKER PROFILE SCREEN
  String get workerAvailability {
    if (isSinhala) return 'ශ්‍රමිකයාගේ රැකියා කාලය';
    return 'Worker Availability';
  }

  String get addAvailability {
    if (isSinhala) return 'රැකියා කාලය එකතු කරන්න';
    return 'Add Availability';
  }

  String get skills {
    if (isSinhala) return 'කුසලතා';
    return 'Skills';
  }

  String get bio {
    if (isSinhala) return 'ජීව තොරතුරු';
    return 'Bio';
  }

  String get experience {
    if (isSinhala) return 'අත්දැකීම්';
    return 'Experience';
  }

  String get pendingJobs {
    if (isSinhala) return 'අපේක්ෂිත රැකියා';
    return 'Pending Jobs';
  }

  String get declineJob {
    if (isSinhala) return 'රැකියා ප්‍රතික්ෂේප කරන්න';
    return 'Decline Job';
  }

  String get rating {
    if (isSinhala) return 'ශ්‍රේණිගත කිරීම';
    return 'Rating';
  }

  String get reviews {
    if (isSinhala) return 'සමාලෝචනයන්';
    return 'Reviews';
  }

  // CONTRACTOR PROFILE SCREEN
  String get contractorAvailability {
    if (isSinhala) return 'කොන්ත්‍රාත්කරුගේ රැකියා කාලය';
    return 'Contractor Availability';
  }

  String get activeJobs {
    if (isSinhala) return 'ක්‍රියාකාරී රැකියා';
    return 'Active Jobs';
  }

  String get completedJobs {
    if (isSinhala) return 'සම්පූර්ණ කරන ලද රැකියා';
    return 'Completed Jobs';
  }

  String get processes {
    if (isSinhala) return 'ක්‍රියාවලීන්';
    return 'Processes';
  }

  String get activeProcesses {
    if (isSinhala) return 'ක්‍රියාකාරී ක්‍රියාවලීන්';
    return 'Active Processes';
  }

  String get pending {
    if (isSinhala) return 'ඉතිරි';
    return 'Pending';
  }

  String get history {
    if (isSinhala) return 'ඉතිහාසය';
    return 'History';
  }

  String get createJob {
    if (isSinhala) return 'රැකියා සාදන්න';
    return 'Create Job';
  }

  String get editJob {
    if (isSinhala) return 'රැකියා සංස්කරණය';
    return 'Edit Job';
  }

  String get hourlyRate {
    if (isSinhala) return 'පැයකට අදාළ ගාස්තුව';
    return 'Hourly Rate';
  }

  String get aboutCompany {
    if (isSinhala) return 'සමාගම ගැන';
    return 'About Company';
  }

  String get companyDetails {
    if (isSinhala) return 'සමාගමේ විස්තර';
    return 'Company Details';
  }

  // LOGIN & AGREEMENT
  String get agreeAndContinue {
    if (isSinhala) return 'එකඟ වී ඉදිරියට යන්න';
    return 'Agree and Continue';
  }

  String get mustAcceptAgreement {
    if (isSinhala) return 'ඉදිරියට යාමට පරිශීලක ගිවිසුමට එකඟ විය යුතුය';
    return 'You must agree to the user agreement to continue';
  }

  String get selectYourLanguage {
    if (isSinhala) return 'ඔබගේ භාෂාව තෝරන්න';
    return 'Select Your Language';
  }

  String get preferred {
    if (isSinhala) return 'කැමති';
    return 'Preferred';
  }

  String get contractorDashboard {
    if (isSinhala) return 'කොන්ත්‍රාත්කරු Dashboard';
    return 'Contractor Dashboard';
  }

  String get retry {
    if (isSinhala) return 'නැවත උත්සාහ කරන්න';
    return 'Retry';
  }

  String get contractorProfileNotFound {
    if (isSinhala) return 'කොන්ත්‍රාත්කරු පැතිකඩ හමු නොවිය';
    return 'Contractor profile not found';
  }

  String get goToHome {
    if (isSinhala) return 'මුල් පිටුවට යන්න';
    return 'Go to Home';
  }

  String get couldNotLoadProcesses {
    if (isSinhala) return 'ක්‍රියාවලි පූරණය කිරීමට නොහැකි විය';
    return 'Could not load processes';
  }

  String get couldNotLoadHistory {
    if (isSinhala) return 'ඉතිහාසය පූරණය කිරීමට නොහැකි විය';
    return 'Could not load history';
  }

  String get noPendingProcesses {
    if (isSinhala) return 'ඉතිරි ක්‍රියාවලි නොමැත';
    return 'No pending processes';
  }

  String get newProcessesWillAppearHere {
    if (isSinhala) return 'නව ක්‍රියාවලි මෙහි දිස්වනු ඇත';
    return 'New processes will appear here';
  }

  String get pressHistoryToLoad {
    if (isSinhala) return 'පූරණය කිරීමට ඉතිහාසය ඔබන්න';
    return 'Press History to load';
  }

  String get noCompletedProcesses {
    if (isSinhala) return 'සම්පූර්ණ ක්‍රියාවලි නොමැත';
    return 'No completed processes';
  }

  String get completedJobsWillShowHere {
    if (isSinhala) return 'සම්පූර්ණ කරන ලද රැකියා මෙහි දිස්වනු ඇත';
    return 'Completed jobs will show here';
  }

  String get manageAvailability {
    if (isSinhala) return 'රැකියා කාලය කළමනාකරණය කරන්න';
    return 'Manage Availability';
  }

  String get windowsUsed {
    if (isSinhala) return 'භාවිතා කරන ලද කවුළු';
    return 'Windows used';
  }

  String get noAvailabilitySet {
    if (isSinhala) return 'රැකියා කාල සැකසුම් නොමැත';
    return 'No availability set';
  }

  String get deleteWindow {
    if (isSinhala) return 'කවුළුව මකා දමන්න';
    return 'Delete Window';
  }

  String get addMoreAvailability {
    if (isSinhala) return 'තවත් රැකියා කාල එකතු කරන්න';
    return 'Add More Availability';
  }

  String get limitReached {
    if (isSinhala) return 'සීමාව ළඟා විය (උපරිම 3)';
    return 'Limit Reached (Max 3)';
  }

  String get confirmDeleteWindow {
    if (isSinhala)
      return 'ඔබ විසින් මෙම රැකියා කවුළුව මකා දැමීමට ඉතා විශ්වාසයි ද?';
    return 'Are you sure you want to delete this availability window?';
  }

  String get availabilityActive {
    if (isSinhala) return 'රැකියා කාලය';
    return 'Availability Active';
  }

  String get myJobs {
    if (isSinhala) return 'මගේ රැකියා';
    return 'My Jobs';
  }

  String get availabilityWindowDeleted {
    if (isSinhala) return 'රැකියා කාලය කවුළුව මකා දමන ලදී';
    return 'Availability window deleted';
  }

  String get failedToDeleteAvailability {
    if (isSinhala) return 'රැකියා කාලය මකා දැමීම අසාර්ථක විය';
    return 'Failed to delete availability';
  }

  String get accountIdMissing {
    if (isSinhala) return 'ගිණුම් අංකය අතුරුදහන්. කරුණාකර නැවත ඇතුළු වන්න.';
    return 'Account ID is missing. Please re-login.';
  }

  String get invalidJobId {
    if (isSinhala) return 'අවලංගු රැකියා අංකය.';
    return 'Invalid job ID.';
  }

  String get addAvailabilityFirst {
    if (isSinhala)
      return 'රැකියාවක් ලබා ගැනීමට මුලින්ම ඔබේ රැකියා කාලය එකතු කරන්න.';
    return 'Add your availability first to accept jobs.';
  }

  String get jobAcceptedSuccessfully {
    if (isSinhala) return 'රැකියාව සාර්ථකව පිළිගනු ලදී';
    return 'Job accepted successfully';
  }

  String get failedToAcceptJob {
    if (isSinhala) return 'රැකියාව පිළිගැනීම අසාර්ථක විය';
    return 'Failed to accept job';
  }

  String get jobRequestSent {
    if (isSinhala)
      return 'ඉල්ලීම යවන ලදී. කොන්ත්‍රාත්කරුගේ අනුමැතිය බලාපොරොත්තුවෙන්.';
    return 'Request sent. Waiting for contractor approval.';
  }

  String get approvedWorkersOnTheseJobs {
    if (isSinhala) return 'අනුමත ශ්‍රමිකයින් මෙම රැකියා කරමින් සිටී';
    return 'Approved workers are on these jobs';
  }

  String get awaitingApprovalJobs {
    if (isSinhala) return 'අනුමැතිය බලාපොරොත්තුවෙන් ඇති රැකියා';
    return 'Awaiting approval';
  }

  String get awaitingContractorApproval {
    if (isSinhala) return 'කොන්ත්‍රාත්කරුගේ අනුමැතිය බලාපොරොත්තුවෙන්';
    return 'Waiting for contractor approval';
  }

  String get worker {
    if (isSinhala) return 'ශ්‍රමිකයා';
    return 'Worker';
  }

  String get workerRequestedJob {
    if (isSinhala) return 'කම්කරුවෙකු මෙම රැකියාව ඉල්ලා ඇත';
    return 'A worker requested this job';
  }

  String get approve {
    if (isSinhala) return 'අනුමත කරන්න';
    return 'Approve';
  }

  String get reject {
    if (isSinhala) return 'ප්‍රතික්ෂේප කරන්න';
    return 'Reject';
  }

  String get jobClaimApproved {
    if (isSinhala) return 'කම්කරු අනුමත කරන ලදී';
    return 'Worker approved';
  }

  String get jobClaimRejected {
    if (isSinhala) return 'ඉල්ලීම ප්‍රතික්ෂේප කරන ලදී';
    return 'Request rejected';
  }

  String get failedToApproveJobClaim {
    if (isSinhala) return 'අනුමත කිරීම අසාර්ථක විය';
    return 'Failed to approve worker';
  }

  String get failedToRejectJobClaim {
    if (isSinhala) return 'ප්‍රතික්ෂේප කිරීම අසාර්ථක විය';
    return 'Failed to reject request';
  }

  String get rejectJobClaimTitle {
    if (isSinhala) return 'ඉල්ලීම ප්‍රතික්ෂේප කරන්නද?';
    return 'Reject request?';
  }

  String get rejectJobClaimMessage {
    if (isSinhala)
      return 'මෙම කම්කරුට නැවත මෙම රැකියාව ඉල්ලිය නොහැක. රැකියාව අනෙකුත් කම්කරුවන්ට නැවත පෙන්වනු ඇත.';
    return 'This worker will not be able to request this job again. The job will be shown to other workers.';
  }

  String lastRequestRejected(String workerName) {
    if (isSinhala)
      return '$workerName ගේ ඉල්ලීම ප්‍රතික්ෂේප කරන ලදී. රැකියාව නැවත විවෘතයි.';
    return 'Request from $workerName was rejected. Job is open again.';
  }

  String lastRequestExpired(String workerName) {
    if (isSinhala)
      return '$workerName ගේ ඉල්ලීම කල් ඉකුත් විය. රැකියාව නැවත විවෘතයි.';
    return 'Request from $workerName expired. Job is open again.';
  }

  String claimRequestedAt(String time) {
    if (isSinhala) return 'ඉල්ලූ වේලාව: $time';
    return 'Requested: $time';
  }

  String get jobStartedSuccessfully {
    if (isSinhala) return 'රැකියාව සාර්ථකව ආරම්භ කරන ලදී';
    return 'Job started successfully';
  }

  String get failedToStartJob {
    if (isSinhala) return 'රැකියාව ආරම්භ කිරීම අසාර්ථක විය';
    return 'Failed to start job';
  }

  String get jobCompletedSuccessfully {
    if (isSinhala) return 'රැකියාව සාර්ථකව සම්පූර්ණ කරන ලදී';
    return 'Job completed successfully';
  }

  String get failedToCompleteJob {
    if (isSinhala) return 'රැකියාව සම්පූර්ණ කිරීම අසාර්ථක විය';
    return 'Failed to complete job';
  }

  String get workerProfileNotFound {
    if (isSinhala) return 'සේවක පැතිකඩ හමු නොවීය';
    return 'Worker profile not found';
  }

  String get viewJobDetails {
    if (isSinhala) return 'රැකියා විස්තර බලන්න';
    return 'View job details';
  }

  String get invalidLocation {
    if (isSinhala) return 'මෙම රැකියාව අවලංගු ස්ථානය ඇත.';
    return 'This job has an invalid location.';
  }

  String get couldNotOpenMaps {
    if (isSinhala) return 'Google සිතියම් විවෘත කිරීමට නොහැක.';
    return 'Could not open Google Maps.';
  }

  String get couldNotOpenRoute {
    if (isSinhala) return 'මාර්ගය විවෘත කිරීමට නොහැක.';
    return 'Could not open the route.';
  }

  String get unavailable {
    if (isSinhala) return 'ලබාගත නොහැක';
    return 'Unavailable';
  }

  String get contractor {
    if (isSinhala) return 'කොන්ත්‍රාත්කරු';
    return 'Contractor';
  }

  String get loadingContact {
    if (isSinhala) return 'සම්බන්ධතා පූරණය වෙමින්...';
    return 'Loading contact...';
  }

  String get suggestedJobs {
    if (isSinhala) return 'යෝජිත රැකියා';
    return 'Suggested Jobs';
  }

  String get workerDashboard {
    if (isSinhala) return 'සේවක පුවරුව';
    return 'Worker Dashboard';
  }

  String get manage {
    if (isSinhala) return 'කළමනාකරණය';
    return 'Manage';
  }

  String get windowsConfigured {
    if (isSinhala) return 'කවුළු සකසා ඇත';
    return 'windows configured';
  }

  String get noSuggestedJobs {
    if (isSinhala) return 'යෝජිත රැකියා නැත';
    return 'No suggested jobs';
  }

  String get jobSuggestionsDescription {
    if (isSinhala) return 'රැකියා ඇති විට රැකියා යෝජනා මෙහි දිස්වෙනු ඇත.';
    return 'Job suggestions will appear here when available.';
  }

  String get maximumAvailabilityReached {
    if (isSinhala)
      return 'උපරිම රැකියා කවුළු 3ක් සකසා ඇත. කරුණාකර ඔබගේ රැකියා කළමනාකරණය කරන්න.';
    return 'Maximum of 3 availability windows reached. Please manage your availability.';
  }

  String get addSlotsDescription {
    if (isSinhala) return 'රැකියා සෙවීම්වල දිස්වීම සඳහා රැකියා කවුළු එක් කරන්න';
    return 'Add slots to appear in job searches';
  }

  // CREATE AVAILABILITY SCREEN

  String get availabilityRange {
    if (isSinhala) return 'රැකියා කාල පරාසය';
    return 'Availability Range';
  }

  String get startDate {
    if (isSinhala) return 'ආරම්භක දිනය';
    return 'Start Date';
  }

  String get endDate {
    if (isSinhala) return 'අවසන් දිනය';
    return 'End Date';
  }

  String get frequency {
    if (isSinhala) return 'සංඛ්‍යාතය';
    return 'Frequency';
  }

  String get daily {
    if (isSinhala) return 'දෛනික';
    return 'Daily';
  }

  String get weekly {
    if (isSinhala) return 'සතිපතා';
    return 'Weekly';
  }

  String get monthly {
    if (isSinhala) return 'මාසික';
    return 'Monthly';
  }

  String get timeWindows {
    if (isSinhala) return 'කාල කවුළු';
    return 'Time Windows';
  }

  String get addTimeWindow {
    if (isSinhala) return 'කාල කවුළුව එකතු කරන්න';
    return 'Add time window';
  }

  String get completeRequiredFields {
    if (isSinhala) return 'අවශ්‍ය ක්ෂේත්‍ර සම්පූර්ණ කරන්න';
    return 'Complete required fields';
  }

  String get pleaseSelectStartDate {
    if (isSinhala) return 'කරුණාකර ආරම්භක දිනය තෝරන්න';
    return 'Please select a start date';
  }

  String get pleaseSelectEndDate {
    if (isSinhala) return 'කරුණාකර අවසන් දිනය තෝරන්න';
    return 'Please select an end date';
  }

  String get endDateMustBeAfterStart {
    if (isSinhala) return 'අවසන් දිනය ආරම්භක දිනයට සමඟ හෝ පසුව විය යුතුය';
    return 'End date must be on or after start date';
  }

  String get pleaseSelectStartTimeForWindow {
    if (isSinhala) return 'කරුණාකර කවුළුව සඳහා ආරම්භක කාලය තෝරන්න';
    return 'Please select start time for window';
  }

  String get durationMustBeGreaterThanZero {
    if (isSinhala) return 'කවුළුව සඳහා කාලසීමා 0 ට වඩා විශාල විය යුතුය';
    return 'Duration must be greater than 0 for window';
  }

  String get startTimeTooLateForSlot {
    if (isSinhala)
      return 'කවුළුව: ආරම්භක වේලාව ඉතා ප්‍රමාද වැඩි බැවින් මධ්‍යම රාත්‍රියට පෙර සම්පූර්ණ පැයක කාල පරාසයක් ලබා ගැනීමට නොහැක';
    return 'Window: start time is too late for any full-hour slot before midnight';
  }

  String get durationCannotExceedMaxHours {
    if (isSinhala)
      return 'කවුළුව: කාලසීමා මධ්‍යරාත්‍රි දක්වා පැය ඉක්මවිය නොහැක (උපරිම 12 පැය)';
    return 'Window: duration cannot exceed hours until midnight (max 12 hours)';
  }

  String get availabilityCreatedSuccessfully {
    if (isSinhala) return 'රැකියා කාලය සාර්ථකව එකතු කරන ලදී';
    return 'Availability created successfully';
  }

  String get failedToCreateAvailability {
    if (isSinhala) return 'රැකියා කාලය එකතු කිරීම අසාර්ථක විය';
    return 'Failed to create availability';
  }

  // WORKER PROFILE SCREEN - ADDITIONAL STRINGS
  String get couldNotLoadSuggestions {
    if (isSinhala) return 'යෝජනා පූරණය කිරීමට නොහැකි විය';
    return 'Could not load suggestions';
  }

  String get couldNotLoadPendingJobs {
    if (isSinhala) return 'පෙන්වන ලද රැකියා පූරණය කිරීමට නොහැකි විය';
    return 'Could not load pending jobs';
  }

  String get noPendingJobs {
    if (isSinhala) return 'බලාපොරොත්තු රැකියා නොමැත';
    return 'No pending jobs';
  }

  String get acceptSuggestedJobDescription {
    if (isSinhala) return 'යෝජිත රැකියා පිළිගැනීමට මෙහි දිස්වනු ඇත';
    return 'Accept a suggested job to see it here.';
  }

  String get noCompletedJobs {
    if (isSinhala) return 'සම්පූර්ණ කරන ලද රැකියා නොමැත';
    return 'No completed jobs';
  }

  String get startJob {
    if (isSinhala) return 'රැකියා ආරම්භ කරන්න';
    return 'Start Job';
  }

  String get completeJob {
    if (isSinhala) return 'සම්පූර්ණ කරන්න';
    return 'Complete';
  }

  String get processDescription {
    if (isSinhala) return 'ක්‍රියාවලිය විස්තරය';
    return 'Process description';
  }

  // PROFILE PHOTO & COMMON UI STRINGS
  String get takePhoto {
    if (isSinhala) return 'ඡායාරූපයක් ගන්න';
    return 'Take photo';
  }

  String get chooseFromGallery {
    if (isSinhala) return 'ගැලරිය වෙතින් තෝරා ගන්න';
    return 'Choose from gallery';
  }

  String get profilePhotoUpdated {
    if (isSinhala) return 'පැතිකඩ ඡායාරූපය යාවත්කාලීන කරන ලදී';
    return 'Profile photo updated';
  }

  String get failedToUploadPhoto {
    if (isSinhala) return 'ඡායා උඩුගත කිරීම අසාර්ථක විය';
    return 'Failed to upload photo';
  }

  String get categoryDescription {
    if (isSinhala) return 'නිපුණතා වර්ග විස්තරය';
    return 'Category description';
  }

  String get houseRepair {
    if (isSinhala) return 'නිවාස අලුත්වැඩියාව';
    return 'House Repair';
  }

  String get gardenWorks {
    if (isSinhala) return 'උද්‍යාන කටයුතු';
    return 'Garden Works';
  }

  String get maintenance {
    if (isSinhala) return 'නඩත්තුව';
    return 'Maintenance';
  }

  // FORM VALIDATION & COMMON ERRORS
  String get noDescriptionAvailableForThisCategory {
    if (isSinhala) return 'මෙම ප්‍රවර්ගයට විස්තරණ ලබා ගත නොහැක';
    return 'No description available for this category.';
  }

  String get fullNameLabel {
    if (isSinhala) return 'සම්පූර්ණ නම *';
    return 'Full Name *';
  }

  String get pleaseEnterName {
    if (isSinhala) return 'කරුණාකර නම ඇතුළු කරන්න';
    return 'Please enter name';
  }

  String get exampleEmail {
    if (isSinhala) return 'example@gmail.com';
    return 'example@gmail.com';
  }

  String get pleaseEnterEmail {
    if (isSinhala) return 'කරුණාකර ඊ-තැපෑල ඇතුළු කරන්න';
    return 'Please enter email';
  }

  String get pleaseEnterValidEmail {
    if (isSinhala) return 'කරුණාකර වලංගු ඊ-තැපෑල ඇතුළු කරන්න';
    return 'Please enter a valid email';
  }

  String get examplePhone {
    if (isSinhala) return '07xxxxxxxx';
    return '07xxxxxxxx';
  }

  String get pleaseEnterPhoneNumber {
    if (isSinhala) return 'කරුණාකර දුරකතන අංකය ඇතුළු කරන්න';
    return 'Please enter phone number';
  }

  String get enterValidPhoneNumber {
    if (isSinhala) return '07xxxxxxxx ඉ.ග. වලංගු ඉලක්කම් 10ක් ඇතුළු කරන්න';
    return 'Enter a valid 10 digit number e.g. 07xxxxxxxx';
  }

  String get skillsAndExpertise {
    if (isSinhala) return 'කුසලතා සහ විශේෂඥ දැනුම *';
    return 'Skills & Expertise *';
  }

  String get selectAtLeastOneSkill {
    if (isSinhala) return 'කරුණාකර අවම වශයෙන් එක් කුසලතාවක්ම තෝරා ගන්න';
    return 'Please select at least one skill.';
  }

  String get selectCategoryTypeAboveToSeeSubcategories {
    if (isSinhala) return 'උප-ප්‍රවර්ග බැලීමට ඉහළින් ප්‍රවර්ග වර්ගයක් තෝරන්න.';
    return 'Select a category type above to see subcategories.';
  }

  String get selectedSkills {
    if (isSinhala) return 'තෝරාගත් කුසලතා';
    return 'Selected Skills';
  }

  String get updateProfilePhoto {
    if (isSinhala) return 'පැතිකඩ ඡායාරූපය යාවත්කාලීන කරන්න';
    return 'Update Profile Photo';
  }

  String get doYouWantToUpdateYourProfilePhoto {
    if (isSinhala) return 'ඔබගේ පැතිකඩ ඡායාරූපය යාවත්කාලීන කිරීමට අවශ්‍යද?';
    return 'Do you want to update your profile photo?';
  }

  String get profileUpdated {
    if (isSinhala) return 'පැතිකඩ යාවත්කාලීන කරන ලදී';
    return 'Profile updated';
  }

  String get subcategoriesLabel {
    if (isSinhala) return 'උප-ප්‍රවර්ග';
    return 'Subcategories';
  }

  String get userDetailsLabel {
    if (isSinhala) return 'පරිශීලක විස්තර';
    return 'User Details';
  }

  String get addEmailAddress {
    if (isSinhala) return 'ඊ-තැපෑල් ලිපිනය එක් කරන්න';
    return 'Add email address';
  }

  // CreateProcessDialog strings
  String get hintJobTitle {
    if (isSinhala) return 'කෙටි රැකියා මාතෘකාවක් ඇතුළු කරන්න';
    return 'Enter a short job title';
  }

  String get pleaseEnterJobTitle {
    if (isSinhala) return 'කරුණාකර රැකියා මාතෘකාවක් ඇතුළු කරන්න';
    return 'Please enter a job title';
  }

  String get hintProcessDescription {
    if (isSinhala) return 'සමස්ත සේවාව හෝ ක්‍රියාවලිය විස්තර කරන්න';
    return 'Describe the overall service or process';
  }

  String get pleaseEnterProcessDescription {
    if (isSinhala) return 'කරුණාකර ක්‍රියාවලි විස්තරය ඇතුළු කරන්න';
    return 'Please enter process description';
  }

  String get startTime {
    if (isSinhala) return 'ආරම්භ වේලාව';
    return 'Start Time';
  }

  String get hintStartTime {
    if (isSinhala) return 'දින දර්ශකයෙන් දිනය සහ වේලාව තෝරන්න';
    return 'Pick date and time from calendar';
  }

  String get pleaseEnterStartTime {
    if (isSinhala) return 'කරුණාකර ආරම්භ වේලාව ඇතුළු කරන්න';
    return 'Please enter start time';
  }

  String get formatYYYYMMDDHHMM {
    if (isSinhala) return 'ස්වරූපය භාවිතා කරන්න: YYYY-MM-DDTHH:MM';
    return 'Use format: YYYY-MM-DDTHH:MM';
  }

  String get invalidStartDateTime {
    if (isSinhala) return 'වලංගු නොවන ආරම්භ දිනය/වේලාව';
    return 'Invalid start date/time';
  }

  String get startTooLateNotEnoughHours {
    if (isSinhala)
      return 'ආරම්භය ප්‍රමාද වැඩියි: මධ්‍යරාත්‍රියට පෙර සම්පූර්ණ පැයක් ඉතිරි නැත';
    return 'Start is too late: no full hour remains before midnight';
  }

  String get durationHours {
    if (isSinhala) return 'කාලසීමාව (පැය)';
    return 'Duration (hours)';
  }

  String get hintPickStartDateFirst {
    if (isSinhala) return 'මුලින්ම ආරම්භ දිනය සහ වේලාව තෝරන්න';
    return 'Pick start date & time first';
  }

  String get durationHoursLongLabel {
    if (isSinhala) return 'කාලසීමාව (පැය, මධ්‍යරාත්‍රිය දක්වා, උපරිම 12)';
    return 'Duration (hours, until midnight, max 12)';
  }

  String get notEnoughTimeBeforeMidnight {
    if (isSinhala)
      return 'මෙම ආරම්භ වේලාවට මධ්‍යරාත්‍රියට පෙර ප්‍රමාණවත් කාලයක් නැත. කලින් ආරම්භයක් තෝරන්න.';
    return 'Not enough time before midnight for this start time. Pick an earlier start.';
  }

  String chooseDurationFromTo(int maxHours) {
    if (isSinhala) return 'පැය 1 සිට $maxHours දක්වා කාලසීමාවක් තෝරන්න';
    return 'Choose a duration from 1 to $maxHours hour(s)';
  }

  String get jobPhotosOptional {
    if (isSinhala) return 'රැකියා ඡායාරූප (විකල්ප)';
    return 'Job photos (optional)';
  }

  String hintUploadPhotos(int max) {
    if (isSinhala) {
      return 'උපරිම පින්තූර $maxක්, කුඩා ඉල්ලීම් සඳහා JPEG ලෙස සම්පීඩනය කෙරේ.';
    }
    return 'Up to $max images, compressed as JPEG for smaller requests.';
  }

  String canAttachAtMostPhotos(int max) {
    if (isSinhala) return 'ඔබට උපරිම ඡායාරූප $maxක් පමණක් ඇමිණිය හැක.';
    return 'You can attach at most $max photos.';
  }

  String couldNotAddPhoto(String error) {
    if (isSinhala) return 'ඡායාරූපය එක් කිරීමට නොහැකි විය: $error';
    return 'Could not add photo: $error';
  }

  String get tapToPickLocation {
    if (isSinhala) return 'ස්ථානය තෝරා ගැනීමට ස්පර්ශ කරන්න';
    return 'Tap to pick location';
  }

  String get selectedCategory {
    if (isSinhala) return 'තෝරාගත් කාණ්ඩය';
    return 'Selected Category';
  }

  String get noCategorySelectedYet {
    if (isSinhala) return 'තවමත් කාණ්ඩයක් තෝරා නැත.';
    return 'No category selected yet.';
  }

  String get amount {
    if (isSinhala) return 'මුදල';
    return 'Amount';
  }

  String get pleaseEnterAmount {
    if (isSinhala) return 'කරුණාකර මුදල ඇතුළු කරන්න';
    return 'Please enter amount';
  }

  String get enterValidAmount {
    if (isSinhala) return 'වලංගු මුදලක් ඇතුළු කරන්න';
    return 'Enter a valid amount';
  }

  // ContractorInfoScreen strings
  String get personalInformation {
    if (isSinhala) return 'පෞද්ගලික තොරතුරු';
    return 'Personal Information';
  }

  String get businessName {
    if (isSinhala) return 'ව්‍යාපාර නම';
    return 'Business Name';
  }

  String get hintEnterContractorName {
    if (isSinhala) return 'කොන්ත්‍රාත්කරුගේ නම ඇතුළු කරන්න';
    return 'Enter contractor name';
  }

  String get contractorInformation {
    if (isSinhala) return 'කොන්ත්‍රාත්කරු තොරතුරු';
    return 'Contractor Information';
  }

  String get wallets {
    if (isSinhala) return 'පසුම්බි';
    return 'Wallets';
  }

  String get yourAccountWalletBalances {
    if (isSinhala) return 'ඔබගේ ගිණුමේ පසුම්බි ශේෂ';
    return 'Your account wallet balances';
  }

  String get noWalletsFound {
    if (isSinhala) return 'පසුම්බි හමු නොවීය';
    return 'No wallets found';
  }

  // SCREENS - ADDITIONAL STRINGS
  String get ok {
    if (isSinhala) return 'හරි';
    return 'OK';
  }

  String get back {
    if (isSinhala) return 'ආපසු';
    return 'Back';
  }

  String get done {
    if (isSinhala) return 'නිමයි';
    return 'Done';
  }

  String get hide {
    if (isSinhala) return 'සඟවන්න';
    return 'Hide';
  }

  String get name {
    if (isSinhala) return 'නම';
    return 'Name';
  }

  String get photo {
    if (isSinhala) return 'ඡායාරූපය';
    return 'Photo';
  }

  String get total {
    if (isSinhala) return 'මුළු';
    return 'total';
  }

  String get balance {
    if (isSinhala) return 'ශේෂය';
    return 'balance';
  }

  String get completed {
    if (isSinhala) return 'සම්පූර්ණයි';
    return 'Completed';
  }

  String get accept {
    if (isSinhala) return 'පිළිගන්න';
    return 'Accept';
  }

  String get start {
    if (isSinhala) return 'ආරම්භය';
    return 'Start';
  }

  String get duration {
    if (isSinhala) return 'කාලසීමාව';
    return 'Duration';
  }

  String get payment {
    if (isSinhala) return 'ගෙවීම';
    return 'Payment';
  }

  String get window {
    if (isSinhala) return 'කවුළුව';
    return 'Window';
  }

  String get availability {
    if (isSinhala) return 'රැකියා කාලය';
    return 'Availability';
  }

  String get homeTagline {
    if (isSinhala) return 'සේවක සහ කොන්ත්‍රාත්කරු කළමනාකරු';
    return 'Worker & Contractor Manager';
  }

  String get couldNotSaveAgreement {
    if (isSinhala) return 'ඔබගේ ගිවිසුම් තහවුරු කිරීම නොහැකි විය.';
    return 'Could not save your agreement confirmation.';
  }

  String get signInError {
    if (isSinhala) return 'ඇතුළු වීමේ දෝෂය';
    return 'Sign-in error';
  }

  String get agreementContent2 {
    if (isSinhala) return 'FixFlow සම්බන්ධතා යෙදුම තුළම තබා ගන්න';
    return 'Keep FixFlow connections in the app';
  }

  String get agreementDesc2 {
    if (isSinhala)
      return 'FixFlow සම්බන්ධතාවයකින් ඇති වන හැඳින්වීම්, රැකියා ඉල්ලීම්, පිරිනැමීම්, පිළිගැනීම්, එකඟ වූ කොන්දේසි සහ වෙනස්කම් මෙම යෙදුම තුළ සිදු කළ යුතුය හෝ වාර්තා කළ යුතුය. අවශ්‍ය අවස්ථාවලදී හදිසි සේවා හෝ වෙනත් අවශ්‍ය මාර්ග භාවිතා කරන්න.';
    return 'Introductions, job requests, offers, acceptances, agreed terms, and changes arising from a FixFlow connection must be made or recorded in this app. Use emergency services or other necessary channels when a situation requires it.';
  }

  String get agreementContent3 {
    if (isSinhala) return 'වැඩබිමේදී කොන්ත්‍රාත්කරුගේ වගකීම';
    return 'Contractor responsibility at the worksite';
  }

  String get agreementDesc3 {
    if (isSinhala)
      return 'සේවකයෙකු කොන්ත්‍රාත්කරුගේ වැඩබිමට පැමිණි විට හෝ කොන්ත්‍රාත්කරු වෙනුවෙන් වැඩ ආරම්භ කළ විට, මුලින්ම සිදුවන දෙයින් පසු, සේවකයා සහ වැඩය සඳහා කොන්ත්‍රාත්කරු වගකිව යුතුය. මෙයට අධීක්ෂණය, උපදෙස්, වැඩබිම් ආරක්ෂාව, ප්‍රවේශය, මෙවලම් සහ උපකරණ, එකඟ වූ ගෙවීම, සහ නීතියෙන් අවශ්‍ය ප්‍රමාණයට අදාළ නීති, රක්ෂණ සහ බලපත්‍රවලට අනුකූල වීම ඇතුළත් වේ.';
    return 'When a worker arrives at the contractor’s worksite or starts work for the contractor, whichever happens first, the contractor is responsible for the worker and the work. This includes supervision, instructions, workplace safety, access, tools and equipment, agreed payment, and compliance with applicable laws, insurance, and permits, to the extent required by law.';
  }

  String get agreementContent4 {
    if (isSinhala) return 'සේවක සහ කොන්ත්‍රාත්කරු බැඳීම්';
    return 'Worker and contractor obligations';
  }

  String get agreementDesc4 {
    if (isSinhala)
      return 'සේවකයින් සහ කොන්ත්‍රාත්කරුවන් නිවැරදි තොරතුරු ලබා දිය යුතු අතර, වැඩ ආරම්භ කිරීමට පෙර වැඩ පරාසය, කාලසටහන, ගාස්තුව සහ ගෙවීම් කොන්දේසි පිළිබඳව සෘජුවම එකඟ විය යුතුය, නීත්‍යනුකූලව සහ ගෞරවයෙන් ක්‍රියා කළ යුතු අතර, ආරක්ෂක ගැටලු වහාම මතු කළ යුතුය. සෑම පාර්ශවයක්ම තම පොරොන්දු සහ හැසිරීම සඳහා වගකිව යුතුය.';
    return 'Workers and contractors must provide accurate information, agree directly on the scope, schedule, rate, and payment terms before work begins, act lawfully and respectfully, and raise safety concerns promptly. Each party is responsible for its own promises and conduct.';
  }

  String get agreementContent5 {
    if (isSinhala) return 'FixFlow විසින් සහතිකයක් හෝ අධීක්ෂණයක් නොමැත';
    return 'No guarantee or supervision by FixFlow';
  }

  String get agreementDesc5 {
    if (isSinhala)
      return 'යෙදුමේ පැහැදිලිව වෙනත් ආකාරයකින් සඳහන් නොකරන්නේ නම්, FixFlow පරිශීලකයෙකුගේ අනන්‍යතාවය, සුදුසුකම්, ලබා ගැනීමේ හැකියාව, වැඩේ ගුණාත්මකභාවය, ගෙවීම හෝ රැකියාවක ප්‍රතිඵලය සහතික නොකරන අතර වැඩ පරීක්ෂා කිරීම හෝ අධීක්ෂණය නොකරයි. සේවකයින් සහ කොන්ත්‍රාත්කරුවන් එකිනෙකා තක්සේරු කර වැඩ සම්බන්ධ ගැටලු සෘජුවම විසඳා ගත යුතුය.';
    return 'Unless the app expressly says otherwise, FixFlow does not guarantee a user’s identity, qualifications, availability, work quality, payment, or the outcome of a job, and does not inspect or supervise work. Workers and contractors must assess each other and resolve work-related issues directly.';
  }

  String get agreementContent6 {
    if (isSinhala) return 'ආරක්ෂාව සහ ආරවුල්';
    return 'Safety and disputes';
  }

  String get agreementDesc6 {
    if (isSinhala)
      return 'කොන්ත්‍රාත්කරුවන් ආරක්ෂිත වැඩ පරිසරයක් සැපයිය යුතු අතර සේවකයෙකු අවදානමට ලක්විය හැකි නම් සුදුසු ක්‍රියාමාර්ග ගත යුතුය. සේවකයින් අනාරක්ෂිත වැඩ නවතා සුදුසු සහාය ලබා ගත යුතුය. ඔවුන් අතර ආරවුල් විසඳීම සේවකයා සහ කොන්ත්‍රාත්කරුගේ වගකීම වේ; අදාළ නීතියෙන් වෙනත් ආකාරයකින් සඳහන් කර ඇති අවස්ථා හැර, ඔවුන්ගේ වැඩ සම්බන්ධතාවය සඳහා FixFlow වගකිව යුතු නොවේ.';
    return 'Contractors must provide a safe work environment and take appropriate action if a worker may be at risk. Workers should stop unsafe work and seek appropriate help. The worker and contractor are responsible for resolving disputes between them; FixFlow is not responsible for their work relationship except where applicable law says otherwise.';
  }

  String get addProfilePhoto {
    if (isSinhala) return 'පැතිකඩ ඡායාරූපය එක් කරන්න';
    return 'Add Profile Photo';
  }

  String get profileReadyAddPhoto {
    if (isSinhala)
      return 'ඔබගේ පැතිකඩ සූදානම්. දැන් ඡායාරූපයක් එක් කරන්න, නැතහොත් මෙම පියවර මඟහැර මුල් පිටුවට යන්න.';
    return 'Your profile is ready. Add a photo now or skip this step and continue to the home page.';
  }

  String get chooseProfilePhoto {
    if (isSinhala) return 'පැතිකඩ ඡායාරූපය තෝරන්න';
    return 'Choose profile photo';
  }

  String get skipForNow {
    if (isSinhala) return 'දැනට මඟහරින්න';
    return 'Skip for now';
  }

  String get pickLocation {
    if (isSinhala) return 'ස්ථානය තෝරන්න';
    return 'Pick Location';
  }

  String get searchLocation {
    if (isSinhala) return 'ස්ථානය සොයන්න...';
    return 'Search location...';
  }

  String get enterPhoneNumber {
    if (isSinhala) return 'දුරකතන අංකය ඇතුළු කරන්න';
    return 'Enter phone number';
  }

  String get processCreatedSuccessfully {
    if (isSinhala) return 'ක්‍රියාවලිය සාර්ථකව සාදන ලදී';
    return 'Process created successfully';
  }

  String get processDeletedSuccessfully {
    if (isSinhala) return 'ක්‍රියාවලිය සාර්ථකව මකා දමන ලදී';
    return 'Process deleted successfully';
  }

  String get failedToDeleteProcess {
    if (isSinhala) return 'ක්‍රියාවලිය මකා දැමීම අසාර්ථක විය';
    return 'Failed to delete process';
  }

  String get deleteJob {
    if (isSinhala) return 'රැකියාව මකා දමන්න';
    return 'Delete Job';
  }

  String get thisJob {
    if (isSinhala) return 'මෙම රැකියාව';
    return 'this job';
  }

  String get unnamedProcess {
    if (isSinhala) return 'නම් නොකළ ක්‍රියාවලිය';
    return 'Unnamed Process';
  }

  String get assignedWorker {
    if (isSinhala) return 'පවරන ලද සේවකයා';
    return 'Assigned worker';
  }

  String get tapToViewWorkerDetails {
    if (isSinhala) return 'සේවක විස්තර බැලීමට ටැප් කරන්න';
    return 'Tap to view worker details';
  }

  String get jobDetails {
    if (isSinhala) return 'රැකියා විස්තර';
    return 'Job Details';
  }

  String get paymentDetails {
    if (isSinhala) return 'ගෙවීම් විස්තර';
    return 'Payment Details';
  }

  String get pleaseSelectOneCategory {
    if (isSinhala) return 'කරුණාකර එක් නිපුණතා ප්‍රවර්ගයක් තෝරන්න';
    return 'Please select one category';
  }

  String get pleaseSelectWallet {
    if (isSinhala) return 'කරුණාකර පසුම්බියක් තෝරන්න';
    return 'Please select a wallet';
  }

  String get noCategoriesAvailable {
    if (isSinhala) return 'නිපුණතා ප්‍රවර්ග ලබා ගත නොහැක';
    return 'No categories available';
  }

  String get availabilityIdMissing {
    if (isSinhala)
      return 'රැකියා කාල අංකය අතුරුදහන්. කරුණාකර නැවුම් කර නැවත උත්සාහ කරන්න.';
    return 'Availability ID is missing. Please refresh and try again.';
  }

  String get mapLegendWorkerJob {
    if (isSinhala) return 'කොළ: ඔබගේ ස්ථානය • රතු: රැකියා ස්ථානය';
    return 'Green: your location • Red: job site';
  }

  String get openRoute {
    if (isSinhala) return 'මාර්ගය විවෘත කරන්න';
    return 'Open Route';
  }

  String get locationInfo {
    if (isSinhala) return 'ස්ථාන තොරතුරු';
    return 'Location Info';
  }

  String get jobLocationDetails {
    if (isSinhala) return 'රැකියා ස්ථාන විස්තර';
    return 'Job Location Details';
  }

  String get addressLabel {
    if (isSinhala) return 'ලිපිනය';
    return 'ADDRESS';
  }

  String get addressUnavailable {
    if (isSinhala) return 'ලිපිනය ලබාගත නොහැක';
    return 'Address unavailable';
  }

  String get coordinates {
    if (isSinhala) return 'ඛණ්ඩාංක';
    return 'Coordinates';
  }

  String get distanceCaps {
    if (isSinhala) return 'දුර';
    return 'DISTANCE';
  }

  String get unableToResolveSkills {
    if (isSinhala)
      return 'තෝරාගත් කුසලතා ප්‍රවර්ග අංකවලට සම්බන්ධ කිරීමට නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න.';
    return 'Unable to resolve selected skills to category IDs. Please retry.';
  }

  String get failedToUpdateWorker {
    if (isSinhala) return 'සේවකයා යාවත්කාලීන කිරීම අසාර්ථක විය';
    return 'Failed to update worker';
  }

  String get pleaseSelectValidSkills {
    if (isSinhala) return 'යාවත්කාලීන කිරීමට පෙර කරුණාකර වලංගු කුසලතා තෝරන්න.';
    return 'Please select valid skills before updating.';
  }

  String get invalidCategoryNamesReselect {
    if (isSinhala)
      return 'තෝරාගත් සමහර අගයන් වලංගු නිපුණතා ප්‍රවර්ග නම් නොවේ. කරුණාකර කුසලතා නැවත තෝරන්න.';
    return 'Some selected values are not valid category names. Please reselect skills.';
  }

  String get workerSkillsUpdatedSuccessfully {
    if (isSinhala) return 'සේවක කුසලතා සාර්ථකව යාවත්කාලීන කරන ලදී';
    return 'Worker skills updated successfully';
  }

  String get failedToUpdateSkills {
    if (isSinhala) return 'කුසලතා යාවත්කාලීන කිරීම අසාර්ථක විය';
    return 'Failed to update skills';
  }

  String get selectedSkillsHint {
    if (isSinhala)
      return 'තෝරාගත් කුසලතා පහතින් පෙන්වයි. කුසලතා එක් කිරීමට හෝ ඉවත් කිරීමට සංස්කාරකය විවෘත කරන්න.';
    return 'Selected skills are shown below. Open the editor to add or remove skills.';
  }

  String get invalidStoredSkills {
    if (isSinhala)
      return 'සුරකින ලද සමහර කුසලතා වලංගු නොවේ (ප්‍රවර්ග නම් හමු නොවීය). වලංගු කුසලතා නැවත තෝරා යාවත්කාලීන කරන්න.';
    return 'Some stored skills are invalid (category names not found). Re-select valid skills and update.';
  }

  String get noSkillsSelected {
    if (isSinhala) return 'තවමත් කුසලතා තෝරා නැත.';
    return 'No skills selected yet.';
  }

  String get updateSkills {
    if (isSinhala) return 'කුසලතා යාවත්කාලීන කරන්න';
    return 'Update Skills';
  }

  String get availabilityWindows {
    if (isSinhala) return 'රැකියා කාල කවුළු';
    return 'Availability Windows';
  }

  String get couldNotLoadAvailabilities {
    if (isSinhala) return 'රැකියා කාල පූරණය කිරීමට නොහැකි විය';
    return 'Could not load availabilities';
  }

  String get tapButtonBelowToAddOne {
    if (isSinhala) return 'එකක් එක් කිරීමට පහත බොත්තම ටැප් කරන්න';
    return 'Tap the button below to add one';
  }

  String get loadingAddress {
    if (isSinhala) return 'ලිපිනය පූරණය වෙමින්...';
    return 'Loading address...';
  }

  String hoursCount(int hours) {
    if (isSinhala) return 'පැය $hours';
    return '$hours hour${hours == 1 ? '' : 's'}';
  }

  String hoursDuration(int hours) {
    if (isSinhala) return 'පැය $hours ක කාලසීමාව';
    return '$hours hours duration';
  }

  String scheduleFromTo(String from, String to) {
    if (isSinhala) return '$from සිට $to දක්වා කාලසටහන';
    return 'Schedule from $from to $to';
  }

  String confirmDeleteJob(String jobName) {
    if (isSinhala) return '"$jobName" මකා දැමීමට ඔබට විශ්වාසද?';
    return 'Are you sure you want to delete "$jobName"?';
  }

  /// Display label for a job/process/worker status code returned by the API.
  String statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return isSinhala ? 'බලාපොරොත්තුවෙන්' : 'PENDING';
      case 'CREATED':
        return isSinhala ? 'සාදන ලදී' : 'CREATED';
      case 'ACCEPTED':
        return isSinhala ? 'පිළිගත්' : 'ACCEPTED';
      case 'AWAITING_APPROVAL':
        return isSinhala ? 'අනුමැතිය බලාපොරොත්තුවෙන්' : 'AWAITING APPROVAL';
      case 'STARTED':
        return isSinhala ? 'ආරම්භ කළ' : 'STARTED';
      case 'IN_PROGRESS':
        return isSinhala ? 'ක්‍රියාත්මකයි' : 'IN PROGRESS';
      case 'SUCCESS':
      case 'COMPLETED':
        return isSinhala ? 'සම්පූර්ණයි' : status.toUpperCase();
      case 'FAILED':
        return isSinhala ? 'අසාර්ථකයි' : 'FAILED';
      case 'CANCELLED':
        return isSinhala ? 'අවලංගුයි' : 'CANCELLED';
      case 'BUSY':
        return isSinhala ? 'කාර්යබහුලයි' : 'BUSY';
      case 'ASSIGNED':
        return isSinhala ? 'පවරා ඇත' : 'ASSIGNED';
      case 'ONLINE':
        return isSinhala ? 'සබැඳි' : 'ONLINE';
      case 'OFFLINE':
        return isSinhala ? 'නොබැඳි' : 'OFFLINE';
      case 'LOADING':
        return isSinhala ? 'පූරණය වෙමින්' : 'LOADING';
      case 'UNKNOWN':
        return isSinhala ? 'නොදනී' : 'UNKNOWN';
      default:
        return status;
    }
  }
}

class AppLocalizationsDelegate {
  static const supportedLocales = [Locale('en'), Locale('si', 'LK')];

  static const defaultLocale = Locale('en');

  static Locale? localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) return defaultLocale;

    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    return defaultLocale;
  }
}
