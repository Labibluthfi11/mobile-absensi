@echo off
echo ======================================================
echo    MEMULAI BUILD APK RELEASE (DENGAN OBFUSCATION)
echo ======================================================
echo.

:: Menjalankan flutter build dengan path lokal lu dan flag keamanan
call .\flutter\bin\flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo.
echo ======================================================
echo    BUILD SELESAI!
echo    Lokasi APK: build\app\outputs\flutter-apk\app-release.apk
echo    Lokasi Simbol: build\app\outputs\symbols (Simpan ini buat debug)
echo ======================================================
echo.
pause
