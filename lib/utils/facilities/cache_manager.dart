import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static final customCacheManager = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'facilities_cache'),
      fileService: HttpFileService(),
    ),
  );
}
