package com.codex.basketpet;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.SystemClock;
import android.provider.Settings;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.Toast;

public final class PetOverlayService extends Service {
    private static final int FRAME_COUNT = 120;
    private static final long FRAME_MS = 67L;
    private static final int NOTIFICATION_ID = 120;
    private static final String CHANNEL_ID = "basket_pet_running";

    private WindowManager windowManager;
    private WindowManager.LayoutParams windowParams;
    private FrameLayout overlay;
    private ImageView image;
    private Drawable[] danceFrames;
    private Drawable[] basketballFrames;
    private boolean basketballMode = false;
    private long modeStart = 0L;
    private int displayedFrame = -1;
    private final Handler handler = new Handler(Looper.getMainLooper());

    private final Runnable animator = new Runnable() {
        @Override
        public void run() {
            renderFrame();
            handler.postDelayed(this, 16L);
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        startForeground(NOTIFICATION_ID, buildNotification());

        if (!Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "请先授予悬浮窗权限", Toast.LENGTH_LONG).show();
            stopSelf();
            return;
        }

        danceFrames = loadFrames("dance");
        basketballFrames = loadFrames("basketball");
        createOverlay();
        modeStart = SystemClock.uptimeMillis();
        handler.post(animator);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (overlay == null && Settings.canDrawOverlays(this)) {
            danceFrames = loadFrames("dance");
            basketballFrames = loadFrames("basketball");
            createOverlay();
            modeStart = SystemClock.uptimeMillis();
            handler.removeCallbacks(animator);
            handler.post(animator);
        }
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacks(animator);
        if (overlay != null && windowManager != null) {
            windowManager.removeView(overlay);
            overlay = null;
        }
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private Drawable[] loadFrames(String prefix) {
        Drawable[] frames = new Drawable[FRAME_COUNT];
        for (int index = 1; index <= FRAME_COUNT; index++) {
            String name = String.format("%s_%03d", prefix, index);
            int resource = getResources().getIdentifier(name, "drawable", getPackageName());
            frames[index - 1] = getDrawable(resource);
        }
        return frames;
    }

    private void createOverlay() {
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        int width = dp(140);
        int height = dp(183);
        int type = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
            ? WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            : WindowManager.LayoutParams.TYPE_PHONE;

        windowParams = new WindowManager.LayoutParams(
            width,
            height,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        );
        windowParams.gravity = Gravity.TOP | Gravity.START;
        windowParams.x = getResources().getDisplayMetrics().widthPixels - width - dp(12);
        windowParams.y = getResources().getDisplayMetrics().heightPixels - height - dp(120);

        overlay = new FrameLayout(this);
        overlay.setBackgroundColor(android.graphics.Color.TRANSPARENT);
        image = new ImageView(this);
        image.setScaleType(ImageView.ScaleType.FIT_CENTER);
        overlay.addView(image, new FrameLayout.LayoutParams(width, height));
        overlay.setOnTouchListener(new PetTouchListener());
        windowManager.addView(overlay, windowParams);
    }

    private void renderFrame() {
        if (image == null) {
            return;
        }
        int frame = (int) (((SystemClock.uptimeMillis() - modeStart) / FRAME_MS) % FRAME_COUNT);
        if (frame == displayedFrame) {
            return;
        }
        displayedFrame = frame;
        image.setImageDrawable((basketballMode ? basketballFrames : danceFrames)[frame]);
    }

    private void toggleMode() {
        basketballMode = !basketballMode;
        modeStart = SystemClock.uptimeMillis();
        displayedFrame = -1;
        renderFrame();
        Toast.makeText(
            this,
            basketballMode ? "篮球运球模式" : "只因你太美舞蹈模式",
            Toast.LENGTH_SHORT
        ).show();
    }

    private final class PetTouchListener implements View.OnTouchListener {
        private float downRawX;
        private float downRawY;
        private int startX;
        private int startY;
        private boolean dragged;

        @Override
        public boolean onTouch(View view, MotionEvent event) {
            switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                downRawX = event.getRawX();
                downRawY = event.getRawY();
                startX = windowParams.x;
                startY = windowParams.y;
                dragged = false;
                return true;
            case MotionEvent.ACTION_MOVE:
                int dx = Math.round(event.getRawX() - downRawX);
                int dy = Math.round(event.getRawY() - downRawY);
                if (Math.abs(dx) >= dp(4) || Math.abs(dy) >= dp(4)) {
                    dragged = true;
                }
                windowParams.x = startX + dx;
                windowParams.y = startY + dy;
                windowManager.updateViewLayout(overlay, windowParams);
                return true;
            case MotionEvent.ACTION_UP:
                if (!dragged) {
                    toggleMode();
                }
                return true;
            default:
                return false;
            }
        }
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "桌宠运行状态",
                NotificationManager.IMPORTANCE_LOW
            );
            getSystemService(NotificationManager.class).createNotificationChannel(channel);
        }
    }

    private Notification buildNotification() {
        Intent open = new Intent(this, MainActivity.class);
        PendingIntent pending = PendingIntent.getActivity(
            this,
            0,
            open,
            PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
        );
        Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
            ? new Notification.Builder(this, CHANNEL_ID)
            : new Notification.Builder(this);
        return builder
            .setContentTitle("只因你太美桌宠正在运行")
            .setContentText("打开应用可关闭悬浮桌宠")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pending)
            .setOngoing(true)
            .build();
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
