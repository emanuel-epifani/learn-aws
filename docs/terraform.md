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

## Comandi di Terraform

### `terraform init`

Prepara la cartella. Scarica il provider AWS e registra i moduli locali. Va fatto **una sola volta** e ogni volta che aggiungi un nuovo modulo.

```bash
cd terraform/environments/dev
terraform init
```

Crea la cartella `.terraform/` con i binari del provider e il file `.terraform.lock.hcl` (che va committato).

### `terraform plan`

Simulazione. Mostra cosa creerebbe/modificherebbe/distruggerebbe **senza toccare nulla**. I simboli:

- `+` = crea
- `~` = modifica
- `-` = distrugge
- `(known after apply)` = AWS lo genera dopo, non lo sai ancora

```bash
terraform plan
```

### `terraform apply`

Esegue davvero. Crea/modifica/distrugge le risorse su AWS. Ti chiede conferma prima di procedere.

```bash
terraform apply
```

Dopo `apply`, Terraform stampa gli output (URL, ID, ecc.) e aggiorna `terraform.tfstate`.

### `terraform destroy`

Distrugge tutte le risorse create. Utile per pulire e non pagare.

```bash
terraform destroy
```

### `terraform output`

Stampa solo gli output (senza fare plan o apply). Utile per recuperare URL e ID dopo.

```bash
terraform output
```

### `terraform state list`

Mostra tutte le risorse gestite da Terraform. Utile per capire cosa c'è nello state.

```bash
terraform state list
```

## Ordine di lavoro per ogni modulo

Quando aggiungi o modifichi un modulo, segui questo ciclo:

```
1. Scrivi i file del modulo (variables.tf → main.tf → outputs.tf)
2. Collega il modulo in environments/dev/main.tf
3. Aggiungi gli output in environments/dev/outputs.tf
4. terraform init     ← solo se è un nuovo modulo
5. terraform plan     ← verifica che non ci siano errori
6. terraform apply    ← crea le risorse su AWS
7. Commit             ← modulo completo
```

**Sempre dalla cartella dell'ambiente:**

```bash
cd terraform/environments/dev
```

Mai lanciare Terraform dalla root del progetto o dalla cartella del modulo.

## Cosa fare se qualcosa va storto

| Problema | Cosa fare |
|---|---|
| `No configuration files` | Sei nella cartella sbagliata. Vai in `terraform/environments/dev` |
| `No valid credential sources` | Lancia `aws configure` o verifica il profilo in `provider "aws"` |
| `Error: module not found` | Lancia `terraform init` per registrare il nuovo modulo |
| `terraform plan` mostra troppe risorse | Controlla `terraform.tfstate`, potrebbe essere corrotto o vuoto |
| Risorse non vengono distrutte | `terraform destroy` non distrugge bucket S3 non vuoti. Svouta il bucket prima |
