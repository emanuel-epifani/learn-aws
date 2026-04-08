# Terraform per AWS - Guida Completa

## Convenzioni vs Nomi Personalizzati

### Convenzioni Standard Terraform
```
main.tf          # File principale con le risorse (CONVENZIONE)
variables.tf     # Definizione variabili (CONVENZIONE)
outputs.tf       # Output delle risorse (CONVENZIONE)
provider.tf      # Configurazione provider (CONVENZIONE)
terraform.tfvars # Valori variabili (CONVENZIONE)
```

### Nomi Personalizzati (scelti da me)
```
lambda_zip/      # Cartella per Lambda zippate (PERSONALE)
backend/         # Codice backend (PERSONALE)
frontend/        # Codice frontend (PERSONALE)
```

### GitHub Actions Convenzioni
```
.github/workflows/    # Percorso OBBLIGATORIO per GitHub Actions
deploy.yml            # Nome file workflow (PERSONALE)
ci.yml               # Altro nome comune (PERSONALE)
```

**Regola:** Se un nome è richiesto dal sistema (.github/workflows/), è obbligatorio. Se è solo organizzazione, è personale.

---

## Struttura Progetto Terraform

### Struttura Minima Raccomandata
```
my-project/
terraform/
|-- main.tf              # Risorse principali
|-- variables.tf         # Variabili di input
|-- outputs.tf           # Output per altri servizi
|-- provider.tf          # Configurazione provider AWS
|-- terraform.tfvars     # Valori specifici ambiente
|-- modules/             # Moduli riutilizzabili
|   |-- s3/
|   |-- lambda/
|   `-- cognito/
`-- environments/         # Configurazioni per ambienti
    |-- dev/
    |-- staging/
    `-- prod/
```

---

## Comandi Base Terraform

### 1. Inizializzazione
```bash
# Scarica i provider necessari (AWS, Azure, etc.)
terraform init

# Inizializza con backend specifico
terraform init -backend-config="bucket=my-terraform-state"
```

### 2. Pianificazione
```bash
# Mostra cosa cambierà (NON applica modifiche)
terraform plan

# Salva il piano in un file
terraform plan -out=tfplan

# Applica un piano salvato
terraform apply tfplan
```

### 3. Applicazione
```bash
# Applica le modifiche (richiede conferma)
terraform apply

# Applica senza conferma (per CI/CD)
terraform apply -auto-approve
```

### 4. Distruzione
```bash
# Distrugge tutte le risorse (richiede conferma)
terraform destroy

# Distrugge senza conferma
terraform destroy -auto-approve
```

### 5. Validazione e Formattazione
```bash
# Controlla sintassi HCL
terraform validate

# Formatta il codice HCL
terraform fmt

# Formatta ricorsivamente
terraform fmt -recursive
```

---

## File Terraform Dettagliati

### variables.tf
```hcl
# Variabili obbligatorie
variable "project_name" {
  description = "Nome del progetto"
  type = string
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Il project_name deve contenere solo lettere minuscole, numeri e trattini."
  }
}

variable "aws_region" {
  description = "Regione AWS"
  type = string
  default = "eu-north-1"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type = string
  default = "dev"
}

# Variabili opzionali
variable "tags" {
  description = "Tags per le risorse"
  type = map(string)
  default = {}
}
```

### provider.tf
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider AWS principale
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project = var.project_name
      Environment = var.environment
      ManagedBy = "Terraform"
    }
  }
}

# Provider per altro regione (opzionale)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
```

### main.tf - Esempio Completo
```hcl
# 1. S3 Bucket
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.project_name}-data-${random_id.bucket_suffix.hex}"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-data"
  })
}

# 2. Random ID per nomi unici
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 3. Cognito User Pool
resource "aws_cognito_user_pool" "users" {
  user_pool_name = "${var.project_name}-users"
  
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }
  
  auto_verified_attributes = ["email"]
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-users"
  })
}

# 4. Cognito User Pool Client
resource "aws_cognito_user_pool_client" "web_client" {
  user_pool_id = aws_cognito_user_pool.users.id
  client_name  = "${var.project_name}-web-client"
  
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  
  generate_secret = false
}

# 5. IAM Role per Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 6. Lambda Function
resource "aws_lambda_function" "rest_api" {
  function_name = "${var.project_name}-rest-api"
  runtime = "nodejs18.x"
  handler = "rest.handler"
  role = aws_iam_role.lambda_role.arn
  
  filename = "lambda_rest.zip"
  source_code_hash = filebase64sha256("lambda_rest.zip")
  
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_bucket.bucket
      USER_POOL_ID = aws_cognito_user_pool.users.id
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-rest-api"
  })
}

# 7. API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-api"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# 8. Authorizer Cognito
resource "aws_api_gateway_authorizer" "cognito" {
  name = "cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.api.id
  type = "COGNITO_USER_POOLS"
  
  provider_arns = [aws_cognito_user_pool.users.arn]
}
```

### outputs.tf
```hcl
# Output per frontend
output "user_pool_id" {
  description = "ID del Cognito User Pool"
  value = aws_cognito_user_pool.users.id
}

output "user_pool_client_id" {
  description = "ID del Cognito User Pool Client"
  value = aws_cognito_user_pool_client.web_client.id
}

output "api_gateway_url" {
  description = "URL dell'API Gateway"
  value = aws_api_gateway_rest_api.api.deployment_url
}

output "s3_bucket_name" {
  description = "Nome del bucket S3"
  value = aws_s3_bucket.data_bucket.bucket
}

# Output per debugging
output "lambda_role_arn" {
  description = "ARN del ruolo Lambda"
  value = aws_iam_role.lambda_role.arn
}

output "lambda_function_name" {
  description = "Nome della funzione Lambda"
  value = aws_lambda_function.rest_api.function_name
}
```

### terraform.tfvars
```hcl
# Valori per ambiente dev
project_name = "learn-aws"
aws_region = "eu-north-1"
environment = "dev"

tags = {
  Owner = "emanuele"
  Team = "learning"
  CostCenter = "education"
}
```

---

## Best Practices

### 1. Organizzazione per Ambienti
```
environments/
|-- dev/
|   |-- main.tf
|   |-- variables.tf
|   `-- terraform.tfvars
|-- staging/
|   |-- main.tf
|   |-- variables.tf
|   `-- terraform.tfvars
`-- prod/
    |-- main.tf
    |-- variables.tf
    `-- terraform.tfvars
```

### 2. Moduli Riutilizzabili
```hcl
# modules/s3/main.tf
variable "bucket_name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name_prefix}-${random_id.suffix.hex}"
  tags = var.tags
}

# Uso del modulo
module "data_bucket" {
  source = "./modules/s3"
  bucket_name_prefix = "${var.project_name}-data"
  tags = var.tags
}
```

### 3. Remote State (per team)
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key = "learn-aws/terraform.tfstate"
    region = "eu-north-1"
    encrypt = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 4. Gestione Segreti
```hcl
# Non mettere segreti in terraform.tfvars!
# Usa variabili d'ambiente o AWS Secrets Manager

variable "db_password" {
  description = "Password database"
  type = string
  sensitive = true
}
```

---

## Comandi Avanzati

### Import Risorse Esistenti
```bash
# Importa una risorsa esistente in Terraform
terraform import aws_s3_bucket.data_bucket my-existing-bucket-name
```

### Workspace per Ambienti
```bash
# Crea workspace
terraform workspace new dev
terraform workspace new prod

# Cambia workspace
terraform workspace select dev

# Lista workspace
terraform workspace list
```

### Taint e Untaint
```bash
# Marchia risorsa da ricreare
terraform taint aws_lambda_function.rest_api

# Rimuovi marca
terraform untaint aws_lambda_function.rest_api
```

### Refresh State
```bash
# Aggiorna stato Terraform con risorse reali
terraform refresh
```

---

## Troubleshooting Comune

### 1. "Error: No configuration files"
```bash
# Controlla di essere nella directory giusta
ls -la terraform/
cd terraform/
terraform init
```

### 2. "Error: Provider not found"
```bash
# Re-inizializza
terraform init -upgrade
```

### 3. "Error: State lock"
```bash
# Forza unlock (attenzione!)
terraform force-unlock LOCK_ID
```

### 4. "Error: Resource already exists"
```bash
# Importa risorsa esistente
terraform import aws_s3_bucket.data_bucket bucket-name
```

---

## Terraform vs Console AWS

| Operazione | Console AWS | Terraform |
|------------|-------------|-----------|
| Creazione risorse | Click GUI | Codice HCL |
| Modifica | Click edit | Modifica codice |
| Tracking | Manuale | Automatico |
| Team collaboration | Difficile | Git-based |
| Reproducibility | No | Sì |
| Version control | No | Sì |

---

## Prossimi Passi per il Tuo Progetto

1. **Setup progetto base**
   ```bash
   mkdir -p learn-aws/terraform
   cd learn-aws/terraform
   ```

2. **Crea file base**
   - `provider.tf`
   - `variables.tf`
   - `main.tf`
   - `outputs.tf`

3. **Test iniziale**
   ```bash
   terraform init
   terraform validate
   terraform plan
   ```

4. **Aggiungi risorse gradualmente**
   - S3 bucket
   - Cognito
   - Lambda
   - API Gateway

5. **Setup GitHub Actions**
   - Workflow per deploy automatico
   - Secrets per AWS credentials

Ricorda: Terraform è dichiarativo, non procedurale. Descrivi COSA vuoi, non COME crearlo.
