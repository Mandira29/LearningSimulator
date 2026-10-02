from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.schemas.db_schemas import (
    UserCreate, UserResponse,
    TopologyCreate, TopologyResponse,
    ProgressCreate, ProgressResponse,
    PacketTraceCreate, PacketTraceResponse,
    DashboardStatsResponse
)
from app.services import db_service

router = APIRouter(prefix="/api", tags=["Database Persistence"])

# --- User Endpoints ---
@router.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db_service.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return db_service.create_user(db=db, user=user)

@router.get("/users", response_model=List[UserResponse])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db_service.get_users(db, skip=skip, limit=limit)

# --- Topology Endpoints ---
@router.post("/topologies", response_model=TopologyResponse, status_code=status.HTTP_201_CREATED)
def save_topology(topology: TopologyCreate, db: Session = Depends(get_db)):
    return db_service.create_topology(db=db, topology=topology)

@router.get("/topologies", response_model=List[TopologyResponse])
def get_all_topologies(user_id: Optional[int] = None, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db_service.get_topologies(db=db, user_id=user_id, skip=skip, limit=limit)

@router.get("/topologies/{topology_id}", response_model=TopologyResponse)
def get_topology(topology_id: int, db: Session = Depends(get_db)):
    topology = db_service.get_topology_by_id(db=db, topology_id=topology_id)
    if not topology:
        raise HTTPException(status_code=404, detail="Topology not found")
    return topology

@router.delete("/topologies/{topology_id}")
def delete_topology(topology_id: int, db: Session = Depends(get_db)):
    success = db_service.delete_topology(db=db, topology_id=topology_id)
    if not success:
        raise HTTPException(status_code=404, detail="Topology not found")
    return {"message": "Topology deleted successfully"}

# --- Level Progress Endpoints ---
@router.post("/progress", response_model=ProgressResponse)
def record_progress(progress: ProgressCreate, db: Session = Depends(get_db)):
    return db_service.save_user_progress(db=db, progress=progress)

@router.get("/progress", response_model=List[ProgressResponse])
def get_progress(user_id: Optional[int] = None, db: Session = Depends(get_db)):
    return db_service.get_user_progress_list(db=db, user_id=user_id)

# --- Packet Trace Endpoints ---
@router.post("/traces", response_model=PacketTraceResponse)
def log_packet_trace(trace: PacketTraceCreate, db: Session = Depends(get_db)):
    return db_service.record_packet_trace(
        db=db,
        source_ip=trace.source_ip,
        destination_ip=trace.destination_ip,
        success=trace.success
    )

# --- Real Database Statistics Endpoint ---
@router.get("/stats", response_model=DashboardStatsResponse)
def get_dashboard_stats(user_id: Optional[int] = None, db: Session = Depends(get_db)):
    return db_service.get_dashboard_stats(db=db, user_id=user_id)
