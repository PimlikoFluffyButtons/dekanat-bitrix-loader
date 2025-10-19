USE [master]
GO

-- Создать login для IIS AppPool
CREATE LOGIN [IIS APPPOOL\testdekanat] FROM WINDOWS
GO

USE [dekanat]
GO

-- Создать user и дать права
CREATE USER [IIS APPPOOL\testdekanat] FOR LOGIN [IIS APPPOOL\testdekanat]
GO

ALTER ROLE [db_datareader] ADD MEMBER [IIS APPPOOL\testdekanat]
GO