CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Mesures capteurs (séries temporelles, lues par l'IA prédictive)
CREATE TABLE measurements (
    time        TIMESTAMPTZ      NOT NULL DEFAULT now(),
    device_id   TEXT             NOT NULL,
    temperature DOUBLE PRECISION,
    humidity    DOUBLE PRECISION,
    gas         INTEGER,
    pir         BOOLEAN
);
SELECT create_hypertable('measurements', 'time');
CREATE INDEX ON measurements (device_id, time DESC);

-- Alertes affichées par le dashboard : écrites par le service de détection (détection temps
-- réel + alertes brutes de l'ESP), lues et acquittées par backend-api (db.js).
CREATE TABLE alerts (
    id              UUID        PRIMARY KEY,
    time            TIMESTAMPTZ NOT NULL DEFAULT now(),
    device_id       TEXT,
    source          TEXT        NOT NULL,
    severity        TEXT        NOT NULL CHECK (severity IN ('critical','high','medium','low')),
    title           TEXT        NOT NULL,
    description     TEXT        NOT NULL DEFAULT '',
    metadata        JSONB       NOT NULL DEFAULT '{}',
    acknowledged    BOOLEAN     NOT NULL DEFAULT false,
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by TEXT
);
CREATE INDEX ON alerts (time DESC);
CREATE INDEX ON alerts (device_id, time DESC);

-- Commandes envoyées à l'ESP (buzzer, LEDs) et leur acquittement
CREATE TABLE commands (
    id          BIGSERIAL PRIMARY KEY,
    time        TIMESTAMPTZ NOT NULL DEFAULT now(),
    device_id   TEXT        NOT NULL,
    action      TEXT        NOT NULL,
    params      JSONB,
    acked_at    TIMESTAMPTZ
);
