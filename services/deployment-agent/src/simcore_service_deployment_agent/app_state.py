from enum import IntEnum

class State(IntEnum):
    STARTING = 0
    RUNNING = 1
    FAILED = 2
    STOPPED = 3
    PAUSED = 4
