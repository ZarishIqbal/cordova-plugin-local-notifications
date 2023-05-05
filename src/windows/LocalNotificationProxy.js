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

var LocalNotification = LocalNotificationProxy.LocalNotification,
       ActivationKind = Windows.ApplicationModel.Activation.ActivationKind;

var impl  = new LocalNotificationProxy.LocalNotificationProxy(),
    queue = [],
    ready = false;

/**
 * Set launchDetails object.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 * @param [ Array ]    args    Interface arguments
 *
 * @return [ Void ]
 */
exports.launch = function (success, error, args) {
    var plugin = cordova.plugins.notification.local;

    if (args.length === 0 || plugin.launchDetails) return;

    plugin.launchDetails = { id: args[0], action: args[1] };
};
