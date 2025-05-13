# Frontend Service - Web interface for rangers to view and submit wildlife sightings

from flask import Flask, redirect, render_template, jsonify

app = Flask(__name__, 
           static_folder='static',
           static_url_path='/wildlife/static')

@app.route('/wildlife')
def wildlife_root():
    return redirect('/wildlife/')

@app.route('/wildlife/')
def index():
    return render_template('index.html')

@app.route('/wildlife/health')
def health_check():
    return jsonify({
        "status": "healthy",
        "service": "frontend"
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)