import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("obituary-30140219")

def get_lambda_handler_30139868(event, context):
    try:
        res = table.scan()
        return {
            "statusCode": 200,
            "body": json.dumps(res["Items"])
        }
    except Exception as exp:
        print(exp)
        return {
            "statusCode": 500,
            "body":json.dumps({
                "message":str(exp)
        })
}
