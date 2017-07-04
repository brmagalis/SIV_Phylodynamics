#!/usr/bin/perl
####################################################
# ©Santiago Sanchez-Ramirez, University of Toronto #
####################################################


my $usage = "
USEAGE:
perl GetPosteriorTrees.pl -burnin <fraction e.g. 0.1 \(default\)>
                     -resample <number of trees or fraction e.g. 1000 or 0.1>
                     -trees <file.trees>
	             -out <outfile>
		     -HPD <true/false, default: true>
	             -lower <likelihood, default: estimate>
     	             -upper <likelihood, default: estimate>
					     
		    Note: the 95% HPD limits in this script are calculated differently than in Tracerv1.5 or LogAnalyserv1.7.5
	            You might want to compare both intervals\n";


my $treefile;
my $outfile;
my $lower=0;
my $upper=0;
my $burnin=0.1;
my $resamp=0;
my $hpd='true';
if ($ARGV[0] eq "-h"){
	die "$usage\n";
} else {
	for (my $i=0; $i<scalar(@ARGV); ++$i){
		if ($ARGV[$i] eq "-trees"){
			$treefile = $ARGV[$i+1];
		}
		if ($ARGV[$i] eq "-out"){
			$outfile = $ARGV[$i+1];
		}
		if ($ARGV[$i] eq "-lower"){
			$lower = $ARGV[$i+1];
			$lower =~ s/\-//;
		}
		if ($ARGV[$i] eq "-upper"){
			$upper = $ARGV[$i+1];
			$upper =~ s/\-//;
		}
		if ($ARGV[$i] eq "-burnin"){  
			$burnin = $ARGV[$i+1];
		}
		if ($ARGV[$i] eq "-resample"){
			$resamp = $ARGV[$i+1];
		}
		if ($ARGV[$i] eq "-HPD"){
			$hpd = $ARGV[$i+1];
		}
	}
}
		
my @startNexus = ();
my @trees = ();
my @NbestTrees=();
my @posteriorTrees=();
my @postBurnPosterior=();
my @globalPosterior=();
open(FILE, $treefile);
open(OUTFILE, $outfile);
my @checkoutfile = <OUTFILE>;
while(<FILE>){
	if ($_ !~ m/^tree/){
		push @startNexus, $_;
	}
	elsif ($_ =~ m/^tree/) {
		my @lines = split(/ /, $_);
		my @posterior = split(/,/, $lines[2]);
		$posterior[1] =~ s/([a-z]+|\=|\]|\-)//g;
		push @trees, "$posterior[1]\t$lines[5]";
		push @globalPosterior, "$posterior[1]";
	}
}

pop(@startNexus);
my $burninStart;
if ($burnin < 1){
	$burninStart=int(scalar(@trees)*$burnin);
}
elsif ($burnin > 1){
	$burninStart=$burnin;
}

print "Your tree file has " . scalar(@trees) . " trees...\n";
print "Discarting the first " . $burninStart . " samples\n";

my @posteriorTrees=@trees[$burninStart..$#trees];
my @postBurnPosterior=@globalPosterior[$burninStart-1..$#globalPosterior];

if ($hpd eq 'true'){
	my $p95=95;
	my $p5=5;
	my @s_postBurnPosterior = sort { $a <=> $b } @postBurnPosterior;
	my $pos95 = int( scalar(@postBurnPosterior) * ( $p95 / 100 ) );
	my $pos5 = int( scalar(@postBurnPosterior) * ( $p5 / 100 ) );

	if (($lower == 0) && ($upper == 0)){
		$lower = @s_postBurnPosterior[$pos95];
		$upper = @s_postBurnPosterior[$pos5];
	}
	
	print "Subsampling on confidence interval\n";
	print "Lower HPD limit is : -$lower\nUpper HPD limit is : -$upper\n";

	for (my $i=0; $i<scalar(@trees); ++$i){
		my @line = split(/\t/, $trees[$i]);
		if (($line[0] <= $lower) && ($line[0] >= $upper)){
			push @NbestTrees, "$line[0]\t$line[1]";
		}
	}
} elsif ($hpd eq 'false'){
	print "Trees will not be extracted from a confidence interval\n";

	for (my $i=0; $i<scalar(@trees); ++$i){
		my @line = split(/\t/, $trees[$i]);
		push @NbestTrees, "$line[0]\t$line[1]";
	}
}

my $everyXtrees=0;
my $posTreeNum = scalar(@NbestTrees);
if ($resamp != 0){
	if ($resamp < 1){
		$resamp = int(scalar(@trees)*$resamp);
		$everyXtrees = int(scalar(@NbestTrees)/$resamp);
		print "Resampling every:\t" . $everyXtrees . " for a total of $resamp trees..." .  "\n";
	}
	elsif ($resamp > 1){
		$everyXtrees = int(scalar(@NbestTrees)/$resamp);
		print "Resampling every: " . $everyXtrees . " for a total of $resamp trees..." . "\n";
	}
} else {
	if ($hpd eq 'true'){
		print "The total number of trees in your HPD interval is: $posTreeNum\n";
	}
}


if (scalar(@checkoutfile) != 0){
	print "$outfile has data. Do you wish to replace? (y | n):";
	chomp ($answer = <STDIN>);
	if ($answer eq "y"){
		close OUTFILE;
		open(OUTFILE, ">$outfile");
		print OUTFILE "";
		close OUTFILE;
		open(OUTFILE, ">>$outfile");
	}
	elsif ($answer eq "n"){
		die "Exiting...\n";
	}
} else {
	open(OUTFILE, ">>$outfile");
}
my $count=-1;
my $temp = $everyXtrees;

if ($resamp != 0){
	print OUTFILE @startNexus;
	for (my $i=0; $i<scalar(@NbestTrees); ++$i){
		my $x;
		for (my $j=0; $j<$resamp; ++$j){
			$x = $everyXtrees+=$temp;
		}
		my $w = int($x/$resamp);
		++$count;
		my $treeNum = $count+1;
		my @lines = split(/\t/, $NbestTrees[$w]);
		if ($i >= $resamp){
			last;
		} else {
			print OUTFILE "tree $treeNum \[&posterior=\-$lines[0]\] \= $lines[1]";
		}
	}
	print OUTFILE "END\;\n";
} elsif ($resamp == 0) {
	print OUTFILE @startNexus;
	for (my $i=0; $i<scalar(@NbestTrees); ++$i){
		my @posterior = split(/\t/, $NbestTrees[$i]);
		++$count;
		my $treeNum = $count+1;
		print OUTFILE "tree $treeNum \[\&posterior=\-$posterior[0]\] \= $posterior[1]";
	}
	print OUTFILE "END;\n";
}

