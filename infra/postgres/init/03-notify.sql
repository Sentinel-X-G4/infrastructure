-- Temps réel base -> backend-api (LISTEN) : le service de détection écrit, l'API diffuse
-- en WebSocket. Le message ne porte que l'identifiant : l'API relit la ligne.

-- Nouvelle alerte (public.alerts) -> canal « sentinel_alerts », payload = id
CREATE FUNCTION notify_alert() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM pg_notify('sentinel_alerts', NEW.id::text);
    RETURN NULL;
END $$;
CREATE TRIGGER alerts_notify AFTER INSERT ON alerts
    FOR EACH ROW EXECUTE FUNCTION notify_alert();

-- Nouvel état d'appareil (detection.predictions) -> canal « sentinel_devices », payload = device_id
CREATE FUNCTION detection.notify_prediction() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM pg_notify('sentinel_devices', NEW.device_id);
    RETURN NULL;
END $$;
CREATE TRIGGER predictions_notify AFTER INSERT ON detection.predictions
    FOR EACH ROW EXECUTE FUNCTION detection.notify_prediction();
