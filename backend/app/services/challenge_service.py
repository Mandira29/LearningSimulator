from typing import List, Dict, Any, Optional
from ..models.challenge_models import (
    ChallengeModel,
    ChallengeActionRequest,
    ChallengeActionResult,
    ChallengeStatus,
)
from .challenge_data import get_all_challenges_data
from ..services.simulation_service import SimulationService

class ChallengeService:
    def __init__(self):
        self._challenges: Dict[str, ChallengeModel] = {
            ch.id: ch for ch in get_all_challenges_data()
        }
        self._sim_service = SimulationService()

    def get_all_challenges(self) -> List[ChallengeModel]:
        return list(self._challenges.values())

    def get_challenge(self, challenge_id: str) -> Optional[ChallengeModel]:
        return self._challenges.get(challenge_id)

    def start_challenge(self, challenge_id: str) -> Optional[ChallengeModel]:
        if challenge_id not in self._challenges:
            return None
        
        # Reset to base definition
        fresh_data = {ch.id: ch for ch in get_all_challenges_data()}
        ch = fresh_data[challenge_id]
        ch.status = ChallengeStatus.IN_PROGRESS
        self._challenges[challenge_id] = ch
        return ch

    def reset_challenge(self, challenge_id: str) -> Optional[ChallengeModel]:
        return self.start_challenge(challenge_id)

    def execute_action(self, challenge_id: str, request: ChallengeActionRequest) -> ChallengeActionResult:
        ch = self._challenges.get(challenge_id)
        if not ch:
            return ChallengeActionResult(
                success=False,
                message=f"Challenge '{challenge_id}' not found.",
                objectiveCompleted=False,
            )

        action = request.actionType
        payload = request.payload

        if challenge_id == "ch01":
            return self._handle_ch01(ch, action, payload)
        elif challenge_id == "ch02":
            return self._handle_ch02(ch, action, payload)
        elif challenge_id == "ch03":
            return self._handle_ch03(ch, action, payload)
        elif challenge_id == "ch04":
            return self._handle_ch04(ch, action, payload)
        elif challenge_id == "ch05":
            return self._handle_ch05(ch, action, payload)
        elif challenge_id == "ch06":
            return self._handle_ch06(ch, action, payload)
        elif challenge_id == "ch07":
            return self._handle_ch07(ch, action, payload)
        elif challenge_id == "ch08":
            return self._handle_ch08(ch, action, payload)
        elif challenge_id == "ch09":
            return self._handle_ch09(ch, action, payload)
        elif challenge_id == "ch10":
            return self._handle_ch10(ch, action, payload)
        elif challenge_id == "ch11":
            return self._handle_ch11(ch, action, payload)
        elif challenge_id == "ch12":
            return self._handle_ch12(ch, action, payload)

        return ChallengeActionResult(
            success=False,
            message=f"Unsupported action for challenge {challenge_id}.",
            objectiveCompleted=False,
        )

    # -------------------------------------------------------------------------
    # Handlers for Individual Challenges
    # -------------------------------------------------------------------------

    def _handle_ch01(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 01: Packet Fields
        src = payload.get("sourceDeviceId", "pc_alice")
        dst = payload.get("destinationDeviceId", "pc_bob")
        src_ip = payload.get("sourceIP", "192.168.1.10")
        dst_ip = payload.get("destinationIP", "192.168.1.20")

        if src == "pc_alice" and dst == "pc_bob":
            ch.progress["delivered"] = True
            ch.status = ChallengeStatus.COMPLETED
            return ChallengeActionResult(
                success=True,
                message="Packet successfully sent from Alice to Bob with valid IP headers!",
                objectiveCompleted=True,
                progress=ch.progress,
                path=["Alice PC", "Bob PC"],
                path_ids=["pc_alice", "pc_bob"],
                packet={
                    "sourceDeviceId": "pc_alice",
                    "destinationDeviceId": "pc_bob",
                    "sourceIP": src_ip,
                    "destinationIP": dst_ip,
                    "sourceMAC": "AA:AA:AA:00:00:10",
                    "destinationMAC": "BB:BB:BB:00:00:20",
                    "protocol": "IPv4",
                    "currentLayer": 3,
                    "status": "delivered",
                },
                explanation="You inspected the Layer 3 headers and verified the Source IP (192.168.1.10) and Destination IP (192.168.1.20) fields."
            )
        else:
            return ChallengeActionResult(
                success=False,
                message="Destination address does not match the objective (Alice PC → Bob PC).",
                objectiveCompleted=False,
                progress=ch.progress,
            )

    def _handle_ch02(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 02: Ping (5 Echo round trips)
        current = ch.progress.get("pingsCompleted", 0) + 1
        ch.progress["pingsCompleted"] = current
        is_completed = current >= 5
        if is_completed:
            ch.status = ChallengeStatus.COMPLETED

        return ChallengeActionResult(
            success=True,
            message=f"ICMP Echo Request delivered! Echo Reply received from Google Server. ({current}/5)",
            objectiveCompleted=is_completed,
            progress=ch.progress,
            path=["Alice PC", "Google Server", "Alice PC"],
            path_ids=["pc_alice", "srv_google", "pc_alice"],
            packet={
                "sourceDeviceId": "pc_alice",
                "destinationDeviceId": "srv_google",
                "sourceIP": "192.168.1.10",
                "destinationIP": "8.8.8.8",
                "protocol": "ICMP",
                "icmpType": "Echo Request (Type 8) / Echo Reply (Type 0)",
                "roundTripTimeMs": 24,
                "currentLayer": 3,
                "status": "delivered",
            },
            explanation="ICMP Echo Requests check bidirectional connectivity: Alice sent an Echo Request (Type 8), and Google responded with an Echo Reply (Type 0)."
        )

    def _handle_ch03(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 03: Routing (Bob -> Router A -> Router C -> Carol)
        src = payload.get("sourceDeviceId", "pc_bob")
        dst = payload.get("destinationDeviceId", "pc_carol")

        if src == "pc_bob" and dst == "pc_carol":
            ch.progress["delivered"] = True
            ch.progress["hopsCompleted"] = 3
            ch.status = ChallengeStatus.COMPLETED
            return ChallengeActionResult(
                success=True,
                message="Packet successfully routed from Bob through Router A and Router C to Carol!",
                objectiveCompleted=True,
                progress=ch.progress,
                path=["Bob", "Router A", "Router C", "Carol"],
                path_ids=["pc_bob", "router_a", "router_c", "pc_carol"],
                packet={
                    "sourceDeviceId": "pc_bob",
                    "destinationDeviceId": "pc_carol",
                    "sourceIP": "192.168.1.10",
                    "destinationIP": "192.168.3.10",
                    "protocol": "IPv4",
                    "currentLayer": 3,
                    "ttl": 62,
                    "status": "delivered",
                },
                explanation="The packet traversed intermediate routers hop-by-hop. Router A matched Carol's subnet (192.168.3.0/24) and forwarded to Router C, which delivered to Carol."
            )
        else:
            return ChallengeActionResult(
                success=False,
                message="No valid route matched the selected endpoints. Route must be from Bob to Carol.",
                objectiveCompleted=False,
                progress=ch.progress,
            )

    def _handle_ch04(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 04: Modems (NAT)
        sender = payload.get("sourceDeviceId", "pc_alice")
        if sender == "pc_alice":
            ch.progress["alicePingCompleted"] = True
        elif sender == "pc_bob":
            ch.progress["bobPingCompleted"] = True

        all_done = ch.progress.get("alicePingCompleted", False) and ch.progress.get("bobPingCompleted", False)
        if ch.progress.get("alicePingCompleted", False):
            # Completes on Alice or both
            ch.status = ChallengeStatus.COMPLETED

        sender_name = "Alice PC" if sender == "pc_alice" else "Bob PC"
        sender_private_ip = "192.168.1.10" if sender == "pc_alice" else "192.168.1.20"

        return ChallengeActionResult(
            success=True,
            message=f"Modem translated {sender_name}'s private IP ({sender_private_ip}) to public IP (203.0.113.5) and routed to Google!",
            objectiveCompleted=True,
            progress=ch.progress,
            path=[sender_name, "Home Modem / NAT", "Internet / Google"],
            path_ids=[sender, "modem", "srv_google"],
            packet={
                "sourceDeviceId": sender,
                "destinationDeviceId": "srv_google",
                "sourceIP": sender_private_ip,
                "translatedSourceIP": "203.0.113.5",
                "destinationIP": "8.8.8.8",
                "natTable": f"NAT Entry: {sender_private_ip}:49152 <-> 203.0.113.5:10024",
                "protocol": "IPv4 / NAT",
                "currentLayer": 3,
                "status": "translated_and_delivered",
            },
            explanation="The Modem performs Network Address Translation (NAT): private internal addresses are rewritten to the modem's public IP so Internet servers can send replies back."
        )

    def _handle_ch05(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 05: IP Spoofing
        spoofed_ip = payload.get("spoofedSourceIP", payload.get("sourceIP", "")).strip()
        actual_sender = payload.get("sourceDeviceId", "pc_alice")
        dest = payload.get("destinationDeviceId", "pc_bob")

        if actual_sender == "pc_alice" and dest == "pc_bob" and spoofed_ip == "192.168.1.30":
            ch.progress["spoofedPacketSent"] = True
            ch.status = ChallengeStatus.COMPLETED
            return ChallengeActionResult(
                success=True,
                message="IP Spoofing successful! Packet physically transmitted by Alice, but header claims Carol (192.168.1.30).",
                objectiveCompleted=True,
                progress=ch.progress,
                path=["Alice (Sender)", "Core Switch", "Bob (Receiver)"],
                path_ids=["pc_alice", "switch1", "pc_bob"],
                packet={
                    "actualSenderId": "pc_alice",
                    "sourceDeviceId": "pc_alice",
                    "destinationDeviceId": "pc_bob",
                    "sourceIP": "192.168.1.30 (Carol - SPOOFED)",
                    "actualSourceIP": "192.168.1.10 (Alice)",
                    "destinationIP": "192.168.1.20 (Bob)",
                    "isSpoofed": True,
                    "protocol": "IPv4",
                    "currentLayer": 3,
                    "status": "spoofed_delivery",
                },
                explanation="IP routing forwards packets according to Destination IP. Because traditional IP headers have no cryptographic origin authentication, Bob sees Carol's IP as the sender."
            )
        else:
            return ChallengeActionResult(
                success=False,
                message="Objective not met. Actual sender must be Alice, destination must be Bob, and source IP must be forged as Carol's (192.168.1.30).",
                objectiveCompleted=False,
                progress=ch.progress,
            )

    def _handle_ch06(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 06: Stealing Packets (CAM table poisoning / redirection)
        ch.progress["camTableInspected"] = True
        ch.progress["redirectionDemonstrated"] = True
        ch.status = ChallengeStatus.COMPLETED

        return ChallengeActionResult(
            success=True,
            message="Switch CAM table learned altered port mapping! Traffic intended for Bob was forwarded to Carol's port.",
            objectiveCompleted=True,
            progress=ch.progress,
            path=["Alice", "Learning Switch", "Carol (Interception Node)"],
            path_ids=["pc_alice", "switch1", "pc_carol"],
            packet={
                "sourceDeviceId": "pc_alice",
                "destinationDeviceId": "pc_carol",
                "intendedDestination": "Bob (BB:BB:BB:00:00:20)",
                "divertedTo": "Carol (Port 3)",
                "switchCAM": "Port 3: BB:BB:BB:00:00:20 (POISONED)",
                "protocol": "Ethernet / L2",
                "currentLayer": 2,
                "status": "intercepted",
            },
            explanation="Switches dynamically update their Content Addressable Memory (CAM) tables based on incoming source MAC addresses. When poisoned, the switch sends frames out the wrong port."
        )

    def _handle_ch07(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 07: Basic DoS
        packet_count = int(payload.get("packetCount", 25))
        capacity = 20
        ch.progress["trafficGenerated"] = packet_count
        ch.progress["serverCapacity"] = capacity

        if packet_count >= capacity:
            ch.progress["serverStatus"] = "OVERLOADED"
            ch.status = ChallengeStatus.COMPLETED
            return ChallengeActionResult(
                success=True,
                message=f"Server Overloaded! Traffic ({packet_count} pkts/tick) exceeded server capacity ({capacity} pkts/tick).",
                objectiveCompleted=True,
                progress=ch.progress,
                path=["Student PC", "Google Server (Capacity: 20)"],
                path_ids=["pc_student", "srv_google"],
                details={"traffic": packet_count, "capacity": capacity, "serverStatus": "OVERLOADED"},
                explanation="Denial of Service occurs when request volume outpaces processing bandwidth. Google Server became overloaded and started dropping legitimate connections."
            )
        else:
            ch.progress["serverStatus"] = "Normal"
            return ChallengeActionResult(
                success=False,
                message=f"Traffic level ({packet_count} pkts) is below server capacity ({capacity} pkts). Increase packet count to overload the server.",
                objectiveCompleted=False,
                progress=ch.progress,
                details={"traffic": packet_count, "capacity": capacity, "serverStatus": "Normal"},
            )

    def _handle_ch08(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 08: Distributed DoS
        alice = int(payload.get("aliceTraffic", 8))
        bob = int(payload.get("bobTraffic", 7))
        carol = int(payload.get("carolTraffic", 9))
        dave = int(payload.get("daveTraffic", 6))
        total = alice + bob + carol + dave

        ch.progress.update({
            "aliceTraffic": alice,
            "bobTraffic": bob,
            "carolTraffic": carol,
            "daveTraffic": dave,
            "totalTraffic": total,
            "serverCapacity": 20,
        })

        if total >= 20:
            ch.progress["serverStatus"] = "OVERLOADED"
            ch.status = ChallengeStatus.COMPLETED
            return ChallengeActionResult(
                success=True,
                message=f"DDoS Successful! Aggregate traffic ({total} pkts) from 4 distributed sources exceeded capacity (20).",
                objectiveCompleted=True,
                progress=ch.progress,
                path=["Core Switch", "Google Server (Cap: 20)"],
                path_ids=["switch1", "srv_google"],
                details={"totalTraffic": total, "capacity": 20, "serverStatus": "OVERLOADED"},
                explanation="A Distributed Denial of Service (DDoS) coordinates multiple endpoints (botnets). No single machine alone exceeded capacity, but combined aggregate traffic overwhelmed the server."
            )
        else:
            return ChallengeActionResult(
                success=False,
                message=f"Total traffic ({total}) has not yet exceeded server capacity (20). Increase output from endpoints.",
                objectiveCompleted=False,
                progress=ch.progress,
            )

    def _handle_ch09(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 09: Smurf Attack (Amplification)
        dst = payload.get("destinationIP", "255.255.255.255")
        spoofed_src = payload.get("sourceIP", "8.8.8.8")

        ch.progress["broadcastSent"] = True
        ch.progress["amplifiedReplies"] = 4
        ch.status = ChallengeStatus.COMPLETED

        return ChallengeActionResult(
            success=True,
            message="Smurf Attack Successful! 1 broadcast request resulted in 4 amplified replies bombarding Google Server.",
            objectiveCompleted=True,
            progress=ch.progress,
            path=["Attacker", "Broadcast Switch", "Victim (Google)"],
            path_ids=["pc_attacker", "switch1", "srv_google"],
            details={"amplificationRatio": "1 request -> 4 replies", "victim": "8.8.8.8"},
            packet={
                "sourceDeviceId": "pc_attacker",
                "destinationDeviceId": "srv_google",
                "sourceIP": "8.8.8.8 (Google - SPOOFED)",
                "destinationIP": "255.255.255.255 (BROADCAST)",
                "amplifiedCount": 4,
                "protocol": "ICMP Echo (Amplified)",
                "currentLayer": 3,
                "status": "amplified_flood",
            },
            explanation="Smurf attacks reflect and amplify traffic: sending one ICMP echo request to a subnet broadcast address with the victim's spoofed source IP tricks all subnet hosts into bombarding the victim."
        )

    def _handle_ch10(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 10: Man-in-the-Middle (MITM)
        is_encrypted = payload.get("encrypted", False)
        ch.progress["interceptionObserved"] = True
        if is_encrypted:
            ch.progress["encryptionTested"] = True
        ch.status = ChallengeStatus.COMPLETED

        payload_text = "Encrypted Ciphertext (AES-256): e3b0c44298fc1c149afbf4c8996fb924" if is_encrypted else "Plaintext Payload: 'Hello Bob! Secret: P@ssw0rd!'"

        return ChallengeActionResult(
            success=True,
            message="MITM Interception observed at Eve! " + ("Encryption protected payload integrity." if is_encrypted else "Plaintext payload was readable and tamperable."),
            objectiveCompleted=True,
            progress=ch.progress,
            path=["Alice", "Eve (Interception Node)", "Bob"],
            path_ids=["pc_alice", "dev_eve", "pc_bob"],
            packet={
                "originalSender": "Alice (192.168.1.10)",
                "originalDestination": "Bob (192.168.1.20)",
                "interceptedBy": "Eve (192.168.1.99)",
                "payload": payload_text,
                "encrypted": is_encrypted,
                "protocol": "TLS/HTTPS" if is_encrypted else "HTTP",
                "currentLayer": 7,
                "status": "intercepted_and_relayed",
            },
            explanation="When packets travel across unencrypted links, intermediate nodes (like Eve) can inspect and alter content. Strong end-to-end encryption (TLS) ensures confidentiality even if traffic is intercepted."
        )

    def _handle_ch11(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 11: Censorship & Proxy Bypass
        use_proxy = payload.get("useProxy", False)
        dest = payload.get("destinationDeviceId", "site_blocked")

        if not use_proxy:
            ch.progress["blockedAttempted"] = True
            return ChallengeActionResult(
                success=False,
                message="BLOCKED BY FIREWALL RULE: Direct traffic from Alice to Blocked Site (198.51.100.99) is denied.",
                objectiveCompleted=False,
                progress=ch.progress,
                path=["Alice", "Firewall / Censor"],
                path_ids=["pc_alice", "fw_censor"],
                packet={
                    "sourceDeviceId": "pc_alice",
                    "destinationDeviceId": "site_blocked",
                    "sourceIP": "192.168.1.10",
                    "destinationIP": "198.51.100.99",
                    "isBlocked": True,
                    "dropReason": "FIREWALL_POLICY_DROP",
                    "currentLayer": 3,
                    "status": "dropped",
                },
                explanation="The firewall inspected the destination IP (198.51.100.99), matched a block rule, and dropped the packet."
            )
        else:
            ch.progress["proxyBypassCompleted"] = True
            ch.status = ChallengeStatus.COMPLETED
            return ChallengeActionResult(
                success=True,
                message="Proxy Bypass Successful! Alice routed via Proxy Server (192.168.1.80), traversing firewall restrictions.",
                objectiveCompleted=True,
                progress=ch.progress,
                path=["Alice", "Proxy Server", "Blocked Site"],
                path_ids=["pc_alice", "proxy_srv", "site_blocked"],
                packet={
                    "sourceDeviceId": "pc_alice",
                    "proxyDeviceId": "proxy_srv",
                    "finalDestination": "Blocked Site (198.51.100.99)",
                    "outerSourceIP": "192.168.1.10",
                    "outerDestinationIP": "192.168.1.80 (Proxy)",
                    "innerDestinationIP": "198.51.100.99",
                    "protocol": "HTTP Proxy Tunnel",
                    "currentLayer": 7,
                    "status": "proxied_delivery",
                },
                explanation="A proxy acts as an intermediary. The local firewall only sees Alice connecting to the allowed Proxy IP (192.168.1.80), which then fetches content from the blocked destination."
            )

    def _handle_ch12(self, ch: ChallengeModel, action: str, payload: Dict[str, Any]) -> ChallengeActionResult:
        # Challenge 12: Traceroute (TTL Discovery)
        ttl = int(payload.get("ttl", 1))
        discovered = list(ch.progress.get("discoveredHops", []))

        routers = [
            ("Router 1", "10.1.1.1", "r1"),
            ("Router 2", "10.2.2.1", "r2"),
            ("Router 3", "10.3.3.1", "r3"),
            ("Router 4", "10.4.4.1", "r4"),
            ("Google Server", "8.8.8.8", "srv_google"),
        ]

        # In index 0-based: ttl=1 discovers Router 1, etc.
        index = min(ttl - 1, 4)
        r_name, r_ip, r_id = routers[index]

        if r_ip not in [h["ip"] for h in discovered]:
            discovered.append({"hop": ttl, "name": r_name, "ip": r_ip, "id": r_id})
        ch.progress["discoveredHops"] = discovered
        ch.progress["currentTTL"] = ttl

        path_names = ["Alice PC"] + [r[0] for r in routers[:index+1]]
        path_ids = ["pc_alice"] + [r[2] for r in routers[:index+1]]

        is_completed = len(discovered) >= 4 or ttl >= 5
        if is_completed:
            ch.status = ChallengeStatus.COMPLETED

        if ttl < 5:
            msg = f"TTL={ttl} reached {r_name} ({r_ip}): TTL Expired in Transit! Hop {ttl} discovered."
            status_str = "ttl_expired"
        else:
            msg = f"TTL={ttl} reached destination Google Server ({r_ip})! Full path mapped."
            status_str = "reached_destination"

        return ChallengeActionResult(
            success=True,
            message=msg,
            objectiveCompleted=is_completed,
            progress=ch.progress,
            path=path_names,
            path_ids=path_ids,
            packet={
                "sourceDeviceId": "pc_alice",
                "destinationDeviceId": r_id,
                "sourceIP": "192.168.1.10",
                "destinationIP": "8.8.8.8",
                "currentTTL": ttl,
                "respondingDevice": r_name,
                "respondingIP": r_ip,
                "icmpMessage": "ICMP Type 11: Time-To-Live Exceeded in Transit" if ttl < 5 else "ICMP Type 0: Echo Reply",
                "protocol": "ICMP / Traceroute",
                "currentLayer": 3,
                "status": status_str,
            },
            explanation="Traceroute sends packets with incrementing TTL starting at 1. Each intermediate router decrements TTL by 1. When TTL reaches 0, the router drops the packet and responds with an ICMP Time Exceeded message, revealing its IP."
        )
