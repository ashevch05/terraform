import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    s3 = boto3.resource('s3', endpoint_url='http://localhost:4566')
    src_bucket_name = 's3-start'
    dst_bucket_name = 's3-finish'
    
    src_bucket = s3.Bucket(src_bucket_name)

    logger.info("Received event: %s", json.dumps(event))

    try:
        if 'Records' not in event:
            raise ValueError("Event does not contain 'Records' field")

        for record in event['Records']:
            if 'Sns' in record:
                sns_message = json.loads(record['Sns']['Message'])
                logger.info("SNS message: %s", json.dumps(sns_message))
                s3_event = sns_message
            else:
                s3_event = record

            for s3_record in s3_event.get('Records', []):
                key = s3_record['s3']['object']['key']
                logger.info("Processing file: %s from bucket: %s", key, src_bucket_name)
                
                copy_source = {'Bucket': src_bucket_name, 'Key': key}
                dst_file_name = key  # Keeping the same file name in the destination bucket
                
                s3.meta.client.copy(copy_source, dst_bucket_name, dst_file_name)

        return {'statusCode': 200, 'body': 'Files copied successfully'}
    except Exception as e:
        logger.error("Error processing event: %s", e)
        return {'statusCode': 500, 'body': 'Error copying files'}
