@echo off

set "BIN=C:\Users\andyl\AppData\Roaming\WinTin++\bin"

wt -M ^
  new-tab --title "Mutiny"   --tabColor "#7A4040" -d "%BIN%" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\start_char.ps1" -tin "nukefire\char\mutiny.tin" ^
  ; new-tab --title "Haenym"  --tabColor "#3D5E7A" -d "%BIN%" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\start_char.ps1" -tin "nukefire\char\haenym.tin" ^
  ; new-tab --title "Prodigy" --tabColor "#3D6B50" -d "%BIN%" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\start_char.ps1" -tin "nukefire\char\prodigy.tin" ^
  ; new-tab --title "Rancor"  --tabColor "#5C3F7A" -d "%BIN%" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\start_char.ps1" -tin "nukefire\char\rancor.tin" ^
  ; new-tab --title "Gossip"   --tabColor "#6B5C2E" -d "%BIN%\nukefire\logs" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\gossip_watch.ps1" ^
  ; new-tab --title "Telepath" --tabColor "#2E6666" -d "%BIN%\nukefire\logs" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\telepath_watch.ps1" ^
  ; new-tab --title "Auction"  --tabColor "#7A5230" -d "%BIN%\nukefire\logs" powershell -NoExit -File ^
    "%BIN%\nukefire\scripts\auction_watch.ps1"
