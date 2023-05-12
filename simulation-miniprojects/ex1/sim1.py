from Costumer import Costumer
from queue import Queue
import numpy as np

np.random.seed( 98474 )

TOTAL_SERVERS_A = 2
TOTAL_SERVERS_B = 1

def timing():
    global next_event_type, sim_time, time_last_event, active_costumers, actual_costumer, queue_type1_costumers, queue_type2_costumers, delay_time_in_queue1, delay_time_in_queue2

    min_time_next_event = 1e9
    next_event_type = ''

    for c in active_costumers:
        event_time = c.get_event_time()
        event_type = c.get_event_type()

        if event_time < min_time_next_event:
            min_time_next_event = event_time
            next_event_type = event_type 
            actual_costumer = c

            if event_type == "work": break

    # preference is given to a type 2 customer if one is present and if both a type A and the type B server are then idle. 
    if not queue_type2_costumers.empty() and (num_serverA_available > 0 and num_serverB_available > 0) and next_event_type != "work":
        c = queue_type2_costumers.queue[0]
        start_working_time = sim_time

        if start_working_time < min_time_next_event:
            min_time_next_event = start_working_time
            next_event_type = c.get_event_type() 
            actual_costumer = queue_type2_costumers.get()
            active_costumers.append( actual_costumer )

            # for statistics: calculate the waiting time of the costumer
            actual_costumer.calculate_waiting_time( sim_time )
            delay_time_in_queue2.append( actual_costumer.get_waiting_time() )

            actual_costumer.set_start_working_time(start_working_time)  # for statistics

    # otherwise, preference is given to a type 1 customer
    elif not queue_type1_costumers.empty() and (num_serverA_available > 0 or num_serverB_available > 0) and next_event_type != "work":
        c = queue_type1_costumers.queue[0]
        start_working_time = sim_time

        if start_working_time < min_time_next_event:
            min_time_next_event = start_working_time
            next_event_type = c.get_event_type() 
            actual_costumer = queue_type1_costumers.get()
            active_costumers.append( actual_costumer )

            # for statistics: calculate the waiting time of the costumer
            actual_costumer.calculate_waiting_time( sim_time )
            delay_time_in_queue1.append( actual_costumer.get_waiting_time() )

            actual_costumer.set_start_working_time(start_working_time)  # for statistics

    time_last_event = sim_time
    sim_time = min_time_next_event


def arrive():
    global num_serverA_available, num_serverB_available, queue_type1_costumers, queue_type2_costumers, actual_costumer, active_costumers, number_in_queue_type1, number_in_queue_type2
    log_msg = False
    
    # check if costumer needs to go to waiting queue: if no servers available
    if actual_costumer.get_type() == 1:
        if not (num_serverA_available > 0 or num_serverB_available > 0):    # no servers available, so waitigng queue
            log_msg = True
            queue_type1_costumers.put( actual_costumer )
            active_costumers.remove( actual_costumer )
            number_in_queue_type1 += 1  # for statistics

    elif actual_costumer.get_type() == 2: 
        if not (num_serverA_available > 0 and num_serverB_available > 0):   # no servers available, so waitigng queue
            log_msg = True
            queue_type2_costumers.put( actual_costumer )
            active_costumers.remove( actual_costumer )
            number_in_queue_type2 += 1  # for statistics
        
    actual_costumer.set_event_type("work")  # costumer ready to work, no mather if we stays on waiting queue or not

    active_costumers.append( Costumer( sim_time + np.random.exponential(1.0) ) )    # add new costumer arrival event
    print('[Costumer {} (id = {})] arrival event at {:.2f} | waiting_queue_1 = {} | waiting_queue_2 = {}'.format(actual_costumer.get_type(), actual_costumer.get_id(), sim_time, queue_type1_costumers.qsize(), queue_type2_costumers.qsize()))
    if log_msg: print(f"[Info] No servers available for that type of costumer!")


def work():
    global num_serverA_available, num_serverB_available, actual_costumer

    if actual_costumer.get_type() == 1:
        # a type 1 customer can be served by any server but will choose a type A server if one is available
        if num_serverA_available > 0:
            num_serverA_available -= 1
            actual_costumer.set_server_type('A')
            actual_costumer.set_event_time( sim_time + np.random.exponential(0.8) )
            actual_costumer.set_event_type('depart')

        elif num_serverB_available > 0:
            num_serverB_available -= 1
            actual_costumer.set_server_type('B')
            actual_costumer.set_event_time( sim_time + np.random.exponential(0.8) )
            actual_costumer.set_event_type('depart')

    elif actual_costumer.get_type() == 2:
        # a type 2 customer requires service from both a type A server and a type B server simultaneously
        num_serverA_available -= 1
        num_serverB_available -= 1
        actual_costumer.set_server_type('AB')
        actual_costumer.set_event_time( sim_time + np.random.uniform(0.5, 0.7) )
        actual_costumer.set_event_type('depart')

    print('[Costumer {} (id = {})] work event at {:.2f} | servers A = {} | servers B = {}'.format(actual_costumer.get_type(), actual_costumer.get_id(), sim_time, num_serverA_available, num_serverB_available))


def depart():
    global actual_costumer, active_costumers, num_serverA_available, num_serverB_available
    global time_serverA_spends_on_type1, time_serverA_spends_on_type2, time_serverB_spends_on_type1, time_serverB_spends_on_type2

    active_costumers.remove( actual_costumer )

    if actual_costumer.get_server_type() == 'A':
        num_serverA_available += 1
        time_serverA_spends_on_type1 += actual_costumer.get_working_time()  # for statistics
    
    elif actual_costumer.get_server_type() == 'B':
        num_serverB_available += 1
        time_serverB_spends_on_type1 += actual_costumer.get_working_time()  # for statistics

    elif actual_costumer.get_server_type() == 'AB':
        num_serverA_available += 1
        num_serverB_available += 1
        time_serverA_spends_on_type2 += actual_costumer.get_working_time()  # for statistics
        time_serverB_spends_on_type2 += actual_costumer.get_working_time()  # for statistics
    
    print('[Costumer {} (id = {})] departure event at {:.2f} | servers A = {} | servers B = {}'.format(actual_costumer.get_type(), actual_costumer.get_id(), sim_time, num_serverA_available, num_serverB_available))  
    

### main
# simulation clock in minutes
sim_time     = 0.0
max_sim_time = 1000.0

# state variables
num_serverA_available = TOTAL_SERVERS_A
num_serverB_available = TOTAL_SERVERS_B

queue_type1_costumers = Queue()
queue_type2_costumers = Queue()

active_costumers      = []          # costumers list that are actually working in a server

# statistics
delay_time_in_queue1  = []
delay_time_in_queue2  = []

total_costumers       = 0
number_in_queue_type1 = 0
number_in_queue_type2 = 0

time_serverA_spends_on_type1 = 0.0
time_serverA_spends_on_type2 = 0.0
time_serverB_spends_on_type1 = 0.0
time_serverB_spends_on_type2 = 0.0
    
# event 
next_event_type = ''
active_costumers.append( Costumer( sim_time + np.random.exponential(1.0) ))

print('initial event at {:.2f}'.format(sim_time))
while sim_time < max_sim_time:

    timing()

    if next_event_type == "arrive":
        arrive()

    elif next_event_type == "work":
        work()

    elif next_event_type == "depart":
        depart()

    if actual_costumer.get_id() > total_costumers:
        total_costumers = actual_costumer.get_id()

    # just for debug
    # if actual_costumer.get_id() == 10: break


avg_delay_in_queue1 = sum(delay_time_in_queue1) / len(delay_time_in_queue1) if delay_time_in_queue1 else 0.0
avg_delay_in_queue2 = sum(delay_time_in_queue2) / len(delay_time_in_queue2) if delay_time_in_queue2 else 0.0

avg_number_in_queue_type1 = number_in_queue_type1 / total_costumers
avg_number_in_queue_type2 = number_in_queue_type2 / total_costumers

print()
print("---------------/ statistics \\---------------")
print(' >> average delay in:\n\t # queue for type 1 costumer = {:.2f}\n\t # queue for type 2 costumer = {:.2f}'.format( avg_delay_in_queue1, avg_delay_in_queue2 ))
print('\n >> average number of costumers in queue:\n\t # type 1 costumer = {:.2f}\n\t # type 2 costumer = {:.2f}'.format( avg_number_in_queue_type1, avg_number_in_queue_type2 ))
print('\n >> time that servers A spend on:\n\t # type 1 costumer = {:.2f}\n\t # type 2 costumer = {:.2f}'.format( time_serverA_spends_on_type1, time_serverA_spends_on_type2 ))
print('\n >> time that server B spends on:\n\t # type 1 costumer = {:.2f}\n\t # type 2 costumer = {:.2f}'.format( time_serverB_spends_on_type1, time_serverB_spends_on_type2 ))
print("---------------------------------------------")