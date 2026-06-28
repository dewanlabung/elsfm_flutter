enum TrackAction {
  play,
  addToPlaylist,
  share,
  download,
  like,
  unlike,
  addToQueue,
  viewDetails,
  reportIssue,
}

extension TrackActionExtension on TrackAction {
  String get label {
    return switch (this) {
      TrackAction.play => 'Play',
      TrackAction.addToPlaylist => 'Add to Playlist',
      TrackAction.share => 'Share',
      TrackAction.download => 'Download',
      TrackAction.like => 'Like',
      TrackAction.unlike => 'Unlike',
      TrackAction.addToQueue => 'Add to Queue',
      TrackAction.viewDetails => 'Song Details',
      TrackAction.reportIssue => 'Report Issue',
    };
  }

  String get icon {
    return switch (this) {
      TrackAction.play => 'play_arrow',
      TrackAction.addToPlaylist => 'playlist_add',
      TrackAction.share => 'share',
      TrackAction.download => 'download',
      TrackAction.like => 'favorite',
      TrackAction.unlike => 'favorite_border',
      TrackAction.addToQueue => 'queue_music',
      TrackAction.viewDetails => 'info',
      TrackAction.reportIssue => 'flag',
    };
  }
}
