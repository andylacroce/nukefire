@echo off

set "BIN=C:\Users\andyl\AppData\Roaming\WinTin++\bin"

wt -M ^
  new-tab --title "Mutiny" -d "%BIN%" cmd /k ^
    "timeout /t 3 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\char\mutiny.tin\"" ^
  ; new-tab --title "Haenym" -d "%BIN%" cmd /k ^
    "timeout /t 5 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\char\haenym.tin\"" ^
  ; new-tab --title "Prodigy" -d "%BIN%" cmd /k ^
    "timeout /t 10 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\char\prodigy.tin\"" ^
  ; new-tab --title "Rancor" -d "%BIN%" cmd /k ^
    "timeout /t 15 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\char\rancor.tin\""