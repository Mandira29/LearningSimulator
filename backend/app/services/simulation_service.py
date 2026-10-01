from typing import Dict, Any, List, Optional
from ..models.simulation_models import SimulationRequest, PacketModel, DeviceModel, ConnectionModel

def get_network_prefix(ip: str, subnet_mask: str = "255.255.255.0") -> str:
    try:
        ip_octets = [int(x) for x in ip.split('.')]
        mask_octets = [int(x) for x in subnet_mask.split('.')]
        if len(ip_octets) == 4 and len(mask_octets) == 4:
            net_octets = [str(ip_octets[i] & mask_octets[i]) for i in range(4)]
            return ".".join(net_octets)
    except Exception:
        pass
    parts = ip.split('.')
    return ".".join(parts[:3]) if len(parts) >= 3 else ip

def is_cable_type_valid(dev1_type: str, dev2_type: str, cable_type: str) -> tuple[bool, str]:
    t1, t2 = dev1_type.upper(), dev2_type.upper()
    c = cable_type.lower()

    if c == "console":
        return False, "Console cables are used for CLI management only and cannot carry network IP packet traffic."

    # PC to PC
    if t1 == "PC" and t2 == "PC":
        if c == "crossover":
            return True, ""
        return False, "Direct link between two PCs requires a Crossover Cable (crossover)."

    # PC to Switch
    if (t1 == "PC" and t2 == "SWITCH") or (t1 == "SWITCH" and t2 == "PC"):
        if c == "straight_through":
            return True, ""
        return False, "Connecting a PC to a Switch requires a Straight-Through Cable (straight_through)."

    # Switch to Switch
    if t1 == "SWITCH" and t2 == "SWITCH":
        if c in ["crossover", "fiber"]:
            return True, ""
        return False, "Switch to Switch uplink requires a Crossover or Fiber Cable."

    # Router to Router
    if t1 == "ROUTER" and t2 == "ROUTER":
        if c in ["crossover", "fiber"]:
            return True, ""
        return False, "Router to Router link requires a Crossover or Fiber Cable."

    # Router to Switch
    if (t1 == "ROUTER" and t2 == "SWITCH") or (t1 == "SWITCH" and t2 == "ROUTER"):
        if c in ["straight_through", "fiber"]:
            return True, ""
        return False, "Router to Switch connection requires a Straight-Through or Fiber Cable."

    # PC to Router (Direct)
    if (t1 == "PC" and t2 == "ROUTER") or (t1 == "ROUTER" and t2 == "PC"):
        if c in ["crossover", "fiber"]:
            return True, ""
        return False, "Direct PC to Router link requires a Crossover Cable."

    return True, ""


class SimulationService:
    def run_simulation(self, request: SimulationRequest) -> Dict[str, Any]:
        devices_dict = {d.id: d for d in request.devices}

        # 1. Validate Source and Destination existence
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

        src_device = devices_dict[request.sourceDeviceId]
        dest_device = devices_dict[request.destinationDeviceId]

        # 2. Check Port Administrative State (UP / DOWN) on Source & Destination
        if (src_device.portStatus or "up").lower() == "down":
            return {
                "success": False,
                "error": "PORT_DOWN",
                "message": f"Port Administrative State DOWN: Interface on source device '{src_device.name}' is administratively shut down (DOWN)."
            }

        if (dest_device.portStatus or "up").lower() == "down":
            return {
                "success": False,
                "error": "PORT_DOWN",
                "message": f"Port Administrative State DOWN: Interface on destination device '{dest_device.name}' is administratively shut down (DOWN)."
            }

        # 3. Build Adjacency List (ignoring broken connections)
        adj_list: Dict[str, List[str]] = {d.id: [] for d in request.devices}
        conn_map: Dict[str, ConnectionModel] = {}

        for conn in request.connections:
            if conn.status == "broken":
                continue
            if conn.sourceDeviceId not in devices_dict or conn.destinationDeviceId not in devices_dict:
                continue

            adj_list[conn.sourceDeviceId].append(conn.destinationDeviceId)
            adj_list[conn.destinationDeviceId].append(conn.sourceDeviceId)

            pair_key1 = f"{conn.sourceDeviceId}_{conn.destinationDeviceId}"
            pair_key2 = f"{conn.destinationDeviceId}_{conn.sourceDeviceId}"
            conn_map[pair_key1] = conn
            conn_map[pair_key2] = conn

        # 4. BFS Pathfinding
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

        if not path_found:
            return {
                "success": False,
                "error": "NO_PATH",
                "message": "No path exists between the selected devices. Ensure active cables connect the topology."
            }

        # 5. Check Port Status UP/DOWN along the path
        for node_id in path_found:
            d = devices_dict[node_id]
            if (d.portStatus or "up").lower() == "down":
                return {
                    "success": False,
                    "error": "PORT_DOWN",
                    "message": f"Port Administrative State DOWN: Interface on node '{d.name}' is administratively shut down (DOWN)."
                }

        # 6. Validate Cable Types along path
        for i in range(len(path_found) - 1):
            n1_id = path_found[i]
            n2_id = path_found[i + 1]
            conn = conn_map.get(f"{n1_id}_{n2_id}")

            if conn:
                dev1 = devices_dict[n1_id]
                dev2 = devices_dict[n2_id]
                valid, msg = is_cable_type_valid(dev1.type, dev2.type, conn.cableType)
                if not valid:
                    return {
                        "success": False,
                        "error": "CABLE_TYPE_MISMATCH",
                        "message": f"✕ CABLE TYPE MISMATCH between {dev1.name} and {dev2.name}\n{msg}"
                    }

        # 7. Validate Subnet & Default Gateway Logic
        src_net = get_network_prefix(src_device.ipAddress, src_device.subnetMask or "255.255.255.0")
        dest_net = get_network_prefix(dest_device.ipAddress, dest_device.subnetMask or "255.255.255.0")

        # Check if path contains a Router
        has_router = any(devices_dict[nid].type.upper() == "ROUTER" for nid in path_found)

        if src_net != dest_net:
            if not has_router:
                return {
                    "success": False,
                    "error": "SUBNET_MISMATCH",
                    "message": f"✕ IP SUBNET MISMATCH\nSource ({src_device.ipAddress}) and Destination ({dest_device.ipAddress}) are on different subnets ({src_net}.x vs {dest_net}.x) and no Router is present in the path."
                }

            # If subnets differ and router is present, verify source device default gateway
            gw = (src_device.defaultGateway or "").strip()
            if not gw or gw == "0.0.0.0":
                return {
                    "success": False,
                    "error": "MISSING_DEFAULT_GATEWAY",
                    "message": f"✕ MISSING DEFAULT GATEWAY\nHost '{src_device.name}' ({src_device.ipAddress}) is trying to reach external subnet ({dest_net}.x) but has no Default Gateway configured."
                }

            # Check if default gateway is in source's subnet
            gw_net = get_network_prefix(gw, src_device.subnetMask or "255.255.255.0")
            if gw_net != src_net:
                return {
                    "success": False,
                    "error": "INVALID_DEFAULT_GATEWAY",
                    "message": f"✕ INVALID DEFAULT GATEWAY\nHost '{src_device.name}' Default Gateway ('{gw}') is not in host's local subnet prefix ({src_net}.x)."
                }

            # Check if a router on the path has this gateway IP
            router_ips = [devices_dict[nid].ipAddress for nid in path_found if devices_dict[nid].type.upper() == "ROUTER"]
            if router_ips and gw not in router_ips:
                return {
                    "success": False,
                    "error": "UNREACHABLE_GATEWAY",
                    "message": f"✕ UNREACHABLE GATEWAY\nHost '{src_device.name}' Default Gateway ('{gw}') does not match any active Router interface IP ({', '.join(router_ips)})."
                }

        # 8. Success: Path Resolved
        resolved_path_names = [devices_dict[node_id].name for node_id in path_found]

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

