@echo off

set "BIN=C:\Users\andyl\AppData\Roaming\WinTin++\bin"

wt -M ^
  new-tab --title "Mutiny" -d "%BIN%" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\start_char.ps1" -tin "nukefire\char\mutiny.tin" ^
  ; new-tab --title "Haenym" -d "%BIN%" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\start_char.ps1" -tin "nukefire\char\haenym.tin" ^
  ; new-tab --title "Prodigy" -d "%BIN%" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\start_char.ps1" -tin "nukefire\char\prodigy.tin" ^
  ; new-tab --title "Rancor" -d "%BIN%" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\start_char.ps1" -tin "nukefire\char\rancor.tin" ^
  ; new-tab --title "Gossip" -d "%BIN%\nukefire\logs" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\gossip_watch.ps1" ^
  ; new-tab --title "Telepath" -d "%BIN%\nukefire\logs" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\telepath_watch.ps1"