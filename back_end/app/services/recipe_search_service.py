from sqlalchemy import text
from sqlalchemy.orm import Session


def search_recipes_by_title_or_tags(db: Session, query: str, limit: int = 50):
    query = (query or "").strip()

    if not query:
        return []

    sql = text("""
        SELECT
            id,
            recipe_title,
            url,
            record_health,
            vote_count,
            rating,
            description,
            cuisine,
            course,
            diet,
            prep_time,
            cook_time,
            ingredients,
            instructions,
            author,
            tags,
            category
        FROM recipes
        WHERE
            LOWER(recipe_title) LIKE LOWER(:contains_query)
            OR LOWER(tags) LIKE LOWER(:contains_query)
        ORDER BY
            CASE
                WHEN LOWER(recipe_title) LIKE LOWER(:starts_query) THEN 1
                WHEN LOWER(tags) LIKE LOWER(:starts_query) THEN 2
                ELSE 3
            END,
            rating DESC,
            vote_count DESC,
            recipe_title ASC
        LIMIT :limit_value
    """)

    rows = db.execute(
        sql,
        {
            "contains_query": f"%{query}%",
            "starts_query": f"{query}%",
            "limit_value": limit,
        },
    ).mappings().all()

    return [dict(row) for row in rows]