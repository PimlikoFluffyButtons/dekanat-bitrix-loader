1. aspnetcore-runtime-2.1.30-win-x64.exe
2. dotnet-hosting-2.1.30-win.exe
3. # 1) В проект
cd "C:\Users\KuroiRyuu\Desktop\teachers_api"
# 2) Удаляем неправильный пакет, ставим совместимый
dotnet add package System.Data.SqlClient --version 4.5.3
# 3) Необязательно Чистим bin/obj (PowerShell-способ)
Remove-Item -Recurse -Force .\bin -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\obj -ErrorAction SilentlyContinue
# (Альтернатива через cmd, если вдруг понадобится)
# cmd /c 'rd /s /q .\bin'
# cmd /c 'rd /s /q .\obj'
# 4) Восстановить и собрать под netcoreapp2.1
dotnet restore
dotnet build -c Release -f netcoreapp2.1
# 5) Публикация FDD (Runtime 2.1.30 должен быть установлен на сервере)
dotnet publish -c Release -f netcoreapp2.1
# 6) Деплой в IIS-папку
New-Item -ItemType Directory -Force -Path "C:\inetpub\myapptest" | Out-Null
robocopy ".\bin\Release\netcoreapp2.1\publish" "C:\inetpub\myapptest" /MIR


4. Добавить права доступа к БД для IIS APPPOOL
5. Точки входа
http://localhost/teachersapi/api/teachers?key=
http://localhost/teachersapi/health
