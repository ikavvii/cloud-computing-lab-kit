"""Integration check against PostgreSQL. Cleans up only its own created record."""
import re
import secrets
from app import app, connect, password

client = app.test_client()
assert client.get('/').status_code == 302
assert client.get('/health').json == {'status': 'ok'}
client.get('/login')
with client.session_transaction() as s:
    token = s['csrf']
assert client.post('/login', data={'csrf': token, 'password': 'wrong'}).status_code == 200
assert client.post('/login', data={'csrf': token, 'password': password}).status_code == 302
with client.session_transaction() as s:
    token = s['csrf']
assert client.post('/products', data={'name': 'test', 'price': '1'}).status_code == 400
assert client.post('/products', data={'csrf': token, 'name': 'test', 'price': 'NaN'}).status_code == 400
name = 'lab-test-' + secrets.token_hex(6) + "' <script>"
product_id = None
try:
    assert client.post('/products', data={'csrf': token, 'name': name, 'price': '12.50'}).status_code == 303
    with connect() as db:
        row = db.execute('SELECT id, price FROM products WHERE name=%s', (name,)).fetchone()
    assert row and str(row['price']) == '12.50'
    product_id = row['id']
    page = client.get('/').get_data(as_text=True)
    assert '&lt;script&gt;' in page and name not in page
    assert client.post(f'/products/{product_id}/update', data={'csrf': token, 'name': name, 'price': '9.25'}).status_code == 303
    with connect() as db:
        row = db.execute('SELECT price FROM products WHERE id=%s', (product_id,)).fetchone()
    assert str(row['price']) == '9.25'
    assert client.post(f'/products/{product_id}/delete', data={'csrf': token}).status_code == 303
    with connect() as db:
        assert db.execute('SELECT id FROM products WHERE id=%s', (product_id,)).fetchone() is None
    print('PASS: authentication, CSRF, validation, HTML escaping and real PostgreSQL create/read/update/delete')
finally:
    if product_id is not None:
        with connect() as db:
            db.execute('DELETE FROM products WHERE id=%s', (product_id,))
