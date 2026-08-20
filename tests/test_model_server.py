import json
from http.client import HTTPConnection
from http.server import ThreadingHTTPServer
from threading import Thread

import pytest

from src.model_server.app import METRICS, METRICS_LOCK, RequestHandler


@pytest.fixture()
def server():
    instance = ThreadingHTTPServer(("127.0.0.1", 0), RequestHandler)
    Thread(target=instance.serve_forever, daemon=True).start()
    yield instance
    instance.shutdown()
    instance.server_close()


def request(server, method: str, path: str, body: bytes | None = None):
    connection = HTTPConnection("127.0.0.1", server.server_port)
    connection.request(method, path, body=body, headers={"Content-Type": "application/json"})
    response = connection.getresponse()
    payload = response.read()
    connection.close()
    return response, payload


def test_health_readiness_and_not_found(server) -> None:
    for endpoint in ("/healthz", "/readyz"):
        response, payload = request(server, "GET", endpoint)
        assert response.status == 200
        assert json.loads(payload) == {"status": "ok"}
    response, _ = request(server, "GET", "/missing")
    assert response.status == 404


def test_prediction_and_metrics(server) -> None:
    with METRICS_LOCK:
        before = METRICS["requests"]
    response, payload = request(server, "POST", "/predict", b'{"text":"hello"}')
    assert response.status == 200
    assert json.loads(payload)["prediction"]["label"] == "example"
    metrics, payload = request(server, "GET", "/metrics")
    assert metrics.status == 200
    assert f"model_requests_total {before + 1}" in payload.decode()


@pytest.mark.parametrize("body", [b"", b"not-json", b"[]"])
def test_prediction_rejects_invalid_input(server, body: bytes) -> None:
    response, payload = request(server, "POST", "/predict", body)
    assert response.status == 400
    assert "error" in json.loads(payload)
