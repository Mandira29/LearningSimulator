from pydantic import BaseModel, Field
from typing import List, Optional

class DeviceModel(BaseModel):
    id: str
    type: str  # PC, SWITCH, ROUTER
    name: str
    x: float
    y: float
    ipAddress: str
    macAddress: str
    subnetMask: Optional[str] = "255.255.255.0"
    defaultGateway: Optional[str] = "192.168.1.1"
    portStatus: Optional[str] = "up"  # up, down

class ConnectionModel(BaseModel):
    id: str
    sourceDeviceId: str
    destinationDeviceId: str
    status: str = "active"  # active, broken
    cableType: str = "straight_through"  # straight_through, crossover, console, fiber

class SimulationRequest(BaseModel):
    devices: List[DeviceModel]
    connections: List[ConnectionModel]
    sourceDeviceId: str
    destinationDeviceId: str

class PacketModel(BaseModel):
    sourceDeviceId: str
    destinationDeviceId: str
    sourceIP: str
    destinationIP: str
    sourceMAC: str
    destinationMAC: str
    protocol: str = "ICMP"
    currentLayer: int = 3
    status: str = "ready"

class ExplanationModel(BaseModel):
    code: str
    title: str
    what_happened: str
    why: str
    how_to_fix: str
    concept: str
    failed_device_id: Optional[str] = None
    failed_connection_id: Optional[str] = None

class SimulationResponse(BaseModel):
    success: bool
    error: Optional[str] = None
    message: Optional[str] = None
    path: Optional[List[str]] = None
    path_ids: Optional[List[str]] = None
    packet: Optional[PacketModel] = None
    explanation: Optional[ExplanationModel] = None

