#!/usr/bin/python3
import sys, os
import getopt
import re

class ReplaceSmbConf:

    file_name   = None
    options     = {}

    def __init__(self):
        try:
            opts, args = getopt.getopt(sys.argv[1:], "hd:o:k:v:f:",
                ["help", "directive=", "opperation=", "key=", "value=", "file="])
        except getopt.GetoptError as e:
            self.usage()
            print(e)
            sys.exit(2)

        for o, a in opts:
            if o in ("-h", "--help"):
                self.usage()
                sys.exit()
            elif o in ("-d", "--directive"):
                self.options["-d"] = a
            elif o in ("-o", "--operation"):
                self.options["-o"] = a
            elif o in ("-k", "--key"):
                self.options["-k"] = a
            elif o in ("-v", "--value"):
                self.options["-v"] = a
            elif o in ("-f", "--file"):
                self.options["-f"] = a


    def execute(self):

        if "-d" in self.options and "-f" in self.options and "-o" in self.options:
            if self.options["-o"] == "override-or-append":
                if not "-k" in self.options or not "-v" in self.options:
                    self.usage()
                    print("Options -k(--key) and -v(--value) are needed in override-or-append opperation.")
                    return 1

                self.override(self.options["-f"]
                    , self.options["-d"], self.options["-k"], self.options["-v"])

            elif self.options["-o"] == "comment-out":
                if not "-k" in self.options:
                    usage()
                    print("Options -k(--key) and are needed in comment-out opperation.")
                    return 1

                self.comment(self.options["-f"]
                    , self.options["-d"], self.options["-k"])

            else:
                self.usage()
                print("Unknown operation \"" + self.options["-o"] + "\"")
                return 1

        else:
            self.usage()
            print("Options -d(or --directive) and -f(or --file) are needed this program.")
            sys.exit()


    def override(self, file_name, directive, key, value):
        contents            = open(file_name).readlines()
        end_of_contents     = len(contents)
        reg_directive       = re.compile('^\s*\[' + directive + '\]\s*$')
        reg_key             = re.compile('^\s*' + key + '\s*=.*$')
        reg_some_directive  = re.compile('^\s*\[.+\]\s*$')
        found_directive     = False
        overriden           = False
        appended            = False

        for i in range(end_of_contents):

            if reg_directive.search(contents[i]):
                # Found target directive
                found_directive = True

                for j in range(i + 1, end_of_contents):

                    if reg_key.search(contents[j]):
                        # Found target directive and element
                        tmp_key, tmp_value = contents[j].split('=', 1)
                        if tmp_value.strip() == value:
                            print("Because of the element \"" + key + " = " + value +
                                "\" is already exists as same one at line " + str(j + 1) + ", override is skipped.")
                        else:
                            print("Override the element from \"" + contents[j].strip()
                                + "\" to \"" + key + " = " + value + "\" at line " + str(j + 1))
                            contents[j] = "\t" + key + " = " + value + "\n"

                        overriden = True
                        break

                    elif reg_some_directive.search(contents[j]):
                        # If reached a some next directive, append an element as new one.
                        if re.search('^\s*$', contents[j - 1]):
                            insert_index = j - 1
                        else:
                            insert_index = j

                        contents.insert(insert_index, "\t" + key + " = " + value + "\n")
                        print("Appended \"" + key + " = " + value + "\" at line " + str(insert_index + 1))

                        appended = True
                        break

        if found_directive and (not overriden and not appended):
            # If target directive is found but reached end of file,
            # append the elements at last line
            print("Appends element \"" + key + " = " + value
                + "\" in the directive \"" + directive + "\" at line " + str(end_of_contents))
            insert_index = end_of_contents - 1
            if re.search('^\s*$', contents[insert_index]):
                contents.insert(insert_index, "\t" + key + " = " + value + "\n")
            else:
                contents.append("\t" + key + " = " + value + "\n")

        elif not found_directive:
            # If target directive is not found and reached end if file,
            # append the directive and the element at last line
            print("Appends directive \"" + directive + "\" and element \""
                + key + " = " + value + "\" at end of the file at line " + str(end_of_contents))
            contents.append("[" + directive + "]\n")
            contents.append("\t" + key + " = " + value + "\n")

        with open(file_name, 'w') as f:
            f.writelines(contents)


    def comment(self, file_name, directive, key):
        contents            = open(file_name).readlines()
        end_of_contents     = len(contents)
        reg_directive       = re.compile('^\s*\[' + directive + '\]\s*$')
        reg_key             = re.compile('^\s*' + key + '\s*=.*$')
        reg_some_directive  = re.compile('^\s*\[.+\]\s*$')
        commented           = False

        for i in range(end_of_contents):

            if reg_directive.search(contents[i]):
                for j in range(i + 1, end_of_contents):

                    if reg_key.search(contents[j]):
                        print("Element \"" + contents[j].strip()
                            + "\" in directive \"" + directive + "\" is commented.")
                        contents[j] = "#" + contents[j]
                        commented = True
                        break
                    elif reg_some_directive.search(contents[j]):
                        break

        if not commented:
            print("Element key \"" + key + "\" in directive \"" + directive + "\" does not exist. Skipped.")

        with open(file_name, 'w') as f:
            f.writelines(contents)


    def usage(self):
        print("Usage:")
        print("To override or appending an element")
        print("  " + os.path.basename(sys.argv[0]) +
            " -f file_name -o override-or-append -d directive -k key -v value")
        print("To comment out an element")
        print("  " + os.path.basename(sys.argv[0]) +
            " -f file_name -d directive -o comment-out -k key")
        print("")


if __name__ == "__main__":
    ReplaceSmbConf().execute()

