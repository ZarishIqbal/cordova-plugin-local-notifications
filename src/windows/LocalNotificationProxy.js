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

/**
 * To execute all queued events.
 *
 * @return [ Void ]
 */
exports.ready = function () {
    ready = true;

    for (var item of queue) {
        exports.fireEvent.apply(exports, item);
    }

    queue = [];
};

/**
 * Check permission to show notifications.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 *
 * @return [ Void ]
 */
exports.check = function (success, error) {
    var granted = impl.hasPermission();
    success(granted);
};

/**
 * Request permission to show notifications.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 *
 * @return [ Void ]
 */
exports.request = function (success, error) {
    exports.check(success, error);
};

/**
 * Schedule notifications.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 * @param [ Array ]    args    Interface arguments
 *
 * @return [ Void ]
 */
exports.schedule = function (success, error, args) {
    var options = [];

    for (var props of args) {
        opts  = exports.parseOptions(props);
        options.push(opts);
    }

    impl.schedule(options);

    for (var toast of options) {
        exports.fireEvent('add', toast);
    }

    exports.check(success, error);
};

/**
 * Update notifications.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 * @param [ Array ]    args    Interface arguments
 *
 * @return [ Void ]
 */
exports.update = function (success, error, args) {
    var options = [];

    for (var props of args) {
        opts  = exports.parseOptions(props);
        options.push(opts);
    }

    impl.update(options);

    for (var toast of options) {
        exports.fireEvent('update', toast);
    }

    exports.check(success, error);
};

/**
 * Clear the notifications specified by id.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 * @param [ Array ]    args    Interface arguments
 *
 * @return [ Void ]
 */
exports.clear = function (success, error, args) {
    var toasts = impl.clear(args) || [];

    for (var toast of toasts) {
        exports.fireEvent('clear', toast);
    }

    success();
};

/**
 * Clear all notifications.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 *
 * @return [ Void ]
 */
exports.clearAll = function (success, error) {
    impl.clearAll();
    exports.fireEvent('clearall');
    success();
};

/**
 * Cancel the notifications specified by id.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 * @param [ Array ]    args    Interface arguments
 *
 * @return [ Void ]
 */
exports.cancel = function (success, error, args) {
    var toasts = impl.cancel(args) || [];

    for (var toast of toasts) {
        exports.fireEvent('cancel', toast);
    }

    success();
};

/**
 * Cancel all notifications.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 *
 * @return [ Void ]
 */
exports.cancelAll = function (success, error) {
    impl.cancelAll();
    exports.fireEvent('cancelall');
    success();
};

/**
 * Get the type of notification.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 * @param [ Array ]    args    Interface arguments
 *
 * @return [ Void ]
 */
exports.type = function (success, error, args) {
    var type = impl.type(args[0]);
    success(type);
};

/**
 * List of all notification ids.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 * @param [ Array ]    args    Interface arguments
 *
 * @return [ Void ]
 */
exports.ids = function (success, error, args) {
    var ids = impl.ids(args[0]) || [];
    success(Array.from(ids));
};

/**
 * Get a single notification by id.
 *
 * @param [ Function ] success Success callback
 * @param [ Function ] error   Error callback
 * @param [ Array ]    args    Interface arguments
 *
 * @return [ Void ]
 */
exports.notification = function (success, error, args) {
    var obj = impl.notification(args[0]);
    success(exports.clone(obj));
};
