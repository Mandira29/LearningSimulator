import 'challenge.dart';
import 'device.dart';
import 'connection.dart';

List<Challenge> getDefaultChallenges() {
  return [
    // 1. Packet Fields
    Challenge(
      id: "ch01",
      number: 1,
      title: "Packet Fields",
      category: ChallengeCategory.fundamentals,
      description: "Learn how data packets carry source and destination headers across the network.",
      learningObjective: "Understand the essential Layer 3 packet fields: Source IP and Destination IP.",
      instructions: [
        "Select Alice PC as the sender and Bob PC as the destination.",
        "Inspect the packet fields before sending to examine its Source IP and Destination IP.",
        "Send the packet from Alice to Bob and pause mid-flight to inspect headers.",
        "Verify that the packet arrives safely at Bob's IP address."
      ],
      difficulty: "Basic",
      objectiveType: ObjectiveType.inspectPacket,
      requiredActions: ["select_endpoints", "inspect_headers", "deliver_packet"],
      successConditions: {"delivered": true, "source": "pc_alice", "destination": "pc_bob"},
      hints: [
        "Check that the Source IP matches Alice (192.168.1.10) and Destination IP matches Bob (192.168.1.20).",
        "Pause the simulation midway by clicking the Pause button, then click on the traveling packet circle to inspect Layer 3 fields."
      ],
      explanation: "Every IP packet contains a header with metadata including the Source IP (where it came from) and Destination IP (where it is going). Network devices use these addresses to deliver traffic correctly.",
      status: ChallengeStatus.available,
      progress: {"delivered": false},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice PC", owner: "Alice (Research Lab)", x: 180, y: 220, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10"),
        Device(id: "pc_bob", type: "PC", name: "Bob PC", owner: "Bob (Design Dept)", x: 540, y: 220, ipAddress: "192.168.1.20", macAddress: "BB:BB:BB:00:00:20"),
      ],
      initialConnections: [
        Connection(id: "conn_ab", sourceDeviceId: "pc_alice", destinationDeviceId: "pc_bob", status: "active", cableType: "crossover"),
      ],
    ),

    // 2. Ping
    Challenge(
      id: "ch02",
      number: 2,
      title: "Ping (ICMP Echo)",
      category: ChallengeCategory.fundamentals,
      description: "Discover how the Internet Control Message Protocol (ICMP) checks device reachability using Echo Requests and Echo Replies.",
      learningObjective: "Master ICMP Echo Request & Response flow and track successful two-way round-trips.",
      instructions: [
        "Configure Alice PC to send an ICMP Echo Request to Google Server.",
        "Observe the Echo Request travel from Alice to Google Server.",
        "Watch Google generate an automated Echo Reply back to Alice.",
        "Send at least 5 successful pings to satisfy the challenge threshold."
      ],
      difficulty: "Beginner",
      objectiveType: ObjectiveType.sendPing,
      requiredActions: ["send_icmp_echo", "receive_icmp_reply"],
      successConditions: {"requiredPings": 5},
      hints: [
        "A Ping is not one-way: an Echo Request must reach the server, and the server must return an Echo Reply.",
        "Use the Ping button to send successive ICMP requests until you reach 5 completed round trips."
      ],
      explanation: "ICMP (Internet Control Message Protocol) is used for network diagnostics. When a host sends an ICMP Echo Request (type 8), the receiving host replies with an ICMP Echo Reply (type 0), proving two-way reachability.",
      status: ChallengeStatus.available,
      progress: {"pingsCompleted": 0, "targetPings": 5},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice PC", owner: "Alice (Research Lab)", x: 180, y: 220, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10"),
        Device(id: "srv_google", type: "ROUTER", name: "Google Server", owner: "Public DNS / Cloud", x: 540, y: 220, ipAddress: "8.8.8.8", macAddress: "GG:GG:GG:00:00:08"),
      ],
      initialConnections: [
        Connection(id: "conn_ag", sourceDeviceId: "pc_alice", destinationDeviceId: "srv_google", status: "active", cableType: "crossover"),
      ],
    ),

    // 3. Routing
    Challenge(
      id: "ch03",
      number: 3,
      title: "Routing",
      category: ChallengeCategory.fundamentals,
      description: "Observe how routers inspect destination IP addresses and consult routing tables to forward packets hop-by-hop.",
      learningObjective: "Understand router decision-making, hop-by-hop forwarding, and routing tables.",
      instructions: [
        "Examine the topology with Bob, Router A, Router B, Router C, Alice, and Carol.",
        "Select Router A or Router B to view their simulated routing tables.",
        "Initiate a transmission from Bob to Carol.",
        "Follow the packet hop-by-hop as routers forward it towards Carol's subnet."
      ],
      difficulty: "Beginner",
      objectiveType: ObjectiveType.configureRouting,
      requiredActions: ["inspect_routing_table", "route_packet"],
      successConditions: {"delivered": true, "source": "pc_bob", "destination": "pc_carol"},
      hints: [
        "Routers do not send packets straight to the end destination; they forward to the next hop listed in their routing table.",
        "Check the routing table of Router A: traffic destined for Carol's network (192.168.3.0/24) routes through Router C."
      ],
      explanation: "Routers operate at Layer 3 (Network Layer). When a packet arrives, the router inspects the destination IP, matches it against its routing table, decrements the TTL, and forwards the packet to the next hop interface.",
      status: ChallengeStatus.available,
      progress: {"delivered": false},
      initialDevices: [
        Device(id: "pc_bob", type: "PC", name: "Bob", owner: "Bob (Branch Office)", x: 350, y: 80, ipAddress: "192.168.1.10", macAddress: "BB:BB:BB:00:00:10", defaultGateway: "192.168.1.1"),
        Device(id: "router_a", type: "ROUTER", name: "Router A", owner: "Core Infrastructure", x: 350, y: 190, ipAddress: "192.168.1.1", macAddress: "RA:RA:RA:00:00:01"),
        Device(id: "router_b", type: "ROUTER", name: "Router B", owner: "West Gateway", x: 180, y: 300, ipAddress: "10.0.1.1", macAddress: "RB:RB:RB:00:00:01"),
        Device(id: "router_c", type: "ROUTER", name: "Router C", owner: "East Gateway", x: 520, y: 300, ipAddress: "10.0.2.1", macAddress: "RC:RC:RC:00:00:01"),
        Device(id: "pc_alice", type: "PC", name: "Alice", owner: "Alice (West Lab)", x: 180, y: 420, ipAddress: "192.168.2.10", macAddress: "AA:AA:AA:00:00:10", defaultGateway: "10.0.1.1"),
        Device(id: "pc_carol", type: "PC", name: "Carol", owner: "Carol (East Lab)", x: 520, y: 420, ipAddress: "192.168.3.10", macAddress: "CC:CC:CC:00:00:10", defaultGateway: "10.0.2.1"),
      ],
      initialConnections: [
        Connection(id: "c_bob_ra", sourceDeviceId: "pc_bob", destinationDeviceId: "router_a", status: "active", cableType: "crossover"),
        Connection(id: "c_ra_rb", sourceDeviceId: "router_a", destinationDeviceId: "router_b", status: "active", cableType: "crossover"),
        Connection(id: "c_ra_rc", sourceDeviceId: "router_a", destinationDeviceId: "router_c", status: "active", cableType: "crossover"),
        Connection(id: "c_rb_rc", sourceDeviceId: "router_b", destinationDeviceId: "router_c", status: "active", cableType: "crossover"),
        Connection(id: "c_rb_alice", sourceDeviceId: "router_b", destinationDeviceId: "pc_alice", status: "active", cableType: "crossover"),
        Connection(id: "c_rc_carol", sourceDeviceId: "router_c", destinationDeviceId: "pc_carol", status: "active", cableType: "crossover"),
      ],
    ),

    // 4. Modems & NAT
    Challenge(
      id: "ch04",
      number: 4,
      title: "Modems & NAT",
      category: ChallengeCategory.fundamentals,
      description: "Explore how home modems and NAT routers map private internal IP addresses to a shared public IP address.",
      learningObjective: "Understand simulated Network Address Translation (NAT) and private-to-public IP mapping.",
      instructions: [
        "Notice Alice and Bob have private IPs (192.168.1.10 and 192.168.1.20) connected to the Modem.",
        "Send a packet from Alice PC through the Modem to Google Server.",
        "Observe the packet before the Modem: source is Alice's private IP 192.168.1.10.",
        "Observe the packet after the Modem: source is translated to the public IP 203.0.113.5.",
        "Watch the response map back through the Modem to Alice."
      ],
      difficulty: "Intermediate",
      objectiveType: ObjectiveType.observePacket,
      requiredActions: ["send_through_modem", "inspect_nat_translation"],
      successConditions: {"translated": true, "delivered": true},
      hints: [
        "Private IP addresses (like 192.168.x.x) cannot be routed directly across the public Internet.",
        "The Modem translates the internal private IP to its public external IP before forwarding to Google."
      ],
      explanation: "Modems and NAT (Network Address Translation) gateways allow multiple devices on a private local network to share a single public IP address. The gateway maintains a translation table to route incoming replies back to the right internal machine.",
      status: ChallengeStatus.available,
      progress: {"alicePingCompleted": false},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice PC", owner: "Alice Home", x: 160, y: 140, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10", defaultGateway: "192.168.1.1"),
        Device(id: "pc_bob", type: "PC", name: "Bob PC", owner: "Bob Home", x: 160, y: 320, ipAddress: "192.168.1.20", macAddress: "BB:BB:BB:00:00:20", defaultGateway: "192.168.1.1"),
        Device(id: "modem", type: "MODEM", name: "Home Modem / NAT", owner: "Broadband Gateway", x: 380, y: 230, ipAddress: "192.168.1.1", macAddress: "MM:MM:MM:00:00:01"),
        Device(id: "srv_google", type: "ROUTER", name: "Internet / Google", owner: "Public Server", x: 620, y: 230, ipAddress: "8.8.8.8", macAddress: "GG:GG:GG:00:00:08"),
      ],
      initialConnections: [
        Connection(id: "c_alice_modem", sourceDeviceId: "pc_alice", destinationDeviceId: "modem", status: "active", cableType: "straight_through"),
        Connection(id: "c_bob_modem", sourceDeviceId: "pc_bob", destinationDeviceId: "modem", status: "active", cableType: "straight_through"),
        Connection(id: "c_modem_google", sourceDeviceId: "modem", destinationDeviceId: "srv_google", status: "active", cableType: "straight_through"),
      ],
    ),

    // 5. IP Spoofing
    Challenge(
      id: "ch05",
      number: 5,
      title: "IP Spoofing",
      category: ChallengeCategory.security,
      description: "Examine how an attacker can forge the source IP header of a packet to impersonate another device.",
      learningObjective: "Understand what IP spoofing is, how source headers differ from physical origin, and why validation is needed.",
      instructions: [
        "Alice wants to send a packet to Bob, but pretend it originated from Carol.",
        "Open the packet configuration panel on Alice.",
        "Set the Destination to Bob (192.168.1.20).",
        "Modify the simulated Source IP to Carol's IP (192.168.1.30).",
        "Dispatch the packet and inspect the headers at Bob's side."
      ],
      difficulty: "Intermediate",
      objectiveType: ObjectiveType.modifySourceAddress,
      requiredActions: ["configure_spoofed_source", "deliver_spoofed_packet"],
      successConditions: {"actualSender": "pc_alice", "spoofedIp": "192.168.1.30", "destination": "pc_bob"},
      hints: [
        "The physical/logical transmitter remains Alice, but the Layer 3 header contains Carol's IP.",
        "In the packet creator, set Source IP to 192.168.1.30 and Destination IP to 192.168.1.20."
      ],
      explanation: "IP Spoofing involves crafting IP packets with a forged source IP address. Standard IP routing forwards packets based solely on the destination address, meaning receivers may incorrectly trust that the packet came from the spoofed address.",
      status: ChallengeStatus.available,
      progress: {"spoofedPacketSent": false},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice (Sender)", owner: "Alice (Attacker/Tester)", x: 160, y: 140, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10"),
        Device(id: "pc_carol", type: "PC", name: "Carol (Victim)", owner: "Carol (Spoofed Identity)", x: 160, y: 320, ipAddress: "192.168.1.30", macAddress: "CC:CC:CC:00:00:30"),
        Device(id: "switch1", type: "SWITCH", name: "Core Switch", owner: "IT Dept", x: 380, y: 230, ipAddress: "192.168.1.50", macAddress: "SW:SW:SW:00:00:01"),
        Device(id: "pc_bob", type: "PC", name: "Bob (Receiver)", owner: "Bob (Target)", x: 600, y: 230, ipAddress: "192.168.1.20", macAddress: "BB:BB:BB:00:00:20"),
      ],
      initialConnections: [
        Connection(id: "c_alice_sw", sourceDeviceId: "pc_alice", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_carol_sw", sourceDeviceId: "pc_carol", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_sw_bob", sourceDeviceId: "switch1", destinationDeviceId: "pc_bob", status: "active", cableType: "straight_through"),
      ],
    ),

    // 6. Stealing Packets
    Challenge(
      id: "ch06",
      number: 6,
      title: "Stealing Packets (CAM Poisoning)",
      category: ChallengeCategory.security,
      description: "Explore how switches build MAC address forwarding tables and how altered port associations can redirect traffic.",
      learningObjective: "Understand switch learning tables, MAC-to-port mapping, and traffic diversion concepts.",
      instructions: [
        "Observe the Switch's internal MAC Address Table (port learning).",
        "Notice that before a switch learns a device's port, it floods unknown frames.",
        "Craft a transmission that updates the switch's forwarding table to divert Bob-destined packets towards Carol.",
        "Send a verification packet and confirm the redirection behavior."
      ],
      difficulty: "Intermediate",
      objectiveType: ObjectiveType.observePacket,
      requiredActions: ["inspect_switch_cam", "divert_packet"],
      successConditions: {"interceptionDemonstrated": true},
      hints: [
        "Switches learn the source MAC address of incoming frames to update their port table.",
        "If Carol sends traffic with Bob's MAC address, the switch associates Bob's MAC with Carol's port!"
      ],
      explanation: "Ethernet switches record incoming source MAC addresses on each port. In an educational model of MAC poisoning, forging MAC frames on another port tricks the switch into forwarding subsequent traffic to the wrong host.",
      status: ChallengeStatus.available,
      progress: {"camTableInspected": false},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice", owner: "Alice", x: 160, y: 120, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10"),
        Device(id: "pc_bob", type: "PC", name: "Bob", owner: "Bob", x: 600, y: 120, ipAddress: "192.168.1.20", macAddress: "BB:BB:BB:00:00:20"),
        Device(id: "switch1", type: "SWITCH", name: "Learning Switch", owner: "Layer 2 Infrastructure", x: 380, y: 220, ipAddress: "192.168.1.50", macAddress: "SW:SW:SW:00:00:01"),
        Device(id: "pc_carol", type: "PC", name: "Carol (Interception Node)", owner: "Carol (Adversary)", x: 160, y: 320, ipAddress: "192.168.1.30", macAddress: "CC:CC:CC:00:00:30"),
        Device(id: "srv_google", type: "ROUTER", name: "Server", owner: "Server Host", x: 600, y: 320, ipAddress: "8.8.8.8", macAddress: "GG:GG:GG:00:00:08"),
      ],
      initialConnections: [
        Connection(id: "c_al_sw", sourceDeviceId: "pc_alice", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_bob_sw", sourceDeviceId: "pc_bob", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_carol_sw", sourceDeviceId: "pc_carol", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_srv_sw", sourceDeviceId: "srv_google", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
      ],
    ),

    // 7. Basic DoS
    Challenge(
      id: "ch07",
      number: 7,
      title: "Basic DoS",
      category: ChallengeCategory.denialOfService,
      description: "Observe how a server's processing capacity can be exhausted when inundated with excessive traffic volume.",
      learningObjective: "Understand denial-of-service through resource exhaustion and threshold overload.",
      instructions: [
        "Google Server has a simulated processing capacity of 20 packets per tick.",
        "Use the Traffic Generator control on Student PC.",
        "Increase the packet generation rate and burst count.",
        "Send traffic until the server load exceeds 20 packets and transitions to OVERLOADED state."
      ],
      difficulty: "Beginner",
      objectiveType: ObjectiveType.generateTraffic,
      requiredActions: ["configure_traffic_rate", "overload_server"],
      successConditions: {"serverOverloaded": true, "thresholdExceeded": 20},
      hints: [
        "A server has finite CPU, memory, and bandwidth. When requests arrive faster than they can be serviced, queues overflow.",
        "Set packet count to 25 and send a burst towards Google Server."
      ],
      explanation: "A Denial of Service (DoS) attack overwhelms a target system with requests, rendering it incapable of responding to legitimate users. Servers have capacity limits after which packets are dropped.",
      status: ChallengeStatus.available,
      progress: {"trafficGenerated": 0, "serverCapacity": 20},
      initialDevices: [
        Device(id: "pc_student", type: "PC", name: "Student PC", owner: "Student (Traffic Gen)", x: 180, y: 220, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10"),
        Device(id: "srv_google", type: "ROUTER", name: "Google Server (Cap: 20)", owner: "Target Host", x: 540, y: 220, ipAddress: "8.8.8.8", macAddress: "GG:GG:GG:00:00:08"),
      ],
      initialConnections: [
        Connection(id: "c_stud_srv", sourceDeviceId: "pc_student", destinationDeviceId: "srv_google", status: "active", cableType: "crossover"),
      ],
    ),

    // 8. Distributed DoS
    Challenge(
      id: "ch08",
      number: 8,
      title: "Distributed DoS (DDoS)",
      category: ChallengeCategory.denialOfService,
      description: "Simulate how multiple compromised hosts (botnet) collectively generate traffic to overwhelm a central target.",
      learningObjective: "Analyze distributed traffic aggregation from multiple sources toward a single target.",
      instructions: [
        "Notice the four endpoints: Alice PC, Bob PC, Carol PC, and Dave PC.",
        "Generate traffic from each endpoint individually towards Google Server.",
        "Watch the traffic meter aggregate packets: Alice (8) + Bob (7) + Carol (9) = 24.",
        "Exceed the Google Server capacity of 20 packets to trigger OVERLOADED status."
      ],
      difficulty: "Intermediate",
      objectiveType: ObjectiveType.generateTraffic,
      requiredActions: ["trigger_distributed_traffic", "exceed_aggregate_capacity"],
      successConditions: {"aggregateTraffic": 20, "serverOverloaded": true},
      hints: [
        "One PC generating 6 packets won't overload the server alone. Aggregate traffic from all 4 PCs!",
        "Generate traffic from Alice, Bob, and Carol in succession to push the combined counter over 20."
      ],
      explanation: "A Distributed Denial of Service (DDoS) leverages multiple distributed sources simultaneously. Because the traffic originates from many different IP addresses, filtering or mitigating it is significantly harder than a single-source DoS.",
      status: ChallengeStatus.available,
      progress: {"totalTraffic": 0, "serverCapacity": 20},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice PC", owner: "Node 1", x: 140, y: 80, ipAddress: "192.168.1.11", macAddress: "AA:AA:AA:00:00:11"),
        Device(id: "pc_bob", type: "PC", name: "Bob PC", owner: "Node 2", x: 140, y: 180, ipAddress: "192.168.1.12", macAddress: "BB:BB:BB:00:00:12"),
        Device(id: "pc_carol", type: "PC", name: "Carol PC", owner: "Node 3", x: 140, y: 280, ipAddress: "192.168.1.13", macAddress: "CC:CC:CC:00:00:13"),
        Device(id: "pc_dave", type: "PC", name: "Dave PC", owner: "Node 4", x: 140, y: 380, ipAddress: "192.168.1.14", macAddress: "DD:DD:DD:00:00:14"),
        Device(id: "switch1", type: "SWITCH", name: "Core Switch", owner: "IT Infrastructure", x: 380, y: 230, ipAddress: "192.168.1.50", macAddress: "SW:SW:SW:00:00:01"),
        Device(id: "srv_google", type: "ROUTER", name: "Google Server (Cap: 20)", owner: "Target Host", x: 620, y: 230, ipAddress: "8.8.8.8", macAddress: "GG:GG:GG:00:00:08"),
      ],
      initialConnections: [
        Connection(id: "c_al_sw", sourceDeviceId: "pc_alice", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_bob_sw", sourceDeviceId: "pc_bob", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_car_sw", sourceDeviceId: "pc_carol", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_dav_sw", sourceDeviceId: "pc_dave", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_sw_srv", sourceDeviceId: "switch1", destinationDeviceId: "srv_google", status: "active", cableType: "straight_through"),
      ],
    ),

    // 9. Smurf Attack
    Challenge(
      id: "ch09",
      number: 9,
      title: "Smurf Attack (Broadcast Amplification)",
      category: ChallengeCategory.denialOfService,
      description: "Explore how sending ICMP requests to a network broadcast address with a spoofed source amplifies return traffic.",
      learningObjective: "Understand broadcast replication, reflection attacks, and traffic amplification factors.",
      instructions: [
        "Attacker crafts an ICMP Echo Request with Destination = BROADCAST (255.255.255.255).",
        "Spoof the Source IP to match Google Server (8.8.8.8).",
        "Send the packet into the local subnet switch.",
        "Observe the single packet replicate across all 4 subnet PCs.",
        "Each PC replies to the spoofed source (Google Server), causing amplified bombardment."
      ],
      difficulty: "Advanced",
      objectiveType: ObjectiveType.generateTraffic,
      requiredActions: ["craft_broadcast_packet", "spoof_victim_ip", "trigger_amplification"],
      successConditions: {"amplificationTriggered": true, "repliesGenerated": 4},
      hints: [
        "Set destination to BROADCAST. The switch replicates the packet to every connected node.",
        "Because the sender was spoofed as Google's IP, all 4 PCs send their echo replies straight to Google!"
      ],
      explanation: "A Smurf attack is an amplification and reflection attack. The attacker sends ICMP requests to a broadcast address with the victim's IP as the spoofed source. Every host on the subnet responds to the victim, multiplying the attacker's traffic volume.",
      status: ChallengeStatus.available,
      progress: {"broadcastSent": false},
      initialDevices: [
        Device(id: "pc_attacker", type: "PC", name: "Attacker", owner: "Attacker Station", x: 140, y: 220, ipAddress: "192.168.1.99", macAddress: "99:99:99:00:00:99"),
        Device(id: "switch1", type: "SWITCH", name: "Broadcast Switch", owner: "Subnet Switch", x: 360, y: 220, ipAddress: "192.168.1.50", macAddress: "SW:SW:SW:00:00:01"),
        Device(id: "pc_node1", type: "PC", name: "Subnet PC 1", owner: "Subnet PC 1", x: 540, y: 80, ipAddress: "192.168.1.11", macAddress: "11:11:11:00:00:11"),
        Device(id: "pc_node2", type: "PC", name: "Subnet PC 2", owner: "Subnet PC 2", x: 540, y: 170, ipAddress: "192.168.1.12", macAddress: "12:12:12:00:00:12"),
        Device(id: "pc_node3", type: "PC", name: "Subnet PC 3", owner: "Subnet PC 3", x: 540, y: 270, ipAddress: "192.168.1.13", macAddress: "13:13:13:00:00:13"),
        Device(id: "pc_node4", type: "PC", name: "Subnet PC 4", owner: "Subnet PC 4", x: 540, y: 360, ipAddress: "192.168.1.14", macAddress: "14:14:14:00:00:14"),
        Device(id: "srv_google", type: "ROUTER", name: "Victim (Google)", owner: "Victim Server", x: 720, y: 220, ipAddress: "8.8.8.8", macAddress: "GG:GG:GG:00:00:08"),
      ],
      initialConnections: [
        Connection(id: "c_att_sw", sourceDeviceId: "pc_attacker", destinationDeviceId: "switch1", status: "active", cableType: "straight_through"),
        Connection(id: "c_sw_n1", sourceDeviceId: "switch1", destinationDeviceId: "pc_node1", status: "active", cableType: "straight_through"),
        Connection(id: "c_sw_n2", sourceDeviceId: "switch1", destinationDeviceId: "pc_node2", status: "active", cableType: "straight_through"),
        Connection(id: "c_sw_n3", sourceDeviceId: "switch1", destinationDeviceId: "pc_node3", status: "active", cableType: "straight_through"),
        Connection(id: "c_sw_n4", sourceDeviceId: "switch1", destinationDeviceId: "pc_node4", status: "active", cableType: "straight_through"),
        Connection(id: "c_sw_vic", sourceDeviceId: "switch1", destinationDeviceId: "srv_google", status: "active", cableType: "straight_through"),
      ],
    ),

    // 10. MITM
    Challenge(
      id: "ch10",
      number: 10,
      title: "Man-in-the-Middle (MITM)",
      category: ChallengeCategory.security,
      description: "Witness how an adversary on the physical or logical path can intercept, read, and tamper with unencrypted communications.",
      learningObjective: "Understand packet interception, eavesdropping, payload tampering, and how encryption prevents inspection.",
      instructions: [
        "Send an unencrypted message from Alice to Bob along the path containing Eve.",
        "Inspect the packet at Eve: observe that Eve can read the plaintext payload 'Hello Bob!'.",
        "Simulate message tampering: alter the payload to 'Transfer \$500 to Eve'.",
        "Toggle simulated encryption on Alice and observe that Eve can now only see unreadable ciphertext."
      ],
      difficulty: "Advanced",
      objectiveType: ObjectiveType.detectInterception,
      requiredActions: ["intercept_plaintext", "tamper_message", "verify_encryption"],
      successConditions: {"intercepted": true, "tamperedOrEncrypted": true},
      hints: [
        "Without encryption (HTTPS/TLS), any router or rogue node in the transmission path can read packet payloads.",
        "Enable encryption on Alice's packet to protect the confidentiality and integrity of the payload."
      ],
      explanation: "A Man-in-the-Middle (MITM) occurs when an attacker secretly relays and possibly alters communications between two parties. End-to-end encryption (such as TLS/HTTPS) renders intercepted data unreadable and tamper-evident.",
      status: ChallengeStatus.available,
      progress: {"interceptionObserved": false},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice", owner: "Alice", x: 160, y: 220, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10"),
        Device(id: "dev_eve", type: "ROUTER", name: "Eve (Interception Node)", owner: "Adversary Device", x: 380, y: 220, ipAddress: "192.168.1.99", macAddress: "EE:EE:EE:00:00:99"),
        Device(id: "pc_bob", type: "PC", name: "Bob", owner: "Bob", x: 600, y: 220, ipAddress: "192.168.1.20", macAddress: "BB:BB:BB:00:00:20"),
      ],
      initialConnections: [
        Connection(id: "c_al_eve", sourceDeviceId: "pc_alice", destinationDeviceId: "dev_eve", status: "active", cableType: "crossover"),
        Connection(id: "c_eve_bob", sourceDeviceId: "dev_eve", destinationDeviceId: "pc_bob", status: "active", cableType: "crossover"),
      ],
    ),

    // 11. Censorship
    Challenge(
      id: "ch11",
      number: 11,
      title: "Censorship & Proxy Bypass",
      category: ChallengeCategory.privacy,
      description: "Learn how firewalls filter traffic by destination address and how proxy routing traverses inspection barriers.",
      learningObjective: "Understand firewall destination rule enforcement and proxy tunneling.",
      instructions: [
        "Attempt to send a packet directly from Alice to the Blocked Site (198.51.100.99).",
        "Observe the Firewall drop the packet with reason: 'BLOCKED BY FIREWALL RULE'.",
        "Reroute Alice's packet to the Proxy Server (192.168.1.80).",
        "The Firewall permits Alice → Proxy traffic because the Proxy is an allowed destination.",
        "Watch the Proxy forward the request to the Blocked Site and relay the response back."
      ],
      difficulty: "Intermediate",
      objectiveType: ObjectiveType.useProxy,
      requiredActions: ["test_firewall_block", "route_via_proxy"],
      successConditions: {"firewallBlockObserved": true, "proxyDelivered": true},
      hints: [
        "Direct connection to 198.51.100.99 is inspected and dropped by the firewall.",
        "Set destination to Proxy Server (192.168.1.80) with inner target 198.51.100.99 to tunnel through."
      ],
      explanation: "Network firewalls inspect packet headers against configured rules, dropping traffic destined for blocked IP addresses or domains. A Proxy server acts as an intermediary: the firewall only sees connections to the proxy IP, allowing users to bypass localized filtering.",
      status: ChallengeStatus.available,
      progress: {"blockedAttempted": false},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice", owner: "Alice", x: 140, y: 220, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10"),
        Device(id: "proxy_srv", type: "ROUTER", name: "Proxy Server", owner: "Anonymizing Proxy", x: 360, y: 100, ipAddress: "192.168.1.80", macAddress: "PR:PR:PR:00:00:80"),
        Device(id: "fw_censor", type: "ROUTER", name: "Firewall / Censor", owner: "Border Inspection", x: 360, y: 260, ipAddress: "192.168.1.1", macAddress: "FW:FW:FW:00:00:01"),
        Device(id: "site_allowed", type: "ROUTER", name: "Allowed Site", owner: "Approved Host", x: 600, y: 180, ipAddress: "198.51.100.10", macAddress: "OK:OK:OK:00:00:10"),
        Device(id: "site_blocked", type: "ROUTER", name: "Blocked Site", owner: "Restricted Host", x: 600, y: 340, ipAddress: "198.51.100.99", macAddress: "NO:NO:NO:00:00:99"),
      ],
      initialConnections: [
        Connection(id: "c_al_proxy", sourceDeviceId: "pc_alice", destinationDeviceId: "proxy_srv", status: "active", cableType: "crossover"),
        Connection(id: "c_al_fw", sourceDeviceId: "pc_alice", destinationDeviceId: "fw_censor", status: "active", cableType: "crossover"),
        Connection(id: "c_fw_allowed", sourceDeviceId: "fw_censor", destinationDeviceId: "site_allowed", status: "active", cableType: "crossover"),
        Connection(id: "c_fw_blocked", sourceDeviceId: "fw_censor", destinationDeviceId: "site_blocked", status: "active", cableType: "crossover"),
        Connection(id: "c_proxy_blocked", sourceDeviceId: "proxy_srv", destinationDeviceId: "site_blocked", status: "active", cableType: "crossover"),
      ],
    ),

    // 12. Traceroute
    Challenge(
      id: "ch12",
      number: 12,
      title: "Traceroute & TTL Discovery",
      category: ChallengeCategory.diagnostics,
      description: "Map every intermediate router between Alice and Google Server using Time-To-Live (TTL) expiration.",
      learningObjective: "Understand IPv4 TTL decrementing, ICMP Time Exceeded (Type 11), and hop-by-hop route discovery.",
      instructions: [
        "Send a packet with TTL = 1. Router 1 decrements TTL to 0 and returns an ICMP Time Exceeded response (Router 1 discovered!).",
        "Increase TTL to 2: packet reaches Router 2 before expiring (Router 2 discovered!).",
        "Increase TTL to 3: packet reaches Router 3 before expiring (Router 3 discovered!).",
        "Increase TTL to 4: packet reaches Router 4 before expiring (Router 4 discovered!).",
        "Increase TTL to 5: packet reaches the final destination Google Server!",
        "Discover all 4 intermediate routers to complete the challenge."
      ],
      difficulty: "Advanced",
      objectiveType: ObjectiveType.discoverRouter,
      requiredActions: ["send_ttl_probes", "discover_all_hops"],
      successConditions: {"discoveredRouters": 4, "destinationReached": true},
      hints: [
        "Every router decrements the packet's TTL field by 1. When TTL hits 0, the router drops the packet and sends an ICMP Type 11 message back to the sender.",
        "Increment TTL one step at a time (1, 2, 3, 4, 5) to progressively discover each hop."
      ],
      explanation: "Traceroute utilizes the TTL (Time-To-Live) field of IP packets. By sending successive packets with incrementing TTL values starting at 1, each router in the path is forced to identify itself via an ICMP Time Exceeded reply.",
      status: ChallengeStatus.available,
      progress: {"discoveredHops": [], "currentTTL": 1, "targetHops": 4},
      initialDevices: [
        Device(id: "pc_alice", type: "PC", name: "Alice PC", owner: "Alice", x: 80, y: 220, ipAddress: "192.168.1.10", macAddress: "AA:AA:AA:00:00:10", defaultGateway: "10.1.1.1"),
        Device(id: "r1", type: "ROUTER", name: "Router 1", owner: "ISP Gateway", x: 230, y: 220, ipAddress: "10.1.1.1", macAddress: "R1:R1:R1:00:00:01"),
        Device(id: "r2", type: "ROUTER", name: "Router 2", owner: "Transit Provider", x: 380, y: 220, ipAddress: "10.2.2.1", macAddress: "R2:R2:R2:00:00:01"),
        Device(id: "r3", type: "ROUTER", name: "Router 3", owner: "Regional Hub", x: 530, y: 220, ipAddress: "10.3.3.1", macAddress: "R3:R3:R3:00:00:01"),
        Device(id: "r4", type: "ROUTER", name: "Router 4", owner: "Edge Provider", x: 680, y: 220, ipAddress: "10.4.4.1", macAddress: "R4:R4:R4:00:00:01"),
        Device(id: "srv_google", type: "ROUTER", name: "Google Server", owner: "Target Host", x: 830, y: 220, ipAddress: "8.8.8.8", macAddress: "GG:GG:GG:00:00:08"),
      ],
      initialConnections: [
        Connection(id: "c_al_r1", sourceDeviceId: "pc_alice", destinationDeviceId: "r1", status: "active", cableType: "crossover"),
        Connection(id: "c_r1_r2", sourceDeviceId: "r1", destinationDeviceId: "r2", status: "active", cableType: "crossover"),
        Connection(id: "c_r2_r3", sourceDeviceId: "r2", destinationDeviceId: "r3", status: "active", cableType: "crossover"),
        Connection(id: "c_r3_r4", sourceDeviceId: "r3", destinationDeviceId: "r4", status: "active", cableType: "crossover"),
        Connection(id: "c_r4_gg", sourceDeviceId: "r4", destinationDeviceId: "srv_google", status: "active", cableType: "crossover"),
      ],
    ),
  ];
}
