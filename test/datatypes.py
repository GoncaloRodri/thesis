from typing import TypedDict

class RawCircuitData(TypedDict):
    id: str
    end_time: float
    num_packets: int
    dummy_count: int
    start_time: float
    deltas: list[float]
    timestamps: list[float]

class CircuitData(TypedDict):
    id: str
    avg_delta: float
    min_delta: float
    max_delta: float
    num_packets: int
    dummy_count: int
    dummy_ratio: float
    delta_variance: float
    delta_deviation: float
    total_elapsed_time: float
    deltas: list[float]
    timestamps: list[float]

class RelayData(TypedDict):
    name: str
    end_time: float
    dummy_count: int
    start_time: float
    dummy_ratio: float
    total_time_elapsed: float
    total_number_of_packets: int
    circuit_data: dict[str, CircuitData]
