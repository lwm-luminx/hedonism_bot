package host.lumiere.chip

import android.app.Application
import host.lumiere.chip.data.AccountStore
import host.lumiere.chip.data.KeystoreTokenStore
import host.lumiere.chip.data.PhoneStaging
import host.lumiere.chip.location.LocationRecorder
import java.io.File

class ChipApplication : Application() {
    val locationRecorder by lazy { LocationRecorder(File(filesDir, "Chip-location-recordings.json")) }
    val accountStore by lazy { AccountStore(this) }
    val tokenStore by lazy { KeystoreTokenStore(this) }
    val phoneStaging by lazy { PhoneStaging(filesDir) }
}
