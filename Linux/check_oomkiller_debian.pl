#!/usr/bin/perl

#
# check_oomkiller Nagios & Zabbix plugin
#
# Origanally written by
# John Chivian
# https://exchange.nagios.org/directory/Addons/Others/check_oomkiller/details
# 4/3/2010
#
# Updated for Debian 7/8
# Jacob Mansfield
# 26/10/2015
#

$ENV{'PATH'}="/bin:/usr/bin";

my $pFile='/tmp/.check_oomkiller.previous';
my $hName=`hostname -s`;
chomp ($hName);

#--- If the previous check instance file doesn't exist then initialize one

if (! -e $pFile) {
   unless (open PREV, ">$pFile") {
      print "can't open previous check instance file ($pFile) for writing\n";
      exit (3);
   }
   unless (print PREV "epoch $hName check_oomkiller: initialization\n") {
      print"can't write initialization entry into previous check instance file ($pFile)\n";
      exit (3);
   }
   close (PREV);
}

#--- Make sure the previous check instance file is a regular file and can be read before actually trying to do so

unless (-f $pFile && -r $pFile) {
   print "can't read from previous check instance file ($pFile)\n";
   exit (3);
}

my $prevLine=`head -1 $pFile`;
chomp($prevLine);

#--- Check for OOM Killer activity since the previous check

my $mFile='/var/log/messages';

unless (open MESS, "<$mFile") {
   print "can't open system messages file ($mFile) for reading\n";
   exit (3);
}

my $currLines=0;
my @oomLines=();

while (<MESS>) {
   chomp($_);

   if ($_ =~ /Out of memory: Kill process/) {
      $oomLines[$currLines]=$_;
      $currLines++;

      if ($_ eq $prevLine) {
         @oomLines=();
         $currLines=0;
      }
   }
}

close (MESS);

#--- If no assassinations since previous check then we're done

if ($currLines eq 0) {
   print "no oom-killer activity since previous check\n";
   exit (0);
}

#--- Record the last oom-killer instance

unless (open PREV, ">$pFile") {
   print "can't open previous check instance file ($pFile) for writing\n";
   exit (2);
}
unless (print PREV "$oomLines[$#oomLines]\n") {
   print "can't write current entry into previous check instance file ($pFile)\n";
   exit (2);
}
close (PREV);

#--- Build the array of victims

my $vpid="";
my $vnam="";

my $loopy=0;
my $theLine="";
my @victims=();

while ($loopy <= $#oomLines) {
   $theLine=$oomLines[$loopy];
   chomp($theLine);
   my @stringPieces=split(/process /,$theLine);
   my @substringPieces=split(/ /,$stringPieces[1]);
   $vpid=$substringPieces[0];
   $vnam=substr($substringPieces[1],1,-2);
   $victims[$loopy]="($vpid/$vnam)";
   $loopy++;
}

my $vString=join("",@victims);
print "OOM-Killer Victims: $vString\n";
exit (2);

