CREATE TABLE analyses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    barcode TEXT UNIQUE NOT NULL,
    score INT NOT NULL CHECK (score BETWEEN 0 AND 100),
    grade TEXT NOT NULL CHECK (
        grade IN ('excellent', 'good', 'average', 'poor')
    ),
    summary JSONB NOT NULL,
    risks JSONB NOT NULL,
    ingredients JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);