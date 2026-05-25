

# Idempotency Project

Proyecto de ejemplo para manejo de transferencias bancarias con idempotencia y procesamiento asíncrono.

## Requisitos

- macOS
- Ruby 3.4.4
- Rails ~> 8.1.1
- PostgreSQL 15+
- Redis
- Docker y Docker Compose (opcional, recomendado)

## Instalación y ejecución en macOS

1. **Clona el repositorio y entra al directorio:**
	```sh
	git clone https://github.com/daniel-arenas-ror/backoffice_ROR
	cd idempotency_project
	```

2. **Instala dependencias Ruby:**
	```sh
	gem install bundler
	bundle install
	```

3. **Configura la base de datos:**
	- Usando Docker Compose (recomendado):
	  ```sh
	  docker-compose -f docker-compose.yml up -d
	  ```
	- O instala PostgreSQL localmente y crea la base de datos `idempotency_project_development`.

4. **Configura Redis:**
	```sh
	brew install redis
	brew services start redis
	```

5. **Configura las credenciales de Rails:**
	```sh
	EDITOR="vim" bin/rails credentials:edit
	```

6. **Crea y migra la base de datos:**
	```sh
	bin/rails db:setup
	```

7. **Inicia Sidekiq:**
	```sh
	bundle exec sidekiq
	```

8. **Inicia el servidor Rails:**
	```sh
	bin/rails server
	```

9. **Correr pruebas automaticas**

  ```sh
  bundle exec rspec
  ```

## Endpoints API

### 1. Crear transferencia

**POST** `/api/v1/transfers`

Request ejemplo:
```sh
curl --location 'http://localhost:3000/api/v1/transfers' \
--header 'Content-Type: application/json' \
--data '{
	 "transfer": {
		  "user_id": 3,
		  "amount_cents": 50000,
		  "idempotency_key": "swxwqweqee233ecdec"
	 }
}'
```

**Respuesta exitosa:**
```json
{
  "id": 5,
  "user_id": 3,
  "amount_cents": 50000,
  "idempotency_key": "swxwqweqee233ecdec",
  "status": "pending",
  "created_at": "2026-05-25T20:34:05.955Z",
  "updated_at": "2026-05-25T20:34:05.955Z"
}
```

Si se repite la petición con el mismo `idempotency_key`, retorna el mismo objeto transferencia.

---

### 2. Consultar estado de transferencia

**GET** `/api/v1/transfers/:id`

Request ejemplo:
```sh
curl --location 'http://localhost:3000/api/v1/transfers/3'
```

**Respuesta exitosa:**
```json
{
  "id": 3,
  "user_id": 3,
  "amount_cents": 50000,
  "idempotency_key": "dcewerwercededcced",
  "status": "processing",
  "created_at": "2026-05-25T20:30:04.016Z",
  "updated_at": "2026-05-25T20:30:04.075Z"
}
```

---

### 3. Webhook para actualizar estado

**POST** `/api/v1/webhooks/transfers/transfer_result`

Request ejemplo:
```sh
curl --location 'http://localhost:3000/api/v1/webhooks/transfers/transfer_result' \
--header 'Content-Type: application/json' \
--data '{
	 "transfer_id": 1,
	 "status": "success"
}'
```

**Respuesta exitosa:**
```json
{
  "status": "completed",
  "message": "Transferencia actualizada con éxito."
}
```

Si el webhook ya fue procesado antes, retorna:
```json
{
  "status": "completed",
  "message": "Webhook procesado previamente."
}
```

---

## Notas

- El procesamiento de transferencias es asíncrono y puede tomar unos segundos.
- El campo `idempotency_key` asegura que la transferencia no se duplique si se reintenta la petición.
