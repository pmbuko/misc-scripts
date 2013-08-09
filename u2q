#!/usr/bin/perl -w
use strict;

# This script automates the process of adding usersets to the user_lists section
# of the SGE cluster queue configs. It takes the userset name as a command line
# argument or it prompts for the userset name if no argument is given. It
# currently supports adding one userset at a time.

# queues to be modified
my @queues = qw(
  archive.q
  f00.q
  f15.q
  f16.q
  gpu.q
  interactive.q
  jain_kep.q
  jain_tes.q
  new.q
  old.q
  short.q
  );

my $input=$ARGV[0];

# If no arguments passed, print helpful info and prompt for userset name
if (! defined($input)) {
  print join( "\n  ", "\nThis command will add a new userset to the following cluster queues:\n" , @queues , "\n" );

  # Get input from STDIN.
  print "Enter the name of the new userset (or ^c to exit): ";
  chomp($input=<STDIN>);
}

foreach my $queue (@queues) {

  # put contents of old queue into @LINES array.
  my $getq = "qconf -sq $queue";
  chomp(my(@LINES)=`$getq`);

  # create a new config file in temp location
  open(NEWCONF,">/dev/shm/$queue") || die "Cannot create $queue";
  foreach my $line (@LINES) {
    # if the current line is the user_lists line
    if ( $line =~ m/^user_lists/ ) {
      # add the new userset to the end of the first user_lists line
	    $line =~ s/ \\$//;
      print NEWCONF "$line $input \\\n";
    } else {  # print the line unmodified
      print NEWCONF "$line\n";
    }
  }
  close(NEWCONF);

  # read in new config in place of old one
  system("qconf -Mq /dev/shm/$queue");

  # delete the temp config file
  unlink("/dev/shm/$queue");
}
