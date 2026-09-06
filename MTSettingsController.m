#import "MTSettingsController.h"
#import "MTCompat.h"

@import SafariServices;

NSUserDefaults *defaults;

@interface MTSettingsController ()
@property (nonatomic, strong) UITableView *table;
- (void)sendSetting:(NSString *)key value:(NSString *)value;
- (void)applyFontName:(NSString *)name;
- (void)presentHexColorEntry;
- (void)dismissSettings;
- (UIColor *)colorFromHexString:(NSString *)hexString;
- (NSString *)hexStringFromColor:(UIColor *)color;
@end

// iOS 13 gained UIFontPickerViewController. This is the fallback for iOS 12.
@interface MTFontListController : UITableViewController {
    NSArray *families;
    MTSettingsController *owner; // not retained; it presents and outlives us
}
- (id)initWithOwner:(MTSettingsController *)_owner;
@end

// Private UIKit API, so availability can't be checked at compile time.
static UIColor *resetActionBackgroundColor(void) {
    if ([UIColor respondsToSelector:@selector(tableCellGroupedBackgroundColor)]) {
        return [UIColor tableCellGroupedBackgroundColor];
    }
    return [UIColor lightGrayColor];
}

@implementation MTSettingsController
- (id)init {
    self = [super init];
    if (self) {
        defaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}
- (void)loadView {
    [super loadView];

    self.title = @"Settings";
    self.navigationController.navigationBar.prefersLargeTitles = YES;

    // Settings apply as they're changed, so this only needs to dismiss. It is
    // required on iOS 12, where modals are fullscreen with no swipe-to-dismiss.
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSettings)];
    self.navigationItem.rightBarButtonItem = done;
    [done release];

    self.table = [[[UITableView alloc] initWithFrame:CGRectZero style:MTGroupedTableViewStyle()] autorelease];
    self.table.translatesAutoresizingMaskIntoConstraints = NO;
	self.table.delegate = self;
    self.table.dataSource = self;
	self.table.separatorColor = [UIColor clearColor];
    [self.view addSubview:self.table];

	[NSLayoutConstraint activateConstraints:@[
		[self.table.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
		[self.table.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
		[self.table.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
	]];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    if (section == 0) {
        rows = 3;
    } else if (section == 1) {
        rows = 5;
    } else if (section == 2) {
        return 1;
    }
	return rows;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
	}
	// reused cells keep the previous row's accessory, so clear both forms
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;

    NSString *title = nil;
    NSString *subtitle = nil;

	NSInteger fontSize = [[defaults objectForKey:@"fontSize"] integerValue] ?: 10;
		
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            title = [NSString stringWithFormat:@"Font Size: %ld", fontSize];
            subtitle = @"Swipe left to reset";
            
            UIStepper *fontStepper = [[[UIStepper alloc] initWithFrame:CGRectMake(0, 0, 60, 40)] autorelease];
            fontStepper.value = fontSize;
            fontStepper.maximumValue = 80;
            fontStepper.minimumValue = 10;
            [fontStepper addTarget:self action:@selector(fontSizeChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = fontStepper;
        } else if (indexPath.row == 1) {
            title = @"Select Font";
            subtitle = [defaults objectForKey:@"fontName"] ?: @"Courier";
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 2) {
            title = @"Use Proportional Font";
            subtitle = @"Improves display of certain fonts";
            UISwitch *switchView = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
            cell.accessoryView = switchView;
            [switchView setOnTintColor:[UIColor systemBlueColor]];
            [switchView setOn:([defaults objectForKey:@"fontProportional"]) ? [[defaults objectForKey:@"fontProportional"] boolValue] : NO animated:NO];
            [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
    } else if (indexPath.section == 1) {
        UIView *colorWell = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)] autorelease];
        colorWell.layer.masksToBounds = YES;
        colorWell.layer.cornerRadius = 15;
        colorWell.layer.borderColor = MTSecondaryLabelColor().CGColor;
        colorWell.layer.borderWidth = 2.0f;

        NSString *defaultColorValue = nil;
        NSString *colorKey = nil;

        switch (indexPath.row) {
            case 0:
                title = @"Text Color";
                colorKey = @"fgColor";
                defaultColorValue = @"FFFFFF";
                break;
            case 1:
                title = @"Bold Text Color";
                colorKey = @"fgBoldColor";
                defaultColorValue = @"FFFFFF";
                break;
            case 2:
                title = @"Background Color";
                colorKey = @"bgColor";
                defaultColorValue = @"000000";
                break;
            case 3:
                title = @"Cursor Color";
                colorKey = @"bgCursorColor";
                defaultColorValue = @"FFFFFF";
                break;
            case 4:
                title = @"Cursor Text Color";
                colorKey = @"fgCursorColor";
                defaultColorValue = @"000000";
                break;
        }
        subtitle = ([defaults objectForKey:colorKey]) ? [NSString stringWithFormat:@"#%@", [defaults objectForKey:colorKey]] : [NSString stringWithFormat:@"#%@", defaultColorValue];
        colorWell.backgroundColor = ([defaults objectForKey:colorKey]) ? [self colorFromHexString:[NSString stringWithFormat:@"#%@", [defaults objectForKey:colorKey]]] : [self colorFromHexString:[NSString stringWithFormat:@"#%@", defaultColorValue]];
        cell.accessoryView = colorWell;
    } else if (indexPath.section == 2) {
        title = @"View Source Code";
        subtitle = @"https://github.com/MTACS/MTerminal";
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

	cell.imageView.image = nil;
	cell.textLabel.text = title;
	cell.detailTextLabel.text = subtitle;
	cell.detailTextLabel.textColor = MTSecondaryLabelColor();
	cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

	return cell;
}
// Settings are applied by round-tripping through the app delegate's URL handler.
// Values are percent-encoded because font names may contain spaces, which would
// make +[NSURL URLWithString:] return nil.
- (void)sendSetting:(NSString *)key value:(NSString *)value {
    NSString *encoded = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: value;
    UIApplication *app = [UIApplication sharedApplication];
    MTAppDelegate *delegate = (MTAppDelegate *)[app delegate];
    [delegate application:app handleOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"mterminal://?%@=%@", key, encoded]]];
}
- (void)switchChanged:(UISwitch *)sender {
    [self sendSetting:@"fontProportional" value:(sender.on) ? @"YES" : @"NO"];
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController API_AVAILABLE(ios(14.0)) {
    UIColor *selectedColor = viewController.selectedColor;
    NSString *colorHex = [self hexStringFromColor:selectedColor];

    [self sendSetting:_selectedColorKey value:colorHex];
    _selectedColorKey = nil;
    [_table reloadData];
}
- (NSDictionary *)dictionaryForColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    NSMutableDictionary *colorDict = [NSMutableDictionary dictionary];
    [colorDict setObject:[NSNumber numberWithFloat:components[0]] forKey:@"red"];
    [colorDict setObject:[NSNumber numberWithFloat:components[1]] forKey:@"green"];
    [colorDict setObject:[NSNumber numberWithFloat:components[2]] forKey:@"blue"];
    [colorDict setObject:[NSNumber numberWithFloat:components[3]] forKey:@"alpha"];
    return colorDict;
}
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}
- (void)presentColorPicker {
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *colorPickerController = [[UIColorPickerViewController alloc] init];
        colorPickerController.delegate = (id)self;
        colorPickerController.supportsAlpha = YES;
        colorPickerController.modalPresentationStyle = UIModalPresentationPageSheet;
        colorPickerController.modalInPresentation = YES;
        [self presentViewController:colorPickerController animated:YES completion:nil];
        [colorPickerController release];
        return;
    }
    [self presentHexColorEntry];
}
// Fallback for iOS < 14, which has no UIColorPickerViewController. Colours are
// stored as hex strings anyway, so ask for one directly.
- (void)presentHexColorEntry {
    NSString *key = _selectedColorKey;
    NSString *current = [defaults objectForKey:key] ?: @"FFFFFF";
    // __block so the block doesn't retain the alert that owns it
    __block UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Color"
                                                                          message:@"Enter a hex colour, for example 1B1B1B"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = current;
        field.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.keyboardType = UIKeyboardTypeASCIICapable;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        _selectedColorKey = nil;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *entered = alert.textFields.firstObject.text ?: @"";
        NSString *hex = [[entered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
        if ([hex hasPrefix:@"#"]) {
            hex = [hex substringFromIndex:1];
        }
        _selectedColorKey = nil;
        if (hex.length == 6 && [hex rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet]].location == NSNotFound) {
            [self sendSetting:key value:hex];
        }
        [_table reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
	UISwipeActionsConfiguration *swipeActions;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UIContextualAction *resetAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [defaults setObject:[NSNumber numberWithInt:10] forKey:@"fontSize"];
                [defaults synchronize];
                [_table reloadData];

                [self sendSetting:@"fontSize" value:@"10"];
                completionHandler(YES);
            }];

            resetAction.backgroundColor = resetActionBackgroundColor();
            resetAction.image = MTSystemImage(@"arrow.triangle.2.circlepath");
            resetAction.title = @"Reset";

            swipeActions = [UISwipeActionsConfiguration configurationWithActions:@[resetAction]];
            swipeActions.performsFirstActionWithFullSwipe = YES;
            return swipeActions;
        }
    } else if (indexPath.section == 1) {
        NSString *colorKey = nil;
        NSString *colorValue = nil;
        switch (indexPath.row) {
            case 0:
                colorKey = @"fgColor";
                colorValue = @"FFFFFF";
                break;
            case 1:
                colorKey = @"fgBoldColor";
                colorValue = @"FFFFFF";
                break;
            case 2:
                colorKey = @"bgColor";
                colorValue = @"000000";
                break;
            case 3:
                colorKey = @"bgCursorColor";
                colorValue = @"FFFFFF";
                break;
            case 4:
                colorKey = @"fgCursorColor";
                colorValue = @"000000";
                break;
        }

        UIContextualAction *resetAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [defaults setObject:nil forKey:colorKey];
            [defaults synchronize];
            [_table reloadData];

            [self sendSetting:colorKey value:colorValue];
            completionHandler(YES);
        }];

        resetAction.backgroundColor = resetActionBackgroundColor();
        resetAction.image = MTSystemImage(@"arrow.triangle.2.circlepath");
        resetAction.title = @"Reset";

        swipeActions = [UISwipeActionsConfiguration configurationWithActions:@[resetAction]];
        swipeActions.performsFirstActionWithFullSwipe = YES;
        return swipeActions;
    }
    return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            [self selectCustomFont];
        }
    } else if (indexPath.section == 1) {
        NSString *colorKey = nil;
        switch (indexPath.row) {
            case 0:
                colorKey = @"fgColor";
                break;
            case 1:
                colorKey = @"fgBoldColor";
                break;
            case 2:
                colorKey = @"bgColor";
                break;
            case 3:
                colorKey = @"bgCursorColor";
                break;
            case 4:
                colorKey = @"fgCursorColor";
                break;
        }
        _selectedColorKey = colorKey;
        [self presentColorPicker];
    } else if (indexPath.section == 2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/MTACS/MTerminal"]];
    }
}
- (NSString *)hexStringFromColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];

    return [NSString stringWithFormat:@"%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}
- (void)fontSizeChanged:(UIStepper *)stepper {
    [defaults setObject:[NSNumber numberWithInt:(int)stepper.value] forKey:@"fontSize"];
    [_table reloadData];
    [self sendSetting:@"fontSize" value:[NSString stringWithFormat:@"%d", (int)stepper.value]];
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    if (section == 0) {
        title = @"Terminal Font";
    } else if (section == 1) {
        title = @"Terminal Colors";
    } else if (section == 2) {
        title = @"Source";
    }
    return title;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)] autorelease];
	titleLabel.textColor = MTSecondaryLabelColor();
	titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
	titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
	return titleLabel;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if ([self tableView:tableView titleForHeaderInSection:section] != nil) {
		return 40;
	}
	return 10;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == 1) {
		UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width / 2) - 100, 0, 200, 100)] autorelease];
		titleLabel.text = @"Tap color cell to pick color. Swipe left to reset";
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.numberOfLines = 2;
		titleLabel.textColor = MTSecondaryLabelColor();
		titleLabel.textAlignment = NSTextAlignmentCenter;
		return titleLabel;
	}
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
		return 60;
	}
	return 0;
}
- (void)selectCustomFont {
	if (@available(iOS 13.0, *)) {
		UIFontPickerViewController *picker = [[UIFontPickerViewController alloc] init];
		picker.delegate = (id)self;
		[self presentViewController:picker animated:YES completion:nil];
		[picker release];
		return;
	}
	MTFontListController *list = [[MTFontListController alloc] initWithOwner:self];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
	[list release];
	[self presentViewController:nav animated:YES completion:nil];
	[nav release];
}
- (void)fontPickerViewControllerDidPickFont:(UIFontPickerViewController *)viewController API_AVAILABLE(ios(13.0)) {
	UIFontDescriptor *descriptor = viewController.selectedFontDescriptor;
	if (descriptor.postscriptName != nil) {
        [self applyFontName:descriptor.postscriptName];
    }
}
- (void)dismissSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)applyFontName:(NSString *)name {
    [self sendSetting:@"fontName" value:name];
    [_table reloadData];
}
- (void)dealloc {
    [_table release];
    [super dealloc];
}
@end

@implementation MTFontListController
- (id)initWithOwner:(MTSettingsController *)_owner {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        families = [[[UIFont familyNames] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
        owner = _owner;
        self.title = @"Select Font";
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = cancel;
        [cancel release];
    }
    return self;
}
- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return families.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Font"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Font"] autorelease];
    }
    NSString *family = [families objectAtIndex:indexPath.row];
    cell.textLabel.text = family;
    cell.textLabel.font = [UIFont fontWithName:family size:17] ?: [UIFont systemFontOfSize:17];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [owner applyFontName:[families objectAtIndex:indexPath.row]];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)dealloc {
    [families release];
    [super dealloc];
}
@end
