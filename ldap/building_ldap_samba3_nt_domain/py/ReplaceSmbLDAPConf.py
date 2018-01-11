#!/usr/bin/python3

import sys, os
import getopt
import re

class ReplaceSmbLDAPConf:
    file_name       = None
    options         = {}

    def __init__(self):
        try:
            opts, args = getopt.getopt(sys.argv[1:], "ho:k:v:f:",
                ["help", "opperation=", "key=", "value=", "file="])
        except getopt.GetoptError as e:
            self.usage()
            print(e)
            sys.exit(2)

        for o, a in opts:
            if o in ("-h", "--help"):
                self.usage()
                sys.exit()
            elif o in ("-o", "--operation"):
                self.options["-o"] = a
            elif o in ("-k", "--key"):
                self.options["-k"] = a
            elif o in ("-v", "--value"):
                self.options["-v"] = a
            elif o in ("-f", "--file"):
                self.options["-f"] = a

    def execute(self):
        if "-f" in self.options and "-o" in self.options:
            if self.options["-o"] == "override-or-append":
                if not "-k" in self.options or not "-v" in self.options:
                    self.usage()
                    print("Options -k(--key) and -v(--value) are needed in override-or-append opperation.")
                    return 1

                self.override_or_comment(
                    self.options["-o"], self.options["-f"], self.options["-k"], self.options["-v"])

            elif self.options["-o"] == "comment-out":
                if not "-k" in self.options:
                    self.usage()
                    print("Options -k(--key) and -v(--value) are needed in override-or-append opperation.")
                    return 1

                self.override_or_comment(
                    self.options["-o"], self.options["-f"], self.options["-k"], None)

            else:
                self.usage()
                print("Unknown operation \"" + self.options["-o"] + "\"")
                return 1

        else:
            self.usage()
            print("Option -f(or --file) is needed this program.")
            sys.exit()


    def override_or_comment(self, operation, file_name, key, value):
        contents                = open(file_name).readlines()
        end_of_contents         = len(contents)
        reg_key                 = re.compile('^\s*' + key + '\s*=.*$')
        overriden_or_commented  = False

        for i in range(end_of_contents):
            if reg_key.search(contents[i]):
                # Found taget element
                tmp_key, tmp_value = contents[i].split('=', 1)
                if tmp_value.strip() == value:
                    print("Because of the element \"" + key + "=" + value +
                        "\" is already exists as same one at line " + str(i + 1) + ", override is skipped.")
                else:
                    if operation == "override-or-append":
                        print("Override the element from \"" + contents[i].strip()
                            + "\" to \"" + key + "=" + value + "\" at line " + str(i + 1))
                        contents[i] = key + "="  + value + "\n"

                    elif operation == "comment-out":
                        print("Element \"" + contents[i].strip() + "\" is commented.")
                        contents[i] = "#" + contents[i]

                overriden_or_commented = True
                break

        if not overriden_or_commented and operation == "override-or-append":
            if operation == "override-or-append":
                print("Appends an element \"" + key + "=" + value + "\" at line " + str(end_of_contents))
                insert_index = end_of_contents - 1
                if re.search('^\s*$', contents[insert_index]):
                    contents.insert(insert_index, key + "=" + value + "\n")
                else:
                    contents.append(key + "=" + value + "\n")
            elif operation == "comment-out":
                print("Element key \"" + key + "\" does not exist. Skipped.")

        with open(file_name, 'w') as f:
            f.writelines(contents)


    def usage(self):
        pass

if __name__ == "__main__":

    ReplaceSmbLDAPConf().execute()

