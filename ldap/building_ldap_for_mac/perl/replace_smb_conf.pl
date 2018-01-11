#!/usr/bin/perl
#
# @param section
# @param key
# @param value
# @param file
#

use strict;
use warnings;

sub main($$$$) {
    my $r_section   = shift;
    my $r_key       = shift;
    my $r_value     = shift;
    my $r_file      = shift;

    my $found_section           = 0;
    my $replace_or_insert_count = 0;
    my $replaced_position       = 0;

    ## print "sectipon=\"", $$r_section, "\", key=\"", $$r_key
    ##         , "\", value=\"", $$r_value, "\", file=\"", $$r_file, "\"\n";   # TODO: debug

    $r_section = \("\\[" . $$r_section . "\\]");

    open(F_SMB_CONF, "< " . $$r_file);
    my @contents = <F_SMB_CONF>;
    close(F_SMB_CONF);


    # Read each lines in smb.conf
    for(my $i = 0; $i <= $#contents; $i++) {
        if ($contents[$i] =~ /^\s*$${r_section}\s*$/) {
            ## print "Section \"", $$r_section, "\" found at line "
            ##         , $i + 1, "\n" , "-> ", $contents[$i];               # TODO: debug
            $found_section = 1;
            next;
        }

        # In detected section
        if($found_section == 1) {
            if ($contents[$i] =~ /^\s*\[.*\]\s*$/) {
                # If target key was not found, insert new line
                while($contents[$i - 1] =~ /.*\n$/) {
                    chomp($contents[$i - 1]);
                }
                if($contents[$i - 1] =~ /^\s*$/) {
                    $contents[$i - 1] = "\t$${r_key} = $${r_value}\n\n";
                } else {
                    $contents[$i - 1] = "\n\t$${r_key} = $${r_value}\n\n";
                }

                $replace_or_insert_count++;
                $replaced_position = $i + 1;
                last;                           # finish replacement
            }

            if ($contents[$i] =~ /^\s*$${r_key}\s*=.*$/) {
                # Search key and replace it.

                $contents[$i] = "\t$${r_key} = $${r_value}\n";
                $replace_or_insert_count++;
                $replaced_position = $i + 1;
                last;                           # finish replacement
            }
        }
    }

    # Nothing to write when replace_count is 0.
    if($replace_or_insert_count == 0) {
        print "No lines were replaced.\n";
        return $replace_or_insert_count;
    }

    # Write contents to the original file
    open(F_SMB_CONF, "> " . $$r_file);
    for(my $i = 0; $i <= $#contents; $i++) {
        print F_SMB_CONF $contents[$i];
    }
    close(F_SMB_CONF);

    print "Replaced or inserted a line at ", $replaced_position, " in ", $$r_file, "\n";

    return $replace_or_insert_count;
}

exit main(\$ARGV[0], \$ARGV[1], \$ARGV[2], \$ARGV[3]);

