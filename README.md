# Learn AWS - Progetto di Apprendimento AWS e Infrastructure as Code

Repository per imparare AWS services e Infrastructure as Code con Terraform.

## Obiettivo del Progetto

Creare un'applicazione serverless completa per imparare i servizi AWS più comuni:
- **Frontend React** con login Cognito
- **Backend serverless** con Lambda functions
- **API REST** e **GraphQL** 
- **Storage** su S3
- **Infrastructure as Code** con Terraform
- **CI/CD** con GitHub Actions

## Architettura

```
┌─────────────────────────────────────────────────────────────────┐
│                        React Frontend                            │
│                    (Login Cognito + 2 bottoni)                   │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              │ JWT Token
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Cognito User Pool                        │
│                      (Autenticazione)                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
┌──────────────────────────────┐  ┌──────────────────────────────┐
│      API Gateway (REST)      │  │       AppSync (GraphQL)       │
│   + Cognito Authorizer       │  │   + Cognito Auth              │
└──────────────┬───────────────┘  └──────────────┬───────────────┘
               │                                  │
               ▼                                  ▼
┌──────────────────────────────┐  ┌──────────────────────────────┐
│   Lambda REST Function       │  │   Lambda GraphQL Function    │
│   (Valida JWT + Legge S3)    │  │   (Valida JWT + Legge S3)    │
└──────────────┬───────────────┘  └──────────────┬───────────────┘
               │                                  │
               └──────────────┬───────────────────┘
                              ▼
              ┌───────────────────────────────┐
              │        S3 Bucket              │
              │    (Storage dati)             │
              └───────────────────────────────┘
```

## Servizi AWS Imparati

### Autenticazione
- **Cognito User Pool**: User authentication e JWT tokens
- **Cognito User Pool Client**: React frontend integration

### Backend
- **Lambda Functions**: Serverless compute (REST + GraphQL)
- **API Gateway**: REST API endpoints con Cognito authorizer
- **AppSync**: GraphQL API con Cognito authentication

### Storage
- **S3 Bucket**: Object storage per dati

### Infrastructure as Code
- **Terraform**: Declarative infrastructure management
- **AWS Provider**: Terraform provider per AWS

### CI/CD
- **GitHub Actions**: Automated deployment pipeline

## Struttura Progetto

```
learn-aws/
├── terraform/              # Infrastructure as Code
│   ├── provider.tf         # AWS provider configuration
│   ├── variables.tf        # Input variables
│   ├── main.tf            # AWS resources definition
│   └── outputs.tf         # Output for frontend
├── backend/               # Lambda functions
│   └── lambda/
│       ├── rest/          # REST API Lambda
│       └── graphql/       # GraphQL Lambda
├── frontend/              # React application
│   └── (React app)
├── AWS-explained/        # Documentation
│   ├── IAM.md
│   ├── roadmap.md
│   ├── terraform-overview.md
│   └── infrastructure-terraform.md
└── README.md
```

## Getting Started

### Prerequisiti
- AWS Account con IAM user configurato
- Terraform installato
- AWS CLI configurato con credenziali
- Node.js per Lambda functions

### Configurazione AWS CLI
```bash
aws configure
# Access Key ID: [tuo access key]
# Secret Access Key: [tuo secret key]
# Default region: eu-north-1
# Default output format: json
```

### Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Output per Frontend
```bash
terraform output user_pool_id
terraform output user_pool_client_id
terraform output appsync_api_url
terraform output api_gateway_url
```

### Cleanup
```bash
cd terraform
terraform destroy
```

## Workflow Sviluppo

1. **Scrivi codice Terraform** → Definisci infrastruttura
2. **terraform plan** → Vedi cosa cambierà
3. **terraform apply** → Crea risorse AWS
4. **Sviluppa Lambda functions** → Backend logic
5. **Sviluppa React frontend** → UI con Cognito login
6. **GitHub Actions** → CI/CD automation

## Comandi Utili

### Terraform
```bash
terraform init          # Scarica provider
terraform plan          # Pianifica modifiche
terraform apply         # Applica modifiche
terraform destroy       # Distrugge risorse
terraform output        # Mostra output
```

### AWS CLI
```bash
aws resource-groups list-resources  # Tutte le risorse
aws s3 ls                           # Bucket S3
aws lambda list-functions           # Lambda functions
aws cognito-idp list-user-pools     # User pools
```

## Costi AWS

- **Cognito**: Gratis fino a 50k MAU/mese
- **Lambda**: Gratis fino a 1M richieste/mese
- **S3**: ~€0.023/GB storage
- **API Gateway**: ~$3.50/M richieste
- **AppSync**: ~$4/M query

## Note Importanti

- **Terraform state** viene mantenuto in ogni folder separatamente
- **Stesso IAM user** può essere usato per più progetti
- **terraform destroy** distrugge solo risorse nel folder corrente
- **Sempre terraform plan** prima di terraform apply

## Risorse

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

Progetto di apprendimento personale.
