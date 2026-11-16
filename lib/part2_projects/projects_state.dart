import 'package:flutter/foundation.dart';
import 'projects_api.dart';

/// Status of the primary screen / first page load.
enum ListStatus {
  initialLoading,
  initialError,
  ready,
  empty,
}

/// Immutable state model representing the projects list and pagination lifecycle.
@immutable
class ProjectsState {
  final List<Project> items;
  final ListStatus status;
  final bool isLoadingMore;
  final Object? loadMoreError; // Non-null renders the inline footer retry row
  final bool hasReachedEnd;
  final int nextPage;
  final int generationToken; // Discards stale async responses on pull-to-refresh

  const ProjectsState({
    this.items = const [],
    this.status = ListStatus.initialLoading,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.hasReachedEnd = false,
    this.nextPage = 0,
    this.generationToken = 0,
  });

  ProjectsState copyWith({
    List<Project>? items,
    ListStatus? status,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
    bool? hasReachedEnd,
    int? nextPage,
    int? generationToken,
  }) {
    return ProjectsState(
      items: items ?? this.items,
      status: status ?? this.status,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      nextPage: nextPage ?? this.nextPage,
      generationToken: generationToken ?? this.generationToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectsState &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          status == other.status &&
          isLoadingMore == other.isLoadingMore &&
          loadMoreError == other.loadMoreError &&
          hasReachedEnd == other.hasReachedEnd &&
          nextPage == other.nextPage &&
          generationToken == other.generationToken;

  @override
  int get hashCode =>
      items.hashCode ^
      status.hashCode ^
      isLoadingMore.hashCode ^
      loadMoreError.hashCode ^
      hasReachedEnd.hashCode ^
      nextPage.hashCode ^
      generationToken.hashCode;
}
