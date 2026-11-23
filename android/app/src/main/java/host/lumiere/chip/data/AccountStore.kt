package host.lumiere.chip.data

import android.content.Context
import android.content.SharedPreferences
import host.lumiere.chip.core.BrowserSignIn
import host.lumiere.chip.core.UploadAccount
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.io.File

/** Saved accounts, the selected account and the browser sign-in in flight. Credentials are in [TokenStore]. */
class AccountStore(private val prefs: SharedPreferences, private val filesDir: File) {
    constructor(context: Context) : this(context.getSharedPreferences("chip", Context.MODE_PRIVATE), context.filesDir)

    var accounts: List<UploadAccount>
        get() = prefs.getString(ACCOUNTS, null)
            ?.let { runCatching { Json.decodeFromString(ListSerializer(UploadAccount.serializer()), it) }.getOrNull() }
            ?: emptyList()
        set(value) { prefs.edit().putString(ACCOUNTS, Json.encodeToString(ListSerializer(UploadAccount.serializer()), value)).apply() }

    var selectedId: String?
        get() = prefs.getString(SELECTED, null)
        set(value) { prefs.edit().putString(SELECTED, value).apply() }

    /** Kept across process death: Android may kill Chip while the browser is in front. */
    var browserSignIn: BrowserSignIn?
        get() {
            val server = prefs.getString("browser.server", null) ?: return null
            val verifier = prefs.getString("browser.verifier", null) ?: return null
            val state = prefs.getString("browser.state", null) ?: return null
            return BrowserSignIn(server, verifier, state)
        }
        set(value) {
            prefs.edit().apply {
                if (value == null) {
                    remove("browser.server"); remove("browser.verifier"); remove("browser.state")
                } else {
                    putString("browser.server", value.server); putString("browser.verifier", value.verifier); putString("browser.state", value.state)
                }
            }.apply()
        }

    /** Upload history is isolated per destination, as on iOS. */
    fun ledgerFile(account: UploadAccount) = File(filesDir, "HedonismUploader/accounts/${account.id}.json")

    private companion object {
        const val ACCOUNTS = "uploadAccounts"
        const val SELECTED = "selectedAccount"
    }
}
