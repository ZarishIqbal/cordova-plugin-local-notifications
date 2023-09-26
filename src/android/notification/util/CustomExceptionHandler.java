package de.appplant.cordova.plugin.notification.util;

import android.content.Context;
import android.util.Log;

public class CustomExceptionHandler implements Thread.UncaughtExceptionHandler {

  private Context context;

  public CustomExceptionHandler(Context context) {
    this.context = context;
  }

  @Override
  public void uncaughtException(Thread thread, Throwable throwable) {
    // Handle the uncaught exception here
    Log.e(
      "GlobalExceptionHandler",
      "Uncaught Exception: " + throwable.getMessage()
    );
    // You can perform actions like logging the error, sending a crash report, or restarting the app.

    // For example, you can restart the app by restarting the main activity:
    /*Intent intent = new Intent(context, YourMainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);*/

    // Terminate the current process to exit the app
    // android.os.Process.killProcess(android.os.Process.myPid());
    // System.exit(10);
  }
}
