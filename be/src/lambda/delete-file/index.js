const { S3Client, DeleteObjectCommand } = require("@aws-sdk/client-s3");

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

  await s3.send(new DeleteObjectCommand({ Bucket: BUCKET_NAME, Key: key }));

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify({ deleted: true, key }),
  };
};
