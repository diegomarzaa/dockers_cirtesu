# Docker — Modular Images

Imágenes Docker modulares basadas en `osrf/ros:humble-desktop-full`. Cada imagen hereda de la anterior y añade solo lo que necesita, compartiendo capas para ahorrar disco.

```
osrf/ros:humble-desktop-full
  └── diegomarza/ros2-dev-base    ← dev tools, uv, sudo, colcon, gedit...
        └── diegomarza/ros2-da3-dev ← ROS2 + DA3 + DA3-Streaming en el Python del sistema
        └── diegomarza/stonefish  ← (pendiente revisar) deps/toolchain para compilar Stonefish + ROS 2 en stonefish_ws
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

## Quick Setup

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

Para trabajar con DA3 y ROS2 en el mismo contenedor:

```bash
docker compose --profile ros2-da3-dev-profile config
docker compose build ros2-da3-dev
docker compose --profile ros2-da3-dev-profile up -d
docker exec -it ros2-da3-dev bash
docker compose --profile ros2-da3-dev-profile down
```

## Build

```bash
# 1) Base
docker build -f ros2-dev-base/Dockerfile -t diegomarza/ros2-dev-base:latest \
  --build-arg USERNAME=$(id -un) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  ros2-dev-base

# 2) ROS2 + DA3
docker compose build ros2-da3-dev

# 3) Stonefish
docker build -f stonefish/Dockerfile -t diegomarza/stonefish:latest .
```

## Compose

`docker-compose.yml` orquesta contenedores construidos. Lo común se agrupa en anclas YAML:

- `x-common-env`: pantalla X11 y OpenGL NVIDIA.
- `x-common-volumes`: montaje principal, `Xauthority` y `/dev`.
- `x-common-service`: red `host`, IPC `host`, `privileged`, GPU, `tty`, `stdin_open`, `working_dir` y `command: bash`.

Perfiles principales:

- `ros2-dev-profile`: ROS2 base de desarrollo.
- `ros2-da3-dev-profile`: ROS2 + DA3 + DA3-Streaming.

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
docker push diegomarza/ros2-da3-dev:latest
```

```bash
docker pull diegomarza/ros2-dev-base:latest
docker pull diegomarza/ros2-da3-dev:latest
```

## Permisos

El usuario dentro del contenedor se configura con `CONTAINER_USER`, `CONTAINER_UID` y `CONTAINER_GID` en `.env`. `sudo` está disponible sin contraseña.

## Python en DA3

`ros2-da3-dev` instala DA3, PyTorch y las dependencias de DA3-Streaming en el mismo Python del sistema que usa ROS2. No usa venv, para evitar conflictos de import entre `rclpy` y el wrapper ROS propio.

La copia usada por el editable install vive en `/opt/depth-anything-3`. Esto
evita que el bind mount del workspace tape el paquete cuando una máquina usa
`Repositories/Depth-Anything-3` y otra usa `src/Depth-Anything-3`.
