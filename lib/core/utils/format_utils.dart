class FormatUtils {
  FormatUtils._();

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDurationShort(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  static String formatBitrate(int bitrate) {
    if (bitrate >= 1000) return '${(bitrate / 1000).toStringAsFixed(0)}kbps';
    return '${bitrate}bps';
  }

  static String formatSampleRate(int sampleRate) {
    if (sampleRate >= 1000) return '${(sampleRate / 1000).toStringAsFixed(1)}kHz';
    return '${sampleRate}Hz';
  }

  static String formatFrequency(int hz) {
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(0)}K';
    return '$hz';
  }

  static String formatTrackCount(int count) {
    if (count == 1) return '1 song';
    return '$count songs';
  }

  static String formatDateRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
