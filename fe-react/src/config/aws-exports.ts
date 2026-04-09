// Configurazione AWS Amplify
// Questi valori verranno popolati dai Terraform outputs dopo il deploy

export const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID || 'eu-north-1_ABC123',
      userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID || 'client-id-placeholder',
      identityPoolId: import.meta.env.VITE_COGNITO_IDENTITY_POOL_ID || '',
      loginWith: {
        email: true
      }
    }
  }
}

export default awsConfig
