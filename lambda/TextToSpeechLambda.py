import json
import boto3
import base64

def lambda_handler(event, context):
    # Extract the text input from the event body (assuming it's passed as JSON)
    body = json.loads(event['body'])
    text = body.get('text')  # Use the lowercase key 'text' as per your curl example
    if not text:
        return {
            'statusCode': 400,
            'body': json.dumps('Text parameter is required.')
        }

    # Initialize the Polly client
    polly = boto3.client('polly')

    try:
        # Request speech synthesis from Polly
        response = polly.synthesize_speech(
            Text=text,
            VoiceId='Joanna',  # You can choose a different voice here
            OutputFormat='mp3'
        )

        # Get the audio stream from the response
        audio_stream = response['AudioStream'].read()

        # Encode the audio to base64 to return as part of the response
        audio_base64 = base64.b64encode(audio_stream).decode('utf-8')

        # Return the base64-encoded audio in the response body
        return {
            'statusCode': 200,
            'body': json.dumps({
                'audio': audio_base64
            }),
            'headers': {
                'Content-Type': 'application/json'
            }
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error generating speech: {str(e)}')
        }
