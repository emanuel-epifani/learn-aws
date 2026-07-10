// Configurazione AWS Amplify
// Questi valori vengono popolati dai Terraform outputs dopo il deploy

const userPoolId = import.meta.env.VITE_COGNITO_USER_POOL_ID
const userPoolClientId = import.meta.env.VITE_COGNITO_CLIENT_ID

if (!userPoolId || !userPoolClientId) {
  throw new Error('Missing required env vars: VITE_COGNITO_USER_POOL_ID, VITE_COGNITO_CLIENT_ID')
}

export const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId,
      userPoolClientId,
      loginWith: {
        email: true
      }
    }
  }
}

export default awsConfig
