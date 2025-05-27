FROM julia:1.11

WORKDIR /app

COPY Manifest.toml Project.toml server.jl setup.jl .

RUN julia server.jl

CMD julia server.jl
