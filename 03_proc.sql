-- Процедуры БД

/*
3. Написать процедуру журнала (списка) документов.
Параметры процедуры:
* Интервал дат документов
* Поиск по частичному совпадению номера документа
* Множественный список типов (фильтр по одному или нескольким типам документов)
Результат работы процедуры:
* Дата
* Номер
* Тип
* Количество изделий
*/
CREATE OR REPLACE PROCEDURE document_log_list_proc( 
	IN date_1 date,
	IN date_2 date,
	IN doc_number_template character varying,
	VARIADIC arr type_operation_enum[])
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
    _len_arr integer = array_length($4, 1);
    _template character varying (12);
BEGIN
    _template = '%' || doc_number_template || '%';
    DROP TABLE IF EXISTS test_document_list_log_table;
    CASE _len_arr
        WHEN 1 THEN 
            CREATE TABLE test_document_list_log_table AS
                with documents_in_range as (
                    select "Doc_date", "Id", "Type_op" from "master"
                        where "Doc_date" >= date_1 and "Doc_date" <= date_2 
                                and "Type_op" = $4[1]
                                and "Id" LIKE _template
                    )
                select "Doc_date", "documents_in_range"."Id", "Type_op", sum("Quantity") as Summ_Quantity
                    from documents_in_range left join "detail" on "IdDocument" = "documents_in_range"."Id"
                    group by "documents_in_range"."Doc_date", "documents_in_range"."Id", "documents_in_range"."Type_op"
                    order by "documents_in_range"."Id";

        WHEN 2 THEN 
            CREATE TABLE test_document_list_log_table AS
                with documents_in_range as (
                    select "Doc_date", "Id", "Type_op" from "master"
                        where "Doc_date" >= date_1 and "Doc_date" <= date_2 
                                and ("Type_op" = $4[1] or "Type_op" = $4[2])
                                and "Id" LIKE _template 
                    )
                select "Doc_date", "documents_in_range"."Id", "Type_op", sum("Quantity") as Summ_Quantity
                    from documents_in_range left join "detail" on "IdDocument" = "documents_in_range"."Id"
                    group by "documents_in_range"."Doc_date", "documents_in_range"."Id", "documents_in_range"."Type_op"
                    order by "documents_in_range"."Id";
        WHEN 3 THEN
            CREATE TABLE test_document_list_log_table AS
                with documents_in_range as (
                    select "Doc_date", "Id", "Type_op" from "master"
                        where "Doc_date" >= date_1 and "Doc_date" <= date_2 
                                and "Id" LIKE _template 
                    )
                select "Doc_date", "documents_in_range"."Id", "Type_op", sum("Quantity") as Summ_Quantity
                    from documents_in_range left join "detail" on "IdDocument" = "documents_in_range"."Id"
                    group by "documents_in_range"."Doc_date", "documents_in_range"."Id", "documents_in_range"."Type_op"
                    order by "documents_in_range"."Id";        
    ELSE
    END CASE;
END;
$BODY$;

/* 
4. Написать процедуру поиска всех документов по номеру изделия
Параметры процедуры:
* Серия изделия
* Номер изделия
Результат работы процедуры (список документов с участием этого номера изделия):
* Дата
* Номер
* Тип
*/

CREATE OR REPLACE PROCEDURE search_documents_by_part_number_proc(product_series character(1), 
                                                                 product_no integer) LANGUAGE plpgsql AS $$
BEGIN
CREATE TABLE test_document_part_number_table AS
    with series_numbers as (
        select distinct on ("IdDocument") "IdDocument", "First", "Last" from "detail"
            where "Series_symbol" = product_series and "First" <= product_no and "Last" >= product_no  
        )
    select "IdDocument", "First", "Last", "master"."Doc_date", "master"."Type_op" 
        from series_numbers left join "master" on "IdDocument" = "master"."Id"
        order by "IdDocument";
END;
$$;

/*
5. Написать процедуру статистики по всем документам
Параметры процедуры:
* Интервал дат документов
Результат работы процедуры:
* Тип
* Суммароное количество документов этого типа
* Суммарное количество изделий в документах этого типа
* Среднее количество изделий в документах этого типа
*/
CREATE OR REPLACE PROCEDURE document_statistics_proc(date_start date,date_end date) LANGUAGE plpgsql AS $$
BEGIN
CREATE TABLE test_document_statistic_table AS
    with documents_in_range as (
        select "Id", "Type_op", "Doc_date" from "master"
            where "Doc_date" >= date_start and "Doc_date" <= date_end  
        )
    select "Type_op", count("Type_op") as Type_count, sum("Quantity") as Summ_Quantity, round(avg("Quantity")) as Average_Quantity
    from documents_in_range left join "detail" on "IdDocument" = "documents_in_range"."Id"
    group by "Type_op";
END;
$$;
