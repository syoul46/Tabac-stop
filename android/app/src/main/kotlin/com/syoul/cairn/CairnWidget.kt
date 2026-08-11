package com.syoul.cairn

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews

/**
 * Widget d'écran d'accueil : le chrono depuis la dernière cigarette.
 *
 * Aucun plugin Flutter n'est utilisé — les candidats déclarent tous une
 * implémentation iOS et se seraient invités dans le build iOS, exactement le
 * problème qu'on vient de résoudre en retirant `open_filex` (cf. PLAN §17.4).
 * Flutter pousse ses données par le canal natif existant, on les range dans les
 * préférences, et le widget les relit.
 *
 * Le chrono est un [android.widget.Chronometer] : il **avance tout seul**. Un
 * texte figé serait périmé en quelques minutes, car Android ne rafraîchit les
 * widgets qu'au mieux toutes les 30 min.
 */
class CairnWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray,
    ) {
        ids.forEach { render(context, manager, it) }
    }

    companion object {
        const val PREFS = "cairn_widget"
        const val KEY_LAST_SMOKE = "last_smoke_at" // epoch ms, -1 si aucune
        const val KEY_TODAY = "today_count"

        /** Redessine toutes les instances posées sur l'écran d'accueil. */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, CairnWidget::class.java)
            )
            ids.forEach { render(context, manager, it) }
        }

        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val lastSmoke = prefs.getLong(KEY_LAST_SMOKE, -1L)
            val today = prefs.getInt(KEY_TODAY, -1)

            val views = RemoteViews(context.packageName, R.layout.cairn_widget)

            if (lastSmoke > 0) {
                // `Chronometer` compte depuis une base exprimée dans l'horloge
                // monotone du système : on convertit l'instant réel en écart.
                val elapsed = System.currentTimeMillis() - lastSmoke
                views.setChronometer(
                    R.id.widget_chrono,
                    SystemClock.elapsedRealtime() - elapsed,
                    "%s",
                    true,
                )
                views.setTextViewText(R.id.widget_label, "depuis la dernière")
            } else {
                views.setChronometer(R.id.widget_chrono, SystemClock.elapsedRealtime(), "%s", false)
                views.setTextViewText(R.id.widget_label, "tape quand tu fumes")
            }

            views.setTextViewText(
                R.id.widget_today,
                if (today >= 0) "$today aujourd’hui" else "",
            )

            // Un tap ouvre l'app — le widget informe, il ne fait rien d'autre.
            val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            if (open != null) {
                views.setOnClickPendingIntent(
                    R.id.widget_chrono,
                    PendingIntent.getActivity(
                        context, 0, open,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    ),
                )
            }

            manager.updateAppWidget(id, views)
        }
    }
}
