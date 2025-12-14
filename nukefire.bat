@echo off

set "BIN=C:\Users\andyl\AppData\Roaming\WinTin++\bin"
set "COLS=210"
set "LINES=60"

wt -M ^
  new-tab --title "Mutiny" -d "%BIN%" cmd /k ^
    "mode con: cols=%COLS% lines=%LINES% & timeout /t 2 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\mutiny.tin\"" ^
  ; new-tab --title "Haenym" -d "%BIN%" cmd /k ^
    "mode con: cols=%COLS% lines=%LINES% & timeout /t 2 /nobreak > nul & \"%BIN%\tt++.exe\" -r \"nukefire\haenym.tin\""
