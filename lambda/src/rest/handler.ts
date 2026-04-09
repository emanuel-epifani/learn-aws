import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.log('REST Lambda invoked with event:', JSON.stringify(event));

  try {
    // TODO: Validate JWT token
    // TODO: Read from S3
    // TODO: Return data

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: 'REST Lambda - Hello World',
        timestamp: new Date().toISOString(),
      }),
    };
  } catch (error) {
    console.error('Error in REST Lambda:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        error: 'Internal Server Error',
        message: error instanceof Error ? error.message : 'Unknown error',
      }),
    };
  }
};
