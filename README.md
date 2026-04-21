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

## Prerequisitos

En la máquina donde se vayan a lanzar los contenedores:

- Docker instalado y funcionando.
- Usuario añadido al grupo `docker`.
- Docker Compose v2 disponible (`docker compose version`).
- NVIDIA driver instalado si se quiere usar GPU.
- NVIDIA Container Toolkit funcionando si se quiere usar GPU desde Docker.
- Este repo clonado en la máquina.
- El workspace/carpeta que quieras montar existe en el host.

Comprobaciones:

```bash
docker ps
docker compose version
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu20.04 nvidia-smi  # O la versión que sea
```

## Quick Setup: ros2-dev

Desde la raíz de este repo:

```bash
cd dockers_cirtesu
cp .env.example .env
nano .env
```

Edita como mínimo estas variables:

```env
MAIN_MOUNT_VOLUME=/home/usuario/depth_anything_ws
CONTAINER_WORKSPACE=/home/usuario/DockerWorkspace
CONTAINER_USER=usuario
```

Revisa en `docker-compose.yml` la sección `x-common-volumes` y asegúrate de
que solo monta las carpetas que necesitas en esa máquina. Por ahora incluye el
workspace principal, X11 y `/dev`

Revisa cómo queda el compose resuelto:

```bash
docker compose --profile ros2-dev-profile config
```

Construye y lanza el contenedor:

```bash
docker compose build ros2-dev
docker compose --profile ros2-dev-profile up -d
docker exec -it ros2-dev bash
docker compose --profile ros2-dev-profile down
```

Comprobación rápida:

```bash
id
pwd
ros2 --help >/dev/null && echo ros2_ok
nvidia-smi
```

## Build

```bash
# 1) Base
docker build -f docker/ros2-dev-base/Dockerfile -t diegomarza/ros2-dev-base:latest \
  --build-arg USERNAME=$(id -un) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  docker/ros2-dev-base

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
- `x-common-volumes`: montaje principal, `Xauthority` y `/dev`.
- `x-common-service`: red `host`, IPC `host`, `privileged`, GPU, `tty`, `stdin_open`, `working_dir` y `command: bash`.

> Perfil activo por ahora: `ros2-dev-profile`.

Si no activas un perfil, no arranca ningún servicio.

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
