import os
import argparse
import re
import json
from datetime import datetime

class Benchmark:
    def __init__(self):
        self.data = {}

    def fetch(self,key):
        if key in self.data:
            return self.data[key]
        else:
            return None

    def get_title(self,key):
        if self.data[key]["host"].title.lower() != "unknown":
            return self.data[key]["host"].title.lower()
        else:
            return "benchmark-"+key

    def init_check(self,key):
        if key not in self.data:
            self.data[key] = {"host": None, "stats": None}

    def add_host(self,key,host):
        self.init_check(key)
        self.title = host.title
        self.data[key]["host"] = host

    def add_stats(self,key,stats):
        self.init_check(key)
        self.data[key]["stats"] = stats

    def keys(self):
        return self.data.keys()

    def remove(self,key):
        del self.data[key]

    def csv_header(self):
        # get first key
        key = next(iter(self.data.keys()))
        return f"{self.data[key]["stats"][0].csv_header()},{self.data[key]["host"].csv_header()}\n"

    def csv(self,key,no_header=False):
        contents = ""
        # ok to print header?
        if not no_header:
            contents = self.csv_header()

        host_data = self.data[key]["host"].csv()

        for stats in self.data[key]["stats"]:
            contents = f"{contents}{stats.csv()},{host_data}\n"
        return contents

    def json(self, key,is_array=False):
        host_padding = 1
        stats_padding = 2
        contents = '{\n'
        closing = '}\n'
        if is_array:
            host_padding = 2
            stats_padding = 3
            contents = '    {\n'
            closing = '    },\n'
        # host data indent level one
        contents += self.data[key]["host"].json(host_padding)
        # build up stats as array
        if is_array:
            contents += '        [\n'
        else:
            contents += '    [\n'
        for stat_data in self.data[key]["stats"]:
            contents += stat_data.json(stats_padding)
        if is_array:
            contents += '        ],\n'
        else:
            contents += '    ],\n'

        # close
        contents += closing
        return contents

class Host():
    def __init__(self, title, misc, date, total_ram, total_swap, huge_pages, os_info, processor_model, number_cores, nodeos_version, config_file):
        self.title = title
        self.misc = misc
        self.date = date
        self.total_ram = total_ram
        self.total_swap = total_swap
        self.huge_pages = huge_pages
        self.os_info = os_info
        self.processor_model = processor_model
        self.number_cores = number_cores
        self.nodeos_version = nodeos_version
        self.config_file = config_file

    def __str__(self):
        return (f"Title: {self.title}\nMisc: {self.misc}\n"
                f"Total RAM: {self.total_ram}\nTotal Swap: {self.total_swap}\n"
                f"Huge Pages: {self.huge_pages}\nOS Info: {self.os_info}\n"
                f"Processor Model: {self.processor_model}\nNumber of Cores: {self.number_cores}\n"
                f"NodeOS Version: {self.nodeos_version}\nConfig File: {self.config_file}\n")

    @staticmethod
    def csv_header():
        return ("Title,Misc,Total_RAM,Total_Swap,Huge_Pages,OS_Info,"
            "Processor_Model,Number_Cores,Nodeos_Version,Config_File")

    def csv(self):
        return (f'"{self.title}","{self.misc}",'
        f'{self.total_ram},{self.total_swap},'
        f'{self.huge_pages},"{self.os_info}",'
        f'"{self.processor_model}",{self.number_cores},'
        f'{self.nodeos_version},{self.config_file}')

    def json(self, indent=0):
        indent=indent*4 # 4 spaces for each indent
        padding= ' ' * indent
        trailing_comma = ''
        if indent > 0:
            trailing_comma = ','

        return(f'{padding}{{\n'
        f'    {padding}title:"{self.title}",\n'
        f'    {padding}misc:"{self.misc}",\n'
        f'    {padding}total_ram:"{self.total_ram}",\n'
        f'    {padding}total_swap:"{self.total_swap}",\n'
        f'    {padding}huge_pages:"{self.huge_pages}",\n'
        f'    {padding}os_info:"{self.os_info}",\n'
        f'    {padding}processor_model:"{self.processor_model}",\n'
        f'    {padding}number_cores:{self.number_cores},\n'
        f'    {padding}nodeos_version:"{self.nodeos_version}",\n'
        f'    {padding}config_file:"{self.config_file}"\n'
        f'{padding}}}{trailing_comma}\n'
        )

class Stats():
    time_format = "%Y-%m-%dT%H:%M:%SZ"
    def __init__(self, start_date, date, stage, r, b, swpd, free, buff, cache, si, so, bi, bo, in_, cs, us, sy, id_, wa, st, head_block_num, db_rows):

        if "T" in date:
            [self.date,self.time]  = date.split("T")   # Date/Time when the stats were collected
        else:
            self.date = date
            self.time = "Unknown"

        self.elasped_secs = 0
        if start_date:
            dt1 = datetime.strptime(start_date, Stats.time_format)
            dt2 = datetime.strptime(date, Stats.time_format)
            # Calculate the difference in seconds
            self.elasped_secs = (dt2 - dt1).total_seconds()

        self.stage = stage          # Stage (can be a label like "stage1", "stage2", etc.)

        # Procs
        self.r = r                  # Number of processes running
        self.b = b                  # Number of processes blocked

        # Memory
        self.swpd = swpd            # Amount of swapped memory (KB)
        self.free = free            # Amount of free memory (KB)
        self.buff = buff            # Amount of memory used as buffers (KB)
        self.cache = cache          # Amount of memory used as cache (KB)

        # Swap
        self.si = si                # Amount of memory swapped in from disk (KB/s)
        self.so = so                # Amount of memory swapped out to disk (KB/s)

        # IO
        self.bi = bi                # Blocks received from a block device (blocks/s)
        self.bo = bo                # Blocks sent to a block device (blocks/s)

        # System
        self.in_ = in_              # Number of interrupts per second
        self.cs = cs                # Number of context switches per second

        # CPU
        self.us = us                # CPU time spent on user processes (%)
        self.sy = sy                # CPU time spent on system processes (%)
        self.id_ = id_              # CPU idle time (%)
        self.wa = wa                # CPU time spent waiting for IO (%)
        self.st = st                # CPU time stolen by hypervisor (%)

        # Nodeos Info
        self.head_block_num = head_block_num    # head block for chain
        self.db_rows = db_rows                  # db rows in chainbase

    def __str__(self):
        return (f"Date: {self.date}, Time: {self.time}, Elasped_Sec: {self.elasped_secs}, Stage: {self.stage}\n"
                f"Procs - r: {self.r}, b: {self.b}\n"
                f"Memory - swpd: {self.swpd}, free: {self.free}, buff: {self.buff}, cache: {self.cache}\n"
                f"Swap - si: {self.si}, so: {self.so}\n"
                f"IO - bi: {self.bi}, bo: {self.bo}\n"
                f"System - in: {self.in_}, cs: {self.cs}\n"
                f"CPU - us: {self.us}, sy: {self.sy}, id: {self.id_}, wa: {self.wa}, st: {self.st}\n"
                f"Nodeos - block: {self.head_block_num}, dbrows: {self.db_rows}\n")

    @staticmethod
    def csv_header():
        headerInitial = "Date,Time,Elasped_Sec,Stage,"
        headerProcs = "ProcsRunning,ProcsBlocked,"
        headerMemory = "Swapped(Kb),Free(Kb),Buffer(Kb),Cache(Kb),"
        headerSwap = "SwapIn(Kb/sec),SwapOut(Kb/sec),"
        headerIO = "BlocksIn(blocks/sec),BlocksOut(blocks/sec),"
        headerSys = "Interrupts,ContextSwitch,"
        headerCPU = "CPU_User_Percent,CPU_Sys_Percent,CPU_Idle_Percent,CPU_WaitIO_Percent,CPU_Stolen_Percent,"
        nodeos_info = "Head_Block,DB_Rows"
        return headerInitial+headerProcs+headerMemory+headerSwap+headerIO+headerSys+headerCPU

    def csv(self):
        return (f"{self.date},{self.time},{self.elasped_secs},{self.stage},"
                f"{self.r},{self.b}"
                f"{self.swpd},{self.free},{self.buff},{self.cache},"
                f"{self.si},{self.so},"
                f"{self.bi},{self.bo},"
                f"{self.in_},{self.cs},"
                f"{self.us},{self.sy},{self.id_},{self.wa},{self.st},"
                f"{self.head_block_num},{self.db_rows}")

    def json(self, indent=0):
        indent=indent*4 # 4 spaces for each indent
        padding= ' ' * indent
        trailing_comma = ''
        if indent > 0:
            trailing_comma = ','

        return(f'{padding}{{\n'
        f'    {padding}date:{self.date},\n'
        f'    {padding}time:{self.time},\n'
        f'    {padding}elasped_secs:{self.elasped_secs},\n'
        f'    {padding}stage:{self.stage},\n'
        f'    {padding}procs_running:{self.r},\n'
        f'    {padding}procs_blocked:{self.b},\n'
        f'    {padding}swapped_kb:{self.swpd},\n'
        f'    {padding}free_kb:{self.free},\n'
        f'    {padding}buffer_kb:{self.buff},\n'
        f'    {padding}cache_kb:{self.cache},\n'
        f'    {padding}swapin:{self.si},\n'
        f'    {padding}swapout:{self.so},\n'
        f'    {padding}blocks_in:{self.bi},\n'
        f'    {padding}blocks_out:{self.bo},\n'
        f'    {padding}interrupts:{self.in_},\n'
        f'    {padding}context_switch:{self.cs},\n'
        f'    {padding}cpu_user_percent:{self.us},\n'
        f'    {padding}cpu_sys_percent:{self.sy},\n'
        f'    {padding}cpu_idle_percent:{self.id_},\n'
        f'    {padding}cpu_waitio_percent:{self.wa},\n'
        f'    {padding}cpu_stolen_percent:{self.st}\n'
        f'    {padding}head_block_num:{self.head_block_num},\n'
        f'    {padding}db_rows:{self.db_rows}\n'
        f'{padding}}}{trailing_comma}\n'
        )



def parse_host_file(file_content):
    # A basic pattern-based parsing logic (modify as needed for actual file formats)
    title = re.search(r"^>>\s*(.*)", file_content)
    date = re.search(r"Date:\s*(.*)", file_content)
    total_ram = re.search(r"Total [Rr][Aa][Mm]:\s*(.*)", file_content)
    total_swap = re.search(r"Total Swap:\s*(.*)", file_content)
    huge_pages = re.search(r"Number of 1Gb Pages:\s*(.*)", file_content)
    os_info = re.search(r"OS Info:\s*(.*)", file_content)
    processor_model = re.search(r"Processor Model:\s*(.*)", file_content)
    number_cores = re.search(r"Num Processor:\s*(.*)", file_content)
    nodeos_version = re.search(r"Nodeos Version:\s*(.*)", file_content)
    config_file = re.search(r"Config File:\s*(.*)", file_content)

    # Multi-line regex for misc (extract everything between the first and last MISC:)
    misc_match = re.search(r"MISC:\s*\n(.*?)\nMISC:", file_content, re.DOTALL)
    misc = misc_match.group(1).strip() if misc_match else "Unknown"

    return Host(
        title.group(1) if title else "Unknown",
        misc,
        date.group(1) if date else "Unknown",
        total_ram.group(1) if total_ram else "Unknown",
        total_swap.group(1) if total_swap else "Unknown",
        huge_pages.group(1) if huge_pages else "Unknown",
        os_info.group(1) if os_info else "Unknown",
        processor_model.group(1).replace(':','') if processor_model else "Unknown",
        number_cores.group(1) if number_cores else "Unknown",
        nodeos_version.group(1) if nodeos_version else "Unknown",
        config_file.group(1) if config_file else "Unknown"
    )

def parse_stats_file(file_contents):
    all_lines = file_contents.split("\n")
    title_pattern = re.compile(r"^>>\s*(.*)")
    earliest_line = True

    stats = []   # array of stats objects
    start_date=None
    for line in all_lines:
        if title_pattern.match(line):
            continue     # skip line
        else:
            data = re.split(r'\s+', line)
            if len(data) >= 19:
                if earliest_line:
                    start_date = data[0]
                    earliest_line = False
                stat_obj = Stats(
                    start_date, # first timestamp calc incr time
                    data[0], # date
                    data[1], # stage
                    data[2], # procs r
                    data[3], # procs b
                    data[4], # swpd
                    data[5], # free
                    data[6], # buff
                    data[7], # cache
                    data[8], # swapd in
                    data[9], # swaped out
                    data[10], # blocks in
                    data[11], # blocks out
                    data[12], # interrupts
                    data[13], # contenxt switches
                    data[14], # cpu user
                    data[15], # cpu sys
                    data[16], # cpu idle
                    data[17], # cpu wait io
                    data[18], # cpu st
                    data[19], # head block num
                    data[20]  # db rows
                )
                stats.append(stat_obj)
    return stats

def parse_txt_files(input_directory):
    # dictionary to return
    benchmark = Benchmark()

    # Regex pattern to match filenames like host_123.txt stat_123.txt
    is_host_file = re.compile(r"host[-_](\d+)\.txt")
    is_stats_file = re.compile(r"stats[_-](\d+)\.txt")

    # List all files in the input directory
    for file_name in os.listdir(input_directory):
        if file_name.endswith('.txt'):
            input_file_path = os.path.join(input_directory, file_name)

            # Open and read the file
            with open(input_file_path, 'r') as file:
                content = file.read()
                print(f"Parsing file: {file_name}")

            # match host file
            # extract file number
            # parse host file
            host_file_match = is_host_file.match(file_name)
            if host_file_match:
                file_number = host_file_match.group(1)
                host = parse_host_file(content)
                benchmark.add_host(file_number,host)
            # match stats file
            # extract file number
            # parse stats file
            stats_file_match = is_stats_file.match(file_name)
            if stats_file_match:
                file_number = stats_file_match.group(1)
                stats = parse_stats_file(content)
                benchmark.add_stats(file_number,stats)
    return benchmark

def write_files(benchmark, output_directory, format, single_file):
    # Check if output directory exists, if not, create it
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    # ouput to one file
    if single_file:
        if format.lower() == "json":
            file_name = f"{output_directory}/all.json"
            print (f"Writing File: {file_name}")
            with open(file_name, "w") as file:
                file.write('[\n')
                for key in benchmark.keys():
                    file.write(benchmark.json(key,True))
                file.write(']\n')
        else:
            file_name = f"{output_directory}/all.csv"
            print (f"Writing File: {file_name}")
            with open(file_name, "w") as file:
                file.write(benchmark.csv_header())
                for key in benchmark.keys():
                    file.write(benchmark.csv(key,True))
    else:
        for key in benchmark.keys():
            file_name = f"{output_directory}/{benchmark.get_title(key)}"
            if format.lower() == "json":
                file_name += ".json"
                print (f"Writing File: {file_name}")
                with open(file_name, "w") as file:
                    # Write the string to the file
                    file.write(benchmark.json(key))
            else:
                file_name += ".csv"
                print (f"Writing File: {file_name}")
                with open(file_name, "w") as file:
                    # Write the string to the file
                    file.write(benchmark.csv(key))

def main():
    parser = argparse.ArgumentParser(description="Parse stats from benchmarking")
    parser.add_argument('--input-directory', type=str, help='Path to the input directory')
    parser.add_argument('--output-directory', type=str, help='Path to the output directory')
    parser.add_argument('--format', type=str, default='CSV', help='CVS or JSON defaults to CSV')
    parser.add_argument('--output-single-file', action='store_true', help='creates single output file')

    args = parser.parse_args()

    data = parse_txt_files(args.input_directory)
    write_files(data, args.output_directory, args.format, args.output_single_file)

if __name__ == "__main__":
    main()
