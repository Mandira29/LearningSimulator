from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    role = Column(String(30), default="Student")  # Student, Teacher, Admin
    created_at = Column(DateTime, default=datetime.utcnow)

    topologies = relationship("Topology", back_populates="owner", cascade="all, delete-orphan")
    progress = relationship("UserProgress", back_populates="user", cascade="all, delete-orphan")


class Topology(Base):
    __tablename__ = "topologies"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    canvas_json = Column(Text, nullable=False)  # JSON string of nodes & cables
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    owner = relationship("User", back_populates="topologies")


class UserProgress(Base):
    __tablename__ = "user_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    level_id = Column(Integer, nullable=False)
    level_name = Column(String(100), nullable=False)
    completed = Column(Boolean, default=True)
    stars = Column(Integer, default=3)
    score = Column(Integer, default=100)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="progress")


class PacketTrace(Base):
    __tablename__ = "packet_traces"

    id = Column(Integer, primary_key=True, index=True)
    source_ip = Column(String(50), nullable=True)
    destination_ip = Column(String(50), nullable=True)
    protocol = Column(String(30), default="ICMP Echo")
    success = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
