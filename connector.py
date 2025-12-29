import argparse
import time
from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
def root():
    return {"status": "ok"}

@app.get("/ping")
def ping():
    return {"pong": True}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    print(f"[connector] Starting on port {args.port}", flush=True)

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=args.port,
        log_level="info",
        access_log=False
    )

if __name__ == "__main__":
    main()
