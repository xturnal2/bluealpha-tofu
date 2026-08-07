import json
import os


def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(
            {
                "message": os.environ.get("MESSAGE", "Hello from BlueAlpha"),
                "request_id": context.aws_request_id,
            }
        ),
    }
