package com.syoul.cairn

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Remplace le plugin `open_filex`, qui ne servait qu'ici — ouvrir l'APK
 * téléchargé pour le passer à l'installeur système — mais déclarait une
 * implémentation iOS, donc s'invitait dans tous les builds iOS et bloquait la
 * migration vers Swift Package Manager (cf. PLAN §17.4).
 *
 * iOS n'a rien à faire de ce code : là-bas, aucune installation hors App Store
 * n'est possible, et `downloadAndInstall` s'arrête sur sa garde `Platform.isAndroid`.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("no_path", "Chemin de l'APK manquant.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            openApk(File(path))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("open_failed", e.message, null)
                        }
                    }
                    // Alimente le widget d'écran d'accueil. On range les
                    // données brutes (instant + compte) et non un texte : le
                    // widget doit rester juste sans que l'app tourne.
                    "updateWidget" -> {
                        val prefs = getSharedPreferences(
                            CairnWidget.PREFS, MODE_PRIVATE
                        )
                        prefs.edit()
                            .putLong(
                                CairnWidget.KEY_LAST_SMOKE,
                                call.argument<Number>("lastSmokeAt")?.toLong() ?: -1L,
                            )
                            .putInt(
                                CairnWidget.KEY_TODAY,
                                call.argument<Number>("todayCount")?.toInt() ?: -1,
                            )
                            .apply()
                        CairnWidget.refreshAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Le fichier vit dans le cache privé de l'app : on ne peut pas passer un
     * `file://` à l'installeur (Android 7+ le refuse). Il faut une URI de
     * FileProvider **et** accorder explicitement la lecture au processus qui
     * recevra l'intent.
     */
    private fun openApk(apk: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, APK_MIME)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private companion object {
        const val CHANNEL = "cairn/installer"
        const val APK_MIME = "application/vnd.android.package-archive"
    }
}
