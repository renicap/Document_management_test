-- файл генерации данных БД

-- Type: type_operation_enum

COMMENT ON TYPE public.type_operation_enum
    IS 'Перечисление типов операций: заказ, прием, выдача.';
    
-- Заполняем таблицу Заказчиков
INSERT INTO "Customers" ("Customer") VALUES
('ООО "Автоматика"'),
('ООО "Транспортная лизинговая компания"'),
('ООО "Автомобильные дороги"'),
('ООО "Ремонтная база 10"'),
('АО "Согруз"'),
('ООО "Завод Серп и Молот"');

-- FUNCTION: public.get_customer_id()

-- DROP FUNCTION IF EXISTS public.get_customer_id();

CREATE OR REPLACE FUNCTION public.get_customer_id(
	)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    _id int;
BEGIN
    SELECT "Customers"."Id" INTO _id
        FROM "Customers" ORDER BY random() LIMIT 1;
    RETURN _id;
END;
$BODY$;

ALTER FUNCTION public.get_customer_id()
    OWNER TO postgres;

-- Заполняем таблицу Склада
INSERT INTO "DeliveryReceipt" ("Clerk", "Warehouse") VALUES
('Егорова А.В.', 1),
('Зимин С.П.', 1),
('Кутаков М.И.', 1),
('Щербина О.С.', 1);

-- FUNCTION: public.get_deliveryreceipt_id()

-- DROP FUNCTION IF EXISTS public.get_deliveryreceipt_id();

CREATE OR REPLACE FUNCTION public.get_deliveryreceipt_id(
	)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    _id int;
BEGIN
    SELECT "DeliveryReceipt"."Id" INTO _id
        FROM "DeliveryReceipt" ORDER BY random() LIMIT 1;
    RETURN _id;
END;
$BODY$;

ALTER FUNCTION public.get_deliveryreceipt_id()
    OWNER TO postgres;

-- таблица состава документов
DROP TABLE IF EXISTS temp_document_composition;
create TEMP table temp_document_composition (
    id serial,
    idDoc character(10),
    ser_symbol character(1),
    first_no integer,
    last_no integer,
    total integer
)
ON COMMIT DROP; 

-- таблица дат диапазонов
DROP TABLE IF EXISTS temp_table_dates_range;
create TEMP table temp_table_dates_range (
    id serial,
    calendar_day date
)
ON COMMIT DROP; 

-- 1) заполняем таблицу по диапазону дат
INSERT INTO "temp_table_dates_range" (calendar_day)
select generate_series('2022-01-01', current_date, interval '1 day') as "calendar_day";
--SELECT * FROM "temp_table_dates_range";

DROP TABLE IF EXISTS "temp_table_data_preparation_1";
CREATE TEMP TABLE temp_table_data_preparation_1 (
    id serial,
    row_no integer,
    day date,
    last_change timestamp without time zone,
    doc_no character(10) default null, 
    doc_type type_operation_enum,
    customer_no integer,
    warehouse_id integer
) 
ON COMMIT DROP; 

-- получить число строк таблицы перечисления дат
-- FUNCTION: public.countdaterows()

-- DROP FUNCTION IF EXISTS public.countdaterows();

CREATE OR REPLACE FUNCTION public.countdaterows(
	)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
    DECLARE
        _count integer = 0;
    BEGIN
        SELECT INTO _count count(*) FROM temp_table_dates_range;
        RETURN _count;
    END;
$BODY$;

ALTER FUNCTION public.countdaterows()
    OWNER TO postgres;

-- 2) Генерируем 1000 пронумерованных строк
INSERT INTO "temp_table_data_preparation_1" (id)
    SELECT generate_series(1,1000) AS id;

-- 3) равномерно отобразить множество дат на множество документов 
UPDATE "temp_table_data_preparation_1" SET row_no = trunc("id"*countdaterows()/1000) + 1 where "id" < 1000;
UPDATE "temp_table_data_preparation_1" SET row_no = countdaterows() where id = 1000; -- добавляем последнюю строку

-- 4) копировать даты из таблицы диапазона дат
UPDATE "temp_table_data_preparation_1" 
    SET day = "temp_table_dates_range"."calendar_day" from "temp_table_dates_range" 
        where "temp_table_data_preparation_1"."row_no" = "temp_table_dates_range"."id";
        
-- 5) распределить ссылки на типы документов (всего 3 типа)

-- FUNCTION: public.select_type_operation() -- выбрать тип операции

-- DROP FUNCTION IF EXISTS public.select_type_operation();

CREATE OR REPLACE FUNCTION public.select_type_operation(
	)
    RETURNS type_operation_enum
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
    DECLARE
        _type_op type_operation_enum;
        _number integer = floor(random()*(3-1+1))+1;
    BEGIN
        
        IF _number = 3 THEN
            _type_op := 'dispatch';
        ELSIF _number = 2 THEN
            _type_op := 'receive';
        ELSE
            _type_op := 'order';
        END IF;
        RETURN _type_op;
    END;
$BODY$;

ALTER FUNCTION public.select_type_operation()
    OWNER TO postgres;


--UPDATE "temp_table_data_preparation_1" SET "doc_type" = floor(random()*(3-1+1))+1;
UPDATE "temp_table_data_preparation_1" SET "doc_type" = select_type_operation();

-- 6) распределить ссылки на номера организаций (всего 5 организаций)
UPDATE "temp_table_data_preparation_1" SET "customer_no" = get_customer_id(); --floor(random()*(5-1+1))+1;
-- 7) добавить склад приема-выдачи (всего один склад)
UPDATE "temp_table_data_preparation_1" SET "warehouse_id" = get_DeliveryReceipt_id();
-- 8) формировать номера документов для каждого типа по номеру индекса 
UPDATE "temp_table_data_preparation_1" SET "doc_no" = 'ЗКЗ-' || lpad(id::text,6,'0') where doc_type = 'order';
UPDATE "temp_table_data_preparation_1" SET "doc_no" = 'ПРМ-' || lpad(id::text,6,'0') where doc_type = 'receive';
UPDATE "temp_table_data_preparation_1" SET "doc_no" = 'ВДЧ-' || lpad(id::text,6,'0') where doc_type = 'dispatch';
-- 9) формировать дату последнего изменения
UPDATE "temp_table_data_preparation_1" SET "last_change" = day;

-- 10) копировать в "master"
truncate "master" cascade;

INSERT INTO "master" ("Id", "Doc_date", "Type_op", "Last_update", "IdCustomer", "IdDeliveryReceipt") 
    SELECT doc_no, day, doc_type, last_change, customer_no, warehouse_id FROM temp_table_data_preparation_1;

-- 11) формировать состав документов
CREATE OR REPLACE FUNCTION public.create_document_composition(
	id_doc character varying)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
    DECLARE
        _first integer ;
        _count integer ;
    BEGIN
        for counter in 1..10 loop
            _first = floor(random()*(999-1+1))+1;
            _count = floor(random()*(9000-1+1))+1;        
            insert INTO "detail" ("Series_symbol", "First", "Last", "Quantity", "IdDocument")
                select 'A', _first, _first + _count, _count, id_doc;        
         end loop;
    END;
$BODY$;

ALTER FUNCTION public.create_document_composition(character varying)
    OWNER TO postgres;

COMMENT ON FUNCTION public.create_document_composition(character varying)
    IS 'Создать состав документа.';

select create_document_composition("Id") from "master";
select * from "master";
