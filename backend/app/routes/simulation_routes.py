from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.services import db_service
from ..models.simulation_models import SimulationRequest, SimulationResponse
from ..services.simulation_service import SimulationService

router = APIRouter(prefix="", tags=["simulation"])
_service = SimulationService()

@router.post("/simulate")
def post_simulate(request: SimulationRequest, db: Session = Depends(get_db)):
    """
    Validates topology and simulates packet routing from source to destination.
    Also records packet trace event in SQLite database.
    """
    result = _service.run_simulation(request)
    try:
        is_success = bool(result.get("success", False))
        db_service.record_packet_trace(
            db=db,
            source_ip=request.sourceDeviceId,
            destination_ip=request.destinationDeviceId,
            success=is_success
        )
    except Exception:
        pass
    return result
