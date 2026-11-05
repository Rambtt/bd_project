\set ON_ERROR_STOP on

DO $$
DECLARE
    index_valid boolean;
    found_count bigint;
BEGIN
    -- Проверяем наличие и корректность индекса
    SELECT indisvalid INTO index_valid
    FROM pg_index
    WHERE indexrelid = to_regclass('dev.idx_news_fulltext_ru');

    IF NOT COALESCE(index_valid, false) THEN
        RAISE EXCEPTION 'Индекс полнотекстового поиска отсутствует или невалиден';
    END IF;

    -- Проверяем поиск по реальным новостям
    SELECT COUNT(*) INTO found_count
    FROM dev.news
    WHERE (
        setweight(to_tsvector('russian', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('russian', coalesce(content, '')), 'B')
    ) @@ plainto_tsquery('russian', 'технологии');

    IF found_count < 10 THEN
        RAISE EXCEPTION 'Найдено слишком мало новостей: %', found_count;
    END IF;

    -- Проверяем учёт русской морфологии
    IF NOT (
        to_tsvector('russian', 'Развитие технологий')
        @@ plainto_tsquery('russian', 'технология')
    ) THEN
        RAISE EXCEPTION 'Не работает поиск по формам русского слова';
    END IF;

    RAISE NOTICE 'Все проверки полнотекстового поиска пройдены!';
    RAISE NOTICE 'Найдено новостей: %', found_count;
END
$$;
