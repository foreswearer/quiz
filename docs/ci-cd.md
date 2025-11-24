# CI/CD de la plataforma Cloud Digital Leader Quiz

Este documento explica cómo está montado el flujo de **integración continua (CI)** y **despliegue continuo (CD)** de la app de quizzes para el Cloud Digital Leader, para que mi yo-profesor (hola 😄) pueda:

- Recordar la arquitectura.
- Entender qué hace cada pieza.
- Saber cómo usarlo en el día a día.
- Enseñarlo en clase como ejemplo real.

---

## 1. Foto global

### Componentes principales

- **Repositorio GitHub**: `foreswearer/quiz`
- **VM en Google Compute Engine**:
  - OS: Debian 12
  - Servicio `quiz-backend.service` (systemd) que levanta FastAPI con uvicorn.
  - nginx como reverse proxy con TLS (Let's Encrypt).
  - PostgreSQL local en la propia VM.
- **CI/CD**: GitHub Actions  
  Workflow: `.github/workflows/deploy.yml`  
  Nombre visible: **“CI and deploy to quiz VM”**

### Idea central

Cada vez que hago **`git push` a `main`**:

1. GitHub Actions:
   - Instala dependencias.
   - Ejecuta tests (si existen).
   - Copia el código a la VM.
   - Lanza un script `deploy.sh` en la VM.
2. Después reintenta un **health check** contra  
   `https://quiz.ramiro-rego.com/health`.
3. Si todo va bien → **run verde** y la web está actualizada.

---

## 2. Secretos necesarios en GitHub

En el repositorio `foreswearer/quiz` →  
**Settings → Secrets and variables → Actions**

Hay que tener definidos:

- `SSH_HOST`  
  IP pública o hostname de la VM (el que uso para conectarme por SSH).

- `SSH_USER`  
  Usuario de la VM, en mi caso:  
  `ramiro_rego`

- `SSH_KEY`  
  Clave privada SSH (formato OpenSSH) creada **solo para CI** y autorizada en
  `~/.ssh/authorized_keys` de la VM.

> Si algún día hay que rotar la clave:  
> regenerar `id_ed25519_quiz_ci` en la VM, actualizar `authorized_keys` y
> pegar la nueva privada en `SSH_KEY`.

---

## 3. Estructura del workflow (`.github/workflows/deploy.yml`)

Resumen lógico (no es el YAML completo, solo la idea):

```yaml
name: CI and deploy to quiz VM

on:
  push:
    branches: [ "main" ]

jobs:
  test-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Set up Python 3.11
      - Install dependencies (requirements.txt)
      - Run tests (pytest), si existe tests/
      - Copy code to VM (scp)
      - Deploy on VM (ssh → ./deploy.sh)
      - Check application health (curl con reintentos)

