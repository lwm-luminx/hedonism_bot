package host.lumiere.chip.data

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Where account credentials live. The app uses [KeystoreTokenStore]; tests use [MemoryTokenStore]. */
interface TokenStore {
    fun token(accountId: String): String?
    fun setToken(accountId: String, token: String?): Boolean
}

class MemoryTokenStore : TokenStore {
    private val tokens = mutableMapOf<String, String>()
    override fun token(accountId: String) = tokens[accountId]
    override fun setToken(accountId: String, token: String?): Boolean {
        if (token == null) tokens.remove(accountId) else tokens[accountId] = token
        return true
    }
}

/**
 * Encrypts each credential with an AES-GCM key that never leaves Android Keystore, the Android
 * counterpart of the iOS Keychain. The ciphertext is kept in private SharedPreferences, which are
 * excluded from backups because the key can't be restored on another device.
 */
class KeystoreTokenStore(context: Context) : TokenStore {
    private val prefs: SharedPreferences = context.getSharedPreferences("chip-credentials", Context.MODE_PRIVATE)

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (keyStore.getEntry(ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    override fun token(accountId: String): String? {
        val stored = prefs.getString(accountId, null) ?: return null
        return runCatching {
            val bytes = Base64.decode(stored, Base64.NO_WRAP)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes, 0, IV_LENGTH))
            String(cipher.doFinal(bytes, IV_LENGTH, bytes.size - IV_LENGTH))
        }.getOrNull()
    }

    override fun setToken(accountId: String, token: String?): Boolean = runCatching {
        if (token == null) return prefs.edit().remove(accountId).commit()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val sealed = cipher.iv + cipher.doFinal(token.toByteArray())
        prefs.edit().putString(accountId, Base64.encodeToString(sealed, Base64.NO_WRAP)).commit()
    }.getOrDefault(false)

    private companion object {
        const val KEYSTORE = "AndroidKeyStore"
        const val ALIAS = "chip-credentials"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val IV_LENGTH = 12
    }
}
