from fastapi import FastAPI
import time

app = FastAPI()

@app.get("/")
def home():
    return {"status": "alive"}

@app.get("/ping")
def ping():
    return {"pong": True, "time": time.time()}


if __name__ == "__main__":
    import uvicorn
    print("Starting connector on port 8080...")
    uvicorn.run(app, host="0.0.0.0", port=8080)
