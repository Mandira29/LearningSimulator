from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# --- User Schemas ---
class UserBase(BaseModel):
    username: str
    email: str
    role: Optional[str] = "Student"

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

# --- Topology Schemas ---
class TopologyBase(BaseModel):
    title: str
    description: Optional[str] = ""
    canvas_json: str  # Encoded topology workspace data

class TopologyCreate(TopologyBase):
    user_id: Optional[int] = None

class TopologyResponse(TopologyBase):
    id: int
    user_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# --- User Progress Schemas ---
class ProgressCreate(BaseModel):
    user_id: Optional[int] = None
    level_id: int
    level_name: str
    completed: bool = True
    stars: int = 3
    score: int = 100

class ProgressResponse(ProgressCreate):
    id: int
    updated_at: datetime

    class Config:
        from_attributes = True

# --- Packet Trace Schemas ---
class PacketTraceCreate(BaseModel):
    source_ip: Optional[str] = None
    destination_ip: Optional[str] = None
    protocol: Optional[str] = "ICMP Echo"
    success: bool = True

class PacketTraceResponse(PacketTraceCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

# --- Dashboard Statistics Aggregate Schema ---
class DashboardStatsResponse(BaseModel):
    total_topologies: int
    total_packets_traced: int
    total_xp: int
    completed_levels_count: int
    completion_percentage: float
    user_progress_list: List[ProgressResponse]
    recent_topologies: List[TopologyResponse]
