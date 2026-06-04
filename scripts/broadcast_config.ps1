# Single source of truth for broadcast channel display rules.
# Add one entry here when a new type appears. broadcast_watch and all_watch pick it up automatically.
# channels.tin still needs a matching #ACTION to log the line — that's the only other touch point.

$script:BroadcastPatterns = @(
    @{ Regex = '^\[GLORY\] (.+)$';                Label = '[GLORY]';         Color = 'Yellow'     }
    @{ Regex = '^\[FACETED WORK\] (.+)$';          Label = '[FACETED WORK]';  Color = 'Magenta'    }
    @{ Regex = '^\[IMPLANT WORK\] (.+)$';          Label = '[IMPLANT WORK]';  Color = 'Blue'       }
    @{ Regex = '^\[ NEW ITEM EVENT \] (.+)$';      Label = '[ NEW ITEM ]';    Color = 'Green'      }
    @{ Regex = '^\[ DCC SYSTEM \] (.+)$';          Label = '[ DCC ]';         Color = 'Red'        }
    @{ Regex = '^\[ NUKEFIRE MUDVAULT \] (.+)$';   Label = '[ MUDVAULT ]';    Color = 'Cyan'       }
    @{ Regex = '^\[CLASS REMORT EVENT\] (.+)$';    Label = '[REMORT]';        Color = 'Yellow'     }
    @{ Regex = '^\[Class Legacy\] (.+)$';          Label = '[LEGACY]';        Color = 'Magenta'    }
    @{ Regex = '^Skynet\(TM\) (.+)$';              Label = 'Skynet(TM)';      Color = 'DarkYellow' }
)

# Write one broadcast line (label + message).
# Caller handles bell and source-tag (Write-Tag) if needed.
function Write-BroadcastContent([string]$content) {
    foreach ($p in $script:BroadcastPatterns) {
        if ($content -match $p.Regex) {
            Write-Host $p.Label -ForegroundColor $p.Color -NoNewline
            Write-Host (' ' + $Matches[1].Trim()) -ForegroundColor White
            return
        }
    }
    # Fallback: unknown type — display raw so nothing is silently dropped
    Write-Host $content -ForegroundColor DarkGray
}
