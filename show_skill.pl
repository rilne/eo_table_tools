use strict;

use File::Slurp;

my $table_blob = read_file(shift);
my @targets = ();
my %type_targets = ();
my $search_mode = 0;
while(@ARGV)
{
	my $item = shift @ARGV;
	if($item eq "-t") { $type_targets{shift @ARGV} = 1; }
	elsif($item eq "-x") { $search_mode = 1; }
	else { push @targets, $item; }
}
$search_mode = 1 if not keys %type_targets;

my $block_size = 376;

my ($skills, $skill_notes) = load_list('skills.dat');
my ($types,  $type_notes)  = load_list('types.dat');

if(keys %type_targets and not @targets)
{ @targets = (0..273); }
#(length($table_blob)/ $block_size)


for my $block (@targets)
{
	my $block_blob = substr($table_blob, $block * $block_size, $block_size);
	
	my $block_header = substr($block_blob, 0, 24);
	
	my $max_level = unpack("c", substr($block_header, 0, 1));
	
	my $buffer_store = "";
	my $valid = 0;
	
	open my $buffer, ">", \$buffer_store;
	
	print $buffer sprintf("  %3d: ", $block).$skills->{$block}."\n";;
	print $buffer sprintf("%05X:head: ",$block * $block_size).unpack("H*",$block_header)."\n";
	
	print $buffer " max level:".join(" ",
		map {	($_ == $max_level)?("main"):
				($_ == $max_level / 2)?(" sub"):("    ")} 1..10)." $max_level\n";
	
	for my $sub (0..7)
	{
		my $sub_blob = substr($block_blob, 24 + $sub * 44, 44);
		my ($type, @values) = unpack("i*", $sub_blob);
		next unless $type;
		next unless $search_mode or $type_targets{$type};
		
		print $buffer sprintf("%05X:%4d: ",$block * $block_size + 24 + $sub * 44, $type)
			.join(", ", map {sprintf("%3d", $_)} @values)." ".
			($types->{$type} // "unknown")."\n";
		
		$valid = 1 if not keys %type_targets or $type_targets{$type};
	} 
	
	close $buffer;
	print $buffer_store if $valid or not keys %type_targets;
}

sub load_list
{
	my $list = {};
	my $notes = {};
	
	open my $in_file, "<", shift;
	while(<$in_file>)
	{
		chomp;
		next unless $_ =~ m{^([0-9]+) \s+ (.+?) (?: \s+ -- \s+ (.+))?$}x;
		$list->{$1} = $2;
		if(defined $3){ $notes->{$1} = $3; }
	}
	close $in_file;
	return $list, $notes;
}