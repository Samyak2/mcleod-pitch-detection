FROM julia:1.11

WORKDIR /app

COPY Manifest.toml Project.toml setup.jl .

RUN julia setup.jl

COPY server.jl .
COPY notebooks notebooks

CMD julia server.jl
