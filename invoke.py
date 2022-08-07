from typing import List
import boto3
import json
import logging
import urllib.parse

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event: dict, context):
    logging.info(json.dumps(event))

    if "challenge" in event:
        return event.get("challenge")

    logging.info(json.dumps(event.get("body-json")))

    text_params: List["str"] = [
        element for element in event.get("body-json").split("&") if element.startswith("text=")
    ]
    params: List["str"] = urllib.parse.unquote_plus(text_params[0].removeprefix("text=")).split(" ")
    logging.info(params)
    logging.info({"path": params[0], "uri": params[1]})

    client = boto3.client('lambda')
    response = client.invoke(
        FunctionName='urip',
        InvocationType='Event',
        LogType='Tail',
        Payload=json.dumps({"path": params[0], "uri": params[1]})
    )

    return {
        'statusCode': 200,
        'body': json.dumps('OK')
    }
