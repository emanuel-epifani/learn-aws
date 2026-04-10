import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({});

export const handler = async (event: any) => {
  console.log('GraphQL Lambda invoked with event:', JSON.stringify(event));

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

    // Return GraphQL response format
    return {
      data: data,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error in GraphQL Lambda:', error);
    // Return GraphQL error format
    return {
      error: {
        message: error instanceof Error ? error.message : 'Unknown error',
        type: 'Internal Server Error',
      },
    };
  }
};
