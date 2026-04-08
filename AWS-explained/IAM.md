

IAM (Identity and Access Management)

E' il servizio di AWS che permette di gestire gli utenti e le loro autorizzazioni.

Concetti base:
- User: persona o servizio che accede a AWS
- Group: insieme di users con stessi permessi
- Roles: ruolo che un user assume per accedere a AWS
- Policy: documento che definisce i permessi un user o role

Come funziona:
- Root User: quell   o con cui crei account AWS
- IAM Users: n utenti creti per ogni persona/team che deve accedere
- PERMISSIONS: policy che dicono ognuno di loro cosa può fare


Da dove configurarli:

Via Web Console GUI (Per iniziare):
```markdown
https://console.aws.amazon.com/iam/
```
Via CLI (per quando sei più esperto)
```bash
aws iam create-user --user-name nome-utente
aws iam attach-user-policy --user-name nome-utente --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
```

IAM -> create user
- IAM user 
    -> web console -> login with email+password
    -> applicazioni -> access key + secret key
