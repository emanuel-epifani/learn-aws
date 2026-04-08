# AWS Learning Roadmap - Dal più importante al meno importante

## Livello 1: Fondamentali Indispensabili

1. **IAM (Identity and Access Management)** - Assolutamente il primo da imparare. Senza IAM non puoi fare nulla su AWS. Controlla chi può fare cosa sulle tue risorse.

2. **S3 (Simple Storage Service)** - Il servizio storage più usato. Servirà per file, immagini, backup, hosting statico. Lo userai praticamente in ogni progetto.

## Livello 2: Core per Applicazioni Serverless

3. **Lambda** - Funzioni serverless. È il cuore del computing serverless su AWS, indispensabile per logica business senza gestire server.

4. **API Gateway** - Per esporre le tue Lambda come API REST/HTTP. Insieme a Lambda formano il duo base per backend serverless.

5. **AppSync + Lambda (GraphQL)** - Per API GraphQL con Lambda come resolvers. È l'alternativa moderna a API Gateway quando hai bisogno di GraphQL o real-time updates.

## Livello 3: Dati e Autenticazione

6. **DynamoDB** - Database NoSQL serverless. Funziona benissimo con Lambda per dati strutturati.

7. **Cognito** - Autenticazione utenti. Se la tua app ha login/register, Cognito è la scelta nativa AWS.

## Livello 4: Comunicazione Asincrona

8. **SQS (Simple Queue Service)** - Code per processare task in background. Essenziale per scalare e gestire picchi di carico.

9. **SNS (Simple Notification Service)** - Pub/Sub per notifiche push, email, SMS. Complementare a SQS.

## Livello 5: Infrastruttura come Codice

10. **IaC (AWS CDK vs Terraform)** - Dopo aver capito i servizi, impara a definirli come codice. CDK è più AWS-nativo, Terraform è multi-cloud.

## Livello 6: Deployment

11. **CI/CD** - Automatizza test e deploy. È l'ultimo step dopo aver capito come costruire l'infrastruttura.

---

## Perché questo ordine?

- I primi 4 (IAM, S3, Lambda, API Gateway) ti permettono già di costruire un backend REST completo
- AppSync + Lambda aggiunge la capacità GraphQL per casi d'uso più moderni
- I successivi aggiungono persistenza dati e autenticazione
- SQS/SNS servono per architetture più robuste
- IaC e CI/CD sono per professionalizzare il workflow

## Primo progetto consigliato

Inizia con **IAM → S3 → Lambda → API Gateway** e crea un semplice backend REST. Poi aggiungi AppSync quando vuoi provare GraphQL.