@echo off

set "BIN=C:\Users\andyl\AppData\Roaming\WinTin++\bin"

wt -M ^
  new-tab --title "Mutiny" -d "%BIN%" cmd /k ^
    "timeout /t 0 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\mutiny.tin\"" ^
  ; new-tab --title "Haenym" -d "%BIN%" cmd /k ^
    "timeout /t 5 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\haenym.tin\"" ^
  ; new-tab --title "Prodigy" -d "%BIN%" cmd /k ^
    "timeout /t 10 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\prodigy.tin\""
