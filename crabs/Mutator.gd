class_name MutationEngine

extends Node

const permutation_matrices = [
	[5, -5],
	[10, -5],
	[5, -10],
	[5, 5, -5],
	[10, 5, -10]
]


static func apply_mutation(stats: Dictionary, mutation: Dictionary) -> Dictionary:
	var new_stats: Dictionary = stats.duplicate()
	for stat in mutation.keys():
		new_stats[stat] += new_stats[stat] * (mutation[stat] * 0.01)
	return new_stats

static func get_mutation_options(stats: Dictionary) -> Dictionary:
	var permutation: Array = permutation_matrices[randi_range(0, permutation_matrices.size() - 1)]
	var affected_attributes: Array = _select_random_attributes(stats.keys(), permutation.size())
	
	var mutations: Dictionary
	for i in affected_attributes.size():
		mutations[affected_attributes[i]] = permutation[i]
	return mutations


static func _select_random_attributes(attributes: Array, num_attributes: int) -> Array[String]:
	if num_attributes > attributes.size():
		push_error("Mutator error: attempting to mutate more attributes than there are")
		return []
	
	var selected_attributes: Array[String]
	
	while (selected_attributes.size() < num_attributes):
		var attribute: String = attributes[randi_range(0, attributes.size() - 1)]
		
		if selected_attributes.has(attribute):
			continue
			
		selected_attributes.push_back(attribute)
	return selected_attributes
