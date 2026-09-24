FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY pyproject.toml ./
# The legal pages are rendered from these at request time — every Markdown
# file, not a hand-listed pair, so a future legal doc never gets left out of
# the image (FIWeatherWatch's Dockerfile has the same note, from real
# experience: a hand-listed pair once shipped an image missing one).
COPY *.md ./
COPY app ./app
RUN pip install --no-cache-dir .

# Non-root, matching the other backends' uid.
RUN useradd -u 1000 -m appuser
USER appuser

EXPOSE 8792
HEALTHCHECK --interval=60s --timeout=5s --start-period=10s \
    CMD python -c "import urllib.request;urllib.request.urlopen('http://127.0.0.1:8792/healthz').read()"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8792"]
