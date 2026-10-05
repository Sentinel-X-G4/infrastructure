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

-- Alertes (capteur, intrusion IA vision, anomalie IA prédictive)
CREATE TABLE alerts (
    id          BIGSERIAL PRIMARY KEY,
    time        TIMESTAMPTZ NOT NULL DEFAULT now(),
    device_id   TEXT        NOT NULL,
    source      TEXT        NOT NULL CHECK (source IN ('sensor','vision','predictive')),
    type        TEXT        NOT NULL,
    severity    TEXT        NOT NULL DEFAULT 'warning' CHECK (severity IN ('info','warning','critical')),
    payload     JSONB,
    acknowledged BOOLEAN    NOT NULL DEFAULT false
);
CREATE INDEX ON alerts (time DESC);

-- Commandes envoyées à l'ESP (buzzer, LEDs) et leur acquittement
CREATE TABLE commands (
    id          BIGSERIAL PRIMARY KEY,
    time        TIMESTAMPTZ NOT NULL DEFAULT now(),
    device_id   TEXT        NOT NULL,
    action      TEXT        NOT NULL,
    params      JSONB,
    acked_at    TIMESTAMPTZ
);
