\set ON_ERROR_STOP on

DO $$
DECLARE
    actual_count bigint;
BEGIN
    SELECT COUNT(*) INTO actual_count FROM dev.news;
    IF actual_count <> 80000 THEN
        RAISE EXCEPTION 'Новости: ожидалось 80000, получено %', actual_count;
    END IF;

    SELECT COUNT(*) INTO actual_count FROM dev.app_user;
    IF actual_count <> 10000 THEN
        RAISE EXCEPTION 'Пользователи: ожидалось 10000, получено %', actual_count;
    END IF;

    SELECT COUNT(*) INTO actual_count FROM dev.news_source;
    IF actual_count <> 100 THEN
        RAISE EXCEPTION 'Источники: ожидалось 100, получено %', actual_count;
    END IF;

    SELECT COUNT(*) INTO actual_count FROM dev.import_result;
    IF actual_count <> 88000 THEN
        RAISE EXCEPTION 'Импорт: ожидалось 88000, получено %', actual_count;
    END IF;

    SELECT COUNT(*) INTO actual_count
    FROM pg_constraint
    WHERE connamespace = 'dev'::regnamespace;

    IF actual_count <> 77 THEN
        RAISE EXCEPTION 'Ограничения: ожидалось 77, получено %', actual_count;
    END IF;

    RAISE NOTICE 'Все 5 SQL-проверок пройдены!';
END
$$;
