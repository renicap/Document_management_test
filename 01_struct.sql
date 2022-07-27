-- 01_struct.sql - файл создания структуры БД

-- Type: type_operation_enum
-- DROP TYPE IF EXISTS public.type_operation_enum CASCADE;

CREATE TYPE public.type_operation_enum AS ENUM
    ('order', 'receive', 'dispatch');

ALTER TYPE public.type_operation_enum
    OWNER TO postgres;
    
-- Table: public.Customers ********************* Заказчики
DROP TABLE IF EXISTS public."Customers";
CREATE TABLE IF NOT EXISTS PUBLIC."Customers" ("Id" integer NOT NULL GENERATED ALWAYS AS IDENTITY
                       (INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1), 
                       "Customer" CHARACTER varying COLLATE PG_CATALOG."default" NOT NULL,
                       CONSTRAINT "Customers_pkey" PRIMARY KEY ("Id")) TABLESPACE PG_DEFAULT;

ALTER TABLE IF EXISTS PUBLIC."Customers" OWNER TO POSTGRES;

COMMENT ON TABLE PUBLIC."Customers" IS 'Заказчики';

-- Table: public.DeliveryReceipt ********************* Дополнительный параметр для документов Приём и Выдача

DROP TABLE IF EXISTS public."DeliveryReceipt";

CREATE TABLE IF NOT EXISTS public."DeliveryReceipt"
(
    "Id" integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "Clerk" character varying COLLATE pg_catalog."default" NOT NULL,
    "Warehouse" integer NOT NULL,
    CONSTRAINT "DeliveryReceipt_pkey" PRIMARY KEY ("Id")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."DeliveryReceipt"
    OWNER to postgres;

COMMENT ON TABLE public."DeliveryReceipt"
    IS 'Дополнительный параметр для документов Приём и Выдача';

-- Table: public.master ********************* База данных содержит документы трёх типов: Заказ, Приём, Выдача.

DROP TABLE IF EXISTS public.master;

CREATE TABLE IF NOT EXISTS public.master
(
    "Id" character(10) COLLATE pg_catalog."default" NOT NULL,
    "Doc_date" date,
    "Last_update" timestamp with time zone,
    "IdCustomer" integer,
    "IdDeliveryReceipt" integer,
    "Type_op" type_operation_enum,
    CONSTRAINT "Documents_pkey" PRIMARY KEY ("Id"),
    CONSTRAINT "IdCustmers" FOREIGN KEY ("IdCustomer")
        REFERENCES public."Customers" ("Id") MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT "IdDeliveryReceipt" FOREIGN KEY ("IdDeliveryReceipt")
        REFERENCES public."DeliveryReceipt" ("Id") MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.master
    OWNER to postgres;

COMMENT ON COLUMN public.master."IdCustomer"
    IS 'Заказчик';

COMMENT ON COLUMN public.master."IdDeliveryReceipt"
    IS 'Дополнительный параметр для документов Приём и Выдача.';

COMMENT ON CONSTRAINT "IdCustmers" ON public.master
    IS 'Дополнительный параметр для документа Заказ.';
COMMENT ON CONSTRAINT "IdDeliveryReceipt" ON public.master
    IS 'Дополнительный параметр для документов Приём и Выдача.';


-- Table: public.detail ********************* Состав документа - подчиненая таблица для документа со строками состава.

DROP TABLE IF EXISTS public.detail;

CREATE TABLE IF NOT EXISTS public.detail
(
    "Id" integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "Series_symbol" character(1) COLLATE pg_catalog."default" NOT NULL,
    "Quantity" integer NOT NULL,
    "IdDocument" character(10) COLLATE pg_catalog."default",
    "First" integer NOT NULL,
    "Last" integer NOT NULL,
    CONSTRAINT "Details_pkey" PRIMARY KEY ("Id"),
    CONSTRAINT "IdDocument" FOREIGN KEY ("IdDocument")
        REFERENCES public.master ("Id") MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.detail
    OWNER to postgres;

COMMENT ON TABLE public.detail
    IS 'Состав документа - подчиненая таблица для документа со строками состава.';

COMMENT ON COLUMN public.detail."Series_symbol"
    IS 'Номер изделия состоит из буквенной серии и 7 значного номера. (Например: А 0000501)';

COMMENT ON COLUMN public.detail."First"
    IS 'Начальный номер.';

COMMENT ON COLUMN public.detail."Last"
    IS 'Последний номер.';


