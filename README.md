# MISW-4304-DevOps

## Requisitos

- Python 3.14 (estable actual)
- PostgreSQL

## Instalacion

1. Crear y activar entorno virtual.
2. Instalar dependencias:

```bash
pip install -r requirements.txt
```

## Ejecucion

```bash
python run.py
```

## Docker

Construir la imagen:

```bash
docker build -t blacklist-service:latest .
```

Ejecutar localmente:

```bash
docker run --rm -p 5000:5000 \
	-e DATABASE_URL=postgresql+psycopg://user:password@host.docker.internal:5432/blacklist_db \
	-e JWT_SECRET_KEY=your-secret \
	-e SERVICE_USERNAME=admin \
	-e SERVICE_PASSWORD=your-password \
	blacklist-service:latest
```

Inicializar tablas antes del arranque del servidor (opcional):

```bash
docker run --rm -p 5000:5000 \
	-e DATABASE_URL=postgresql+psycopg://user:password@host.docker.internal:5432/blacklist_db \
	-e JWT_SECRET_KEY=your-secret \
	-e SERVICE_USERNAME=admin \
	-e SERVICE_PASSWORD=your-password \
	-e RUN_DB_INIT=true \
	-e DB_INIT_REQUIRED=true \
	blacklist-service:latest
```

Variables del init script:

- `RUN_DB_INIT`: ejecuta `scripts/init_db.py` al iniciar el contenedor (`true` o `false`).
- `DB_INIT_REQUIRED`: si esta en `true`, el contenedor falla si no puede inicializar BD.
- `DB_INIT_MAX_RETRIES`: numero de reintentos para conectar/inicializar (default `10`).
- `DB_INIT_RETRY_DELAY_SECONDS`: espera entre reintentos en segundos (default `5`).

## Despliegue en Elastic Beanstalk (Docker)

1. Crear un entorno de Elastic Beanstalk usando plataforma Docker (single container).
2. Subir el codigo fuente con el `Dockerfile` en la raiz del proyecto.
3. Configurar variables de entorno en Elastic Beanstalk:
	 - `DATABASE_URL`
	 - `JWT_SECRET_KEY`
	 - `JWT_EXPIRES_HOURS` (opcional)
	 - `SERVICE_USERNAME`
	 - `SERVICE_PASSWORD`
	 - `RUN_DB_INIT` (opcional)
	 - `DB_INIT_REQUIRED` (opcional)
	 - `DB_INIT_MAX_RETRIES` (opcional)
	 - `DB_INIT_RETRY_DELAY_SECONDS` (opcional)
4. Verificar conectividad de red hacia PostgreSQL (security groups, VPC, puerto 5432).