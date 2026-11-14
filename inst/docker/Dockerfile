FROM rocker/r-ver:4.5.0

LABEL org.opencontainers.image.title="dicomtk.server" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.description="Multi-user clinical DICOM server, honest-broker custody, and SMART on FHIR portal"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash dicomtk
WORKDIR /app
COPY . /app

RUN Rscript -e "install.packages(c('httr2', 'jsonlite', 'tibble', 'cli', 'rlang', 'plumber', 'shiny', 'mirai', 'openssl'), repos = 'https://cloud.r-project.org')" \
 && R CMD INSTALL --no-multiarch /app

USER dicomtk
EXPOSE 8080 3838

CMD ["Rscript", "-e", "ctx <- dicomtk.server::server_create_context('/tmp/dicomtk-srv'); pr <- dicomtk.server::server_plumber_api(ctx); pr$run(host = '0.0.0.0', port = 8080)"]
