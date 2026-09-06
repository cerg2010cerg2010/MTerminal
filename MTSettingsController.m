#import "MTSettingsController.h"

@import SafariServices;

NSUserDefaults *defaults;

@interface MTSettingsController ()
@property (nonatomic, strong) UITableView *table;
@end

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

    self.table = [[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped] autorelease];
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
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}

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
            
            UIImageView *accessoryImage = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)] autorelease];
            accessoryImage.contentMode = UIViewContentModeScaleAspectFit;
            accessoryImage.image = [UIImage systemImageNamed:@"chevron.right"];
            accessoryImage.tintColor = [UIColor secondaryLabelColor];
            cell.accessoryView = accessoryImage;
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
        colorWell.layer.borderColor = [UIColor secondaryLabelColor].CGColor;
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
        
        UIImageView *accessoryImage = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)] autorelease];
        accessoryImage.contentMode = UIViewContentModeScaleAspectFit;
        accessoryImage.image = [UIImage systemImageNamed:@"link"];
        accessoryImage.tintColor = [UIColor secondaryLabelColor];
        cell.accessoryView = accessoryImage;
    }

	UIListContentConfiguration *content = [cell defaultContentConfiguration];
    [content setImage:nil];
    [content setText:title];
    [content setSecondaryText:subtitle];
    [content.secondaryTextProperties setColor:[UIColor secondaryLabelColor]];
    [content.secondaryTextProperties setFont:[UIFont systemFontOfSize:12]];
    [cell setContentConfiguration:content];

	return cell;
}
- (void)switchChanged:(UISwitch *)sender {
    UIApplication *app = [UIApplication sharedApplication];
    MTAppDelegate *delegate = (MTAppDelegate *)[app delegate];
    [delegate application:app handleOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"mterminal://?fontProportional=%@", (sender.on) ? @"YES" : @"NO"]]];
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
    UIColor *selectedColor = viewController.selectedColor;
    NSString *colorHex = [self hexStringFromColor:selectedColor];
    
    UIApplication *app = [UIApplication sharedApplication];
    MTAppDelegate *delegate = (MTAppDelegate *)[app delegate];
    [delegate application:app handleOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"mterminal://?%@=%@", _selectedColorKey, colorHex]]];
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
    UIColorPickerViewController *colorPickerController = [[UIColorPickerViewController alloc] init];
    colorPickerController.delegate = self;
    colorPickerController.supportsAlpha = YES;
    colorPickerController.modalPresentationStyle = UIModalPresentationPageSheet;
    colorPickerController.modalInPresentation = YES;
    [self presentViewController:colorPickerController animated:YES completion:nil];
    [colorPickerController release];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
	UISwipeActionsConfiguration *swipeActions;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UIContextualAction *resetAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [defaults setObject:[NSNumber numberWithInt:10] forKey:@"fontSize"];
                [defaults synchronize];
                [_table reloadData];

                UIApplication *app = [UIApplication sharedApplication];
                MTAppDelegate *delegate = (MTAppDelegate *)[app delegate];
                [delegate application:app handleOpenURL:[NSURL URLWithString:@"mterminal://?fontSize=10"]];
                completionHandler(YES);
            }];

            resetAction.backgroundColor = [UIColor tableCellGroupedBackgroundColor];
            resetAction.image = [UIImage systemImageNamed:@"arrow.triangle.2.circlepath"];
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

            UIApplication *app = [UIApplication sharedApplication];
            MTAppDelegate *delegate = (MTAppDelegate *)[app delegate];
            [delegate application:app handleOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"mterminal://?%@=%@", colorKey, colorValue]]];
            completionHandler(YES);
        }];

        resetAction.backgroundColor = [UIColor tableCellGroupedBackgroundColor];
        resetAction.image = [UIImage systemImageNamed:@"arrow.triangle.2.circlepath"];
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
    UIApplication *app = [UIApplication sharedApplication];
    MTAppDelegate *delegate = (MTAppDelegate *)[app delegate];
    NSString *fontString = [NSString stringWithFormat:@"mterminal://?fontSize=%d", (int)stepper.value]; 
    [delegate application:app handleOpenURL:[NSURL URLWithString:fontString]];
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
	titleLabel.textColor = [UIColor secondaryLabelColor];
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
		titleLabel.textColor = [UIColor secondaryLabelColor];
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
	UIFontPickerViewController *picker = [[UIFontPickerViewController alloc] init];
	picker.delegate = self;
	[self presentViewController:picker animated:YES completion:nil];
	[picker release];
}
- (void)fontPickerViewControllerDidPickFont:(UIFontPickerViewController *)viewController {
	UIFontDescriptor *descriptor = viewController.selectedFontDescriptor;
	if (descriptor.postscriptName != nil) {
        UIApplication *app = [UIApplication sharedApplication];
        MTAppDelegate *delegate = (MTAppDelegate *)[app delegate];
        NSString *fontString = [NSString stringWithFormat:@"mterminal://?fontName=%@", descriptor.postscriptName]; 
        [delegate application:app handleOpenURL:[NSURL URLWithString:fontString]];
        [_table reloadData];
    }
}
- (void)dealloc {
    [_table release];
    [super dealloc];
}
@end
