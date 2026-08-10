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

class ConnectionModel(BaseModel):
    id: str
    sourceDeviceId: str
    destinationDeviceId: str
    status: str  # active, broken

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

class SimulationResponse(BaseModel):
    success: bool
    error: Optional[str] = None
    message: Optional[str] = None
    path: Optional[List[str]] = None  # Wait: String is not a python type. Use str!
    packet: Optional[PacketModel] = None
