DECLARE @CurrentYear INT = YEAR(GETDATE())
DECLARE @AcademicYear NVARCHAR(20)

IF MONTH(GETDATE()) < 9
    SET @AcademicYear = CAST(@CurrentYear - 1 AS NVARCHAR) + '-' + CAST(@CurrentYear AS NVARCHAR)
ELSE
    SET @AcademicYear = CAST(@CurrentYear AS NVARCHAR) + '-' + CAST(@CurrentYear + 1 AS NVARCHAR)

SELECT 
    p.[Код] AS КодПреподавателя,
    p.[Фамилия],
    p.[Имя],
    p.[Отчество],
    
    STUFF((
        SELECT DISTINCT '; ' + 
            RTRIM(k.[Название]) + ' - ' + RTRIM(n.[ПреподавательДолжность])
        FROM [Нагрузка] n
        INNER JOIN [Кафедры] k ON n.[КодКафедры] = k.[Код]
        WHERE n.[КодПреподавателя] = p.[Код]
            AND RTRIM(ISNULL(n.[ПреподавательДолжность], '')) <> ''
            AND RTRIM(ISNULL(k.[Название], '')) <> ''
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Должность,
    
    STUFF((
        SELECT DISTINCT '; ' + n.[Дисциплина]
        FROM [Нагрузка] n
        WHERE n.[КодПреподавателя] = p.[Код] 
            AND n.[УчебныйГод] = @AcademicYear
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Дисциплины,
    
    -- ИСПРАВЛЕНО: правильный порядок полей и синтаксис CASE
    STUFF((
        SELECT '; ' + 
            RTRIM(ISNULL(npo.[Квалификация], '')) +
            CASE 
                WHEN RTRIM(ISNULL(npo.[Специальность], '')) <> '' 
                THEN ', ' + RTRIM(npo.[Специальность])
                ELSE '' 
            END +
            CASE 
                WHEN RTRIM(ISNULL(npo.[НаименованиеОрганизации], '')) <> '' 
                THEN ' (' + RTRIM(npo.[НаименованиеОрганизации]) + ')'
                ELSE '' 
            END
        FROM [НагрузкаПреподОбразование] npo
        WHERE npo.[КодПреподавателя] = p.[Код]
            AND RTRIM(ISNULL(npo.[Специальность], '')) <> ''
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Образование,
    
    p.[Степень] AS УченаяСтепень,
    p.[Звание] AS УченоеЗвание,
    
    STUFF((
        SELECT '; ' + ppk.[Программа]
        FROM [ПреподавателиПовышенияКвалификации] ppk
        WHERE ppk.[КодПреподавателя] = p.[Код]
            AND TRY_CAST(LEFT(ppk.[УчебныйГод], 4) AS INT) IS NOT NULL
            AND (@CurrentYear - TRY_CAST(LEFT(ppk.[УчебныйГод], 4) AS INT)) <= 3
            AND ppk.[ФормаПрограммы] = 'Курсы повышения квалификации'
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ПовышениеКвалификации,
    
    STUFF((
        SELECT '; ' + ppk.[Программа]
        FROM [ПреподавателиПовышенияКвалификации] ppk
        WHERE ppk.[КодПреподавателя] = p.[Код]
            AND TRY_CAST(LEFT(ppk.[УчебныйГод], 4) AS INT) IS NOT NULL
            AND (@CurrentYear - TRY_CAST(LEFT(ppk.[УчебныйГод], 4) AS INT)) <= 3
            AND ppk.[ФормаПрограммы] = 'Профессиональная переподготовка'
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Переподготовка,
    
    p.[ПедСтаж] AS ПедагогическийСтаж,
    
    STUFF((
        SELECT DISTINCT '; ' + s.[Специальность] + ' ' + s.[Название_Спец]
        FROM [Нагрузка] n
        INNER JOIN [Все_Группы] g ON n.[КодГруппы] = g.[Код]
        INNER JOIN [Специальности] s ON g.[Код_Специальности] = s.[Код]
        WHERE n.[КодПреподавателя] = p.[Код]
            AND n.[УчебныйГод] = @AcademicYear
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ОбразовательныеПрограммы

FROM [Преподаватели] p
WHERE p.[Код] <> 1
    AND EXISTS (
        SELECT 1 
        FROM [Нагрузка] n 
        WHERE n.[КодПреподавателя] = p.[Код] 
            AND n.[УчебныйГод] = @AcademicYear
            AND n.[Дисциплина] IS NOT NULL
    )
ORDER BY p.[Фамилия], p.[Имя]