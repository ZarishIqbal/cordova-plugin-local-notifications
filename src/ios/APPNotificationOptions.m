/*
 * Apache 2.0 License
 *
 * Copyright (c) Sebastian Katzer 2017
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apache License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://opensource.org/licenses/Apache-2.0/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 */

#import "APPNotificationOptions.h"
#import "UNUserNotificationCenter+APPLocalNotification.h"

@import CoreLocation;
@import UserNotifications;

// Maps these crap where Sunday is the 1st day of the week
static NSInteger WEEKDAYS[8] = { 0, 2, 3, 4, 5, 6, 7, 1 };

@interface APPNotificationOptions ()

// The dictionary which contains all notification properties
@property(nonatomic, retain) NSDictionary* dict;

@end

@implementation APPNotificationOptions : NSObject

@synthesize dict;

#pragma mark -
#pragma mark Initialization

/**
 * Initialize by using the given property values.
 *
 * @param [ NSDictionary* ] dict A key-value property map.
 *
 * @return [ APPNotificationOptions ]
 */
- (id) initWithDict:(NSDictionary*)dictionary
{
    self      = [self init];
    self.dict = dictionary;

    return self;
}

#pragma mark -
#pragma mark Properties

/**
 * The ID for the notification.
 *
 * @return [ NSNumber* ]
 */
- (NSNumber*) id
{
    NSInteger id = [dict[@"id"] integerValue];

    return [NSNumber numberWithInteger:id];
}

/**
 * The ID for the notification.
 *
 * @return [ NSString* ]
 */
- (NSString*) identifier
{
    return [NSString stringWithFormat:@"%@", self.id];
}

/**
 * The title for the notification.
 *
 * @return [ NSString* ]
 */
- (NSString*) title
{
    return dict[@"title"];
}

/**
 * The subtitle for the notification.
 *
 * @return [ NSString* ]
 */
- (NSString*) subtitle
{
    NSArray *parts = [self.title componentsSeparatedByString:@"\n"];

    return parts.count < 2 ? @"" : [parts objectAtIndex:1];
}

/**
 * The text for the notification.
 *
 * @return [ NSString* ]
 */
- (NSString*) text
{
    return dict[@"text"];
}

/**
 * Show notification.
 *
 * @return [ BOOL ]
 */
- (BOOL) silent
{
    return [dict[@"silent"] boolValue];
}

/**
 * Show notification in foreground.
 *
 * @return [ BOOL ]
 */
- (int) priority
{
    return [dict[@"priority"] intValue];
}

/**
 * The badge number for the notification.
 *
 * @return [ NSNumber* ]
 */
- (NSNumber*) badge
{
    id value = dict[@"badge"];

    return (value == NULL) ? NULL : [NSNumber numberWithInt:[value intValue]];
}

/**
 * The category of the notification.
 *
 * @return [ NSString* ]
 */
- (NSString*) actionGroupId
{
    id actions = dict[@"actions"];
    
    return ([actions isKindOfClass:NSString.class]) ? actions : kAPPGeneralCategory;
}

/**
 * The sound file for the notification.
 *
 * @return [ UNNotificationSound* ]
 */
- (UNNotificationSound*) sound
{
    NSString* path = dict[@"sound"];
    NSString* file;

    if ([path isKindOfClass:NSNumber.class]) {
        return [path boolValue] ? [UNNotificationSound defaultSound] : NULL;
    }

    if (!path.length)
        return NULL;

    if ([path hasPrefix:@"file:/"]) {
        file = [self soundNameForAsset:path];
    } else
    if ([path hasPrefix:@"res:"]) {
        file = [self soundNameForResource:path];
    }

    return [UNNotificationSound soundNamed:file];
}


/**
 * Additional content to attach.
 *
 * @return [ UNNotificationSound* ]
 */
- (NSArray<UNNotificationAttachment *> *) attachments
{
    NSArray* paths              = dict[@"attachments"];
    NSMutableArray* attachments = [[NSMutableArray alloc] init];

    if (!paths)
        return attachments;

    for (NSString* path in paths) {
        NSURL* url = [self urlForAttachmentPath:path];

        UNNotificationAttachment* attachment;
        attachment = [UNNotificationAttachment attachmentWithIdentifier:path
                                                                    URL:url
                                                                options:NULL
                                                                  error:NULL];

        if (attachment) {
            [attachments addObject:attachment];
        }
    }

    return attachments;
}

#pragma mark -
#pragma mark Public
/**
 * Specify how and when to trigger the notification.
 *
 * @return [ UNNotificationTrigger* ]
 */
- (UNNotificationTrigger*) trigger
{
    NSString* type = [self valueForTriggerOption:@"type"];

    if ([type isEqualToString:@"location"])
        return [self triggerWithRegion];

    if (![type isEqualToString:@"calendar"])
        NSLog(@"Unknown type: %@", type);

    if ([self isRepeating])
        return [self repeatingTrigger];

    return [self nonRepeatingTrigger];
}

/**
 * The notification's user info dict.
 *
 * @return [ NSDictionary* ]
 */
- (NSDictionary*) userInfo
{
    if (dict[@"updatedAt"]) {
        NSMutableDictionary* data = [dict mutableCopy];

        [data removeObjectForKey:@"updatedAt"];

        return data;
    }

    return dict;
}

#pragma mark -
#pragma mark Private

- (id) valueForTriggerOption:(NSString*)key
{
    return dict[@"trigger"][key];
}

/**
 * The date when to fire the notification.
 *
 * @return [ NSDate* ]
 */
- (NSDate*) triggerDate
{
    double timestamp = [[self valueForTriggerOption:@"at"] doubleValue];

    return [NSDate dateWithTimeIntervalSince1970:(timestamp / 1000)];
}

/**
 * If the notification shall be repeating.
 *
 * @return [ BOOL ]
 */
- (BOOL) isRepeating
{
    id every = [self valueForTriggerOption:@"every"];

    if ([every isKindOfClass:NSString.class])
        return ((NSString*) every).length > 0;

    if ([every isKindOfClass:NSDictionary.class])
        return ((NSDictionary*) every).count > 0;

    return every > 0;
}

/**
 * Non repeating trigger.
 *
 * @return [ UNTimeIntervalNotificationTrigger* ]
 */
- (UNNotificationTrigger*) nonRepeatingTrigger
{
    id timestamp = [self valueForTriggerOption:@"at"];

    if (timestamp) {
        return [self triggerWithDateMatchingComponents:NO];
    }

    return [UNTimeIntervalNotificationTrigger
            triggerWithTimeInterval:[self timeInterval] repeats:NO];
}

/**
 * Repeating trigger.
 *
 * @return [ UNNotificationTrigger* ]
 */
- (UNNotificationTrigger*) repeatingTrigger
{
    id every = [self valueForTriggerOption:@"every"];

    if ([every isKindOfClass:NSString.class])
        return [self triggerWithDateMatchingComponents:YES];

    if ([every isKindOfClass:NSDictionary.class])
        return [self triggerWithCustomDateMatchingComponents];

    return [self triggerWithTimeInterval];
}

/**
 * A trigger based on a calendar time defined by the user.
 *
 * @return [ UNTimeIntervalNotificationTrigger* ]
 */
- (UNTimeIntervalNotificationTrigger*) triggerWithTimeInterval
{
    double ticks   = [[self valueForTriggerOption:@"every"] doubleValue];
    NSString* unit = [self valueForTriggerOption:@"unit"];
    double seconds = [self convertTicksToSeconds:ticks unit:unit];

    if (seconds < 60) {
        NSLog(@"time interval must be at least 60 sec if repeating");
        seconds = 60;
    }

    UNTimeIntervalNotificationTrigger* trigger =
    [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:seconds
                                                       repeats:YES];

    NSLog(@"[local-notification] Next trigger at: %@", trigger.nextTriggerDate);

    return trigger;
}

/**
 * A repeating trigger based on a calendar time intervals defined by the plugin.
 *
 * @return [ UNCalendarNotificationTrigger* ]
 */
- (UNCalendarNotificationTrigger*) triggerWithDateMatchingComponents:(BOOL)repeats
{
    NSCalendar* cal        = [self calendarWithMondayAsFirstDay];
    NSDateComponents *date = [cal components:[self repeatInterval]
                                    fromDate:[self triggerDate]];

    date.timeZone = [NSTimeZone defaultTimeZone];

    UNCalendarNotificationTrigger* trigger =
    [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:date
                                                             repeats:repeats];

    NSLog(@"[local-notification] Next trigger at: %@", trigger.nextTriggerDate);

    return trigger;
}

/**
 * A repeating trigger based on a calendar time intervals defined by the user.
 *
 * @return [ UNCalendarNotificationTrigger* ]
 */
- (UNCalendarNotificationTrigger*) triggerWithCustomDateMatchingComponents
{
    NSCalendar* cal        = [self calendarWithMondayAsFirstDay];
    NSDateComponents *date = [self customDateComponents];

    date.calendar = cal;
    date.timeZone = [NSTimeZone defaultTimeZone];

    UNCalendarNotificationTrigger* trigger =
    [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:date
                                                             repeats:YES];

    NSLog(@"[local-notification] Next trigger at: %@", trigger.nextTriggerDate);

    return trigger;
}

/**
 * A repeating trigger based on a location region.
 *
 * @return [ UNLocationNotificationTrigger* ]
 */
- (UNLocationNotificationTrigger*) triggerWithRegion
{
    NSArray* center = [self valueForTriggerOption:@"center"];
    double radius   = [[self valueForTriggerOption:@"radius"] doubleValue];
    BOOL single     = [[self valueForTriggerOption:@"single"] boolValue];

    CLLocationCoordinate2D coord =
    CLLocationCoordinate2DMake([center[0] doubleValue], [center[1] doubleValue]);

    CLCircularRegion* region =
    [[CLCircularRegion alloc] initWithCenter:coord
                                      radius:radius
                                  identifier:self.identifier];

    region.notifyOnEntry = [[self valueForTriggerOption:@"notifyOnEntry"] boolValue];
    region.notifyOnExit  = [[self valueForTriggerOption:@"notifyOnExit"] boolValue];

    return [UNLocationNotificationTrigger triggerWithRegion:region
                                                    repeats:!single];
}

/**
 * The time interval between the next fire date and now.
 *
 * @return [ double ]
 */
- (double) timeInterval
{
    double ticks   = [[self valueForTriggerOption:@"in"] doubleValue];
    NSString* unit = [self valueForTriggerOption:@"unit"];
    double seconds = [self convertTicksToSeconds:ticks unit:unit];

    return MAX(0.01f, seconds);
}

/**
 * The repeat interval for the notification.
 *
 * @return [ NSCalendarUnit ]
 */
- (NSCalendarUnit) repeatInterval
{
    NSString* interval = [self valueForTriggerOption:@"every"];
    NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;

    if ([interval isEqualToString:@"minute"])
        return NSCalendarUnitSecond;

    if ([interval isEqualToString:@"hour"])
        return NSCalendarUnitMinute|NSCalendarUnitSecond;

    if ([interval isEqualToString:@"day"])
        return NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;

    if ([interval isEqualToString:@"week"])
        return NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;

    if ([interval isEqualToString:@"month"])
        return NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;

    if ([interval isEqualToString:@"year"])
        return NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;

    return units;
}

/**
 * The repeat interval for the notification.
 *
 * @return [ NSDateComponents* ]
 */
- (NSDateComponents*) customDateComponents
{
    NSDateComponents* date  = [[NSDateComponents alloc] init];
    NSDictionary* every     = [self valueForTriggerOption:@"every"];

    date.second = 0;

    for (NSString* key in every) {
        long value = [[every valueForKey:key] longValue];

        if ([key isEqualToString:@"minute"]) {
            date.minute = value;
        } else
        if ([key isEqualToString:@"hour"]) {
            date.hour = value;
        } else
        if ([key isEqualToString:@"day"]) {
            date.day = value;
        } else
        if ([key isEqualToString:@"weekday"]) {
            date.weekday = WEEKDAYS[value];
        } else
        if ([key isEqualToString:@"weekdayOrdinal"]) {
            date.weekdayOrdinal = value;
        } else
        if ([key isEqualToString:@"week"]) {
            date.weekOfYear = value;
        } else
        if ([key isEqualToString:@"weekOfMonth"]) {
            date.weekOfMonth = value;
        } else
        if ([key isEqualToString:@"month"]) {
            date.month = value;
        } else
        if ([key isEqualToString:@"quarter"]) {
            date.quarter = value;
        } else
        if ([key isEqualToString:@"year"]) {
            date.year = value;
        }
    }

    return date;
}

/**
 * Convert an assets path to an valid sound name attribute.
 *
 * @param [ NSString* ] path A relative assets file path.
 *
 * @return [ NSString* ]
 */
- (NSString*) soundNameForAsset:(NSString*)path
{
    return [path stringByReplacingOccurrencesOfString:@"file:/"
                                           withString:@"www"];
}

/**
 * Convert a ressource path to an valid sound name attribute.
 *
 * @param [ NSString* ] path A relative ressource file path.
 *
 * @return [ NSString* ]
 */
- (NSString*) soundNameForResource:(NSString*)path
{
    return [path pathComponents].lastObject;
}
