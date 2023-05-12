import numpy as np

class Costumer:
    identifier = 0
    type1_probability = 0.8

    def __init__(self, arrival_time) -> None:
        # initializate costumer variables
        self.id = Costumer.identifier

        # upon arrival, a customer is determined to be either a type 1 customer or a type 2 customer
        self.type         = 1 if np.random.rand() < Costumer.type1_probability else 2
        self.time         = arrival_time
        self.event_type   = "arrive"
        self.server_type  = None
        self.arrival_time = arrival_time

        self.waiting_time       = 0.0
        self.start_working_time = arrival_time      # the start working time could not be the arrival time !!!
        self.end_working_time   = 0.0

        Costumer.identifier += 1

    def get_id(self):
        return self.id
    
    def get_type(self):
        return self.type

    def get_event_time(self):
        return self.time
    
    def set_event_time(self, departure_time):
        self.time = departure_time

    def get_event_type(self):
        return self.event_type
    
    def set_event_type(self, event):
        self.event_type = event
    
    def get_server_type(self):
        return self.server_type
    
    def set_server_type(self, server):
        self.server_type = server

    def get_waiting_time(self):
        return self.waiting_time
    
    def calculate_waiting_time(self, time):
        self.waiting_time = time - self.arrival_time

    def get_working_time(self):
        return self.time - self.start_working_time
    
    def set_start_working_time(self, time):
        self.start_working_time = time
    
    def __str__(self) -> str:
        return f"type {self.type} costumer, event = {self.event_type}, event time = {self.time}"