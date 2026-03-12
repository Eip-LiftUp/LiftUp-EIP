"""
Health check endpoints
"""

from fastapi import APIRouter
from datetime import datetime
import psutil
import GPUtil

router = APIRouter()


@router.get("/health")
async def health_check():
    """Basic health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "LiftUp ML Service",
    }


@router.get("/health/detailed")
async def detailed_health_check():
    """Detailed health check with system information"""
    try:
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Memory usage
        memory = psutil.virtual_memory()
        
        # GPU availability (if available)
        gpu_available = False
        gpu_info = []
        try:
            gpus = GPUtil.getGPUs()
            gpu_available = len(gpus) > 0
            gpu_info = [
                {
                    "id": gpu.id,
                    "name": gpu.name,
                    "load": f"{gpu.load * 100:.1f}%",
                    "memory_used": f"{gpu.memoryUsed}MB",
                    "memory_total": f"{gpu.memoryTotal}MB",
                }
                for gpu in gpus
            ]
        except:
            pass
        
        return {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "system": {
                "cpu_usage": f"{cpu_percent}%",
                "memory_usage": f"{memory.percent}%",
                "memory_available": f"{memory.available / (1024**3):.2f}GB",
                "gpu_available": gpu_available,
                "gpus": gpu_info,
            },
        }
    except Exception as e:
        return {
            "status": "degraded",
            "timestamp": datetime.utcnow().isoformat(),
            "error": str(e),
        }
