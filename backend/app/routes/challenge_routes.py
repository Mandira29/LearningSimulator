from typing import List, Optional
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from ..models.challenge_models import (
    ChallengeModel,
    ChallengeActionRequest,
    ChallengeActionResult,
)
from ..services.challenge_service import ChallengeService

router = APIRouter(prefix="/challenges", tags=["challenges"])
_challenge_service = ChallengeService()

@router.get("", response_model=List[ChallengeModel])
def get_all_challenges():
    """Retrieve all 12 educational networking challenges with categories and metadata."""
    return _challenge_service.get_all_challenges()

@router.get("/{challenge_id}", response_model=ChallengeModel)
def get_challenge_detail(challenge_id: str):
    """Retrieve details for a specific challenge by ID."""
    ch = _challenge_service.get_challenge(challenge_id)
    if not ch:
        raise HTTPException(status_code=404, detail=f"Challenge '{challenge_id}' not found.")
    return ch

@router.post("/{challenge_id}/start", response_model=ChallengeModel)
def post_start_challenge(challenge_id: str):
    """Start and initialize the topology, state, and objectives for a challenge."""
    ch = _challenge_service.start_challenge(challenge_id)
    if not ch:
        raise HTTPException(status_code=404, detail=f"Challenge '{challenge_id}' not found.")
    return ch

@router.post("/{challenge_id}/action", response_model=ChallengeActionResult)
def post_challenge_action(challenge_id: str, request: ChallengeActionRequest, db: Session = Depends(get_db)):
    """Execute an educational challenge action and evaluate objective completion."""
    result = _challenge_service.execute_action(challenge_id, request)
    return result

@router.post("/{challenge_id}/reset", response_model=ChallengeModel)
def post_reset_challenge(challenge_id: str):
    """Reset the topology and progress for a challenge to its initial state."""
    ch = _challenge_service.reset_challenge(challenge_id)
    if not ch:
        raise HTTPException(status_code=404, detail=f"Challenge '{challenge_id}' not found.")
    return ch

@router.post("/{challenge_id}/validate", response_model=ChallengeActionResult)
def post_validate_challenge(challenge_id: str):
    """Validate current challenge state against success conditions."""
    ch = _challenge_service.get_challenge(challenge_id)
    if not ch:
        raise HTTPException(status_code=404, detail=f"Challenge '{challenge_id}' not found.")
    
    is_completed = (ch.status.value == "completed")
    return ChallengeActionResult(
        success=is_completed,
        message="Challenge successfully completed!" if is_completed else "Challenge objectives not yet fulfilled.",
        objectiveCompleted=is_completed,
        progress=ch.progress,
        explanation=ch.explanation if is_completed else None
    )
