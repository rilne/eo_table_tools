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

my $version_format = {
	"4"	=> {
		"header_len"=> 24,
		"block_size"=> 376,
		"max_block"	=> 273,
		"max_level"	=> 10,
		"columns"	=> 8,
		"zero_lvl"	=> 0,
	},
	"X"	=> {
		"header_len"=> 36,
		"block_size"=> 612,
		"max_block"	=> 769,
		"max_level"	=> 11,
		"columns"	=> 12,
		"zero_lvl"	=> 1,
	},
};

my $version = "X";



my	($block_size, $header_len, $max_block, $max_level, $columns, $zero_lvl) =
	@{$version_format->{$version}}
	{"block_size","header_len","max_block","max_level","columns","zero_lvl"};

my $sub_size = $max_level * 4 + 4;

my ($skills, $skill_notes) = load_list("skills_${version}.dat");
my ($types,  $type_notes)  = load_list("types_${version}.dat");

if(keys %type_targets and not @targets)
{ @targets = (0..$max_block); }
#(length($table_blob)/ $block_size)


for my $block (@targets)
{
	my $block_blob = substr($table_blob, $block * $block_size, $block_size);
	
	my $block_header = substr($block_blob, 0, $header_len);
	
	my $max_level = unpack("c", substr($block_header, 0, 1));
	
	my $buffer_store = "";
	my $valid = 0;
	
	open my $buffer, ">", \$buffer_store;
	
	print $buffer sprintf("  %3d: ", $block).$skills->{$block}."\n";;
	print $buffer sprintf("%05X:head: ",$block * $block_size).unpack("H*",$block_header)."\n";
	
	print $buffer " max level:".join(" ",
		map {	($_ == $max_level)?("main"):
				($_ == $max_level / 2)?(" sub"):
				($_ == 0)?("   0"):("    ")} (!$zero_lvl)..$max_level)." $max_level\n";
	
	for my $sub (0..($columns - 1))
	{
		my $sub_blob = substr($block_blob, $header_len + $sub * $sub_size, $sub_size);
		my ($type, @values) = unpack("i*", $sub_blob);
		next unless $type;
		next unless $search_mode or $type_targets{$type};
		
		print $buffer sprintf("%05X:%4d: ",$block * $block_size + $header_len + $sub * $sub_size, $type)
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