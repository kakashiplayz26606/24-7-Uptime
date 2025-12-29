from fastapi import FastAPI
import argparse
import uvicorn

app = FastAPI()

@app.get("/")
def home():
    return {"status": "alive"}

@app.get("/ping")
def ping():
    return {"pong": True}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=args.port,
        log_level="info"
    )
