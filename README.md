# Docker — Modular Images

Imágenes Docker modulares basadas en `osrf/ros:humble-desktop-full`. Cada imagen hereda de la anterior y añade solo lo que necesita, compartiendo capas para ahorrar disco.

> Nota: Tener en cuenta .dockerignore en carpeta Cirtesu/.dockerignore para evitar montar cosas innecesarias dentro del contenedor.

```
osrf/ros:humble-desktop-full
  └── diegomarza/ros2-dev-base    ← dev tools, uv, sudo, colcon, gedit...
        └── diegomarza/da3        ← torch + DA3 deps en venv /opt/venvs/da3
              └── diegomarza/da3-ros2-wrapper ← overlay colcon del wrapper ROS 2 desde fork remoto
        └── diegomarza/stonefish  ← deps/toolchain para compilar Stonefish + ROS 2 en stonefish_ws
        └── diegomarza/zed        ← (futuro)
```

## Build

```bash
# 1) Base
docker build -f docker/ros2-dev-base/Dockerfile -t diegomarza/ros2-dev-base:latest \
  --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) docker/ros2-dev-base

# 2) DA3
docker build -f docker/da3/Dockerfile -t diegomarza/da3:latest .

# 3) Wrapper ROS 2
docker build -f docker/da3-ros2-wrapper/Dockerfile -t diegomarza/da3-ros2-wrapper:latest .

# 4) Stonefish
docker build -f docker/stonefish/Dockerfile -t diegomarza/stonefish:latest .
```

El wrapper ROS 2 se clona durante el build desde el fork remoto configurado en [docker/da3-ros2-wrapper/Dockerfile](./da3-ros2-wrapper/Dockerfile). La imagen final conserva solo el overlay instalado en `~/ros2_wrapper_ws/install`, no el repo fuente.

## Compose

`docker-compose.yml` orquesta contenedores construidos. Lo común se agrupa en anclas YAML:

- `x-common-env`: pantalla X11 y OpenGL NVIDIA.
- `x-common-volumes`: workspace, `Xauthority`, `/dev`, `.codex`, `.ssh`, `.gitconfig` y caché de Hugging Face.
- `x-common-service`: red `host`, IPC `host`, `privileged`, GPU, `tty`, `stdin_open`, `working_dir` y `command: bash`.

> Perfiles disponibles: `base`, `da3`, `da3-ros2-wrapper` y `stonefish`.

Si no activas un perfil, no arranca ningún servicio.

```bash
docker compose -f docker/docker-compose.yml --profile da3-ros2-wrapper up -d
docker exec -it da3-ros2-wrapper bash
docker compose -f docker/docker-compose.yml --profile da3-ros2-wrapper down
```

## Docs

- [21_docker_compact_state.md](/home/diego/Documents/02-Universidad/Cirtesu/agentdocs/workflows/21_docker_compact_state.md)

Stonefish:
- [2026-03-30_docker_stonefish.md](/home/diego/Documents/02-Universidad/Cirtesu/agentdocs/stonefish/2026-03-30_docker_stonefish.md)
- [stonefish/README.md](./stonefish/README.md)

## DockerHub

[hub.docker.com/repositories/diegomarza](https://hub.docker.com/repositories/diegomarza)

```bash
docker login
```

(Buildear)

```bash
docker push diegomarza/ros2-dev-base:latest
```

```bash
docker pull diegomarza/ros2-dev-base:latest
```

## Permisos

El usuario dentro del container es `diego` con UID/GID 1000 (el default de Ubuntu). Si tu UID es distinto, pasa `--build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)` al build. `sudo` está disponible sin contraseña.

## Python en DA3

DA3 usa un venv en `/opt/venvs/da3` gestionado con `uv` y ya queda horneado en la imagen `diegomarza/da3:latest`. El `PATH` del contenedor deja `da3` y `python` apuntando a `/opt/venvs/da3/bin`, y `PYTHONPATH` expone solo las rutas Python necesarias de ROS 2 junto con el override local de `Depth-Anything-3` montado en `/home/diego/Cirtesu/Repositories/Depth-Anything-3/src`.

Esto ya está verificado en runtime sobre el servicio `da3` recreado con Compose: `da3 --help`, `import rclpy`, carga de `DA3-SMALL` en GPU e inferencia simple. No se instala nada en el Python del sistema.
