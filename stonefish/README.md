Arranque minimo previsto:

```bash
docker build -f docker/stonefish/Dockerfile -t diegomarza/stonefish:latest .
docker compose -f docker/docker-compose.yml --profile stonefish up -d
docker exec -it stonefish bash
build_stonefish_ws
source_stonefish_env
```

Validación inicial:

```bash
PKGSHARE=$(ros2 pkg prefix peacetolero_stonefish)/share/peacetolero_stonefish

ros2 launch stonefish_ros2 stonefish_simulator.launch.py \
  simulation_data:=$PKGSHARE/resources \
  scenario_desc:=$PKGSHARE/scenarios/cirtesu_tank.scn \
  simulation_rate:=100.0 window_res_x:=1200 window_res_y:=800 rendering_quality:=high
```
