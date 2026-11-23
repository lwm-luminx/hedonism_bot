package host.lumiere.chip.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import host.lumiere.chip.R
import host.lumiere.chip.core.PendingArchiveChoice
import host.lumiere.chip.core.ServiceEndpoints

/** The branded sign-in page: Facebook first, device code as the alternative, then the archive picker. */
@Composable
fun SignInScreen(state: ChipState, actions: ChipActions, onCancel: (() -> Unit)? = null, startWithDeviceCode: Boolean = false) {
    var server by rememberSaveable { mutableStateOf(ServiceEndpoints.API) }
    var deviceCode by rememberSaveable { mutableStateOf("") }
    var usingDeviceCode by rememberSaveable { mutableStateOf(startWithDeviceCode) }
    var advanced by rememberSaveable { mutableStateOf(false) }

    Column(
        Modifier.fillMaxSize().background(ChipBrand.ink).safeDrawingPadding().imePadding()
            .verticalScroll(rememberScrollState()).padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (onCancel != null) {
            Row(Modifier.fillMaxWidth()) {
                TextButton(onClick = onCancel, enabled = !state.signingIn) { Text("Cancel") }
            }
        }
        Spacer(Modifier.height(if (onCancel == null) 44.dp else 8.dp))
        Image(painterResource(R.drawable.lumiere_brand), contentDescription = null, Modifier.size(100.dp))
        Spacer(Modifier.height(12.dp))
        Text("Chip", fontSize = 48.sp, fontFamily = FontFamily.Serif, fontWeight = FontWeight.Medium)
        Text("BY LUMIÈRE", style = MaterialTheme.typography.labelMedium, color = ChipBrand.gold, letterSpacing = 4.sp, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(36.dp))

        Column(Modifier.widthIn(max = 520.dp).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            val choice = state.pendingArchiveChoice
            when {
                choice != null -> ArchivePicker(choice, state.signingIn, actions)
                usingDeviceCode -> {
                    OutlinedTextField(
                        value = deviceCode, onValueChange = { deviceCode = it }, label = { Text("Device code") },
                        singleLine = true, textStyle = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.Monospace),
                        keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Characters, autoCorrectEnabled = false),
                        modifier = Modifier.fillMaxWidth().testTag("deviceCodeField"),
                    )
                    Text("One-time code · expires in 10 minutes", style = MaterialTheme.typography.bodySmall, color = ChipBrand.muted)
                    PrimaryButton("Sign in with device code", enabled = deviceCode.isNotBlank() && !state.signingIn) {
                        actions.signInWithDeviceCode(server, deviceCode)
                    }
                }
                else -> PrimaryButton("Continue with Facebook", enabled = !state.signingIn) { actions.signInWithFacebook(server) }
            }
            if (state.signingIn) {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.testTag("signInProgress")) {
                    CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                    Spacer(Modifier.size(12.dp))
                    Text("Signing in…")
                }
            }
            state.accountError?.let { Text(it, color = MaterialTheme.colorScheme.error, modifier = Modifier.testTag("signInError")) }
        }

        if (state.pendingArchiveChoice == null) {
            TextButton(
                onClick = { usingDeviceCode = !usingDeviceCode; actions.clearAccountError() },
                enabled = !state.signingIn, modifier = Modifier.testTag("switchSignInMethod"),
            ) { Text(if (usingDeviceCode) "Sign in with Facebook" else "or sign in with device code") }
        }

        Spacer(Modifier.height(16.dp))
        Column(Modifier.widthIn(max = 520.dp).fillMaxWidth()) {
            Text(
                (if (advanced) "▾ " else "▸ ") + "Server",
                style = MaterialTheme.typography.bodySmall, color = ChipBrand.muted,
                modifier = Modifier.clickable(enabled = !state.signingIn) { advanced = !advanced }.padding(vertical = 8.dp),
            )
            if (advanced) {
                OutlinedTextField(
                    value = server, onValueChange = { server = it }, label = { Text("Server URL") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri, autoCorrectEnabled = false),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}

@Composable
private fun ArchivePicker(choice: PendingArchiveChoice, signingIn: Boolean, actions: ChipActions) {
    Text("Choose an archive", style = MaterialTheme.typography.titleMedium)
    for (archive in choice.archives) {
        Row(
            Modifier.fillMaxWidth().background(ChipBrand.card, RoundedCornerShape(12.dp))
                .clickable(enabled = !signingIn) { actions.chooseArchive(archive) }
                .padding(16.dp).testTag("archive-" + archive.subdomain),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(archive.name, fontWeight = FontWeight.SemiBold)
                Text(archive.subdomain, style = MaterialTheme.typography.bodySmall, color = ChipBrand.muted)
            }
            Text("›", color = ChipBrand.muted, fontSize = 22.sp)
        }
    }
    TextButton(onClick = actions::cancelArchiveChoice, enabled = !signingIn) { Text("Cancel") }
}

@Composable
fun PrimaryButton(title: String, enabled: Boolean = true, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Button(
        onClick = onClick, enabled = enabled, modifier = modifier.fillMaxWidth().height(52.dp),
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(containerColor = ChipBrand.gold, contentColor = ChipBrand.ink),
    ) { Text(title, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center) }
}
