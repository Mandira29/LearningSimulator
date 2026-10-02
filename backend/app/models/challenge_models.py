from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from enum import Enum
from .simulation_models import DeviceModel, ConnectionModel, PacketModel

class ChallengeCategory(str, Enum):
    FUNDAMENTALS = "fundamentals"
    SECURITY = "security"
    DENIAL_OF_SERVICE = "denialOfService"
    PRIVACY = "privacy"
    DIAGNOSTICS = "diagnostics"

class ChallengeStatus(str, Enum):
    LOCKED = "locked"
    AVAILABLE = "available"
    IN_PROGRESS = "inProgress"
    COMPLETED = "completed"

class ObjectiveType(str, Enum):
    SEND_PACKET = "sendPacket"
    SEND_PING = "sendPing"
    INSPECT_PACKET = "inspectPacket"
    CONFIGURE_PACKET = "configurePacket"
    CONFIGURE_ROUTING = "configureRouting"
    MODIFY_SOURCE_ADDRESS = "modifySourceAddress"
    GENERATE_TRAFFIC = "generateTraffic"
    OBSERVE_PACKET = "observePacket"
    DISCOVER_ROUTER = "discoverRouter"
    USE_PROXY = "useProxy"
    DETECT_INTERCEPTION = "detectInterception"
    COMPLETE_SEQUENCE = "completeSequence"

class ChallengeModel(BaseModel):
    id: str
    number: int
    title: str
    category: ChallengeCategory
    description: str
    learningObjective: str
    instructions: List[str]
    difficulty: str  # Basic, Beginner, Intermediate, Advanced
    initialDevices: List[DeviceModel]
    initialConnections: List[ConnectionModel]
    objectiveType: ObjectiveType
    requiredActions: List[str]
    successConditions: Dict[str, Any]
    hints: List[str]
    explanation: str
    status: ChallengeStatus = ChallengeStatus.AVAILABLE
    progress: Dict[str, Any] = Field(default_factory=dict)

class ChallengeActionRequest(BaseModel):
    actionType: str
    payload: Dict[str, Any] = Field(default_factory=dict)

class ChallengeActionResult(BaseModel):
    success: bool
    message: str
    details: Dict[str, Any] = Field(default_factory=dict)
    objectiveCompleted: bool = False
    progress: Dict[str, Any] = Field(default_factory=dict)
    path: Optional[List[str]] = None
    path_ids: Optional[List[str]] = None
    packet: Optional[Dict[str, Any]] = None
    explanation: Optional[str] = None
