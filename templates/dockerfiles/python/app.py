from flask import Flask, jsonify
import os
import sys

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        'message': 'Python Docker Template',
        'python_version': sys.version,
        'environment': os.getenv('ENVIRONMENT', 'development')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    # Only for development - use Gunicorn in production
    app.run(host='0.0.0.0', port=8000)
