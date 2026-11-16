import 'dart:async';
import 'dart:math';

/// Custom exception thrown by ProjectsApi to simulate network or server failures.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// Domain model representing a teen freelance project on Funngro.
class Project {
  final String id;
  final String title;
  final String company;
  final int payout;

  const Project({
    required this.id,
    required this.title,
    required this.company,
    required this.payout,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          company == other.company &&
          payout == other.payout;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ company.hashCode ^ payout.hashCode;
}

/// Given ProjectsApi specification (as provided in Part 2):
class ProjectsApi {
  final _rng = Random();

  /// Optional test hook to deterministically force failure for unit tests and Loom demo.
  bool? forceFailNext;

  /// Returns 20 projects per page. Pages 0..7 exist.
  /// ~900ms latency. Fails (throws ApiException) roughly 1 in 5 calls.
  Future<List<Project>> fetchProjects(int page) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (forceFailNext == true) {
      forceFailNext = null;
      throw const ApiException('server error');
    }
    if (_rng.nextInt(5) == 0) throw const ApiException('server error');
    if (page > 7) return [];
    return List.generate(20, (i) => Project(
      id: 'p${page * 20 + i}',
      title: 'Project ${page * 20 + i}',
      company: 'Company ${_rng.nextInt(50)}',
      payout: 200 + _rng.nextInt(1800),
    ));
  }
}
