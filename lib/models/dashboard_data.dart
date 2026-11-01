/// Result of one dashboard load. All money values are halalas (int).
class DashboardData {
  final int total, active, temporary, offboarded, mudad, ajeer, contractWatch;
  final int fullyLoadedMinor, paidMinor, outstandingMinor, eosbPendingMinor, loansMinor;
  final int paidRows, openRows, redFlags;

  /// keys: expired, d7, d30, d60, d90 (exclusive ranges)
  final Map<String, int> expiryBuckets;

  /// Company-wide (scope-limited) comparison views - NOT narrowed by filters.
  final Map<String, int> costByDepartment; // departmentId -> halalas
  final Map<String, int> headcountByRegion; // regionId -> active headcount

  final DateTime loadedAt;

  const DashboardData({
    this.total = 0, this.active = 0, this.temporary = 0, this.offboarded = 0,
    this.mudad = 0, this.ajeer = 0, this.contractWatch = 0,
    this.fullyLoadedMinor = 0, this.paidMinor = 0, this.outstandingMinor = 0,
    this.eosbPendingMinor = 0, this.loansMinor = 0,
    this.paidRows = 0, this.openRows = 0, this.redFlags = 0,
    this.expiryBuckets = const {},
    this.costByDepartment = const {},
    this.headcountByRegion = const {},
    required this.loadedAt,
  });
}

class DashboardFilter {
  final String? regionId, departmentId, month; // month = 'YYYY-MM'
  const DashboardFilter({this.regionId, this.departmentId, this.month});
}
