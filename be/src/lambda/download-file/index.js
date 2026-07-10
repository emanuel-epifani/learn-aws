const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const s3 = new S3Client({});
const BUCKET_NAME = process.env.BUCKET_NAME;

exports.handler = async (event) => {
  const key = event.pathParameters?.key;

  if (!key) {
    return {
      statusCode: 400,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "key path parameter is required" }),
    };
  }

  const command = new GetObjectCommand({ Bucket: BUCKET_NAME, Key: key });
  const url = await getSignedUrl(s3, command, { expiresIn: 300 });

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify({ url }),
  };
};
