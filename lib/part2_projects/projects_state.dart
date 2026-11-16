import 'package:flutter/foundation.dart';
import 'projects_api.dart';

enum ListStatus {
  initialLoading,
  initialError,
  ready,
  empty,
}

@immutable
class ProjectsState {
  final List<Project> items;
  final ListStatus status;
  final bool isLoadingMore;
  final Object? loadMoreError;
  final bool hasReachedEnd;
  final int nextPage;
  final int generationToken;

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
