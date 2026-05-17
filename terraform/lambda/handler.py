import os
import json
import urllib.parse
import boto3

ENDPOINT = os.environ.get("LOCALSTACK_ENDPOINT", "http://localhost.localstack.cloud:4566")
DEST_BUCKET = os.environ["DEST_BUCKET"]
SNS_TOPIC = os.environ["SNS_TOPIC"]

s3 = boto3.client("s3", endpoint_url=ENDPOINT)
sns = boto3.client("sns", endpoint_url=ENDPOINT)


def lambda_handler(event, context):
    copied = []
    for record in event.get("Records", []):
        src_bucket = record["s3"]["bucket"]["name"]
        src_key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        print(f"Copying s3://{src_bucket}/{src_key} -> s3://{DEST_BUCKET}/{src_key}")

        s3.copy_object(
            Bucket=DEST_BUCKET,
            Key=src_key,
            CopySource={"Bucket": src_bucket, "Key": src_key},
        )
        copied.append(src_key)

        sns.publish(
            TopicArn=SNS_TOPIC,
            Subject="File copied",
            Message=json.dumps({
                "source_bucket": src_bucket,
                "destination_bucket": DEST_BUCKET,
                "key": src_key,
            }),
        )

    return {"statusCode": 200, "copied": copied}
