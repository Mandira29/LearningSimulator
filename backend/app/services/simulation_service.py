from typing import Dict, Any, List
from ..models.simulation_models import SimulationRequest, PacketModel

class SimulationService:
    def run_simulation(self, request: SimulationRequest) -> Dict[str, Any]:
        devices_dict = {d.id: d for d in request.devices}

        # 1. Validate Source and Destination
        if request.sourceDeviceId not in devices_dict:
            return {
                "success": False,
                "error": "SOURCE_NOT_FOUND",
                "message": f"Source device with ID '{request.sourceDeviceId}' was not found in the topology."
            }

        if request.destinationDeviceId not in devices_dict:
            return {
                "success": False,
                "error": "DESTINATION_NOT_FOUND",
                "message": f"Destination device with ID '{request.destinationDeviceId}' was not found in the topology."
            }

        if request.sourceDeviceId == request.destinationDeviceId:
            return {
                "success": False,
                "error": "INVALID_DESTINATION",
                "message": "Source and destination devices must be different nodes."
            }

        # 2. Build Adjacency List (ignoring broken/invalid connections)
        adj_list: Dict[str, List[str]] = {d.id: [] for d in request.devices}
        
        for conn in request.connections:
            # Skip broken connections
            if conn.status == "broken":
                continue
                
            # Skip connections referencing non-existent devices
            if conn.sourceDeviceId not in devices_dict or conn.destinationDeviceId not in devices_dict:
                continue
                
            adj_list[conn.sourceDeviceId].append(conn.destinationDeviceId)
            adj_list[conn.destinationDeviceId].append(conn.sourceDeviceId)

        # 3. BFS Pathfinding
        queue: List[List[str]] = [[request.sourceDeviceId]]
        visited = set()

        path_found: List[str] = []

        while queue:
            current_path = queue.pop(0)
            node = current_path[-1]

            if node == request.destinationDeviceId:
                path_found = current_path
                break

            if node not in visited:
                visited.add(node)
                for neighbor in adj_list.get(node, []):
                    new_path = list(current_path) + [neighbor]
                    queue.append(new_path)

        # 4. Handle No Path Found
        if not path_found:
            return {
                "success": False,
                "error": "NO_PATH",
                "message": "No path exists between the selected devices. Ensure cables are connected and active."
            }

        src_device = devices_dict[request.sourceDeviceId]
        dest_device = devices_dict[request.destinationDeviceId]

        # 4.5 Validate IP Subnets (Local subnet check: share first 3 octets)
        src_ip_parts = src_device.ipAddress.split('.')
        dest_ip_parts = dest_device.ipAddress.split('.')
        if len(src_ip_parts) >= 3 and len(dest_ip_parts) >= 3:
            src_subnet = ".".join(src_ip_parts[:3])
            dest_subnet = ".".join(dest_ip_parts[:3])
            if src_subnet != dest_subnet:
                return {
                    "success": False,
                    "error": "IP_MISMATCH",
                    "message": f"IP Subnet Mismatch: Source ({src_device.ipAddress}) and Destination ({dest_device.ipAddress}) are on different subnets. They must share the same network prefix (e.g., 192.168.1.x) to communicate."
                }

        # 5. Path Name Resolution (Map IDs to Names for user display)
        resolved_path_names = [devices_dict[node_id].name for node_id in path_found]

        # 6. Create Packet Model
        packet_info = PacketModel(
            sourceDeviceId=src_device.id,
            destinationDeviceId=dest_device.id,
            sourceIP=src_device.ipAddress,
            destinationIP=dest_device.ipAddress,
            sourceMAC=src_device.macAddress,
            destinationMAC=dest_device.macAddress
        )

        return {
            "success": True,
            "path": resolved_path_names,
            "packet": packet_info.dict()
        }
