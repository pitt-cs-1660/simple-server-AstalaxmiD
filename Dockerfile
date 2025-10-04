#Build Stage

FROM python:3.12 AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY pyproject.toml ./
COPY tests/ ./tests
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:${PATH}"
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN uv venv $VIRTUAL_ENV && uv sync --no-install-project --no-editable

# Final Stage
FROM python:3.12-slim AS final
WORKDIR /app
RUN useradd -m appuser
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH=/app
COPY --from=builder --chown=appuser:appuser /app/.venv /app/.venv
COPY --chown=appuser:appuser cc_simple_server/ ./cc_simple_server/
COPY --from=builder /app/tests ./tests
RUN chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
CMD ["uvicorn", "cc_simple_server.server:app", "--host","0.0.0.0","--port", "8000"]
