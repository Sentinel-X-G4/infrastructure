-- Service de détection (backend-iot-alerts/detection-service), schéma dédié « detection ».
-- Doit rester aligné sur detection_service/storage/tables.py (le service ne crée aucune table).

CREATE SCHEMA IF NOT EXISTS detection;

-- Mesures brutes de l'ESP (sentinelx/{device_id}/telemetry), horodatées à la réception
CREATE TABLE detection.sensor_readings (
    id          BIGSERIAL,
    device_id   TEXT      NOT NULL,
    received_at TIMESTAMPTZ      NOT NULL,
    device_ts   BIGINT,
    temp        DOUBLE PRECISION,
    hum         DOUBLE PRECISION,
    pir         BOOLEAN          NOT NULL,
    gas_raw     SMALLINT         NOT NULL,
    gas_do      BOOLEAN,
    warmup      BOOLEAN          NOT NULL,
    PRIMARY KEY (id, received_at)
);
SELECT create_hypertable('detection.sensor_readings', 'received_at');
CREATE INDEX ix_sensor_readings_device_received ON detection.sensor_readings (device_id, received_at DESC);

-- Détections de personnes de l'IA vision (sentinelx/{device_id}/camera)
CREATE TABLE detection.camera_events (
    id          BIGSERIAL,
    device_id   TEXT NOT NULL,
    received_at TIMESTAMPTZ NOT NULL,
    device_ts   BIGINT,
    person      BOOLEAN     NOT NULL,
    PRIMARY KEY (id, received_at)
);
SELECT create_hypertable('detection.camera_events', 'received_at');
CREATE INDEX ix_camera_events_device_received ON detection.camera_events (device_id, received_at DESC);

-- Features par fenêtre (entrée du modèle) ; label/session_id = jeu d'entraînement
CREATE TABLE detection.feature_windows (
    device_id          TEXT NOT NULL,
    window_end         TIMESTAMPTZ NOT NULL,
    pir_ratio          DOUBLE PRECISION,
    cam_ratio          DOUBLE PRECISION,
    gas_mean           DOUBLE PRECISION,
    gas_max            DOUBLE PRECISION,
    gas_min            DOUBLE PRECISION,
    gas_slope          DOUBLE PRECISION,
    gas_delta_baseline DOUBLE PRECISION,
    gas_do_ratio       DOUBLE PRECISION,
    temp_last          DOUBLE PRECISION,
    hum_last           DOUBLE PRECISION,
    temp_delta_long    DOUBLE PRECISION,
    hum_delta_long     DOUBLE PRECISION,
    temp_slope_long    DOUBLE PRECISION,
    n_samples_short    DOUBLE PRECISION,
    session_id         UUID,
    label              TEXT,
    PRIMARY KEY (device_id, window_end)
);
SELECT create_hypertable('detection.feature_windows', 'window_end');
CREATE INDEX ix_feature_windows_session ON detection.feature_windows (session_id);

-- Résultats publiés sur sentinelx/{device_id}/detection
CREATE TABLE detection.predictions (
    id            BIGSERIAL PRIMARY KEY,
    device_id     TEXT  NOT NULL,
    window_end    TIMESTAMPTZ  NOT NULL,
    status        TEXT  NOT NULL,
    device_state  TEXT  NOT NULL,
    reason        TEXT  NOT NULL,
    alerts        JSONB        NOT NULL,
    metrics       JSONB        NOT NULL,
    model_version TEXT NOT NULL
);
CREATE INDEX ix_predictions_device_window ON detection.predictions (device_id, window_end);

-- Sessions d'enregistrement étiquetées (POST /recording/start|stop)
CREATE TABLE detection.recording_sessions (
    id         UUID        PRIMARY KEY,
    device_id  TEXT NOT NULL,
    label      TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at   TIMESTAMPTZ,
    notes      TEXT
);
