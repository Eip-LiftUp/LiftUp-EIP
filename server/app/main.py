"""
LiftUp ML Service - Main FastAPI Application

This is the main entry point for the LiftUp ML service that provides
pose estimation and form analysis for workout videos.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from app.api.endpoints import pose, analysis, health
from app.core.config import settings

# Initialize FastAPI app
app = FastAPI(
    title="LiftUp ML Service",
    description="AI-powered pose estimation and form analysis for fitness coaching",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configure CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(health.router, prefix="/api/v1", tags=["health"])
app.include_router(pose.router, prefix="/api/v1/pose", tags=["pose"])
app.include_router(analysis.router, prefix="/api/v1/analysis", tags=["analysis"])


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "LiftUp ML Service",
        "version": "0.1.0",
        "status": "running",
        "docs": "/docs",
    }


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler"""
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc) if settings.DEBUG else "An error occurred",
        },
    )


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info",
    )
