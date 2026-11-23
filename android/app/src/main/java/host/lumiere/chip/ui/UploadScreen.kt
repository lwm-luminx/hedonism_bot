package host.lumiere.chip.ui

import android.text.format.Formatter
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import host.lumiere.chip.core.ServiceEndpoints

/** The upload screen: account, shoot details, shoot location, photos and the files to upload. */
@Composable
fun UploadScreen(state: ChipState, actions: ChipActions, onAddAccount: () -> Unit) {
    val context = LocalContext.current
    LazyColumn(
        Modifier.fillMaxSize().background(ChipBrand.ink).safeDrawingPadding().imePadding().testTag("uploadScreen"),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        item {
            Column(Modifier.widthIn(max = 640.dp).fillMaxWidth().padding(top = 8.dp, bottom = 4.dp)) {
                Text("Chip by Lumière", fontSize = 30.sp, fontFamily = FontFamily.Serif, fontWeight = FontWeight.Medium)
            }
        }
        item {
            Section("Upload account") {
                AccountPicker(state, actions)
                state.selectedAccount?.let { Text(it.host, style = MaterialTheme.typography.bodySmall, color = ChipBrand.muted) }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(onClick = onAddAccount, enabled = !state.running) { Text("Add account") }
                    TextButton(onClick = actions::signOut, enabled = !state.running && state.selectedAccount != null) {
                        Text("Sign out", color = MaterialTheme.colorScheme.error)
                    }
                }
                val server = state.selectedAccount?.server ?: ServiceEndpoints.API
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    LinkText("Privacy policy") { actions.openLink(ServiceEndpoints.privacy(server)) }
                    LinkText("Delete my account and data") { actions.openLink(ServiceEndpoints.dataDeletion(server)) }
                }
            }
        }
        item {
            Section("Shoot details") {
                Field("Album", state.album, actions::setAlbum, !state.running, "albumField")
                Field("Event", state.event, actions::setEvent, !state.running, "eventField")
                Field("Venue", state.venue, actions::setVenue, !state.running, "venueField")
            }
        }
        item { LocationSection(state, actions) }
        item {
            Section("Photos") {
                OutlinedButton(onClick = actions::pickFolder, enabled = !state.running, modifier = Modifier.fillMaxWidth().testTag("pickFolder")) {
                    Text("Select card / DCIM folder")
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                    if (state.cameraAvailable) {
                        OutlinedButton(onClick = actions::takePhoto, enabled = !state.running && !state.importing, modifier = Modifier.weight(1f)) {
                            Text("Take photo")
                        }
                    }
                    OutlinedButton(onClick = actions::pickPhotos, enabled = !state.running && !state.importing, modifier = Modifier.weight(1f)) {
                        Text(if (state.importing) "Adding photos…" else "Photo library")
                    }
                }
                if (!state.running && state.phonePhotoCount > 0) {
                    TextButton(onClick = actions::removePhonePhotos) {
                        val n = state.phonePhotoCount
                        Text("Remove $n phone photo${if (n == 1) "" else "s"}", color = MaterialTheme.colorScheme.error)
                    }
                }
                Text(state.status, modifier = Modifier.testTag("uploadStatus"))
                val progress = state.progress
                if (progress != null && progress.totalFiles > 0) {
                    LinearProgressIndicator(
                        progress = { (progress.uploadedFiles + progress.failedFiles).toFloat() / progress.totalFiles },
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Text(progress.currentFile ?: "", style = MaterialTheme.typography.bodySmall, color = ChipBrand.muted)
                }
                if (state.running) {
                    OutlinedButton(onClick = actions::cancelUpload, modifier = Modifier.fillMaxWidth().testTag("cancelUpload")) {
                        Text("Cancel", color = MaterialTheme.colorScheme.error)
                    }
                } else {
                    PrimaryButton("Upload new files", enabled = state.canUpload, modifier = Modifier.testTag("uploadButton"), onClick = actions::upload)
                }
            }
        }
        if (state.files.isNotEmpty()) {
            item { SectionTitle("Files to upload") }
            items(state.files, key = { it.name + it.size }) { file ->
                Row(Modifier.widthIn(max = 640.dp).fillMaxWidth().padding(horizontal = 4.dp)) {
                    Text(file.name, Modifier.weight(1f))
                    Text(Formatter.formatShortFileSize(context, file.size), color = ChipBrand.muted)
                }
                HorizontalDivider(Modifier.widthIn(max = 640.dp).padding(top = 8.dp), color = ChipBrand.card)
            }
        }
    }
}

@Composable
private fun LocationSection(state: ChipState, actions: ChipActions) {
    var expanded by rememberSaveable { mutableStateOf(false) }
    val location = state.location
    Section("Shoot location") {
        Text(
            (if (expanded || location.recording) "▾ " else "▸ ") +
                if (location.recording) "Recording your shoot location" else "Record shoot location",
            modifier = Modifier.fillMaxWidth().clickable { expanded = !expanded }.padding(vertical = 4.dp),
            color = if (location.recording) ChipBrand.gold else MaterialTheme.colorScheme.onSurface,
        )
        if (expanded || location.recording) {
            Text(location.status, style = MaterialTheme.typography.bodyMedium)
            OutlinedButton(
                onClick = { if (location.recording) actions.stopRecording() else actions.startRecording() },
                modifier = Modifier.fillMaxWidth().testTag("recordLocation"),
            ) { Text(if (location.recording) "Stop recording location" else "Start recording location") }
            Text(
                "${location.sampleCount} saved samples. History accompanies uploads from this phone. Camera time must match phone time.",
                style = MaterialTheme.typography.bodySmall, color = ChipBrand.muted,
            )
            TextButton(onClick = actions::deleteRecordings, enabled = !state.running && location.recordings.isNotEmpty()) {
                Text("Delete saved location history", color = MaterialTheme.colorScheme.error)
            }
        }
    }
}

@Composable
private fun AccountPicker(state: ChipState, actions: ChipActions) {
    var open by rememberSaveable { mutableStateOf(false) }
    Box {
        val selected = state.selectedAccount
        Row(
            Modifier.fillMaxWidth().background(ChipBrand.ink, RoundedCornerShape(10.dp))
                .clickable(enabled = !state.running && state.accounts.size > 1) { open = true }
                .padding(14.dp).testTag("uploadAccountPicker"),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(selected?.let { "${it.name} · ${it.subdomain}" } ?: "Sign in to choose where your photos go.", Modifier.weight(1f))
            if (state.accounts.size > 1) Text("▾", color = ChipBrand.gold)
        }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            for (account in state.accounts) {
                DropdownMenuItem(text = { Text("${account.name} · ${account.subdomain}") }, onClick = { open = false; actions.selectAccount(account.id) })
            }
        }
    }
}

@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    Column(Modifier.widthIn(max = 640.dp).fillMaxWidth()) {
        SectionTitle(title)
        Spacer(Modifier.height(8.dp))
        Column(
            Modifier.fillMaxWidth().background(ChipBrand.card, RoundedCornerShape(16.dp)).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) { content() }
    }
}

@Composable
private fun SectionTitle(title: String) {
    Text(
        title.uppercase(), style = MaterialTheme.typography.labelMedium, color = ChipBrand.muted, letterSpacing = 1.5.sp,
        modifier = Modifier.widthIn(max = 640.dp).fillMaxWidth().padding(start = 4.dp),
    )
}

@Composable
private fun Field(label: String, value: String, onChange: (String) -> Unit, enabled: Boolean, tag: String) {
    OutlinedTextField(value = value, onValueChange = onChange, label = { Text(label) }, enabled = enabled, singleLine = true,
        modifier = Modifier.fillMaxWidth().testTag(tag))
}

@Composable
private fun LinkText(text: String, onClick: () -> Unit) {
    Text(text, color = ChipBrand.gold, style = MaterialTheme.typography.bodySmall, modifier = Modifier.clickable(onClick = onClick).padding(vertical = 6.dp))
}
