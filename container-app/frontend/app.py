from flask import Flask, redirect, render_template
import os

app = Flask(__name__, 
           static_folder='static',
           static_url_path='/wildlife/static')

# Environment variables
ENV_VARS = {
    'PREFIX_CODE': os.getenv('PREFIX_CODE'),
    'AWS_ACCOUNT_ID': os.getenv('AWS_ACCOUNT_ID'),
    'BUCKET_NAME': os.getenv('BUCKET_NAME'),
    'AWS_REGION': os.getenv('AWS_REGION')
}

if not all(ENV_VARS.values()):
    raise ValueError("Missing required environment variables: " + 
                    ", ".join(k for k, v in ENV_VARS.items() if not v))

@app.route('/wildlife')
def wildlife_root():
    return redirect('/wildlife/')

@app.route('/wildlife/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)