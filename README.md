# Infraestructura como Código (AWS + Terraform)

El equipo concluyó que el diagrama muestra una arquitectura AWS para el procesamiento de imágenes, el cliente sube su imagen, se redimensiona y se almacena.

## Requisitos
- AWS CLI configurado
- Terraform CLI
- Node.js y npm

## Instrucciones

### 1. Instalación de dependencias

```bash
cd infra/lambda
npm install
cd ..
```

### 2. Configuración de variables

Crear el archivo `infra/terraform.tfvars`:

```hcl
aws_profile = "default"
environment = "dev"
```

### 3. Despliegue de la infraestructura

```bash
cd infra
terraform init
terraform apply
```

### 4. Endpoint y Verificación

**Ruta de API Gateway:** `POST {api_url}/upload`

**Formatos de entrada aceptados:**
- `multipart/form-data`: Archivo adjunto.
- `application/json`: Payload JSON (`fileBase64`, `mimeType`, `filename`).

**Tipos permitidos:** `image/jpeg`, `image/png`, `image/gif`, `image/webp` (máximo 10 MB).

**Verificación en Amazon S3:**
- La imagen original se almacena bajo el prefijo `uploads/`.
- El flujo genera la imagen recortada de 40x40 en `processed/`.

### 5. Destrucción de recursos

```bash
terraform destroy
```