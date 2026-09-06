#import <UIKit/UIKit.h>
#import "MTAppDelegate.h"

@interface UIColor (MTerminal) 
+ (id)tableCellGroupedBackgroundColor;
@end

// UIFontPickerViewControllerDelegate (iOS 13) and UIColorPickerViewControllerDelegate
// (iOS 14) are newer than the deployment target, so conformance can't be declared
// here. Those delegate methods are implemented and the pickers are assigned `(id)self`.
@interface MTSettingsController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSString *_selectedColorKey;
}
@end
