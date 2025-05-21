package emmanuelmuturia.arcane.dependencyInjection

import android.app.Application
import org.koin.android.ext.koin.androidContext
import org.koin.core.component.KoinComponent

class ArcaneApplication : Application(), KoinComponent {

    override fun onCreate() {
        super.onCreate()

        initKoin {
            androidContext(this@ArcaneApplication)
        }

    }

}