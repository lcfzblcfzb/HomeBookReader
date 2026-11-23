package com.homepdfreader.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Rect
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import kotlin.math.roundToInt
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(currentStatus())
                    "root" -> result.success(Environment.getExternalStorageDirectory().absolutePath)
                    "request" -> requestAccess(result)
                    else -> result.notImplemented()
                }
            }
        // 书签入口贴在右侧边、与系统返回手势的排除区：Dart 侧已按 200dp 预算裁剪，
        // 这里只做 dp→px 转换与屏幕边界兜底。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setExclusionRects" ->
                        applyGestureExclusionRects(call.argument<List<*>>("rects"), result)
                    "clearExclusionRects" -> {
                        applyGestureExclusionRects(emptyList<Any>(), result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// 把逻辑像素（dp）矩形转成物理像素后上报给系统。
    private fun applyGestureExclusionRects(raw: List<*>?, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            // Android 10 以下没有系统手势排除区。
            result.success(null)
            return
        }
        val density = resources.displayMetrics.density
        val width = resources.displayMetrics.widthPixels
        val height = resources.displayMetrics.heightPixels
        val rects = raw.orEmpty().mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val left = (map["left"] as? Number)?.toDouble() ?: return@mapNotNull null
            val top = (map["top"] as? Number)?.toDouble() ?: return@mapNotNull null
            val right = (map["right"] as? Number)?.toDouble() ?: return@mapNotNull null
            val bottom = (map["bottom"] as? Number)?.toDouble() ?: return@mapNotNull null
            val rect = Rect(
                (left * density).roundToInt(),
                (top * density).roundToInt(),
                (right * density).roundToInt(),
                (bottom * density).roundToInt(),
            )
            if (rect.intersect(0, 0, width, height)) rect else null
        }
        window.decorView.systemGestureExclusionRects = rects
        Log.d("GestureExclusion", "set rects=$rects density=$density display=${width}x${height}")
        result.success(null)
    }

    private fun hasAllFilesAccess(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && Environment.isExternalStorageManager()

    private fun hasReadStorage(): Boolean = ContextCompat.checkSelfPermission(
        this,
        Manifest.permission.READ_EXTERNAL_STORAGE,
    ) == PackageManager.PERMISSION_GRANTED

    private fun currentStatus(): String = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ->
            if (hasAllFilesAccess()) "granted" else "denied"
        else ->
            if (hasReadStorage()) "granted" else "denied"
    }

    private fun requestAccess(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ 没有普通运行时弹窗，只能跳到系统「所有文件访问权限」页。
            val grantedIntent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                data = Uri.parse("package:$packageName")
            }
            try {
                startActivity(grantedIntent)
                result.success("settings")
            } catch (_: Exception) {
                try {
                    startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
                    result.success("settings")
                } catch (error: Exception) {
                    result.error("no_settings", error.message, null)
                }
            }
            return
        }

        if (hasReadStorage()) {
            result.success("granted")
            return
        }
        pendingPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE), REQUEST_READ_STORAGE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_READ_STORAGE) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(if (granted) "granted" else "denied")
        pendingPermissionResult = null
    }

    companion object {
        private const val CHANNEL = "homepdfreader/storage_access"
        private const val GESTURE_CHANNEL = "homepdfreader/gesture_exclusion"
        private const val REQUEST_READ_STORAGE = 4201
    }
}
