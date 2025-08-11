from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from Docker & AWS ECS with Terraform!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
