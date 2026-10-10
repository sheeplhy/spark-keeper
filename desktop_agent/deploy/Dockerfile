FROM python:3.12-slim

WORKDIR /app
COPY engine/requirements.txt /app/engine/requirements.txt
RUN pip install --no-cache-dir -r /app/engine/requirements.txt \
    && python -m playwright install --with-deps chromium

COPY bridge.py /app/bridge.py
COPY engine /app/engine

ENV SPARK_AGENT_HOST=0.0.0.0 \
    SPARK_LOGIN_HEADLESS=true \
    HEADLESS=true \
    PYTHONUNBUFFERED=1

EXPOSE 8765
CMD ["python", "/app/bridge.py"]
