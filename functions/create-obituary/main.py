import json
import base64
import boto3
import time
import hashlib
import requests
from requests_toolbelt.multipart import decoder

client = boto3.client("polly")

dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table("obituary-30140219")
    
def get_parameter(parameter_name):
    ssm = boto3.client('ssm')
    response = ssm.get_parameter(
        Name=parameter_name,
        WithDecryption=True
    )
    return response['Parameter']['Value']

def gpt_response(prompt):
    GPT_key = get_parameter('CHATGPT_KEY')
    url = "https://api.openai.com/v1/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {GPT_key}"
    }
    body = {
        "model": "text-davinci-003",
        "prompt": prompt,
        "max_tokens": 200,
        "temperature": 0.2
    }
    res = requests.post(url, headers=headers, json=body)
    response_json = json.loads(res.text)
    return response_json["choices"][0]["text"]


def upload_to_cloudinary(filename, resource_type, fields=None):
    Cloudinary_key = get_parameter('CLOUDINARY_KEY')
    api_key = "192422764738119"
    cloud_name = "dfuasp6oi"

    body = {
        "api_key": api_key,
    }

    files = {
        "file": open(filename, "rb")
    }

    if fields:
        eager = fields.get("eager", [])
        if eager:
            fields["eager"] = ",".join(eager)
        body.update(fields)

    body["signature"] = create_signature(body, Cloudinary_key)
    url = f"https://api.cloudinary.com/v1_1/{cloud_name}/{resource_type}/upload"
    res = requests.post(url, files=files, data=body)
    return res.json()

def create_signature(body, secret_key):
    exclude = ["api_key", "resource_type", "cloud_name"]
    timestamp = int(time.time())
    body["timestamp"] = timestamp

    sorted_body = sort_dict(body, exclude)
    query_string = query_string_create(sorted_body)

    query_string_appended = f"{query_string}{secret_key}"
    hashed = hashlib.sha1(query_string_appended.encode())
    return hashed.hexdigest()

def sort_dict(dictionary, exclude):
    return {k: v for k, v in sorted(dictionary.items(), key=lambda item: item[0]) if k not in exclude}

def query_string_create(body):
    q_string = ""
    for idx, (k,v) in enumerate(body.items()):
        if idx == 0:
            q_string = f"{k}={v}"
        else:
            q_string = f"{q_string}&{k}={v}"
    return q_string

def polly_speech(prompt):
    response = client.synthesize_speech(
        Engine='standard',
        LanguageCode='en-US',
        OutputFormat='mp3',
        Text = prompt,
        TextType = 'text',
        VoiceId = 'Joanna'
    )

    filename = "/tmp/polly.mp3"
    with open(filename, "wb") as f:
        f.write(response["AudioStream"].read())
    
    return filename

def create_lambda_handler_30139868(event, context):
    body = event["body"]
    if event["isBase64Encoded"]:
        body = base64.b64decode(body)

    content_type = event["headers"]["content-type"]
    data = decoder.MultipartDecoder(body, content_type)

    binary_data = [part.content for part in data.parts]
    name = binary_data[1].decode()
    born_year = binary_data[2].decode()
    died_year = binary_data[3].decode()
    id = binary_data[4].decode()

    key = "/tmp/obituary.png"
    with open(key, "wb") as f:
        f.write(binary_data[0])

    res_img = upload_to_cloudinary(key, resource_type="image", fields={"eager": ["e_art:zorro"]})
    chatgpt_prompt = gpt_response(
        f"write an obituary about a fictional character named {name} who was born on {born_year} and died on {died_year}. Keep it to 10 sentences max."
    )

    voice_prompt = polly_speech(chatgpt_prompt)
    res_mp3 = upload_to_cloudinary(voice_prompt, resource_type="raw")

    item = {
        "id":id,
        "name":name,
        "born_year":born_year,
        "died_year":died_year,
        "cloud_img": res_img["eager"][0]["secure_url"],
        "chatgpt":chatgpt_prompt,
        "voice_resp": res_mp3["secure_url"],
    }

    try:
        table.put_item(Item=item)
        return {
            "statusCode": 200,
            "body": json.dumps(item)
        }
    except Exception as ex:
        print(f"Exception: {ex}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": str(ex)
            })
        }