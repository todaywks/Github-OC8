FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY dbt/meteo_dbt/ ./meteo_dbt/
COPY dbt/profiles/ ./profiles/
ENV DBT_PROFILES_DIR=/app/profiles
WORKDIR /app/meteo_dbt
ENTRYPOINT ["dbt"]
CMD ["build"]
