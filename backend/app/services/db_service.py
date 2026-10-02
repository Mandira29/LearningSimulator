from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.db_models import User, Topology, UserProgress, PacketTrace
from app.schemas.db_schemas import UserCreate, TopologyCreate, ProgressCreate

# --- User CRUD ---
def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def create_user(db: Session, user: UserCreate):
    db_user = User(username=user.username, email=user.email, role=user.role)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(User).offset(skip).limit(limit).all()

# --- Topology CRUD ---
def create_topology(db: Session, topology: TopologyCreate):
    db_topology = Topology(
        title=topology.title,
        description=topology.description,
        canvas_json=topology.canvas_json,
        user_id=topology.user_id
    )
    db.add(db_topology)
    db.commit()
    db.refresh(db_topology)
    return db_topology

def get_topologies(db: Session, user_id: int = None, skip: int = 0, limit: int = 100):
    query = db.query(Topology)
    if user_id:
        query = query.filter(Topology.user_id == user_id)
    return query.order_by(Topology.updated_at.desc()).offset(skip).limit(limit).all()

def get_topology_by_id(db: Session, topology_id: int):
    return db.query(Topology).filter(Topology.id == topology_id).first()

def delete_topology(db: Session, topology_id: int):
    topology = db.query(Topology).filter(Topology.id == topology_id).first()
    if topology:
        db.delete(topology)
        db.commit()
        return True
    return False

# --- User Progress CRUD ---
def save_user_progress(db: Session, progress: ProgressCreate):
    existing = db.query(UserProgress).filter(
        UserProgress.user_id == progress.user_id,
        UserProgress.level_id == progress.level_id
    ).first()

    if existing:
        existing.completed = progress.completed
        existing.stars = max(existing.stars, progress.stars)
        existing.score = max(existing.score, progress.score)
        db.commit()
        db.refresh(existing)
        return existing
    else:
        db_progress = UserProgress(
            user_id=progress.user_id,
            level_id=progress.level_id,
            level_name=progress.level_name,
            completed=progress.completed,
            stars=progress.stars,
            score=progress.score
        )
        db.add(db_progress)
        db.commit()
        db.refresh(db_progress)
        return db_progress

def get_user_progress_list(db: Session, user_id: int = None):
    query = db.query(UserProgress)
    if user_id:
        query = query.filter(UserProgress.user_id == user_id)
    return query.all()

# --- Packet Trace CRUD ---
def record_packet_trace(db: Session, source_ip: str = None, destination_ip: str = None, success: bool = True):
    trace = PacketTrace(
        source_ip=source_ip,
        destination_ip=destination_ip,
        success=success
    )
    db.add(trace)
    db.commit()
    db.refresh(trace)
    return trace

# --- Real Aggregate Dashboard Stats Query ---
def get_dashboard_stats(db: Session, user_id: int = None):
    # Total topologies saved in database
    top_query = db.query(Topology)
    if user_id:
        top_query = top_query.filter(Topology.user_id == user_id)
    total_topologies = top_query.count()

    # Total packet traces recorded in database
    total_packets_traced = db.query(PacketTrace).count()

    # Progress list & total XP
    prog_query = db.query(UserProgress)
    if user_id:
        prog_query = prog_query.filter(UserProgress.user_id == user_id)
    progress_list = prog_query.all()

    completed_levels_count = sum(1 for p in progress_list if p.completed)
    total_xp = sum(p.score for p in progress_list if p.completed)

    # Calculate real completion % (based on 4 total course modules)
    total_available_modules = 4
    completion_percentage = round((completed_levels_count / total_available_modules) * 100, 1)

    recent_topologies = top_query.order_by(Topology.updated_at.desc()).limit(5).all()

    return {
        "total_topologies": total_topologies,
        "total_packets_traced": total_packets_traced,
        "total_xp": total_xp,
        "completed_levels_count": completed_levels_count,
        "completion_percentage": min(100.0, completion_percentage),
        "user_progress_list": progress_list,
        "recent_topologies": recent_topologies,
    }
