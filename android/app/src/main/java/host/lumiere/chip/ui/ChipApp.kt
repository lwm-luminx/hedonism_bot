package host.lumiere.chip.ui

import androidx.activity.compose.BackHandler
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue

/** Signed-out people see the sign-in page; everyone else the upload screen, with sign-in for more accounts. */
@Composable
fun ChipApp(state: ChipState, actions: ChipActions) {
    var addingAccount by rememberSaveable { mutableStateOf(false) }
    var signInCountWhenAdding by rememberSaveable { mutableIntStateOf(state.signInCount) }
    LaunchedEffect(state.signInCount) {
        if (addingAccount && state.signInCount != signInCountWhenAdding) addingAccount = false
    }
    ChipTheme {
        when {
            state.accounts.isEmpty() -> SignInScreen(state, actions)
            addingAccount -> {
                val close = { addingAccount = false; actions.cancelArchiveChoice() }
                BackHandler(onBack = close)
                SignInScreen(state, actions, onCancel = close)
            }
            else -> UploadScreen(state, actions, onAddAccount = {
                signInCountWhenAdding = state.signInCount
                actions.clearAccountError()
                addingAccount = true
            })
        }
    }
}
