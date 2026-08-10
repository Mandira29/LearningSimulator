from fastapi import APIRouter, HTTPException
from ..models.simulation_models import SimulationRequest, SimulationResponse
from ..services.simulation_service import SimulationService

router = APIRouter(prefix="", tags=["simulation"])
_service = SimulationService()

@router.post("/simulate")
def post_simulate(request: SimulationRequest):
    """
    Validates topology and simulates packet routing from source to destination.
    """
    result = _service.run_simulation(request)
    return result
