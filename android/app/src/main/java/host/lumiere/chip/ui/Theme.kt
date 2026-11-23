package host.lumiere.chip.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/** Chip's brand colours, shared with the iOS app (ChipBrand). */
object ChipBrand {
    val ink = Color(0xFF0F0F0F)
    val gold = Color(0xFFC9A96E)
    val paper = Color(0xFFFBEEC6)
    val card = Color(0xFF1A1917)
    val muted = Color(0xFFA39E94)
}

@Composable
fun ChipTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = ChipBrand.gold,
            onPrimary = ChipBrand.ink,
            secondary = ChipBrand.paper,
            background = ChipBrand.ink,
            onBackground = Color(0xFFF2EFE8),
            surface = ChipBrand.ink,
            onSurface = Color(0xFFF2EFE8),
            surfaceVariant = ChipBrand.card,
            onSurfaceVariant = ChipBrand.muted,
            surfaceContainer = ChipBrand.card,
            surfaceContainerHigh = Color(0xFF24221F),
            error = Color(0xFFFF6B5E),
        ),
        content = content,
    )
}
