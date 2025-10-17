from flask import Flask, jsonify
import os
import psycopg
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Gauge

app = Flask(__name__)
metrics = PrometheusMetrics(app)
app.logger.info("Application started")

user_count_gauge = Gauge("app_user_count", "Total number of users in the database")
product_count_gauge = Gauge("app_product_count", "Total number of products in the database")
order_count_gauge = Gauge("app_order_count", "Total number of orders in the database")
avg_order_price_gauge = Gauge("app_avg_order_price", "Average value of an order")
orders_pending_gauge = Gauge("app_orders_pending", "Number of orders with status pending")
orders_shipped_gauge = Gauge("app_orders_shipped", "Number of orders with status shipped")
orders_cancelled_gauge = Gauge("app_orders_cancelled", "Number of orders with status cancelled")

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "user")
DB_PASS = os.getenv("DB_PASS", "password")
DB_NAME = os.getenv("DB_NAME", "mydb")

def get_db_connection():
    return psycopg.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        dbname=DB_NAME
    )

def update_metrics():
    try:
        with get_db_connection() as db_conn:
            with db_conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM users;")
                user_count_gauge.set(cursor.fetchone()[0])

                cursor.execute("SELECT COUNT(*) FROM products;")
                product_count_gauge.set(cursor.fetchone()[0])

                cursor.execute("SELECT COUNT(*) FROM orders;")
                order_count_gauge.set(cursor.fetchone()[0])

                cursor.execute("SELECT AVG(products.price * orders.quantity) FROM orders JOIN products ON orders.product_id = products.id;")
                avg = cursor.fetchone()[0]
                avg_order_price_gauge.set(avg if avg is not None else 0)

                cursor.execute("SELECT status, COUNT(*) FROM orders GROUP BY status;")
                counts = dict(cursor.fetchall())
                orders_pending_gauge.set(counts.get("pending", 0))
                orders_shipped_gauge.set(counts.get("shipped", 0))
                orders_cancelled_gauge.set(counts.get("cancelled", 0))
    except Exception as e:
        app.logger.error(f"Metrics update error: {e}")

@app.before_request
def before_metrics_request():
    from flask import request
    if request.path == '/metrics':
        update_metrics()

@app.route("/")
def home():
    return "Local DevOps Platform with CI/CD, GitOps and Observability"

@app.get("/healthz")
def healthz():
    return "", 204

@app.get("/readyz")
def readyz():
    return "", 204

@app.route("/users")
def get_users():
    try:
        with get_db_connection() as db_conn:
            with db_conn.cursor() as cursor:
                cursor.execute("SELECT id, name, email, country, city FROM users LIMIT 10;")
                users_data = cursor.fetchall()
        update_metrics()
        return jsonify(users_data)
    except Exception as e:
        app.logger.error(f"Error fetching users: {e}")
        return jsonify({"error": "DB error"}), 500

@app.route("/orders")
def get_orders():
    try:
        with get_db_connection() as db_conn:
            with db_conn.cursor() as cursor:
                cursor.execute("SELECT id, user_id, product_id, quantity, status FROM orders LIMIT 10;")
                orders_data = cursor.fetchall()
        update_metrics()
        return jsonify(orders_data)
    except Exception as e:
        app.logger.error(f"Error fetching orders: {e}")
        return jsonify({"error": "DB error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)