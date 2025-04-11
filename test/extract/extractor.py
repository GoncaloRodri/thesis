from stem.control import Controller

with Controller.from_port(port=9051) as controller:
    controller.authenticate("")  # Use appropriate auth method
    circuits = controller.get_circuits()
    for circuit in circuits:
        # if (circuit.purpose == "GENERAL"):
        print(f"Node: {circuit}")
