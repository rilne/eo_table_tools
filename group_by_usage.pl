use strict;

use File::Slurp;

my $table_blob = read_file('playerskilltable.eo4.tbl');

my ($skills, $skill_notes) = load_list('skills.dat');
my ($types,  $type_notes)  = load_list('types.dat');

my $block_size = 376;

my $sub_usage = {};

for my $block (0..273)
{
	my $block_blob = substr($table_blob, $block * $block_size, $block_size);
	
	my $block_header = substr($block_blob, 0, 24);
	
	#print sprintf("%3d:", $block).unpack("H*",$block_header)."\n";
	
	for my $sub (0..7)
	{
		my $sub_blob = substr($block_blob, 24 + $sub * 44, 44);
		my ($type, @values) = unpack("i*", $sub_blob);
		next unless $type;
		push @{$sub_usage->{$type}}, $block;
		
		#print sprintf("%1d:%3d: ", $sub, $type).join(", ",@values)."\n";
	} 
	
}

for my $sub (sort { scalar @{$sub_usage->{$b}} <=> scalar @{$sub_usage->{$a}} || $a <=> $b } keys %{$sub_usage})
{
	print sprintf("[%03d]:[", $sub).$types->{$sub}."]: ". join(", ", map {skill_name($_)} @{$sub_usage->{$sub}}) . "\n";
}

sub skill_name
{
	return "$_:".$skills->{$_};
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