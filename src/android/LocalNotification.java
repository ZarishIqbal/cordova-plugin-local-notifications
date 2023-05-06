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

// codebeat:disable[TOO_MANY_FUNCTIONS]

package de.appplant.cordova.plugin.localnotification;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.util.Pair;
import android.view.View;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

import de.appplant.cordova.plugin.notification.Manager;
import de.appplant.cordova.plugin.notification.Notification;
import de.appplant.cordova.plugin.notification.Options;
import de.appplant.cordova.plugin.notification.Request;
import de.appplant.cordova.plugin.notification.action.ActionGroup;

import static de.appplant.cordova.plugin.notification.Notification.Type.SCHEDULED;
import static de.appplant.cordova.plugin.notification.Notification.Type.TRIGGERED;

/**
 * This plugin utilizes the Android AlarmManager in combination with local
 * notifications. When a local notification is scheduled the alarm manager takes
 * care of firing the event. When the event is processed, a notification is put
 * in the Android notification center and status bar.
 */
@SuppressWarnings({"Convert2Diamond", "Convert2Lambda"})
public class LocalNotification extends CordovaPlugin {

    // Reference to the web view for static access
    private static WeakReference<CordovaWebView> webView = null;

    // Indicates if the device is ready (to receive events)
    private static Boolean deviceready = false;

    // Queues all events before deviceready
    private static ArrayList<String> eventQueue = new ArrayList<String>();

    // Launch details
    private static Pair<Integer, String> launchDetails;

    /**
     * Called after plugin construction and fields have been initialized.
     * Prefer to use pluginInitialize instead since there is no value in
     * having parameters on the initialize() function.
     */
    @Override
    public void initialize (CordovaInterface cordova, CordovaWebView webView) {
        LocalNotification.webView = new WeakReference<CordovaWebView>(webView);
    }

    /**
     * Called when the activity will start interacting with the user.
     *
     * @param multitasking Flag indicating if multitasking is turned on for app.
     */
    @Override
    public void onResume (boolean multitasking) {
        super.onResume(multitasking);
        deviceready();
    }

    /**
     * The final call you receive before your activity is destroyed.
     */
    @Override
    public void onDestroy() {
        deviceready = false;
    }

    /**
     * Executes the request.
     *
     * This method is called from the WebView thread. To do a non-trivial
     * amount of work, use:
     *      cordova.getThreadPool().execute(runnable);
     *
     * To run on the UI thread, use:
     *     cordova.getActivity().runOnUiThread(runnable);
     *
     * @param action  The action to execute.
     * @param args    The exec() arguments in JSON form.
     * @param command The callback context used when calling back into
     *                JavaScript.
     *
     * @return Whether the action was valid.
     */
    @Override
    public boolean execute (final String action, final JSONArray args,
                            final CallbackContext command) throws JSONException {

        if (action.equals("launch")) {
            launch(command);
            return true;
        }

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                if (action.equals("ready")) {
                    deviceready();
                } else
                if (action.equals("check")) {
                    check(command);
                } else
                if (action.equals("request")) {
                    request(command);
                } else
                if (action.equals("actions")) {
                    actions(args, command);
                } else
                if (action.equals("schedule")) {
                    schedule(args, command);
                } else
                if (action.equals("update")) {
                    update(args, command);
                } else
                if (action.equals("cancel")) {
                    cancel(args, command);
                } else
                if (action.equals("cancelAll")) {
                    cancelAll(command);
                } else
                if (action.equals("clear")) {
                    clear(args, command);
                } else
                if (action.equals("clearAll")) {
                    clearAll(command);
                } else
                if (action.equals("type")) {
                    type(args, command);
                } else
                if (action.equals("ids")) {
                    ids(args, command);
                } else
                if (action.equals("notification")) {
                    notification(args, command);
                } else
                if (action.equals("notifications")) {
                    notifications(args, command);
                }
            }
        });

        return true;
    }

    /**
     * Set launchDetails object.
     *
     * @param command The callback context used when calling back into
     *                JavaScript.
     */
    @SuppressLint("DefaultLocale")
    private void launch(CallbackContext command) {
        if (launchDetails == null)
            return;

        JSONObject details = new JSONObject();

        try {
            details.put("id", launchDetails.first);
            details.put("action", launchDetails.second);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        command.success(details);

        launchDetails = null;
    }

    /**
     * Ask if user has enabled permission for local notifications.
     *
     * @param command The callback context used when calling back into
     *                JavaScript.
     */
    private void check (CallbackContext command) {
        boolean allowed = getNotMgr().hasPermission();
        success(command, allowed);
    }

    /**
     * Request permission for local notifications.
     *
     * @param command The callback context used when calling back into
     *                JavaScript.
     */
    private void request (CallbackContext command) {
        check(command);
    }

    /**
     * Register action group.
     *
     * @param args    The exec() arguments in JSON form.
     * @param command The callback context used when calling back into
     *                JavaScript.
     */
    private void actions (JSONArray args, CallbackContext command) {
        int task        = args.optInt(0);
        String id       = args.optString(1);
        JSONArray list  = args.optJSONArray(2);
        Context context = cordova.getActivity();

        switch (task) {
            case 0:
                ActionGroup group = ActionGroup.parse(context, id, list);
                ActionGroup.register(group);
                command.success();
                break;
            case 1:
                ActionGroup.unregister(id);
                command.success();
                break;
            case 2:
                boolean found = ActionGroup.isRegistered(id);
                success(command, found);
                break;
        }
    }

    /**
     * Schedule multiple local notifications.
     *
     * @param toasts  The notifications to schedule.
     * @param command The callback context used when calling back into
     *                JavaScript.
     */
    private void schedule (JSONArray toasts, CallbackContext command) {
        Manager mgr = getNotMgr();

        for (int i = 0; i < toasts.length(); i++) {
            JSONObject dict    = toasts.optJSONObject(i);
            Options options    = new Options(dict);
            Request request    = new Request(options);
            Notification toast = mgr.schedule(request, TriggerReceiver.class);

            if (toast != null) {
                fireEvent("add", toast);
            }
        }

        check(command);
    }
