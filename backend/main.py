from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.routes.simulation_routes import router as simulation_router
from app.routes.db_routes import router as db_router
from app.routes.challenge_routes import router as challenge_router

# Initialize SQLite database tables automatically
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="NetVisual Academy Backend API",
    description="Backend service and SQLite persistence layer for NetVisual Academy",
    version="1.0.0"
)

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
app.include_router(db_router)
app.include_router(challenge_router)

@app.get("/health")
def get_health():
    """
    Health check endpoint for checking backend availability.
    """
    return {"status": "ok", "database": "sqlite connected"}

if __name__ == "__main__":
    import uvicorn
    # When running as main, start uvicorn directly listening on 0.0.0.0
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)


