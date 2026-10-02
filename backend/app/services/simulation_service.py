import ipaddress
from typing import Dict, Any, List, Optional
from ..models.simulation_models import (
    SimulationRequest,
    SimulationResponse,
    PacketModel,
    DeviceModel,
    ConnectionModel,
    ExplanationModel,
)

def get_network_prefix_info(ip: str, subnet_mask: str = "255.255.255.0") -> str:
    """Uses Python's ipaddress module to calculate the exact network CIDR string (e.g. 192.168.1.0/24)."""
    try:
        if not subnet_mask or subnet_mask.strip() == "":
            subnet_mask = "255.255.255.0"
        interface = ipaddress.ip_interface(f"{ip.strip()}/{subnet_mask.strip()}")
        return str(interface.network)
    except Exception:
        # Fallback if IP address string is malformed
        parts = ip.split(".")
        if len(parts) >= 3:
            return f"{'.'.join(parts[:3])}.0/24"
        return f"{ip}/24"

def is_cable_type_valid(dev1_type: str, dev2_type: str, cable_type: str) -> tuple[bool, str]:
    t1, t2 = dev1_type.upper(), dev2_type.upper()
    c = cable_type.lower()

    if c == "console":
        return False, "Console cables are for command-line management only and cannot carry IP data packets."

    # PC to PC
    if t1 == "PC" and t2 == "PC":
        if c == "crossover":
            return True, ""
        return False, "Two PCs are the same type of end-device, so connecting them directly requires a Crossover Cable."

    # PC to Switch
    if (t1 == "PC" and t2 == "SWITCH") or (t1 == "SWITCH" and t2 == "PC"):
        if c == "straight_through":
            return True, ""
        return False, "A PC and a Switch are different types of devices, so connecting them requires a Straight-Through Cable."

    # Switch to Switch
    if t1 == "SWITCH" and t2 == "SWITCH":
        if c in ["crossover", "fiber"]:
            return True, ""
        return False, "Connecting two Switches together requires a Crossover Cable or Fiber Optic link."

    # Router to Router
    if t1 == "ROUTER" and t2 == "ROUTER":
        if c in ["crossover", "fiber"]:
            return True, ""
        return False, "Connecting two Routers together requires a Crossover Cable or Fiber Optic link."

    # Router to Switch
    if (t1 == "ROUTER" and t2 == "SWITCH") or (t1 == "SWITCH" and t2 == "ROUTER"):
        if c in ["straight_through", "fiber"]:
            return True, ""
        return False, "Connecting a Router to a Switch requires a Straight-Through Cable or Fiber Optic link."

    # PC to Router (Direct)
    if (t1 == "PC" and t2 == "ROUTER") or (t1 == "ROUTER" and t2 == "PC"):
        if c in ["crossover", "fiber"]:
            return True, ""
        return False, "Connecting a PC directly to a Router requires a Crossover Cable."

    return True, ""


class SimulationService:
    def run_simulation(self, request: SimulationRequest) -> Dict[str, Any]:
        devices_dict = {d.id: d for d in request.devices}

        # 1. Validate Source and Destination existence
        if request.sourceDeviceId not in devices_dict:
            exp = ExplanationModel(
                code="SOURCE_NOT_FOUND",
                title="Sender Device Not Found",
                what_happened="The selected source device does not exist in the network topology.",
                why="The simulator needs a valid sender device to generate data packets.",
                how_to_fix="Select a valid source device node from the canvas.",
                concept="Device Identification",
                failed_device_id=request.sourceDeviceId,
            )
            return SimulationResponse(
                success=False,
                error="SOURCE_NOT_FOUND",
                message=exp.what_happened,
                explanation=exp,
            ).model_dump()

        if request.destinationDeviceId not in devices_dict:
            exp = ExplanationModel(
                code="DESTINATION_NOT_FOUND",
                title="Receiver Device Not Found",
                what_happened="The selected destination device does not exist in the network topology.",
                why="The simulator needs a valid receiver device to deliver packets to.",
                how_to_fix="Select a valid destination device node from the canvas.",
                concept="Device Identification",
                failed_device_id=request.destinationDeviceId,
            )
            return SimulationResponse(
                success=False,
                error="DESTINATION_NOT_FOUND",
                message=exp.what_happened,
                explanation=exp,
            ).model_dump()

        if request.sourceDeviceId == request.destinationDeviceId:
            exp = ExplanationModel(
                code="INVALID_DESTINATION",
                title="Same Source and Destination",
                what_happened="The source and destination devices are the same node.",
                why="Network packets must travel between two distinct devices across a connection.",
                how_to_fix="Select two different devices to test communication.",
                concept="End-to-End Networking",
                failed_device_id=request.sourceDeviceId,
            )
            return SimulationResponse(
                success=False,
                error="INVALID_DESTINATION",
                message=exp.what_happened,
                explanation=exp,
            ).model_dump()

        src_device = devices_dict[request.sourceDeviceId]
        dest_device = devices_dict[request.destinationDeviceId]

        # 2. Check Port Administrative State (UP / DOWN) on Source & Destination
        if (src_device.portStatus or "up").lower() == "down":
            exp = ExplanationModel(
                code="PORT_DOWN",
                title="Source Port Is Turned Off",
                what_happened=f"The network port on {src_device.name} is administratively shut down (DOWN).",
                why="When a network port is turned off, no signals or packets can enter or leave the device.",
                how_to_fix=f"Click on {src_device.name} in the inspector and toggle its port status to UP.",
                concept="Port Administrative Status",
                failed_device_id=src_device.id,
            )
            return SimulationResponse(
                success=False,
                error="PORT_DOWN",
                message=exp.what_happened,
                explanation=exp,
            ).model_dump()

        if (dest_device.portStatus or "up").lower() == "down":
            exp = ExplanationModel(
                code="PORT_DOWN",
                title="Destination Port Is Turned Off",
                what_happened=f"The network port on {dest_device.name} is administratively shut down (DOWN).",
                why="When a network port is turned off, no signals or packets can enter or leave the device.",
                how_to_fix=f"Click on {dest_device.name} in the inspector and toggle its port status to UP.",
                concept="Port Administrative Status",
                failed_device_id=dest_device.id,
            )
            return SimulationResponse(
                success=False,
                error="PORT_DOWN",
                message=exp.what_happened,
                explanation=exp,
            ).model_dump()

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

        # 4. BFS Pathfinding (Rule: Intermediate nodes CANNOT be PCs, since PCs do not forward packets)
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
                    # Do not route through intermediate PCs
                    if neighbor != request.destinationDeviceId:
                        neighbor_dev = devices_dict[neighbor]
                        if neighbor_dev.type.upper() == "PC":
                            continue

                    new_path = list(current_path) + [neighbor]
                    queue.append(new_path)

        if not path_found:
            exp = ExplanationModel(
                code="NO_PATH",
                title="No Cable Path Found",
                what_happened=f"The packet could not find a connected cable path from {src_device.name} to {dest_device.name}.",
                why="The physical connection between devices is broken or missing.",
                how_to_fix="Add active cables between devices, or repair broken cables on the canvas.",
                concept="Physical Connectivity",
            )
            return SimulationResponse(
                success=False,
                error="NO_PATH",
                message=exp.what_happened,
                explanation=exp,
            ).model_dump()

        # 5. Check Port Status UP/DOWN along the path
        for node_id in path_found:
            d = devices_dict[node_id]
            if (d.portStatus or "up").lower() == "down":
                exp = ExplanationModel(
                    code="PORT_DOWN",
                    title="Intermediate Interface Port Is Turned Off",
                    what_happened=f"The network port on {d.name} is administratively shut down (DOWN).",
                    why="Devices cannot forward packets through an interface set to DOWN state.",
                    how_to_fix=f"Click on {d.name} and toggle its interface port status to UP.",
                    concept="Port Administrative Status",
                    failed_device_id=d.id,
                )
                return SimulationResponse(
                    success=False,
                    error="PORT_DOWN",
                    message=exp.what_happened,
                    explanation=exp,
                ).model_dump()

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
                    exp = ExplanationModel(
                        code="CABLE_TYPE_MISMATCH",
                        title="Wrong Cable Type Used",
                        what_happened=f"The cable between {dev1.name} and {dev2.name} is the wrong type ({conn.cableType}).",
                        why=msg,
                        how_to_fix="Click on the cable to select it and change its type in the properties inspector.",
                        concept="Cable Types & Wiring",
                        failed_connection_id=conn.id,
                        failed_device_id=dev1.id,
                    )
                    return SimulationResponse(
                        success=False,
                        error="CABLE_TYPE_MISMATCH",
                        message=exp.what_happened,
                        explanation=exp,
                    ).model_dump()

        # 7. Validate Subnet & Default Gateway Logic using ipaddress module
        src_net = get_network_prefix_info(src_device.ipAddress, src_device.subnetMask or "255.255.255.0")
        dest_net = get_network_prefix_info(dest_device.ipAddress, dest_device.subnetMask or "255.255.255.0")

        # Check if path contains a Router
        has_router = any(devices_dict[nid].type.upper() == "ROUTER" for nid in path_found)

        if src_net != dest_net:
            if not has_router:
                exp = ExplanationModel(
                    code="SUBNET_MISMATCH",
                    title="IP Subnet Mismatch (Missing Router)",
                    what_happened=f"{src_device.name} ({src_device.ipAddress}) and {dest_device.name} ({dest_device.ipAddress}) are on different IP subnets ({src_net} vs {dest_net}).",
                    why="Devices on different IP subnets cannot talk directly through a simple Switch. A Router is required to route packets between different subnets.",
                    how_to_fix="Change IP addresses so both devices share the same subnet prefix, or place a Router between them.",
                    concept="IP Subnetting & CIDR",
                )
                return SimulationResponse(
                    success=False,
                    error="SUBNET_MISMATCH",
                    message=exp.what_happened,
                    explanation=exp,
                ).model_dump()

            # If subnets differ and router is present, verify source device default gateway
            gw = (src_device.defaultGateway or "").strip()
            if not gw or gw == "0.0.0.0":
                exp = ExplanationModel(
                    code="MISSING_DEFAULT_GATEWAY",
                    title="Missing Default Gateway Configuration",
                    what_happened=f"{src_device.name} is trying to reach an external network ({dest_net}) but has no Default Gateway configured.",
                    why="When sending packets to an IP outside its local subnet, a device must send them to a Default Gateway (Router IP).",
                    how_to_fix=f"Click on {src_device.name} and set its Default Gateway to the local Router interface IP address.",
                    concept="Default Gateways",
                    failed_device_id=src_device.id,
                )
                return SimulationResponse(
                    success=False,
                    error="MISSING_DEFAULT_GATEWAY",
                    message=exp.what_happened,
                    explanation=exp,
                ).model_dump()

            # Check if default gateway is in source's subnet
            gw_net = get_network_prefix_info(gw, src_device.subnetMask or "255.255.255.0")
            if gw_net != src_net:
                exp = ExplanationModel(
                    code="INVALID_DEFAULT_GATEWAY",
                    title="Default Gateway IP Not in Local Subnet",
                    what_happened=f"The Default Gateway for {src_device.name} ({gw}) is not in its local subnet ({src_net}).",
                    why="A device can only talk directly to a Default Gateway that sits inside its own local network subnet.",
                    how_to_fix=f"Update {src_device.name}'s Default Gateway IP address so its subnet prefix matches {src_net}.",
                    concept="Default Gateways",
                    failed_device_id=src_device.id,
                )
                return SimulationResponse(
                    success=False,
                    error="INVALID_DEFAULT_GATEWAY",
                    message=exp.what_happened,
                    explanation=exp,
                ).model_dump()

            # Check if a router on the path has this gateway IP
            router_ips = [devices_dict[nid].ipAddress for nid in path_found if devices_dict[nid].type.upper() == "ROUTER"]
            if router_ips and gw not in router_ips:
                exp = ExplanationModel(
                    code="UNREACHABLE_GATEWAY",
                    title="Unreachable Gateway Router Interface",
                    what_happened=f"{src_device.name}'s Default Gateway ({gw}) does not match any active Router interface IP ({', '.join(router_ips)}).",
                    why="The host is sending packets to a gateway address that no router in the active path currently holds.",
                    how_to_fix=f"Update {src_device.name}'s Default Gateway to match the Router's actual interface IP address ({router_ips[0]}).",
                    concept="Router Interfaces & Gateways",
                    failed_device_id=src_device.id,
                )
                return SimulationResponse(
                    success=False,
                    error="UNREACHABLE_GATEWAY",
                    message=exp.what_happened,
                    explanation=exp,
                ).model_dump()

        # 8. Success: Path Resolved
        resolved_path_names = [devices_dict[node_id].name for node_id in path_found]
        resolved_path_ids = list(path_found)

        packet_info = PacketModel(
            sourceDeviceId=src_device.id,
            destinationDeviceId=dest_device.id,
            sourceIP=src_device.ipAddress,
            destinationIP=dest_device.ipAddress,
            sourceMAC=src_device.macAddress,
            destinationMAC=dest_device.macAddress,
        )

        exp_success = ExplanationModel(
            code="SUCCESS",
            title="Packet Delivered Successfully",
            what_happened=f"The packet travelled cleanly from {src_device.name} to {dest_device.name} across {len(path_found)-1} link hop(s).",
            why="All IP subnets, default gateways, interface port states, and physical cables are correctly configured.",
            how_to_fix="No fix required! Your network topology is functioning properly.",
            concept="End-to-End Network Delivery",
        )

        return SimulationResponse(
            success=True,
            path=resolved_path_names,
            path_ids=resolved_path_ids,
            packet=packet_info,
            explanation=exp_success,
        ).model_dump()
