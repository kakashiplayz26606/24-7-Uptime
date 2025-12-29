from fastapi import FastAPI
import uvicorn
import os

app = FastAPI()

@app.get("/")
def home():
    return {
        "status": "online",
        "platform": "codesandbox",
        "note": "Use CodeSandbox preview URL"
    }

@app.get("/ping")
def ping():
    return {"pong": True}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
