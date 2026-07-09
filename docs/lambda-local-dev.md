# Eseguire e emulare Lambda in locale

## Perché testare in locale

Lambda gira su AWS con un ruolo IAM. In locale non hai quel ruolo, ma puoi usare
le credenziali del tuo profilo AWS (`~/.aws/credentials`). Il codice resta identico:
cambia solo **chi fornisce le credenziali** al runtime.

I motivi per testare in locale:
- Iterazione veloce (no deploy per ogni modifica)
- Debug con breakpoint nell'IDE
- Test offline (con LocalStack)
- Costi zero su AWS

---

## Metodo 1: Manuale (Node diretto)

Il più semplice. Nessun tool aggiuntivo. Ideale per Lambda semplici che chiamano
servizi AWS (S3, DynamoDB, ecc.).

### Prerequisiti

- Node.js installato (stessa versione del runtime Lambda, es. Node 20)
- Profilo AWS configurato (`~/.aws/credentials`)

### Procedura

```bash
cd be/src/lambda/presigned-url
```

Crea un file `test-local.js`:

```js
const { handler } = require('./index');

const event = {
  queryStringParameters: {
    filename: 'test.pdf',
    contentType: 'application/pdf',
  },
};

handler(event)
  .then((res) => {
    console.log('statusCode:', res.statusCode);
    console.log('body:', res.body);
  })
  .catch(console.error);
```

Esegui:

```bash
BUCKET_NAME=learn-aws-dev-filebin AWS_PROFILE=learn-aws node test-local.js
```

### Cosa succede

1. Node carica `index.js` e ottiene la funzione `handler`
2. Chiama `handler(event)` con l'evento simulato
3. La Lambda usa `@aws-sdk/client-s3` che legge le credenziali da `AWS_PROFILE`
4. Chiama davvero S3 su AWS e genera il presigned URL
5. Stampa il risultato

### Limiti

- Non simula il runtime Lambda (timeout, memory limits, cold start)
- Non simula API Gateway (devi costruire l'event a mano)
- Non simola le variabili d'ambiente del ruolo IAM (devi passarle a mano)
- Se la Lambda usa `context` (callbackWaitsForEmptyEventLoop, ecc.) non è simulato

### Quando usarlo

- Lambda semplici con poche dipendenze
- Debug rapido durante sviluppo
- Test unitari del handler

---

## Metodo 2: AWS SAM CLI

Il tool ufficiale AWS per sviluppare e testare applicazioni serverless localmente.
Usa Docker per simulare il runtime Lambda.

### Prerequisiti

- Docker installato e in esecuzione
- AWS SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
- Profilo AWS configurato

### Installazione (mac)

```bash
brew install aws-sam-cli
```

Verifica:

```bash
sam --version
```

### Procedura

SAM CLI ha bisogno di un `template.yaml` (formato AWS SAM) che descrive la Lambda.
Non è Terraform — è un file separato solo per test locali.

Crea `template.yaml` nella root del progetto:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  PresignedUrlFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: be/src/lambda/presigned-url
      Handler: index.handler
      Runtime: nodejs20.x
      MemorySize: 128
      Timeout: 3
      Environment:
        Variables:
          BUCKET_NAME: learn-aws-dev-filebin
```

Crea un file `event.json` con l'evento di test:

```json
{
  "httpMethod": "GET",
  "queryStringParameters": {
    "filename": "test.pdf",
    "contentType": "application/pdf"
  }
}
```

#### Invocazione diretta

```bash
sam local invoke PresignedUrlFunction --event event.json
```

SAM:
1. Scarica un'immagine Docker del runtime `nodejs20.x`
2. Monta la cartella `be/src/lambda/presigned-url` nel container
3. Inietta le variabili d'ambiente (`BUCKET_NAME`)
4. Chiama `handler` con il contenuto di `event.json`
5. Stampa la risposta

#### Avvio di API Gateway locale

```bash
sam local start-api
```

SAM avvia un server locale (default `http://localhost:3000`) che simula API Gateway.
Puoi testare con curl:

```bash
curl "http://localhost:3000/upload?filename=test.pdf&contentType=application/pdf"
```

#### Hot reload

```bash
sam local start-api --warm-containers EAGER
```

Mantiene il container caldo. Quando modifichi `index.js`, la prossima richiesta
usa il codice aggiornato senza riavviare il container.

### Limiti

- Richiede Docker (pesante su macchine con poca RAM)
- Il `template.yaml` è un file aggiuntivo da mantenere
- Non tutti i runtime sono supportati (controlla la lista)
- Alcune feature Lambda avanzate (Layers, EFS) hanno supporto limitato

### Quando usarlo

- Hai API Gateway + Lambda e vuoi testare il flusso HTTP completo
- Vuoi testare timeout, memory limits, cold start
- Vuoi un ambiente il più simile possibile a produzione

### Link utili

- Docs: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html
- Install: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
- `sam local invoke`: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-local-invoke.html
- `sam local start-api`: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-local-start-api.html

---

## Metodo 3: LocalStack

Emula i servizi AWS interamente in locale. Non chiama AWS reale: simula S3, Lambda,
API Gateway, DynamoDB, SQS, SNS, ecc. tutto sul tuo computer.

### Prerequisiti

- Docker installato e in esecuzione
- Python (pip) o Homebrew

### Installazione (mac)

```bash
pip install localstack
localstack start -d
```

Oppure con Docker diretto:

```bash
docker run -d --name localstack -p 4566:4566 localstack/localstack
```

Verifica:

```bash
localstack status
```

### Come funziona

LocalStack espone un endpoint unico `http://localhost:4566` che simula tutti i
servizi AWS. Configuri l'AWS SDK per puntare a quell'endpoint invece che ad AWS.

Per Terraform, aggiungi un override provider:

```hcl
provider "aws" {
  region                      = "eu-north-1"
  profile                     = "learn-aws"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    iam      = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}
```

Poi `terraform apply` deploya su LocalStack invece che su AWS.

### Per Lambda

Con LocalStack puoi:
- Deployare la Lambda con Terraform (su LocalStack)
- Creare bucket S3 fittizi
- Invocare la Lambda con `awslocal lambda invoke`
- Testare il flusso completo senza spendere nulla su AWS

```bash
awslocal lambda invoke \
  --function-name learn-aws-dev-presigned-url \
  --payload '{"queryStringParameters":{"filename":"test.pdf"}}' \
  output.json

cat output.json
```

### Limiti

- La versione gratuita (Community) ha servizi limitati
- La versione Pro (a pagamento) supporta più servizi (VPC, RDS, ecc.)
- Non tutto è perfettamente compatibile (alcune API hanno bug)
- Setup più complesso rispetto a SAM

### Quando usarlo

- Vuoi testare l'infrastruttura completa senza spendere su AWS
- Vuoi test offline totale (senza connessione internet)
- CI/CD pipeline con test di integrazione

### Link utili

- Sito: https://localstack.cloud/
- Docs: https://docs.localstack.cloud/
- Lambda support: https://docs.localstack.cloud/user-guide/aws/lambda/
- Terraform integration: https://docs.localstack.cloud/user-guide/integrations/terraform/

---

## Confronto riassuntivo

| Feature | Manuale | SAM CLI | LocalStack |
|---|---|---|---|
| Setup | Nessuno | Docker | Docker + Python |
| Simula runtime Lambda | No | Sì (Docker) | Sì (Docker) |
| Simula API Gateway | No | Sì | Sì |
| Simula S3/DynamoDB | No (chiama AWS reale) | No (chiama AWS reale) | Sì (emulato) |
| Chiama AWS reale | Sì | Sì | No |
| Costo | Gratis (ma usa AWS) | Gratis (ma usa AWS) | Gratis |
| Velocità iterazione | Veloce | Medio | Lento (primo deploy) |
| Configurazione extra | Nessuna | `template.yaml` | Provider override |
| Ideale per | Lambda semplici | API GW + Lambda | Infra completa |

## Raccomandazione per questo progetto

1. **Sviluppo quotidiano**: metodo manuale. Veloce, nessun tool, basta `node test-local.js`
2. **Test con API Gateway**: SAM CLI quando implementeremo l'API Gateway
3. **Test di integrazione**: LocalStack se in futuro vorrai test CI/CD offline
