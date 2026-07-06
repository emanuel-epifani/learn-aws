# Learn AWS — Backend + Cloud Project

Side project per dimostrare padronanza di AWS e Terraform in un'architettura realistica per un backend engineer.

## Frontend

Single-page React app con due colonne indipendenti, nessuno shared state tra i backend.

```
┌─────────────────────────────┬─────────────────────────────┐
│         NOTE MANAGER        │         FILE BIN            │
│      (container stack)      │    (serverless stack)       │
├─────────────────────────────┼─────────────────────────────┤
│  Title: _______________     │  Choose file: [file.pdf]    │
│  Content:                   │  [Upload]                   │
│  ┌─────────────────┐        │                             │
│  │                 │        │  My files:                  │
│  │                 │        │  - report.pdf [Dl] [Del]    │
│  └─────────────────┘        │  - photo.png  [Dl] [Del]    │
│  [Save Note]                │                             │
│  My notes:                  │                             │
│  - Shopping list      [x]   │                             │
│  - Meeting notes      [x]   │                             │
└─────────────────────────────┴─────────────────────────────┘
```

## Infrastruttura

```
                         ┌──────────────┐
                         │   Cognito    │
                         │  User Pool   │
                         └──────┬───────┘
                                │ JWT
                    ┌───────────┴────────────┐
                    │                        │
         ┌──────────▼──────────┐  ┌──────────▼──────────┐
         │       ALB           │  │    API Gateway       │
         │   (public subnet)   │  │  (AWS managed)       │
         │   :80 / :443        │  │  Cognito Authorizer  │
         │   Cognito Auth      │  │                      │
         └──────────┬──────────┘  └──────────┬──────────┘
                    │                        │
         ┌──────────▼──────────┐  ┌──────────▼──────────┐
         │   ECS Fargate       │  │     Lambda          │
         │   (private subnet)  │  │  (AWS managed)      │
         │   Node/Express      │  │  Node               │
         └──────────┬──────────┘  └──────────┬──────────┘
                    │                        │
         ┌──────────▼──────────┐  ┌──────────▼──────────┐
         │   RDS PostgreSQL    │  │      S3 Bucket      │
         │   (private subnet)  │  │  (AWS managed)      │
         └─────────────────────┘  └─────────────────────┘

                    VPC
         ┌─────────────────────────────────┐
         │  ┌─────────┐  ┌─────────┐       │
         │  │ public  │  │ public  │       │
         │  │ subnet  │  │ subnet  │       │
         │  │  (ALB)  │  │  (ALB)  │       │
         │  └────┬────┘  └────┬────┘       │
         │       │            │            │
         │  ┌────▼────┐  ┌────▼────┐       │
         │  │ private │  │ private │       │
         │  │ subnet  │  │ subnet  │       │
         │  │(ECS,RDS)│  │(ECS,RDS)│       │
         │  └─────────┘  └─────────┘       │
         └─────────────────────────────────┘

         ECR ──► Docker image ──► ECS
         IAM ──► roles per ECS, Lambda, GitHub Actions
         GitHub Actions ──► build + push ECR + terraform apply
```

## Flow 1 — Container (Note Manager)

```
React ──POST /api/notes──► ALB ──► ECS (Node/Express) ──► RDS
React ──GET /api/notes───► ALB ──► ECS ──► SELECT ──► RDS
```

ECS task in private subnet. ALB in public subnet come entry point. RDS PostgreSQL in private subnet. ECR store la Docker image.

## Flow 2 — Serverless (File Bin)

```
React ──POST /files/upload──► API Gateway ──► Lambda ──► presigned PUT URL
React ──PUT file──► S3

React ──GET /files──► API Gateway ──► Lambda ──► S3 ListObjects

React ──GET /files/:key/download──► API Gateway ──► Lambda ──► presigned GET URL

React ──DELETE /files/:key──► API Gateway ──► Lambda ──► S3 DeleteObject
```

API Gateway REST con Cognito authorizer. Lambda genera presigned URL per S3 e gestisce CRUD. Lambda gira fuori VPC.

## Auth (condiviso)

```
React ──login/register──► Cognito ──► JWT
React ──JWT in header──► ALB (validato da ALB Cognito Auth)
React ──JWT in header──► API Gateway (validato da Cognito Authorizer)
```

Entrambi gli stack validano il JWT al bordo (ALB / API Gateway). Il backend (ECS / Lambda) riceve solo traffico autenticato e non deve validare il JWT.

## CI/CD

```
GitHub push ──► GitHub Actions ──► build Docker ──► push ECR
                                      ──► terraform apply
                                      ──► ECS new task definition
```

## Servizi AWS

| Service | Stack | Purpose |
|---------|-------|---------|
| Cognito | Both | Auth, JWT |
| VPC | Container | Network isolation |
| ALB | Container | HTTP entry point |
| ECS Fargate | Container | Node runtime |
| ECR | Container | Docker registry |
| RDS PostgreSQL | Container | Relational data |
| API Gateway | Serverless | REST front door |
| Lambda | Serverless | File operations |
| S3 | Serverless | Object storage |
| IAM | Both | Least-privilege roles |
| GitHub Actions | Both | CI/CD |

## Struttura Terraform

```
terraform/
├── modules/
│   ├── vpc/          # VPC + subnet + route tables (no NAT)
│   ├── cognito/      # User Pool + Client
│   ├── s3/           # Bucket + policy
│   ├── iam/          # Roles per ECS, Lambda, GitHub Actions
│   ├── ecr/          # Docker registry
│   ├── alb/          # Load balancer + target group
│   ├── rds/          # PostgreSQL + subnet group
│   ├── ecs/          # Cluster + task definition + service
│   ├── apigateway/   # REST API + Cognito authorizer
│   └── lambda/       # Lambda function + permissions
└── environments/
    └── dev/
        ├── main.tf           # provider + backend + chiama moduli
        ├── variables.tf      # variabili ambiente
        ├── outputs.tf        # output per frontend
        └── terraform.tfvars  # valori dev
```

## Risorse

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
