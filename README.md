# ComposableCacheKit

[![CI Status](https://img.shields.io/travis/kcramer/ComposableCacheKit.svg?style=flat)](https://travis-ci.com/kcramer/ComposableCacheKit)

ComposableCacheKit is a Swift framework that provides a lightweight composable cache. 
Inspired by functional caches such as Carlos, it provides for constructing minimal, composable 
caches.

Cache keys and values can be mapped to other values.  It supports memory, disk, and 
network caches.  It also provides a pooled cache which avoids duplication of in-flight requests. 
If your app is rendering a page and requests the same item multiple times, a pooled cache
would only perform the lookup once but share the results with all requesters.

As an example, you can create a in-memory cache backed by a disk cache that will download 
images with a key that is the URL.  Requests for the same image are pooled and only a single 
disk or network lookup is made.

```Swift
let appId = "com.example.MyApp"

let memoryCache = MemoryCache<UIImage>(subsystem: appId)

let diskCache = DiskCache(path: "\(appId)/Images/",
                          logSubsystem: appId,
                          limit: 100_000_000)

let networkCache = NetworkCache(subsystem: appId)

// Compose the disk and network cache so values are cached on disk
// but retrieved from the network if not found.  Downloaded images are 
// added to the disk cache.
// Wrap that composed cache with a pooled cache that will only perform
// a lookup once even if multiple requests are made for the same key
// at the same time.
// Finally, wrap the pooled cache so it returns images and not Data.
let pooledDiskCache = diskCache
    .compose(with: networkCache)
    .pooled()
    .mappingValues(using: BidirectionalMappers.dataToImageMapper)

let imageCache = memoryCache.compose(with: pooledDiskCache)
```
