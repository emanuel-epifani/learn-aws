# Autenticazione AWS e Terraform

## AWS CLI — Login locale

```bash
aws configure
# Access Key ID: AKIA...
# Secret Access Key: ...
# Default region: eu-north-1
```

Verifica chi sei:
```bash
aws sts get-caller-identity
# {
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/mario",
#   "UserId": "AIDAXXXXX"
# }
```

## Profili multipli

Configura più account:
```bash
aws configure --profile lavoro
aws configure --profile personale
```

Usa un profilo specifico:
```bash
aws s3 ls --profile lavoro
```

Vedi i profili salvati:
```bash
cat ~/.aws/credentials
cat ~/.aws/config
```

## Terraform — Come si autentica

Terraform non ha login proprio. Legge le credenziali in questo ordine:

### 1. Variabili d'ambiente (usate in CI/CD)
```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=eu-north-1
terraform apply
```

### 2. Profilo AWS CLI (usato in locale)
```hcl
provider "aws" {
  profile = "lavoro"
  region  = "eu-north-1"
}
```

### 3. Assume Role (best practice in produzione)
```hcl
provider "aws" {
  region = "eu-north-1"
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  }
}
```

## Pipeline — Autenticazione in CI/CD

### Metodo moderno: OIDC (consigliato)

Nessuna secret key nel repository. GitHub Actions assume un ruolo IAM tramite token OIDC.

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
      aws-region: eu-north-1

  - run: terraform init && terraform apply -auto-approve
```

### Metodo legacy: Secrets (da evitare)

```yaml
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## Riassunto metodi

| Metodo | Quando usarlo | Vantaggi | Svantaggi |
|--------|-------------|----------|-----------|
| `aws configure` | Sviluppo locale | Semplice | Credenziali sul disco |
| Profili multipli | Più account AWS | Organizzato | Da gestire manualmente |
| Variabili d'ambiente | CI/CD semplice | Facile da automare | Esposte nei log se non attenzione |
| Assume Role | Produzione, team | Credenziali temporanee, audit trail | Richiede configurazione IAM |
| OIDC | Pipeline GitHub/GitLab | Zero secret nel repo, sicuro | Richiede setup iniziale |

## Comandi utili

```bash
aws sts get-caller-identity          # Chi sono ora
aws configure list                   # Configurazione attiva
aws configure list-profiles          # Elenca tutti i profili
aws iam list-users                   # Utenti IAM nell'account
```
