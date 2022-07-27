-- Демонстрационный вызовом процедур.
-- Результаты сохраняются в таблицы БД.

-- 3. Поиск по журналу (списку) документов
DROP TABLE IF EXISTS "test_document_list_log_table"; 
CALL document_log_list_proc('2022-01-01', '2022-07-26', '41', 'dispatch', 'receive', 'order');

-- 4. Поиск всех документов по номеру изделия
DROP TABLE IF EXISTS "test_document_part_number_table"; 
CALL search_documents_by_part_number_proc('A', 127);

-- 5. Статистики по всем документам
DROP TABLE IF EXISTS "test_document_statistic_table"; 
CALL document_statistics_proc('2022-01-01', '2022-07-26');

-- Результаты вызова процедур:
-- 3. Результат поиска по журналу (списку) документов
select * from test_document_list_log_table;
-- 4. Результат поиска документов по номеру изделия
-- select * from test_document_part_number_table;
-- 5. Статистики по всем документам
-- select * from test_document_statistic_table;
