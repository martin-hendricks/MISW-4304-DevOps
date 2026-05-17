import newrelic.agent
from app import create_app

# Gunicorn target; WSGIApplicationWrapper helps Flask factory + RESTful route tracing.
application = newrelic.agent.WSGIApplicationWrapper(create_app())
app = application

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
