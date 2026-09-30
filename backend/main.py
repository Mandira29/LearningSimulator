from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.simulation_routes import router as simulation_router

app = FastAPI(title="NetVisual Academy Backend API", version="1.0.0")

# Configure CORS for Flutter Web development (wildcard origins require allow_credentials=False)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(simulation_router)

@app.get("/health")
def get_health():
    """
    Health check endpoint for checking backend availability.
    """
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    # When running as main, start uvicorn directly listening on 0.0.0.0
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

