# Progetto di Apprendimento AWS e Infrastructure as Code

Repository per imparare AWS services e Infrastructure as Code con Terraform.

## Target Architecture

Single-page React app with two independent columns, no data coupling between backends.

```
┌─────────────────────────────┬─────────────────────────────┐
│         NOTE MANAGER        │         FILE BIN            │
│      (ECS + RDS + ALB)      │   (API Gateway + Lambda     │
│                             │    + S3 + Cognito Auth)     │
├─────────────────────────────┼─────────────────────────────┤
│                             │                             │
│  Title: _______________     │  Choose file: [file.pdf]    │
│                             │  [Upload]                   │
│  Content:                   │                             │
│  ┌─────────────────┐        │  My files:                  │
│  │                 │        │  - report.pdf [Dl] [Del]    │
│  │                 │        │  - photo.png  [Dl] [Del]    │
│  └─────────────────┘        │                             │
│                             │                             │
│  [Save Note]                │                             │
│                             │                             │
│  My notes:                  │                             │
│  - Shopping list      [x]   │                             │
│  - Meeting notes      [x]   │                             │
│                             │                             │
└─────────────────────────────┴─────────────────────────────┘
```

## Backend Flows

```
User
 │
 ├─ Login ───► Cognito ───► JWT
 │
 ├─ Note Manager ───► ALB ───► ECS/Fargate ───► RDS
 │
 └─ File Bin ───► API Gateway ───► Lambda ───► S3
```

## Stack 1 — Container (Note Manager)

ECS task (Node/Express) in private subnet. ALB in public subnet as entry point. RDS PostgreSQL in private subnet. ECR stores Docker image.

## Stack 2 — Serverless (File Bin)

API Gateway REST with Cognito authorizer. Lambda (Node) generates presigned URLs for S3 and handles object CRUD. Lambda runs outside VPC.

## Shared Services

- **Cognito User Pool** — single login for both stacks.
- **VPC** — public subnets (ALB, NAT), private subnets (ECS, RDS).
- **S3** — file storage.
- **IAM** — roles for ECS tasks, Lambda, GitHub Actions.
- **GitHub Actions** — build Docker image, push to ECR, terraform apply, update ECS.

## End-to-End Flows

Create note
```
React ──POST /api/notes──► ALB ──► ECS ──► INSERT ──► RDS
```

List notes
```
React ──GET /api/notes──► ALB ──► ECS ──► SELECT ──► RDS
```

Upload file
```
React ──POST /files/upload──► API Gateway ──► Lambda ──► presigned PUT URL
React ──PUT file──► S3
```

List files
```
React ──GET /files──► API Gateway ──► Lambda ──► S3 ListObjects ──► React
```

Download file
```
React ──GET /files/:key/download──► API Gateway ──► Lambda ──► presigned GET URL
```

Delete file
```
React ──DELETE /files/:key──► API Gateway ──► Lambda ──► S3 DeleteObject
```

Login
```
React ──Auth flow──► Cognito
```

CI/CD
```
GitHub push ──► GitHub Actions ──► ECR + Terraform apply + ECS deploy
```

## Services Used

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
| S3 | Both | Object storage |
| IAM | Both | Least-privilege roles |
| GitHub Actions | Both | CI/CD |



## Risorse

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

