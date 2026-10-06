from flask import Flask, jsonify
import os

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify({
        "message": "OrderHub API"
    })


@app.route("/health")
def health():
    return jsonify({
        "status": "UP"
    })


@app.route("/orders")
def orders():
    return jsonify([
        {
            "id": 1,
            "customer": "Gayathri",
            "product": "Laptop",
            "quantity": 1
        },
        {
            "id": 2,
            "customer": "Rahul",
            "product": "Mobile",
            "quantity": 2
        }
    ])


@app.route("/version")
def version():
    return jsonify({
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "build": os.getenv("BUILD_NUMBER", "unknown"),
        "commit": os.getenv("GIT_COMMIT", "unknown")
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)