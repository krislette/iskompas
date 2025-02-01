import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  // Static instance of CacheManager with custom configuration
  static final customCacheManager = CacheManager(
    Config(
      'customCacheKey',
      // Duration before cached data is considered stale and maximum number
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      // Repository for cache info
      repo: JsonCacheInfoRepository(databaseName: 'facilities_cache'),
      fileService: HttpFileService(),
    ),
  );
}
