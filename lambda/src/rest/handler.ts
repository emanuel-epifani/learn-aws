import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({});

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.log('REST Lambda invoked with event:', JSON.stringify(event));

  try {
    const bucketName = process.env.BUCKET_NAME;
    if (!bucketName) {
      throw new Error('BUCKET_NAME environment variable is not set');
    }

    // Read data.json from S3
    const command = new GetObjectCommand({
      Bucket: bucketName,
      Key: 'data.json',
    });

    const response = await s3Client.send(command);
    const dataString = await response.Body?.transformToString();

    if (!dataString) {
      throw new Error('Failed to read data from S3');
    }

    const data = JSON.parse(dataString);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        data: data,
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
