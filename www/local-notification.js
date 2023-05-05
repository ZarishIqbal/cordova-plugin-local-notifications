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

var exec    = require('cordova/exec'),
    channel = require('cordova/channel');

// Defaults
exports._defaults = {
    actions       : [],
    attachments   : [],
    autoClear     : true,
    badge         : null,
    channel       : null,
    clock         : true,
    color         : null,
    data          : null,
    defaults      : 0,
    foreground    : null,
    group         : null,
    groupSummary  : false,
    icon          : null,
    iconType      : null,
    id            : 0,
    launch        : true,
    led           : true,
    lockscreen    : true,
    mediaSession  : null,
    number        : 0,
    priority      : 0,
    progressBar   : false,
    silent        : false,
    smallIcon     : 'res://icon',
    sound         : true,
    sticky        : false,
    summary       : null,
    text          : '',
    timeoutAfter  : false,
    title         : '',
    trigger       : { type : 'calendar' },
    vibrate       : false,
    wakeup        : true
};

// Event listener
exports._listener = {};

/**
 * Check permission to show notifications.
 *
 * @param [ Function ] callback The function to be exec as the callback.
 * @param [ Object ]   scope    The callback function's scope.
 *
 * @return [ Void ]
 */
exports.hasPermission = function (callback, scope) {
    this._exec('check', null, callback, scope);
};

/**
 * Request permission to show notifications.
 *
 * @param [ Function ] callback The function to be exec as the callback.
 * @param [ Object ]   scope    The callback function's scope.
 *
 * @return [ Void ]
 */
exports.requestPermission = function (callback, scope) {
    this._exec('request', null, callback, scope);
};

/**
 * Schedule notifications.
 *
 * @param [ Array ]    notifications The notifications to schedule.
 * @param [ Function ] callback      The function to be exec as the callback.
 * @param [ Object ]   scope         The callback function's scope.
 * @param [ Object ]   args          Optional flags how to schedule.
 *
 * @return [ Void ]
 */
exports.schedule = function (msgs, callback, scope, args) {
    var fn = function (granted) {
        var toasts = this._toArray(msgs);

        if (!granted && callback) {
            callback.call(scope || this, false);
            return;
        }

        for (var i = 0, len = toasts.length; i < len; i++) {
            var toast = toasts[i];
            this._mergeWithDefaults(toast);
            this._convertProperties(toast);
        }

        this._exec('schedule', toasts, callback, scope);
    };

    if (args && args.skipPermission) {
        fn.call(this, true);
    } else {
        this.requestPermission(fn, this);
    }
};

/**
 * Schedule notifications.
 *
 * @param [ Array ]    notifications The notifications to schedule.
 * @param [ Function ] callback      The function to be exec as the callback.
 * @param [ Object ]   scope         The callback function's scope.
 * @param [ Object ]   args          Optional flags how to schedule.
 *
 * @return [ Void ]
 */
exports.update = function (msgs, callback, scope, args) {
    var fn = function(granted) {
        var toasts = this._toArray(msgs);

        if (!granted && callback) {
            callback.call(scope || this, false);
            return;
        }

        for (var i = 0, len = toasts.length; i < len; i++) {
            this._convertProperties(toasts[i]);
        }

        this._exec('update', toasts, callback, scope);
    };
