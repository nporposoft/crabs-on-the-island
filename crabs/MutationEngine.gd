class_name MutationEngine

extends Node

const permutation_matrices = [
	[5, -5],
	[10, -5],
	[5, -10],
	[5, 5, -5],
	[10, 5, -10]
]


func apply_mutation(stats: Dictionary, mutation: Dictionary) -> Dictionary:
	var new_stats: Dictionary = stats.duplicate()
	for stat in mutation.keys:
		new_stats[stat] += new_stats[stat] (mutation[stat] * 0.01)

func get_mutation_options(stats: Dictionary) -> Dictionary:
	var permutation: Array = permutation_matrices[randi_range(0, permutation_matrices.size())]
	var affected_attributes: Array[String] = _select_random_attributes(stats.keys, permutation.size())
	
	var mutations: Dictionary
	for i in permutation.size():
		mutations[affected_attributes[i]] = permutation[i]
	return mutations


func _select_random_attributes(attributes: Array[String], num_attributes: int) -> Array[String]:
	var selected_attributes: Array[String]
	
	while (selected_attributes.size() < num_attributes):
		var attribute: String = attributes[randi_range(0, attributes.size())]
		
		if selected_attributes.has(attribute):
			continue
			
		selected_attributes.push_back(attribute)
	return selected_attributes
