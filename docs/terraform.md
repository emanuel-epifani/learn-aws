# Terraform — Come Funziona e Best Practice

## Come funziona Terraform

Terraform legge file `.tf` (linguaggio HCL), costruisce un grafo delle risorse, confronta lo stato desiderato con quello reale su AWS, e applica le differenze.

```
.tuoi file .tf  →  terraform plan  →  terraform apply  →  AWS
                        ↑                                   │
                        └──── terraform.tfstate ◄───────────┘
```

- **plan**: mostra cosa cambierà senza toccare nulla.
- **apply**: crea/modifica/distrugge le risorse reali.
- **state**: file che registra com'è il mondo reale. Mai editare a mano, mai committare.

## I 5 file di Terraform

### `main.tf` — il codice

È dove scrivi le risorse e chiami i moduli. Terraform parte da qui.

```hcl
# environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"
  name   = "learn-aws-dev"
}
```

### `variables.tf` — la dichiarazione

Definisce **quali** variabili esistono, il tipo, e un default. **Non contiene valori concreti.**

```hcl
variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "db_instance_class" {
  type    = string
  # niente default: obbligatorio passarlo
}
```

### `terraform.tfvars` — i valori concreti per ambiente

È qui che **valorizzi** le variabili dichiarate in `variables.tf`. Cambia per ogni ambiente.

```hcl
# environments/dev/terraform.tfvars
aws_region         = "eu-north-1"
environment        = "dev"
db_instance_class  = "db.t3.micro"
```

```hcl
# environments/prod/terraform.tfvars
aws_region         = "eu-north-1"
environment        = "prod"
db_instance_class  = "db.t3.medium"
```

**Il flusso**: `variables.tf` dice "esiste una variabile `db_instance_class` di tipo string". `terraform.tfvars` dice "in dev vale `db.t3.micro`". `main.tf` la usa come `var.db_instance_class`.

### `outputs.tf` — valori in uscita

**Li scrivi tu a mano.** Non sono autogenerati. Servono a esporre valori che ti servono fuori dal modulo.

```hcl
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
```

Dopo `terraform apply`, ti stampa:
```
Outputs:
alb_dns_name = "learn-aws-alb-123456.eu-north-1.elb.amazonaws.com"
```

Servono per:
- Il frontend che ha bisogno dell'URL dell'ALB e del Cognito User Pool ID.
- Un modulo che ne usa un altro: il modulo VPC espone `vpc_id`, il modulo ALB lo legge.
- Te, che vuoi sapere l'endpoint RDS senza aprire la console AWS.

### `terraform.tfstate` — lo snapshot

È un **JSON che registra lo stato reale di AWS**. Non lo scrivi tu, lo gestisce Terraform.

Risponde alla domanda: *"com'è il mondo reale adesso?"*

Quando lanci `terraform plan`, Terraform:
1. Legge i tuoi `.tf` → **stato desiderato**
2. Legge `terraform.tfstate` → **stato noto**
3. Chiama AWS API → **stato reale**
4. Confronta e mostra le differenze

**Uno per ambiente**: `environments/dev/terraform.tfstate` e `environments/prod/terraform.tfstate` sono file separati. Ogni ambiente ha il suo state, definito dal `backend` in `main.tf`:

```hcl
backend "s3" {
  key = "dev/terraform.tfstate"
}
```

## Riassunto file

| File | Chi lo scrive | Cosa fa |
|---|---|---|
| `main.tf` | Tu | Codice: risorse e moduli |
| `variables.tf` | Tu | Dichiara variabili (tipo + default) |
| `terraform.tfvars` | Tu | Valori concreti per quell'ambiente |
| `outputs.tf` | Tu | Valori da esporre (a te, al frontend, ad altri moduli) |
| `terraform.tfstate` | Terraform | Snapshot dello stato reale AWS |

## Struttura multi-ambiente

```
terraform/
├── modules/              # codice condiviso, riutilizzabile
│   ├── vpc/
│   │   ├── main.tf       # risorse VPC
│   │   ├── variables.tf  # cosa il modulo accetta in input
│   │   └── outputs.tf    # cosa il modulo restituisce
│   ├── cognito/
│   ├── s3/
│   ├── iam/
│   ├── ecr/
│   ├── alb/
│   ├── rds/
│   ├── ecs/
│   ├── apigateway/
│   └── lambda/
├── environments/
│   └── dev/
│       ├── main.tf           # provider + backend + chiama moduli
│       ├── variables.tf      # variabili globali
│       ├── outputs.tf        # output per frontend
│       └── terraform.tfvars  # valori concreti per dev
```

Ogni modulo è un blocco riutilizzabile. `environments/dev/main.tf` li chiama tutti passando i valori da `terraform.tfvars`:

```hcl
module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name    # arriva da terraform.tfvars
  environment  = var.environment
}
```

I moduli **non hanno `terraform.tfvars`**: ricevono i valori dal `main.tf` dell'ambiente che li chiama.

## Best practice

### 1. State remoto, mai locale

Il `terraform.tfstate` non deve stare su git. Si mette su S3 + DynamoDB (lock):

```hcl
terraform {
  backend "s3" {
    bucket         = "learn-aws-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "learn-aws-tf-locks"
    encrypt        = true
  }
}
```

### 2. Tagging uniforme

Ogni risorsa ha gli stessi tag:

```hcl
tags = {
  Project     = "learn-aws"
  Environment = var.environment
  ManagedBy   = "terraform"
}
```

### 3. Mai hardcode

Male: `region = "eu-north-1"` dentro ogni risorsa.
Bene: `region = var.aws_region` ovunque.

### 4. terraform plan sempre prima di apply

Sempre. Senza eccezioni.
