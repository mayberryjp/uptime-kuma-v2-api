FROM python:3.12-alpine

# non-root user
RUN adduser -D -u 10001 appuser
WORKDIR /app

COPY requirements.txt .
RUN apk add --no-cache libstdc++ && \
    apk add --no-cache --virtual .build-deps build-base cargo linux-headers && \
    pip install --no-cache-dir -r requirements.txt && \
    apk del .build-deps

COPY app ./app

USER appuser
EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=5 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health',timeout=3).status==200 else 1)" || exit 1

# FORWARDED_ALLOW_IPS controls which proxy IPs may set X-Forwarded-* (set to your proxy)
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port 8000 --forwarded-allow-ips \"${FORWARDED_ALLOW_IPS:-127.0.0.1}\""]
