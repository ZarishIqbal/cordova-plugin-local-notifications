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
