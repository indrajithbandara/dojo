#!/usr/bin/python3
import sys, os
import re

class AddHosts:
    ip          = None
    host        = None
    file_name   = None

    def __init__(self, ip, host, file_name):
        self.ip         = ip
        self.host       = host
        self.file_name  = file_name

    def execute(self):
        contents    = open(self.file_name).readlines()
        reg_split   = re.compile('\s+')
        found_ip    = False
        found_host  = False

        for i in range(len(contents)):
            lines = reg_split.split(contents[i].strip())
            if lines[0] == self.ip:
                found_ip = True
                for j in range(len(lines) - 1):
                    if lines[j] == self.host:
                        found_host = True
                        break

                if not found_host:
                    contents[i] = contents[i].strip() + " " + self.host + "\n"
                    print("Appending new host " + self.host + " to the end of " + self.ip)

                break

        if not found_ip and not found_host:
            contents.append(self.ip + "\t" + self.host + "\n")
            print("Appending new record \"" + self.ip + " " + self.host + "\"")

        if not found_ip or not found_host:
            with open(self.file_name, 'w') as f:
                f.writelines(contents)
        else:
            print("IP " + self.ip + " and host " + self.host + " are already existed in " + self.file_name)

        return


if __name__ == "__main__":
    AddHosts(sys.argv[1], sys.argv[2], sys.argv[3]).execute()

