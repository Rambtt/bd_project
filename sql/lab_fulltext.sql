\set ON_ERROR_STOP on

-- Индекс GIN для быстрого полнотекстового поиска
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_news_fulltext_ru
ON dev.news USING GIN (
    (
        setweight(
            to_tsvector('russian', coalesce(title, '')), 'A'
        ) ||
        setweight(
            to_tsvector('russian', coalesce(content, '')), 'B'
        )
    )
);

-- Поиск новостей по запросу "технологии"
WITH search_query AS (
    SELECT plainto_tsquery('russian', 'технологии') AS query
)
SELECT
    n.id,
    n.title,
    n.published_at,
    ts_rank(
        setweight(to_tsvector('russian', coalesce(n.title, '')), 'A') ||
        setweight(to_tsvector('russian', coalesce(n.content, '')), 'B'),
        q.query
    ) AS relevance
FROM dev.news n
CROSS JOIN search_query q
WHERE (
    setweight(to_tsvector('russian', coalesce(n.title, '')), 'A') ||
    setweight(to_tsvector('russian', coalesce(n.content, '')), 'B')
) @@ q.query
ORDER BY relevance DESC, n.published_at DESC
LIMIT 10;
