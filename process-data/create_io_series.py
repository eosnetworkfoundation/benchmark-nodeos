import argparse
import os

def parse_txt_files(file_name):
    header = True
    data = {}
    with open(file_name, 'r') as file:
        # Iterate through each line in the file
        for line in file:
            # Remove trailing newline characters and any leading/trailing whitespace
            line = line.strip()
            if header:              # skip header
                header = False
                continue
            parts = line.split(',')
            # 0 Date
            # 1 Time
            # 2 Elasped_Sec
            # 3 Stage
            # 4 ProcsRunning
            # 5 ProcsBlocked
            # 6 Swapped(Kb)
            # 7 Free(Kb)
            # 8 Buffer(Kb)
            # 9 Cache(Kb)
            # 10 SwapIn(Kb/sec)
            # 11 SwapOut(Kb/sec)
            # 12 BlocksIn(blocks/sec)
            # 13 BlocksOut(blocks/sec)
            # 14 Interrupts
            # 15 ContextSwitch
            # 16 CPU_User_Percent
            # 17 CPU_Sys_Percent
            # 18 CPU_Idle_Percent
            # 19 CPU_WaitIO_Percent
            # 20 CPU_Stolen_Percent
            # 21 Head_Block
            # 22 DB_Rows
            # 23 Title
            # 24 Misc
            # 25 Total_RAM
            # 26 Total_Swap
            # 27 Huge_Pages
            # 28 OS_Info
            # 29 Processor_Model
            # 30 Number_Cores
            # 31 Nodeos_Version
            # 32 Config_File

            elapsed_sec = parts[2]
            elapsed_sec = elapsed_sec.split(".")[0]
            rounded_secs = round(int(elapsed_sec)/30)*30
            extracted_stats = {
                "stage": parts[3],
                "swapped": parts[6],
                "free": parts[7],
                "buffer": parts[8],
                "cache": parts[9],
                "swapin": parts[10],
                "swapout": parts[11],
                "blocksin": parts[12],
                "blocksout": parts[13],
                "title": parts[23]
            }

            for type in ["swapped", "free", "buffer", "cache", "swapin", "swapout", "blocksin", "blocksout"]:
                # initialize
                if type not in data:
                    data[type] = {}
                    data[type]['col'] = {}
                    data[type]['stats'] = {}
                else:
                    # build up list of unique columns
                    if extracted_stats['title'] not in data[type]['col']:
                        data[type]['col'][extracted_stats['title']] = 1
                    else:
                        data[type]['col'][extracted_stats['title']] += 1
                # add the main record
                if rounded_secs not in data[type]['stats']:
                    data[type]['stats'][rounded_secs] = []
                data[type]['stats'][rounded_secs].append({
                    'title': extracted_stats['title'],
                    'stat': extracted_stats[type],
                    'stage': extracted_stats['stage']
                })
    return data

def write_files(data, output_directory):
    # Check if output directory exists, if not, create it
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)
    for type in ["swapped", "free", "buffer", "cache", "swapin", "swapout", "blocksin", "blocksout"]:
        file_name = f"{output_directory}/{type}.csv"
        columns = data[type]['col'].keys()
        with open(file_name, "w") as file:
            # write header
            header = f"elapsed_sec,{','.join(columns)}\n"
            file.write(header)
            # iterating by type, now pull our the stats
            # first we pull out the time, elapsed_secs in ascending order
            for secs in sorted(data[type]['stats']):
                line = f"{secs}"
                stats = {}
                # the next level of the data structure is a array of stats
                # we pull those out and create a dictionary
                # mapping title -> stat value
                # example for type 'swapped' 'replay-gp2-mapped-state'-> 6000
                for record in data[type]['stats'][secs]:
                    stats[record['title']] = record['stat']
                # no guarentee of order, and there may be missing columns
                # we have our our unique list of columns we'll use
                for title in columns:
                    if title in stats:
                        line = f"{line},{stats[title]}"
                    else:
                        line = f"{line},"
                file.write(f"{line}\n")

def main():
    parser = argparse.ArgumentParser(description="Parse csv file and create series for free, swap-in, swap-out, blocks-in, blocks-out")
    parser.add_argument('--file', type=str, help='Path to the csv file ')
    parser.add_argument('--output-directory', type=str, help='Path to the output directory')

    args = parser.parse_args()

    data = parse_txt_files(args.file)
    write_files(data, args.output_directory)

if __name__ == "__main__":
    main()
