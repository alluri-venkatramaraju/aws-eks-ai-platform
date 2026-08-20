"""Small production-oriented inference API with health, metrics, and tracing."""

from __future__ import annotations

import json
import logging
import os
import time
from datetime import UTC, datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Lock
from typing import Any
from uuid import uuid4

SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "model-server")
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
MAX_BODY_BYTES = int(os.getenv("MAX_BODY_BYTES", "1048576"))
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(message)s")
logger = logging.getLogger(SERVICE_NAME)


def _tracer() -> Any:
    try:
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor

        provider = TracerProvider(
            resource=Resource.create({"service.name": SERVICE_NAME, "deployment.environment": ENVIRONMENT})
        )
        if os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT"):
            provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
        trace.set_tracer_provider(provider)
        return trace.get_tracer(SERVICE_NAME)
    except ImportError:
        return None


TRACER = _tracer()
METRICS = {"requests": 0, "errors": 0, "latency_seconds": 0.0}
METRICS_LOCK = Lock()


def log_event(event: str, **fields: Any) -> None:
    record = {
        "timestamp": datetime.now(UTC).isoformat(),
        "service": SERVICE_NAME,
        "environment": ENVIRONMENT,
        "severity": "INFO",
        "event": event,
        **fields,
    }
    logger.info(json.dumps(record, separators=(",", ":")))


class RequestHandler(BaseHTTPRequestHandler):
    """Serve probes, Prometheus metrics, and deterministic mocked inference."""

    server_version = "model-server/2.0"

    def _write(self, status: int, payload: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(payload)

    def _write_json(self, status: int, body: dict[str, Any]) -> None:
        self._write(status, json.dumps(body, separators=(",", ":")).encode(), "application/json")

    def do_GET(self) -> None:  # noqa: N802
        if self.path in {"/healthz", "/readyz"}:
            self._write_json(200, {"status": "ok"})
        elif self.path == "/metrics":
            with METRICS_LOCK:
                body = (
                    "# TYPE model_requests_total counter\n"
                    f"model_requests_total {METRICS['requests']}\n"
                    "# TYPE model_request_errors_total counter\n"
                    f"model_request_errors_total {METRICS['errors']}\n"
                    "# TYPE model_request_latency_seconds_sum counter\n"
                    f"model_request_latency_seconds_sum {METRICS['latency_seconds']:.6f}\n"
                ).encode()
            self._write(200, body, "text/plain; version=0.0.4; charset=utf-8")
        else:
            self._write_json(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/predict":
            self._write_json(404, {"error": "not found"})
            return
        request_id = self.headers.get("x-request-id") or str(uuid4())
        try:
            length = int(self.headers.get("content-length", "0"))
            if length <= 0 or length > MAX_BODY_BYTES:
                raise ValueError("request body size is invalid")
            body = json.loads(self.rfile.read(length))
            if not isinstance(body, dict):
                raise ValueError("request body must be a JSON object")
        except (ValueError, json.JSONDecodeError) as exc:
            with METRICS_LOCK:
                METRICS["errors"] += 1
            self._write_json(400, {"error": str(exc), "request_id": request_id})
            return

        start = time.perf_counter()
        context = TRACER.start_as_current_span("predict") if TRACER else None
        if context:
            span = context.__enter__()
            span.set_attribute("request.id", request_id)
        try:
            prediction = {"label": "example", "score": 1.0, "input": body}
            latency = time.perf_counter() - start
            with METRICS_LOCK:
                METRICS["requests"] += 1
                METRICS["latency_seconds"] += latency
            log_event("prediction_completed", request_id=request_id, latency_ms=round(latency * 1000, 3))
            self._write_json(200, {"request_id": request_id, "prediction": prediction})
        finally:
            if context:
                context.__exit__(None, None, None)

    def log_message(self, format: str, *args: Any) -> None:
        log_event("http_access", message=format % args)


def main() -> None:
    address = os.getenv("BIND_ADDRESS", "0.0.0.0")
    port = int(os.getenv("PORT", "8080"))
    server = ThreadingHTTPServer((address, port), RequestHandler)
    log_event("server_started", address=address, port=port)
    server.serve_forever()


if __name__ == "__main__":
    main()
