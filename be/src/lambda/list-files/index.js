const { S3Client, ListObjectsV2Command } = require("@aws-sdk/client-s3");

const s3 = new S3Client({});
const BUCKET_NAME = process.env.BUCKET_NAME;

exports.handler = async () => {
  const command = new ListObjectsV2Command({ Bucket: BUCKET_NAME });
  const response = await s3.send(command);

  const files = (response.Contents || []).map((obj) => ({
    key: obj.Key,
    size: obj.Size,
    lastModified: obj.LastModified,
  }));

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify({ files }),
  };
};
