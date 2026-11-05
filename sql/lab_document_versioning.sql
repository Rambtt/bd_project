\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS lab_json;

CREATE TABLE IF NOT EXISTS lab_json.news_documents (
    news_id bigint PRIMARY KEY,
    document jsonb NOT NULL
);

-- Версия 1: плоская структура документа
INSERT INTO lab_json.news_documents (news_id, document)
SELECT
    id,
    jsonb_build_object(
        'schema_version', 1,
        'title', title,
        'text', content,
        'source_id', source_id
    )
FROM dev.news
ORDER BY id
LIMIT 3
ON CONFLICT (news_id) DO NOTHING;

-- Миграция с версии 1 на версию 2
UPDATE lab_json.news_documents
SET document =
    (document - 'text' - 'source_id' - 'schema_version')
    || jsonb_build_object(
        'schema_version', 2,
        'content', jsonb_build_object(
            'body', document->>'text',
            'language', 'ru'
        ),
        'source', jsonb_build_object(
            'id', (document->>'source_id')::integer
        ),
        'tags', '[]'::jsonb
    )
WHERE document->>'schema_version' = '1';

-- Автоматическая проверка миграции
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM lab_json.news_documents
    ) THEN
        RAISE EXCEPTION 'Нет документов для проверки';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM lab_json.news_documents
        WHERE document->>'schema_version' <> '2'
           OR NOT (document ? 'content')
           OR NOT (document ? 'source')
           OR NOT (document ? 'tags')
           OR document ? 'text'
           OR document ? 'source_id'
    ) THEN
        RAISE EXCEPTION 'Миграция JSONB выполнена неправильно';
    END IF;

    RAISE NOTICE 'Миграция JSONB с версии 1 на версию 2 прошла успешно!';
END
$$;

-- Просмотр результата
SELECT
    news_id,
    document->>'schema_version' AS version,
    document->>'title' AS title,
    document #>> '{content,language}' AS language
FROM lab_json.news_documents
ORDER BY news_id;
