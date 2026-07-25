package com.codex.basketpet;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public final class MainActivity extends Activity {
    private static final int OVERLAY_REQUEST = 120;
    private static final int NOTIFICATION_REQUEST = 121;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(createContent());
        requestNotificationPermissionIfNeeded();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (Settings.canDrawOverlays(this)) {
            startPet();
        }
    }

    private LinearLayout createContent() {
        int padding = dp(24);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setGravity(Gravity.CENTER_HORIZONTAL);
        layout.setPadding(padding, padding, padding, padding);
        layout.setBackgroundColor(Color.rgb(248, 250, 252));

        TextView title = new TextView(this);
        title.setText("只因你太美桌宠");
        title.setTextSize(26);
        title.setTextColor(Color.rgb(17, 24, 39));
        title.setGravity(Gravity.CENTER);
        layout.addView(title, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ));

        TextView instructions = new TextView(this);
        instructions.setText(
            "\n• 单击人物：切换舞蹈和篮球\n" +
            "• 按住拖动：移动桌宠\n" +
            "• 两种模式各 120 帧、15 FPS\n" +
            "• 不读取或跟随鼠标方向\n"
        );
        instructions.setTextSize(16);
        instructions.setTextColor(Color.rgb(55, 65, 81));
        layout.addView(instructions, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ));

        Button start = new Button(this);
        start.setText("启动悬浮桌宠");
        start.setOnClickListener(view -> ensureOverlayAndStart());
        layout.addView(start, buttonParams());

        Button stop = new Button(this);
        stop.setText("关闭悬浮桌宠");
        stop.setOnClickListener(view -> stopService(new Intent(this, PetOverlayService.class)));
        layout.addView(stop, buttonParams());
        return layout;
    }

    private LinearLayout.LayoutParams buttonParams() {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(54)
        );
        params.topMargin = dp(14);
        return params;
    }

    private void ensureOverlayAndStart() {
        if (!Settings.canDrawOverlays(this)) {
            Intent intent = new Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:" + getPackageName())
            );
            startActivityForResult(intent, OVERLAY_REQUEST);
            Toast.makeText(this, "请允许“显示在其他应用上层”", Toast.LENGTH_LONG).show();
            return;
        }
        startPet();
    }

    private void startPet() {
        Intent service = new Intent(this, PetOverlayService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(service);
        } else {
            startService(service);
        }
    }

    private void requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(
                new String[]{Manifest.permission.POST_NOTIFICATIONS},
                NOTIFICATION_REQUEST
            );
        }
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
