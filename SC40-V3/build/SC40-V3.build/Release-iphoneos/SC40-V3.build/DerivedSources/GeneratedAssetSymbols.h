#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "76" asset catalog image resource.
static NSString * const ACImageName76 AC_SWIFT_PRIVATE = @"76";

/// The "appstore" asset catalog image resource.
static NSString * const ACImageNameAppstore AC_SWIFT_PRIVATE = @"appstore";

/// The "playstore" asset catalog image resource.
static NSString * const ACImageNamePlaystore AC_SWIFT_PRIVATE = @"playstore";

/// The "track-background" asset catalog image resource.
static NSString * const ACImageNameTrackBackground AC_SWIFT_PRIVATE = @"track-background";

/// The "usa_sprinter" asset catalog image resource.
static NSString * const ACImageNameUsaSprinter AC_SWIFT_PRIVATE = @"usa_sprinter";

#undef AC_SWIFT_PRIVATE
