#pragma once
#import <UIKit/UIKit.h>

// The UI was written against iOS 13/14 API, but the deployment target is 12.0.
// These helpers keep the modern appearance where the system provides it and
// fall back to equivalents that exist on iOS 12.

static inline UIImage *MTSystemImage(NSString *name) {
    if (@available(iOS 13.0, *)) {
        return [[UIImage systemImageNamed:name] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return nil; // SF Symbols are unavailable; callers fall back to a title
}

static inline UIColor *MTLabelColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    }
    return [UIColor blackColor];
}

static inline UIColor *MTSecondaryLabelColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    }
    return [UIColor grayColor];
}

static inline UIColor *MTSystemBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemBackgroundColor];
    }
    return [UIColor whiteColor];
}

static inline UITableViewStyle MTGroupedTableViewStyle(void) {
    if (@available(iOS 13.0, *)) {
        return UITableViewStyleInsetGrouped;
    }
    return UITableViewStyleGrouped;
}
