from fastapi import FastAPI
import time
import uvicorn

app = FastAPI()

@app.get("/")
def home():
    return {"status": "alive"}

@app.get("/ping")
def ping():
    return {"pong": True, "time": time.time()}

if __name__ == "__main__":
    uvicorn.run(
        "connector:app",
        host="0.0.0.0",
        port=8080,
        log_level="error"
    )
