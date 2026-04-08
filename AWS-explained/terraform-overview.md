# Terraform - Overview Completo

## Cos'è Terraform

Terraform è un **Infrastructure as Code (IaC)** tool creato da HashiCorp che permette di definire, provisionare e gestire infrastruttura cloud in modo **declarativo**.

### Concetto Chiave: Declarative vs Imperative

**Declarative (Terraform):**
```hcl
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-data-bucket"
  encryption = "AES256"
}
```
*Descrivi COSA vuoi, non COME crearlo*

**Imperative (AWS CLI):**
```bash
aws s3api create-bucket --bucket my-data-bucket
aws s3api put-bucket-encryption --bucket my-data-bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```
*Descrivi i passaggi per creare la risorsa*

## Come Funziona Terraform

### 1. Workflow Base
```
1. Scrivi codice HCL (HashiCorp Configuration Language)
2. terraform init (scarica provider)
3. terraform plan (mostra cosa cambierà)
4. terraform apply (applica modifiche)
5. Stato salvato in .tfstate file
```

### 2. State Management
Terraform mantiene un **state file** che traccia:
- Risorse create
- Dipendenze tra risorse
- Metadata delle risorse

```bash
# Il file .tfstate contiene mapping tra codice e risorse reali
{
  "version": 4,
  "terraform_version": "1.5.0",
  "resources": [
    {
      "mode": "managed",
      "type": "aws_s3_bucket",
      "name": "my_bucket",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]"
    }
  ]
}
```

### 3. Provider Architecture
Terraform usa **provider** per comunicare con diversi servizi cloud:

```hcl
# Provider AWS
provider "aws" {
  region = "eu-north-1"
}

# Provider Azure
provider "azurerm" {
  features {}
}

# Provider Google Cloud
provider "google" {
  project = "my-project"
  region = "us-central1"
}
```

## Struttura Progetto Terraform

### Convenzioni Standard
```
my-project/
terraform/
|-- main.tf              # Risorse principali
|-- variables.tf         # Variabili di input
|-- outputs.tf           # Output delle risorse
|-- provider.tf          # Configurazione provider
|-- terraform.tfvars     # Valori variabili
|-- .terraform/          # Stato e plugin (auto-generato)
|-- .terraform.lock.hcl  # Lock versioni provider
`-- terraform.tfstate    # Stato infrastruttura (auto-generato)
```

### File Dettagliati

#### main.tf - Risorse Principali
```hcl
# Definizione risorse AWS
resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-data-bucket"
  
  tags = {
    Environment = "dev"
    Project = "learn-aws"
  }
}

resource "aws_lambda_function" "api" {
  function_name = "my-api"
  runtime = "nodejs18.x"
  handler = "index.handler"
  role = aws_iam_role.lambda_role.arn
}
```

#### variables.tf - Variabili di Input
```hcl
variable "project_name" {
  description = "Nome del progetto"
  type = string
  default = "learn-aws"
}

variable "aws_region" {
  description = "Regione AWS"
  type = string
  default = "eu-north-1"
}

variable "enable_logging" {
  description = "Abilita logging"
  type = bool
  default = true
}
```

#### outputs.tf - Output Risorse
```hcl
output "bucket_name" {
  description = "Nome del bucket S3"
  value = aws_s3_bucket.data_bucket.bucket
}

output "lambda_arn" {
  description = "ARN della funzione Lambda"
  value = aws_lambda_function.api.arn
}
```

#### provider.tf - Configurazione Provider
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

#### terraform.tfvars - Valori Variabili
```hcl
project_name = "my-aws-project"
aws_region = "eu-north-1"
enable_logging = true
```

## Comandi Terraform

### Comandi Base
```bash
# Inizializza il progetto (scarica provider)
terraform init

# Pianifica le modifiche (mostra cosa cambierà)
terraform plan

# Applica le modifiche
terraform apply

# Applica senza conferma (per CI/CD)
terraform apply -auto-approve

# Distrugge tutte le risorse
terraform destroy
```

### Comandi di Gestione
```bash
# Valida sintassi HCL
terraform validate

# Formatta il codice
terraform fmt

# Aggiorna stato con risorse reali
terraform refresh

# Importa risorse esistenti
terraform import aws_s3_bucket.data_bucket bucket-name
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

## Concetti Avanzati

### 1. Dipendenze Implicithe
Terraform crea automaticamente le dipendenze:

```hcl
resource "aws_s3_bucket" "bucket" {
  bucket = "my-bucket"
}

resource "aws_lambda_function" "lambda" {
  function_name = "my-lambda"
  # Terraform capisce che bucket deve esistere prima
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.bucket.bucket
    }
  }
}
```

### 2. Moduli Riutilizzabili
```hcl
# modules/s3/main.tf
variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

# Uso del modulo
module "data_bucket" {
  source = "./modules/s3"
  bucket_name = "my-data-bucket"
}
```

### 3. Remote State
Per team collaboration:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key = "terraform.tfstate"
    region = "eu-north-1"
    encrypt = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 4. Data Sources
Leggi risorse esistenti:

```hcl
# Leggi AMI più recente
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Usa l'AMI in una risorsa
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

## Best Practices

### 1. Organizzazione File
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

### 2. Gestione Segreti
```hcl
# Non mettere segreti in terraform.tfvars!
variable "db_password" {
  description = "Password database"
  type = string
  sensitive = true
}

# Usa variabili d'ambiente
# export TF_VAR_db_password="secret123"
```

### 3. Validation
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type = string
  
  validation {
    condition = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium."
  }
}
```

## Terraform vs Altri Tool

| Tool | Linguaggio | Provider | Learning Curve | Multi-cloud |
|------|------------|----------|----------------|-------------|
| Terraform | HCL | 100+ | Media | Sì |
| AWS CDK | TypeScript/Python | Solo AWS | Bassa | No |
| Pulumi | Linguaggi generici | 20+ | Alta | Sì |
| CloudFormation | YAML | Solo AWS | Alta | No |

## Quando Usare Terraform

### **Casi Ideali:**
- Multi-cloud strategy
- Team collaboration
- Infrastruttura complessa
- Governance e compliance
- Automazione CI/CD

### **Casi Non Ideali:**
- Solo AWS (CDK è meglio)
- Progetti molto semplici
- Learning curve troppo alta per il team

## Esempio Completo: Web App Serverless

```hcl
# main.tf
provider "aws" {
  region = var.aws_region
}

# S3 bucket per assets statici
resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-assets"
  
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "users" {
  user_pool_name = "${var.project_name}-users"
  
  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers = true
  }
}

# Lambda function
resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-api"
  runtime = "nodejs18.x"
  handler = "index.handler"
  role = aws_iam_role.lambda_role.arn
  
  environment {
    variables = {
      USER_POOL_ID = aws_cognito_user_pool.users.id
      BUCKET_NAME = aws_s3_bucket.static_assets.bucket
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-api"
}

# IAM Role per Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}
```

## Prossimi Passi per Iniziare

1. **Installa Terraform**
2. **Crea struttura progetto base**
3. **Scrivi primo main.tf con una risorsa S3**
4. **Test con terraform init/plan/apply**
5. **Aggiungi gradualmente più risorse**

Ricorda: Terraform è **declarative** - descrivi il risultato finale, non i passaggi intermedi.
