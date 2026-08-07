import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


@app.route(route="health", methods=["GET"])
def health(request: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        body='{"status":"ok","service":"bluealpha-functions-http"}',
        status_code=200,
        mimetype="application/json",
    )
