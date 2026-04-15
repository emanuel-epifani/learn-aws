# AWS Learning Roadmap - Backend Dev (Minimo Indispensabile)

---

# Fondamentali Comuni (2 servizi)

1. **IAM** - Security. Controlla chi può fare cosa. Prerequisito assoluto.

2. **S3** - Storage. File, immagini, backup, hosting statico.

---

# Serverless (4 servizi)

Per side project veloci, zero gestione server.

3. **Lambda** - Funzioni serverless. Compute senza server.

4. **API Gateway** - Espone Lambda come API REST/HTTP.

5. **DynamoDB** - Database NoSQL serverless.

6. **Cognito** - Autenticazione utenti (se serve login).

---

# Container (5 servizi)

Per side project con Docker/Kubernetes.

7. **VPC** - Networking. Subnets, security groups. Base per tutto non-serverless.

8. **EC2** - Macchine virtuali. Compute tradizionale.

9. **ECR** - Registry per immagini Docker.

10. **ECS** - Container orchestration nativa AWS (più semplice di EKS).

11. **ALB** - Load balancing per distribuire traffico.

---

# Nice-to-Have (impara dopo)

- **Route 53** - DNS (puoi usare servizi esterni all'inizio)
- **CloudWatch** - Monitoring (puoi aspettare)
- **Secrets Manager** - Gestione secrets (puoi usare env variables)
- **IaC (Terraform/CDK)** - Infrastruttura come codice (puoi usare console)
- **CI/CD** - Deploy automatizzato (puoi fare deploy manuale)

---

# Come iniziare

## Serverless (più veloce per side project)
IAM → S3 → Lambda → API Gateway → DynamoDB → Cognito

## Container
IAM → S3 → VPC → EC2 → ECR → ECS → ALB